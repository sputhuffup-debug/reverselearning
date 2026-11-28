# How C control flow compiles

This primer shows what `if`, loops, `switch`, calls and recursion look like once GCC has compiled them. [Day 3](../day3-training.md) relies on all of it, and [Day 2](../day2-training.md) on the last section about `-O2`. Reading time: about 30 minutes.

## How to read the examples

Each example puts a few lines of C next to the assembly MinGW GCC makes at `-O0` on 64-bit Windows. Labels such as `.Lbody` stand for addresses; in Ghidra you see real addresses and names like `LAB_1400015a3`. The exact registers, offsets and label order vary between builds, so learn the shapes rather than the numbers.

All the examples assume a frame built with `push rbp` and `mov rbp, rsp`. Locals are at `[rbp-0x4]` and below, and the first argument is saved at `[rbp+0x10]`. [The stack and the calling convention](05-stack-and-calls.md) explains why. If an instruction is new to you, look it up in [Reading assembly](03-reading-assembly.md).

Every decision in machine code is two steps. A `cmp` or `test` sets the flags. Then a conditional jump (a **jcc**, such as `jle` or `jne`) jumps or falls through based on them. [Registers and flags](02-registers-and-flags.md) lists the jumps and the flags they read.

## if

```c
if (x > 5)
    y = 1;
```

```
cmp  dword ptr [rbp+0x10], 5    ; compare x with 5
jle  .Lskip                     ; x <= 5: skip the body
mov  dword ptr [rbp-0x4], 1     ; y = 1
.Lskip:
```

The jump goes around the body, so it tests the **opposite** of the C condition. The C says `x > 5`; the jump says "if `x <= 5`, skip". Expect this inversion almost everywhere at `-O0`.

The kind of jump also tells you the type. `jl`, `jle`, `jg` and `jge` compare signed values. `jb`, `jbe`, `ja` and `jae` compare unsigned values, so a `ja` hints at an `unsigned` variable or a pointer.

A check against zero often uses `test` instead of `cmp`. `test eax, eax` sets ZF when EAX is 0, so `if (f())` becomes `test eax, eax` followed by `je` around the body.

## if-else

```c
if (x > 5)
    y = 1;
else
    y = 2;
```

```
cmp  dword ptr [rbp+0x10], 5
jle  .Lelse                     ; condition false: go to the else part
mov  dword ptr [rbp-0x4], 1     ; then part: y = 1
jmp  .Lend                      ; skip over the else part
.Lelse:
mov  dword ptr [rbp-0x4], 2     ; else part: y = 2
.Lend:
```

The signature of an if-else is the unconditional `jmp` at the end of the first block. It jumps over the second block, so only one of the two runs. In Ghidra's Function Graph this is a diamond: one block splits in two, and the two meet again.

## && and ||

C stops evaluating `&&` and `||` as soon as the answer is known. This is called **short-circuiting**, and it turns each part of the condition into its own compare and jump.

```c
if (a > 0 && b > 0)
    r = 1;
```

```
cmp  dword ptr [rbp+0x10], 0    ; a > 0 ?
jle  .Lend                      ; no: the whole && is false
cmp  dword ptr [rbp+0x18], 0    ; b > 0 ?
jle  .Lend                      ; no: false
mov  dword ptr [rbp-0x4], 1     ; both true
.Lend:
```

For `&&`, every failed test jumps to the same place: past the body.

```c
if (a == 3 || b == 4)
    r += 2;
```

```
cmp  dword ptr [rbp+0x10], 3    ; a == 3 ?
je   .Lbody                     ; yes: the whole || is true, go straight to the body
cmp  dword ptr [rbp+0x18], 4    ; b == 4 ?
jne  .Lend                      ; no: false
.Lbody:
add  dword ptr [rbp-0x4], 2
.Lend:
```

For `||`, the first test is **not** inverted: a true part jumps into the body. Only the last test is inverted and jumps past it. Several jumps aimed at the same target usually mean `&&` or `||`.

## Loops: for and while

At `-O0`, GCC puts the loop test at the bottom. It jumps down to the test first, then the test jumps back up to the body while the condition holds.

```c
for (i = 0; i < 8; i++)
    sum += a[i];
```

```
mov  dword ptr [rbp-0x8], 0     ; i = 0
jmp  .Lcond                     ; go to the test first
.Lbody:
...                             ; sum += a[i]
add  dword ptr [rbp-0x8], 1     ; i++
.Lcond:
cmp  dword ptr [rbp-0x8], 7     ; i <= 7 ?  (same as i < 8)
jle  .Lbody                     ; yes: run the body again
```

Notice that GCC wrote `i < 8` as `i <= 7`, with `cmp ..., 7` and `jle`. The test at the bottom is **not** inverted, because it jumps when the loop should go on.

A `while` loop has the same shape, without the setup and the increment:

```c
while (s[i] != 0)
    i++;
```

```
jmp  .Lcond                     ; go to the test first
.Lbody:
add  dword ptr [rbp-0x8], 1     ; i++
.Lcond:
mov  eax, dword ptr [rbp-0x8]   ; load i
movsx rdx, eax                  ; widen it to 64 bits for the address
mov  rax, qword ptr [rbp+0x10]  ; load s
add  rax, rdx                   ; rax = s + i
movzx eax, byte ptr [rax]       ; read s[i]
test al, al                     ; is it 0?
jne  .Lbody                     ; no: loop again
```

So a `for` and a `while` look almost the same in assembly. A counter set just before the first `jmp` and changed just before the test suggests a `for`. The decompiler often picks one or the other no matter what the source said.

## Loops: do-while

```c
do {
    sum--;
} while (sum > 100);
```

```
.Lbody:
sub  dword ptr [rbp-0x4], 1     ; sum--
cmp  dword ptr [rbp-0x4], 100   ; sum > 100 ?
jg   .Lbody                     ; yes: loop again
```

There is no `jmp` to the test before the body, so the body always runs at least once. That missing first jump is the only difference from a `while`.

| Loop | First instruction of the loop | Test | How to spot it |
| --- | --- | --- | --- |
| `for` | Set the counter, then `jmp` to the test | At the bottom, jumps back up | Counter set before the `jmp`, changed just before the test |
| `while` | `jmp` to the test | At the bottom, jumps back up | Like `for`, without the counter pattern |
| `do`-`while` | The body itself | At the bottom, jumps back up | No `jmp` before the body |

In every case, a conditional jump to a **lower** address closes a loop. In the Function Graph it is an arrow that points back up.

## break and continue

`break` leaves the loop, so it becomes a jump to the first instruction after the loop. `continue` skips the rest of the body, so in a `for` loop it jumps to the increment. In a `while` loop it jumps to the test.

```c
for (i = 0; i < 8; i++) {
    if (s[i] == ' ') continue;
    if (s[i] == 0) break;
    sum += s[i];
}
```

```
        mov  dword ptr [rbp-0x8], 0
        jmp  .Lcond
.Lbody: ...                     ; load s[i] into AL
        cmp  al, 0x20           ; a space?
        je   .Lnext             ; continue: jump to the increment
        ...                     ; load s[i] again
        test al, al             ; the end of the string?
        je   .Lafter            ; break: jump out of the loop
        ...                     ; sum += s[i]
.Lnext: add  dword ptr [rbp-0x8], 1     ; i++
.Lcond: cmp  dword ptr [rbp-0x8], 7
        jle  .Lbody
.Lafter:
```

A conditional jump out of the middle of a loop, to the code after it, is a `break` or a `return`. Several exits are also what `&&` in a loop condition looks like, as in Day 3's `ex2`.

## switch: a chain of compares

A `switch` with few cases, or cases far apart, becomes a chain of compares:

```c
switch (opt) {
case 1:  return 10;
case 7:  return 20;
case 40: return 30;
}
return 0;
```

```
cmp  dword ptr [rbp+0x10], 40
je   .Lcase40
cmp  dword ptr [rbp+0x10], 40
jg   .Ldefault                  ; above 40: no case matches
cmp  dword ptr [rbp+0x10], 1
je   .Lcase1
cmp  dword ptr [rbp+0x10], 7
je   .Lcase7
jmp  .Ldefault
```

GCC may split the chain into a small tree, as here with the `jg`. Either way, each case is one `cmp` and one `je`. Ghidra's decompiler turns this back into a `switch` or a run of `if`s.

## switch: a jump table

With many cases close together, GCC builds a **jump table**: an array in `.rdata` with one entry per case value. The code uses the value as an index into it and jumps to the address it finds.

```c
switch (opt) {
case 0: puts("a"); break;
case 1: puts("b"); break;
...
case 5: puts("f"); break;
default: puts("z"); break;
}
```

```
cmp  dword ptr [rbp+0x10], 5    ; 1. bounds check against the highest case
ja   .Ldefault                  ;    unsigned: negatives also go to default
mov  eax, dword ptr [rbp+0x10]  ; 2. the value becomes the index
lea  rdx, [rax*4]               ;    each entry is 4 bytes
lea  rax, [.Ltable]             ;    address of the table
mov  eax, dword ptr [rdx+rax]   ;    read the entry: an offset
cdqe                            ;    sign-extend it to 64 bits
lea  rdx, [.Ltable]
add  rax, rdx                   ; 3. target = table + offset
jmp  rax                        ;    indirect jump to the case
```

The three parts are always there. A **bounds check** sends values outside the table to `default`. A **table lookup** reads an entry. An **indirect jump**, `jmp rax`, goes to an address held in a register.

MinGW GCC stores each entry as a 4-byte offset from the start of the table, not as a full address. If the lowest case isn't 0, a `sub eax, lowest` comes before the bounds check.

**What Ghidra shows.** Ghidra's analysis reads the table and recovers every target. In the Listing it labels the indirect jump `switchD`, the targets `caseD_0`, `caseD_1` and so on, and the table `switchdataD`. The decompiler then shows an ordinary `switch`. Day 3's Module 1 walks through this, including what to do when recovery fails.

## Function calls and return values

A call loads the arguments into RCX, RDX, R8 and R9, runs `call`, and finds the result in EAX or RAX. [The stack and the calling convention](05-stack-and-calls.md) covers the details. In control flow, what matters is what happens to the result next:

```c
if (check(code))
    puts("Door unlocked.");
```

```
lea  rax, [rbp-0x20]            ; address of the local array code
mov  rcx, rax                   ; argument 1
call check
test eax, eax                   ; did it return 0?
je   .Lskip                     ; yes: skip the body
...
```

A `test eax, eax` right after a `call` means the result is used as true or false. A `mov dword ptr [rbp-0x14], eax` means it was stored in a local. If nothing reads EAX before the next call, the result is ignored.

Inside the callee, `return x;` becomes a load into EAX and a jump to the epilogue. Functions with several `return`s often share one epilogue, so look for several `jmp`s to the same address near the end.

## Recursion

A **recursive** function calls itself. In the Listing, that is a `call` whose target is the start of the function it is in.

```c
int fact(int n) {
    if (n <= 1) return 1;
    return n * fact(n - 1);
}
```

```
fact:
    push rbp
    mov  rbp, rsp
    sub  rsp, 0x20                 ; shadow space for the call below
    mov  dword ptr [rbp+0x10], ecx ; save n in its home slot
    cmp  dword ptr [rbp+0x10], 1   ; n <= 1 ?
    jg   .Lrecurse
    mov  eax, 1                    ; base case: return 1
    jmp  .Lend
.Lrecurse:
    mov  eax, dword ptr [rbp+0x10]
    sub  eax, 1
    mov  ecx, eax                  ; argument: n - 1
    call fact                      ; the call to itself
    imul eax, dword ptr [rbp+0x10] ; result * n
.Lend:
    add  rsp, 0x20
    pop  rbp
    ret
```

Each call gets its own frame, so each one has its own `n`. At `-O0` each `n` is saved in the shadow space its caller reserved, just above the return address. When `fact(3)` calls `fact(2)` and then `fact(1)`, three frames sit on the stack at once:

```
        higher addresses
          |  main's frame                       |
          |    its shadow space: n = 3          |
          |  return address into main           |
          |  fact(3): saved RBP                 |
          |    its shadow space: n = 2          |
          |  return address into fact(3)        |
          |  fact(2): saved RBP                 |
          |    its shadow space: n = 1          |
          |  return address into fact(2)        |
          |  fact(1): saved RBP                 |
 rsp -->  |    its shadow space (unused)        |
        lower addresses
```

`fact(1)` returns 1 in EAX. `fact(2)` multiplies it by its own `n`, which is still in its frame, and returns 2. Then `fact(3)` returns 6. Look for the **base case** first: the test that returns without calling itself.

## What -O2 changes

Optimized code keeps the same logic but reshapes it. [Day 2](../day2-training.md) covers this in depth; these are the changes that affect control flow.

| Change | What you see | Example at `-O2` |
| --- | --- | --- |
| Values kept in registers | No `[rbp-n]` loads and stores; often no `push rbp` at all | A loop counter lives in ECX the whole time |
| Inlining | A small function's body is copied into its caller; the `call` disappears | `sq(x) + 3` becomes `imul ecx, ecx` and `lea eax, [rcx+3]` |
| Tail calls | `return g(x);` becomes `jmp g` instead of `call` and `ret` | `add ecx, 1` then `jmp check` |
| Reshaped loops | One test before the loop, one at the bottom; counters become pointers | `add rcx, 4`, `cmp rcx, rdx`, `jne` |
| Recursion removed | A simple recursive function can become a loop | `fact` turns into a loop with `imul`, and no `call` |
| Fewer jumps | Short if-else turns into `cmov` or `setcc`, which choose a value without jumping | `cmovg eax, edx` |

The decompiler rebuilds C from either version, so it hides much of this. The Listing shows all of it, and that's where Day 2 and Day 3 have you look.

## Check yourself

1. The C says `if (n == 0)`. Which conditional jump do you expect at `-O0` before the body, and why?
2. How can you tell an if-else from a plain `if` in the Listing?
3. You see `cmp dword ptr [rbp-0x8], 9` followed by `jle` to a lower address. What loop condition is that likely to be?
4. What single difference tells a `do`-`while` from a `while` at `-O0`?
5. Name the three parts of a jump table `switch`, and say why the bounds check uses `ja`.
6. What does `continue` compile to in a `for` loop?
7. How do you recognize a recursive function in the Listing?
8. A function ends with `jmp` to another function instead of `call` and `ret`. What is that called, and what does it mean for the call stack in x64dbg?

<details><summary>Answers</summary>

1. `jne`, around the body. The jump skips the body when the condition is false, so it tests the opposite.
2. An if-else has an unconditional `jmp` at the end of the first block that jumps over the second block.
3. `i < 10` (written by GCC as `i <= 9`) in a `for` or `while` loop.
4. A `do`-`while` has no `jmp` to the test before the body, so the body runs at least once.
5. The bounds check, the table lookup and the indirect jump. `ja` compares unsigned, so negative values look huge and also go to `default`.
6. A jump to the increment, just before the loop test.
7. It contains a `call` to its own start address. Ghidra's Function Call Trees also list it among its own outgoing calls.
8. A tail call. The middle function leaves no return address behind, so it is missing from the call stack.

</details>

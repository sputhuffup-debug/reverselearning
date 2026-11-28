# The stack and the calling convention

This primer explains how functions use the stack, and how they pass arguments and results on 64-bit Windows. It ends with a real `main` from Day 1, walked through line by line. [Day 1](../day1-training.md) needs everything up to "The Windows x64 calling convention"; [Day 2](../day2-training.md) builds on all of it. Reading time: about 40 minutes.

## What the stack is

The **stack** is a region of memory where functions keep short-lived data: local variables, saved registers and the addresses to return to. Each thread has one. [A program in memory](04-memory-layout.md) shows where it sits among the other regions.

It works like a pile of plates: you add to the top and take from the top. On x86-64 the top is at the lowest address, so the stack **grows down**. Adding an item moves the top to a lower address.

The register **RSP** (the stack pointer) holds the address of the top. Everything at RSP and above is in use; everything below it is free. [Registers and flags](02-registers-and-flags.md) introduces RSP with the other registers.

## Push and pop

`push` and `pop` add and remove 8 bytes at a time:

| Instruction | What it does |
| --- | --- |
| `push rbp` | RSP = RSP − 8, then write RBP to `[rsp]` |
| `pop rbp` | Read `[rsp]` into RBP, then RSP = RSP + 8 |
| `sub rsp, 0x70` | Reserve 0x70 bytes at once, without writing anything |
| `add rsp, 0x70` | Release those 0x70 bytes |

Popped memory isn't wiped. The old values stay there until something overwrites them, which is why you sometimes see stale data below RSP in x64dbg.

## Call and ret

`call` and `ret` use the stack to remember where to come back to.

- `call target` pushes the **return address**, the address of the instruction right after the `call`. Then it jumps to `target`.
- `ret` pops the return address into RIP, so execution continues right after the `call`.

So `call` is a `push` plus a `jmp`, and `ret` is a `pop` into RIP. If a function leaves RSP anywhere else when it reaches `ret`, it returns to the wrong place and usually crashes.

## Stack frames

A function's **frame** is the part of the stack it owns while it runs. At `-O0`, GCC builds every frame the same way. The first instructions, the **prologue**, set it up:

```
push rbp           ; save the caller's RBP
mov  rbp, rsp      ; RBP now marks this frame
sub  rsp, 0x70     ; reserve space for locals and for calls this function makes
```

The last instructions, the **epilogue**, take it down again:

```
add  rsp, 0x70     ; release the space        (or: leave, which does
pop  rbp           ; restore the caller's RBP  mov rsp, rbp then pop rbp)
ret                ; return to the caller
```

MinGW GCC usually writes `add rsp` and `pop rbp`. Other compilers, and some GCC builds, use `leave` instead; it does the same job.

**RBP** (the frame pointer) stays fixed for the whole function, while RSP can still move. That makes RBP a steady reference point: locals are at negative offsets from it, and the caller's data at positive ones.

Here is the stack right after a `call`, before the prologue runs. Higher addresses are at the top; the stack grows down the page.

```
        higher addresses
          |  caller's frame                |
          |  arguments 5, 6, ... (if any)  |  rsp+0x28, rsp+0x30 ...
          |  shadow space, 32 bytes        |  rsp+0x08 to rsp+0x27
 rsp -->  |  return address                |  rsp+0x00
        lower addresses
```

The shadow space is explained under the calling convention below. Here is the same stack after `push rbp`, `mov rbp, rsp` and `sub rsp, 0x70`:

```
        higher addresses
          |  arguments 5, 6, ... (if any)  |  rbp+0x30, rbp+0x38 ...
          |  shadow space, 32 bytes        |  rbp+0x10 to rbp+0x2f
          |  return address                |  rbp+0x08
 rbp -->  |  caller's saved RBP            |  rbp+0x00
          |  local variables               |  rbp-0x01 and down
          |  ...                           |
          |  space for calls this function |
          |  makes (their shadow space and |
          |  stack arguments)              |
 rsp -->  |                                |  rbp-0x70
        lower addresses
```

## Locals and how Ghidra names them

At `-O0` every local variable has a fixed slot in the frame, at a negative offset from RBP. An `int` might be `[rbp-0x4]` and a 64-byte buffer `[rbp-0x40]`, which covers `rbp-0x40` to `rbp-0x1`. The compiler picks the order, so it may not match the source.

Ghidra measures stack offsets from a different point: the value RSP had when the function started. At that moment `[rsp]` is the return address, which is `Stack[0x0]`. The `push rbp` puts RBP 8 bytes lower, so `rbp-0x40` is `Stack[-0x48]`.

Ghidra names each stack variable from that offset:

| Listing operand | Ghidra's stack offset | Default name |
| --- | --- | --- |
| `[RBP + -0x40]` | `Stack[-0x48]` | `local_48` |
| `[RBP + -0x4]` | `Stack[-0xc]` | `local_c` |
| `[RBP + 0x10]` | `Stack[0x8]` | `local_res8` (the first shadow-space slot) |

The list of variables sits at the top of each function in the Listing. In instructions, Ghidra shows both forms, for example `LEA RAX=>local_48,[RBP + -0x40]`. Rename a local with `L` and the new name appears everywhere it's used.

## The Windows x64 calling convention

A **calling convention** is the set of rules a caller and a callee agree on: where arguments go, where the result comes back, and which registers survive a call. All 64-bit Windows code uses one convention, so these rules hold for your code, MinGW's runtime and Windows DLLs alike.

**Arguments.** The first four integer or pointer arguments go in registers, by position:

| Argument | 64-bit | 32-bit (an `int`) | Floating-point |
| --- | --- | --- | --- |
| 1 | RCX | ECX | XMM0 |
| 2 | RDX | EDX | XMM1 |
| 3 | R8 | R8D | XMM2 |
| 4 | R9 | R9D | XMM3 |
| 5 and up | stack | stack | stack |

The slot is chosen by position, not by type. In `f(int a, double b)`, `a` goes in ECX and `b` goes in XMM1, and RDX and XMM0 go unused.

Writing a 32-bit register such as EDX also clears the top half of RDX. So `mov edx, 0xe` sets the full RDX to 14, which is how GCC often passes a small `size_t`.

**Stack arguments.** Arguments 5 and up are written to the stack before the `call`. At the `call`, argument 5 is at `[rsp+0x20]` and argument 6 at `[rsp+0x28]`. Inside the callee the return address sits on top, so they appear 8 bytes higher.

**Shadow space.** The caller always reserves 32 bytes just above the return address, even if the callee takes fewer than four arguments. This is the **shadow space** (also called home space). The callee may use it freely; GCC at `-O0` stores RCX, RDX, R8 and R9 there:

```
mov dword ptr [rbp+0x10], ecx     ; argument 1 goes to its home slot
mov dword ptr [rbp+0x18], edx     ; argument 2
```

That is why stack arguments start at `[rsp+0x20]`: the 32 bytes below them are the shadow space.

**Return value.** The result comes back in RAX, or EAX for an `int`. A `double` comes back in XMM0. A caller that tests a result uses `test eax, eax` right after the `call`.

## Volatile and non-volatile registers

A call can destroy some registers and must keep others. **Volatile** registers (caller-saved) may hold anything after a call; if the caller needs a value in one, it saves it first. **Non-volatile** registers (callee-saved) must hold the same value after the call; a callee that uses one pushes it first and pops it before `ret`.

| Kind | Registers |
| --- | --- |
| Volatile (caller-saved) | RAX, RCX, RDX, R8, R9, R10, R11, XMM0 to XMM5 |
| Non-volatile (callee-saved) | RBX, RBP, RDI, RSI, RSP, R12 to R15, XMM6 to XMM15 |

This explains two patterns you will see. A function that starts with `push rbx` and `push rsi` uses those registers and must restore them. And a value that must outlive a call is kept in a non-volatile register or on the stack, never in RCX.

## Stack alignment

RSP must be a multiple of 16 at every `call` instruction. The `call` then pushes 8 bytes, so at a function's first instruction RSP ends in `8` in hex. Some instructions that move 16 bytes at a time crash on misaligned data, so the rule matters.

This is why frame sizes look odd. In the example below, `push rbp` brings RSP back to a multiple of 16, and `sub rsp, 0x70` keeps it there. The compiler rounds each frame up to keep the rule.

## Worked example: ex3's main

This is the Listing Ghidra 12.2 produced for `main` in Day 1's `ex3.exe`, built with `gcc -O0 -s`. The comments in parentheses are annotations added here. The addresses will differ on your build, and so may the `FUN_` names; the shape will be the same.

The source is [ex3\_crackme.c](../../lab/day1/ex3_crackme.c). Read it alongside if you have finished Day 1's Module 3; otherwise, treat this section as a spoiler and come back later.

```
1400014f3 PUSH RBP
1400014f4 MOV RBP,RSP
1400014f7 SUB RSP,0x70
1400014fb CALL 0x1400016a0
140001500 MOV RAX,qword ptr [0x14000e238]
140001507 CALL RAX                          (IsDebuggerPresent)
140001509 TEST EAX,EAX
14000150b JZ 0x140001526
14000150d LEA RAX,[0x14000a00e]             ("Debugger detected. Bye.")
140001514 MOV RCX,RAX
140001517 CALL 0x140008bc8                  (puts)
14000151c MOV EAX,0x2
140001521 JMP 0x1400015c8
140001526 LEA RAX,[0x14000a026]             ("License key: ")
14000152d MOV RCX,RAX
140001530 CALL 0x140002850                  (printf)
140001535 MOV ECX,0x0
14000153a MOV RAX,qword ptr [0x1400090f0]
140001541 CALL RAX                          (returns stdin)
140001543 MOV RDX,RAX
140001546 LEA RAX,[RBP + -0x40]
14000154a MOV R8,RDX
14000154d MOV EDX,0x40
140001552 MOV RCX,RAX
140001555 CALL 0x140008b90                  (fgets)
14000155a TEST RAX,RAX
14000155d JNZ 0x140001566
14000155f MOV EAX,0x1
140001564 JMP 0x1400015c8
140001566 LEA RDX,[0x14000a034]             ("\r\n")
14000156d LEA RAX,[RBP + -0x40]
140001571 MOV RCX,RAX
140001574 CALL 0x140008be8                  (strcspn)
140001579 MOV byte ptr [RBP + RAX*0x1 + -0x40],0x0
14000157e LEA RAX,[RBP + -0x4f]
140001582 MOV EDX,0xe
140001587 MOV RCX,RAX
14000158a CALL 0x140001490                  (decode)
14000158f LEA RDX,[RBP + -0x4f]
140001593 LEA RAX,[RBP + -0x40]
140001597 MOV RCX,RAX
14000159a CALL 0x140008be0                  (strcmp)
14000159f TEST EAX,EAX
1400015a1 JNZ 0x1400015b4
1400015a3 LEA RAX,[0x14000a037]             ("License OK. Welcome!")
1400015aa MOV RCX,RAX
1400015ad CALL 0x140008bc8                  (puts)
1400015b2 JMP 0x1400015c3
1400015b4 LEA RAX,[0x14000a04c]             ("Bad license key.")
1400015bb MOV RCX,RAX
1400015be CALL 0x140008bc8                  (puts)
1400015c3 MOV EAX,0x0
1400015c8 ADD RSP,0x70
1400015cc POP RBP
1400015cd RET
```

### The prologue and the frame

`PUSH RBP`, `MOV RBP,RSP` and `SUB RSP,0x70` build the frame. The source has two locals: `char input[64]` and `char key[15]`. The code puts `input` at `RBP-0x40` and `key` at `RBP-0x4f`, which Ghidra names `local_48` and `local_57`.

The 0x70 bytes hold those 79 bytes of locals plus 32 bytes of shadow space for the calls `main` makes. 0x4f + 0x20 = 0x6f, rounded up to 0x70 for alignment. This is `main`'s frame after the prologue:

```
        higher addresses
          |  shadow space from main's caller |  rbp+0x10 to rbp+0x2f
          |  return address into MinGW start |  rbp+0x08
 rbp -->  |  saved RBP                       |  rbp+0x00
          |  input[64]                       |  rbp-0x40 to rbp-0x01
          |  key[15]                         |  rbp-0x4f to rbp-0x41
          |  1 unused byte                   |  rbp-0x50
          |  shadow space for main's calls   |  rbp-0x70 to rbp-0x51
 rsp -->  |                                  |  rsp = rbp-0x70
        lower addresses
```

### The hidden call: \_\_main

`CALL 0x1400016a0` has no match in the source. It is MinGW's `__main`, which GCC inserts at the start of every `main`. It runs static initializers (code that must run before `main`, such as C++ constructors of globals) once. In a C program it does almost nothing, and you can step over it.

### IsDebuggerPresent through the IAT

`windows.h` declares `IsDebuggerPresent` with `dllimport`, which tells GCC it lives in a DLL. So GCC reads its address from the IAT slot at `0x14000e238` and calls through RAX. [A program in memory](04-memory-layout.md) explains the IAT.

The result comes back in EAX. `TEST EAX,EAX` sets ZF when it is 0, and `JZ` skips ahead when no debugger is found. Note the inverted test: the source says "if a debugger is present", while the jump says "if not, skip this block".

If the jump is not taken, `puts` prints the message, `MOV EAX,0x2` sets the return value, and `JMP 0x1400015c8` goes straight to the epilogue. That is `return 2;`.

### printf, and calls through stubs

`LEA RAX,[0x14000a026]` loads the address of "License key: " in `.rdata`, and `MOV RCX,RAX` makes it argument 1. At `-O0`, GCC often builds a value in RAX first and then copies it, so expect that extra `MOV`.

`FUN_140002850` is `printf`. MinGW links its own `printf` into the program, so this is real code in `.text`. `puts`, `fgets`, `strcspn` and `strcmp` are different: their calls go to small stubs between `0x140008b90` and `0x140008be8`. Each stub is one `JMP` through an IAT slot into the C runtime DLL.

### Getting stdin

`stdin` looks like a variable in C, but MinGW defines it as a function call: `__acrt_iob_func(0)`. That's why `MOV ECX,0x0` sets argument 1 to 0, and the call goes through a pointer at `0x1400090f0`. In this build the pointer holds `FUN_140008580`, which returns the `FILE *` for stdin in RAX.

### fgets(input, sizeof input, stdin)

The result of the stdin call is moved to RDX, then to R8 as argument 3. RCX gets the address of `input` (`RBP-0x40`), and EDX gets `0x40`, which is 64. The stdin call came first because any call would destroy RCX, RDX and R8.

`fgets` returns a pointer, so the test is `TEST RAX,RAX`, the full 64 bits. When it returns NULL, the jump is not taken and `main` returns 1. That is `if (!fgets(...)) return 1;`.

### Removing the newline

`strcspn(input, "\r\n")` gets RCX = `input` and RDX = the string at `0x14000a034`. It returns a count in RAX. The next line, `MOV byte ptr [RBP + RAX*0x1 + -0x40],0x0`, writes a zero at `input + RAX`. That is `input[strcspn(input, "\r\n")] = 0;`.

### decode(key, 14)

`FUN_140001490` is `decode`. RCX gets the address of `key` (`RBP-0x4f`) and EDX gets `0xe`, which is 14, the size of `secret`. `decode` writes the key into `main`'s frame through that pointer and returns nothing useful.

### strcmp and the result

`strcmp(input, key)` gets RCX = `input` and RDX = `key`. This is where Day 1 has you read RCX and RDX in the dump. It returns 0 when the strings match.

`TEST EAX,EAX` and `JNZ 0x1400015b4` jump to "Bad license key." when the result isn't 0. Otherwise the code prints "License OK. Welcome!" and jumps over the bad branch. Both paths meet at `MOV EAX,0x0`, which is `return 0;`.

### The epilogue

All three returns reach `0x1400015c8` with the value already in EAX: 2, 1 or 0. `ADD RSP,0x70` releases the frame, `POP RBP` restores the caller's RBP, and `RET` returns to MinGW's startup code. It passes EAX on as the program's exit code.

## Seeing it in x64dbg

Set a breakpoint on `main`'s `PUSH RBP` (line up addresses as in Day 1's Exercise 2.3) and run to it. The stack pane shows the return address at RSP. Step with F8 over the prologue and watch RSP drop by 8, then by 0x70.

On any `call`, read RCX, RDX, R8 and R9 for the arguments, and step over it to read RAX. Right-click RBP → Follow in Dump, then scroll up by 0x40 bytes to see `input`.

## Check yourself

1. Before a `call`, RSP is `0x5FF900`. What is RSP at the callee's first instruction, and what is stored there?
2. What three instructions make GCC's `-O0` prologue, and what does each one do?
3. A function calls `f(a, b, c, d, e)`. Where does each argument go?
4. What is the shadow space, who reserves it, and how big is it?
5. Ghidra shows a local named `local_28`. What is its offset from RBP in a GCC `-O0` function?
6. A function puts a value in RCX, calls `puts`, then reads RCX again. Why is that a bug, and where should the value be kept instead?
7. In `ex3`'s `main`, why is `decode`'s second argument loaded into EDX and not RDX?
8. Why is `IsDebuggerPresent` called with `CALL RAX` while `puts` is called with `CALL 0x140008bc8`?

<details><summary>Answers</summary>

1. `0x5FF8F8`. `call` pushes 8 bytes: the return address, the address of the instruction after the `call`.
2. `push rbp` saves the caller's RBP; `mov rbp, rsp` makes RBP point at this frame; `sub rsp, N` reserves space for locals and for the calls the function makes.
3. `a` in RCX, `b` in RDX, `c` in R8, `d` in R9 (or their 32-bit halves), and `e` on the stack at `[rsp+0x20]` at the `call`.
4. 32 bytes just above the return address, reserved by the caller for every call. The callee may store its four register arguments there.
5. `Stack[-0x28]` is measured from RSP at entry. RBP is 8 below that, so it's `[rbp-0x20]`.
6. RCX is volatile, so `puts` may change it. Keep the value in a non-volatile register such as RBX, or on the stack.
7. Writing EDX also clears the top half of RDX, so RDX becomes 14. The 32-bit instruction is shorter.
8. `IsDebuggerPresent` is declared `dllimport`, so GCC reads its address from the IAT and calls it directly. `puts` isn't, so the call goes to a stub that jumps through the IAT.

</details>

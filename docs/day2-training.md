# Day 2: Optimized Code and the Stack

Nov 27, 2026

## Overview

On Day 1 every program was built with `-O0`, so the code followed the source line by line. Real programs are built with optimization. Today you read the same programs at `-O2` and learn how functions pass arguments and use the stack. You also see how inlining and tail calls change what both tools show.

**Why this matters.** Almost every program you will meet outside this course is a release build. Installers, games, drivers and Windows itself are compiled with optimization, so `-O0` code is the exception. If you can only read `-O0` code, you can only read code built for debugging.

**Goals for the day**

1. Recognize what `-O2` does to code you already understand: inlined functions, values kept in registers, rewritten arithmetic and reshaped loops.
2. Read a stack frame: the return address, saved registers, local variables and the shadow space.
3. Follow the Windows x64 calling convention, including arguments five and up, which go on the stack.
4. Set function signatures in Ghidra so the decompiler shows the right arguments.
5. Use x64dbg's call stack to see how the program got where it is, and know when a tail call hides a step.
6. Match functions between an `-O0` and an `-O2` build with Version Tracking.

**What you need**

- The portable kit and the course repo, as on Day 1.
- Your Day 1 Ghidra project with `ex1.exe`, `ex2.exe` and `ex3.exe` analyzed, and your Day 1 notes.
- Today's programs in `lab/day2`. Three of them are the Day 1 sources built again with `-O2`, so you already know the answers to those.

**Before you start**

Read [The stack and the calling convention](primers/05-stack-and-calls.md) in full; today builds on all of it. Skim the `-O2` section of [How C control flow compiles](primers/06-control-flow.md). If registers or flags feel shaky, reread [Registers and flags](primers/02-registers-and-flags.md).

Throughout the guide, pointers that start with "Primer:" lead to the exact primer section behind a step. Follow them when a step doesn't make sense, then come back.

**How to read the worked examples.** Modules 1 to 3 have worked examples that are not exercise programs. Each one shows a small C snippet, the pseudo-code a reverser would write, and MinGW GCC output at `-O0` and `-O2`. They were built with MinGW-w64 GCC 13 and printed in Intel syntax.

The kit's GCC may be newer and pick other registers, offsets and instruction order, so learn the shapes, not the exact lines. Comments after `;` are annotations, and labels such as `.Lloop` stand for addresses. Primer: [How to read the examples](primers/06-control-flow.md#how-to-read-the-examples).

**Lab rules**

- Work in your Windows VM and take a snapshot before you start.
- Only analyze the practice programs in this guide.
- Keep notes as you go: addresses, what each function does, and how you found it.

## Schedule

The day runs about 7 hours 15 minutes with breaks, and roughly half of it is hands-on exercise time. The extra-credit challenges in "Beyond this lesson" are outside this schedule.

| Time | Block | What you do |
| --- | --- | --- |
| 0:00–0:20 | Module 0: Setup | Snapshot the VM, build the Day 2 programs |
| 0:20–1:00 | Module 1A: What `-O2` changes | Inlining, registers, arithmetic, loops; analyzer options; worked examples |
| 1:00–2:15 | Exercise 1.1–1.4 | Compare `ex1o2`, `ex2o2`, `ex3o2` with Day 1; Version Tracking on `ex2` |
| 2:15–2:30 | Break |  |
| 2:30–3:05 | Module 2A: The stack and the calling convention | Frames, shadow space, stack arguments, function signatures; a seven-argument example |
| 3:05–4:05 | Exercise 2.1–2.3 | Map the call chain in `ex4`; read stack arguments; the call stack in x64dbg |
| 4:05–4:50 | Lunch |  |
| 4:50–5:45 | Module 3: Inlining and tail calls | A tail-call example; Exercise 3.1–3.2 on `ex4o2` |
| 5:45–6:45 | Module 4: Capstone | Recover the boarding pass from `ex5` with both tools |
| 6:45–7:00 | Review | Go over the answer key and write up your notes |
| 7:00–7:15 | Wrap-up | Cheat sheet additions and the plan for Day 3 |

## Module 0: Build the practice programs (20 min)

Today's programs are in the repo's `lab/day2` folder. Three of them reuse the Day 1 sources; the Day 2 Makefile builds them again with `-O2`.

| Program | Source | Built with | What it is |
| --- | --- | --- | --- |
| `ex1o2.exe` | [ex1\_password.c](../lab/day1/ex1_password.c) | `-O2` | Day 1's password check |
| `ex2o2.exe` | [ex2\_serial.c](../lab/day1/ex2_serial.c) | `-O2` | Day 1's serial from a name |
| `ex3o2.exe` | [ex3\_crackme.c](../lab/day1/ex3_crackme.c) | `-O2` | Day 1's hidden key and debugger check |
| `ex4.exe` | [ex4\_chain.c](../lab/day2/ex4_chain.c) | `-O0` | An access code checked through a chain of calls |
| `ex4o2.exe` | [ex4\_chain.c](../lab/day2/ex4_chain.c) | `-O2` | The same program, optimized |
| `ex5.exe` | [ex5\_boarding.c](../lab/day2/ex5_boarding.c) | `-O2` | A boarding pass that is never stored as a string |

Don't open `ex4_chain.c` or `ex5_boarding.c` yet. The aim is to recover them with the tools.

You know what `ex1`, `ex2` and `ex3` do, so every difference in their `-O2` builds comes from the optimizer.

**Compile** with `make`. Open `RE-Portable\Devkit.cmd`; its shell starts in the repo's `lab` folder. Then run:

```bash
make day1     # rebuilds bin/day1/ if you cleaned it
make day2     # builds bin/day2/ex1o2.exe ... ex5.exe
```

The executables go into `bin/day2`. Every program gets the usual `-O0 -s -Wall`. For the optimized ones, the Day 2 Makefile adds `-O2` after it, and the last `-O` option wins. Plain `make` builds every day at once.

`make` prints each `gcc` command it runs, so you can check that the optimized programs got `-O2`.

Run each new program once with a wrong answer: `ex4` asks for an access code and `ex5` for a boarding pass. Then import all six into your Day 1 Ghidra project and analyze them. Leave the analysis options at their defaults for now; Exercise 1.1 looks at them.

**Common mistake.** Importing `bin/day1/ex1.exe` again instead of `bin/day2/ex1o2.exe` gives you two identical programs. Check the file name in the project window before you analyze.

## Module 1: Optimized code (1 h 55 min)

### 1A. What `-O2` changes (40 min)

The optimizer keeps what the program does and changes how it does it. These are the changes you will meet today:

- **Inlining.** A small function's body is copied into its caller, and the call disappears. A function you renamed on Day 1 may not exist at all in the `-O2` build.
- **Registers instead of the stack.** At `-O0` every variable lives in memory, such as `[rbp-0x4]`, and is loaded and stored on each use. At `-O2` values stay in registers, so there are far fewer memory accesses.
- **No frame pointer.** At `-O0` each function starts with `push rbp` and `mov rbp, rsp`. At `-O2` RBP is often a normal register, and locals are addressed from RSP.
- **Cheaper arithmetic.** `h * 31` can become a shift and a subtract: `(h << 5) - h`. Division by a constant becomes a multiply by a large "magic" number and a shift. GCC does the division trick even at `-O0`.
- **Reshaped loops.** The loop test often moves to the bottom, with one extra check before the loop. Counters can turn into pointers that walk the data.
- **Reordering.** Instructions from different source lines are mixed together, and branches can be flipped. The order in the Listing no longer follows the source.

The decompiler hides some of this, because it rebuilds C from the instructions either way. The Listing shows all of it. Today you read both.

Primer: [What -O2 changes](primers/06-control-flow.md#what--o2-changes) has a one-line example of each change. For the `-O0` frame that `-O2` removes, see [Stack frames](primers/05-stack-and-calls.md#stack-frames). For `lea` used as arithmetic and for the shift instructions, see [The core instructions](primers/03-reading-assembly.md#the-core-instructions).

**How to read optimized code.** Start from what you can anchor: string references, calls to known library functions and distinctive constants. Then work outward one register at a time, asking where each value came from.

**Register sizes matter more at `-O2`.** At `-O0`, a variable's size shows in its memory operand, such as `dword ptr`. At `-O2` there is no memory operand, so the register name is your only clue. ECX means a 32-bit value such as an `int`; RCX means a 64-bit value such as a pointer.

Primer: [Sub-registers](primers/02-registers-and-flags.md#sub-registers) and [Writing a piece: what happens to the rest](primers/02-registers-and-flags.md#writing-a-piece-what-happens-to-the-rest).

**Analyzer options.** When Ghidra asks to analyze a program, it shows a list of analyzers with a tick box each. You can come back to the list at any time with Analysis → Auto Analyze, and re-run analysis after you change something. Analysis → One Shot runs a single analyzer once.

#### Worked example 1: a value kept in a register

This function keeps two values alive across a call. It is not one of today's programs.

```c
int print_len(const char *s) {
    size_t n = strlen(s);
    puts(s);
    return (int)n * 2;
}
```

A reverser reading either build would write:

```
n = strlen(s)
puts(s)
return n * 2
```

At `-O0`, both `s` and `n` live in the frame. Every use is a load or a store:

```
push rbp
mov  rbp, rsp
sub  rsp, 0x30
mov  qword ptr [rbp+0x10], rcx     ; s saved in its home slot (shadow space)
mov  rax, qword ptr [rbp+0x10]
mov  rcx, rax
call strlen
mov  qword ptr [rbp-0x8], rax      ; n = strlen(s), stored in the frame
mov  rax, qword ptr [rbp+0x10]     ; s loaded again
mov  rcx, rax
call puts
mov  rax, qword ptr [rbp-0x8]      ; n loaded back after the call
add  eax, eax                      ; n * 2
leave
ret
```

At `-O2`, both values stay in registers. `puts` may destroy RCX and RAX, so GCC moves them into RSI and RBX first:

```
push rsi                           ; RSI and RBX are non-volatile:
mov  rsi, rcx                      ;   save them, then keep s in RSI
push rbx
sub  rsp, 0x28                     ; shadow space for the calls, plus alignment
call strlen                        ; RCX still holds s
mov  rcx, rsi                      ; s again, from RSI
mov  rbx, rax                      ; n kept in RBX across the next call
call puts
add  rsp, 0x28
lea  eax, [rbx+rbx]                ; n * 2, without touching memory
pop  rbx
pop  rsi
ret
```

There is no `push rbp`, so RSP alone addresses the frame. The `push rbx` and `push rsi` at the start name the non-volatile registers the function uses. A value copied into one of them just before a `call` is one the function still needs afterwards.

Primer: [Volatile and non-volatile registers](primers/05-stack-and-calls.md#volatile-and-non-volatile-registers).

#### Worked example 2: an inlined helper

```c
static int clamp(int v, int lo, int hi) {
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
}

int volume_step(int vol, int delta) {
    return clamp(vol + delta, 0, 100);
}
```

Reverser's pseudo-code for the `-O2` build:

```
v = vol + delta
if (v > 100) v = 100
if (v < 0)   v = 0
return v
```

At `-O0`, `volume_step` sets up three arguments and calls `clamp`, which is a separate function with two compares and jumps:

```
volume_step:
push rbp
mov  rbp, rsp
sub  rsp, 0x20
mov  dword ptr [rbp+0x10], ecx     ; vol
mov  dword ptr [rbp+0x18], edx     ; delta
mov  edx, dword ptr [rbp+0x10]
mov  eax, dword ptr [rbp+0x18]
add  eax, edx                      ; vol + delta
mov  r8d, 0x64                     ; hi = 100
mov  edx, 0x0                      ; lo = 0
mov  ecx, eax                      ; v
call clamp
leave
ret
```

At `-O2`, `clamp` is gone. Its body is copied into `volume_step` with the constants filled in, and the jumps became conditional moves:

```
volume_step:
lea   eax, [rcx+rdx]               ; v = vol + delta
mov   edx, 0x64
cmp   eax, edx
cmovg eax, edx                     ; if (v > 100) v = 100
xor   edx, edx
test  eax, eax
cmovs eax, edx                     ; if (v < 0) v = 0
ret
```

The two checks now run in the opposite order to the source, with the same result. This is the reordering from the list above.

Inlining also removes a name. The `-O2` build has no `clamp` to rename, and Version Tracking has nothing to pair with the `-O0` one. When a helper you expect is missing, look for its constants or its shape inside the callers.

Primer: [Function calls and return values](primers/06-control-flow.md#function-calls-and-return-values).

#### Worked example 3: multiply and divide by a constant

```c
int      times9(int x)            { return x * 9; }
unsigned minutes(unsigned secs)   { return secs / 60; }
unsigned seconds_left(unsigned s) { return s % 60; }
int      div10(int x)             { return x / 10; }
```

Reverser's pseudo-code, once the tricks below are undone:

```
times9:       return x * 9
minutes:      return secs / 60
seconds_left: return s - (s / 60) * 60      // that is, s % 60
div10:        return x / 10                 // signed: rounds toward zero
```

**A multiply.** At `-O0`, GCC already uses a shift and an add. At `-O2` one `lea` does it:

```
-O0                                   -O2
mov  edx, dword ptr [rbp+0x10]        lea  eax, [rcx+rcx*8]
mov  eax, edx
shl  eax, 0x3
add  eax, edx
```

The `-O0` build computes x × 8 with `shl`, then adds x. The `-O2` build computes x + x × 8 in one `lea`.

`lea` with a scale of 2, 4 or 8 can multiply by 3, 5 or 9 in one step. Larger constants become a short chain of `lea`, `shl`, `add` and `sub`, or an `imul`.

**An unsigned division.** Both builds multiply by a magic number:

```
-O0                                   -O2
mov  eax, dword ptr [rbp+0x10]        mov  eax, ecx
mov  edx, eax                         mov  edx, 0x88888889
mov  eax, 0x88888889                  imul rax, rdx
imul rax, rdx                         shr  rax, 0x25
shr  rax, 0x20
shr  eax, 0x5
```

`imul rax, rdx` gives a 64-bit product. The `-O0` build keeps its high 32 bits with `shr rax, 0x20`, then shifts 5 more. The `-O2` build does both in one shift of `0x25`, which is 37.

To recover the divisor, add up the shifts and divide: 2^37 / `0x88888889` is 60.0000…, so the divisor is 60. In Python, `round(2**37 / 0x88888889)` prints 60. Always check the result: a wrong guess gives a number that is not close to a whole number.

**A remainder.** `seconds_left` is the same divide, followed by a multiply back and a subtract:

```
mov  eax, ecx
mov  edx, 0x88888889
imul rax, rdx
shr  rax, 0x25                     ; q = s / 60
imul edx, eax, 0x3c                ; q * 60
mov  eax, ecx
sub  eax, edx                      ; s - q*60 = s % 60
```

So a magic multiply followed by `imul` with a round number and a `sub` is a `%`. The `imul` constant is the divisor, which confirms your calculation.

**A signed division.** Signed division needs one more step, because C rounds toward zero and a shift rounds down:

```
; -O2
movsx rax, ecx                     ; widen x to 64 bits, keeping its sign
sar   ecx, 0x1f                    ; ECX = -1 if x < 0, else 0
imul  rax, rax, 0x66666667         ; magic for 10
sar   rax, 0x22                    ; 34 = 32 + 2
sub   eax, ecx                     ; adds 1 when x < 0: rounds toward zero
```

The `sar ..., 0x1f` and `sub` pair is the sign fix. `sar` instead of `shr`, and `movsx` instead of `mov`, tell you the value is signed. Here 2^34 / `0x66666667` is 9.99999…, so the divisor is 10.

Primer: [Signed and unsigned numbers](primers/01-numbers-and-data.md#signed-and-unsigned-numbers).

#### Worked example 4: a loop rotated, then unrolled

```c
int count_char(const char *s, char c) {
    int n = 0;
    for (int i = 0; s[i]; i++)
        if (s[i] == c) n++;
    return n;
}
```

Reverser's pseudo-code for the `-O2` build:

```
n = 0
p = s
if (*p != 0) {
    do {
        n += (*p == c)
        p++
    } while (*p != 0)
}
return n
```

At `-O0` this is the standard shape: jump to the test at the bottom, with `i` and `n` in the frame. Primer: [Loops: for and while](primers/06-control-flow.md#loops-for-and-while).

```
mov   eax, edx
mov   byte ptr [rbp+0x18], al      ; c, saved in its home slot
mov   dword ptr [rbp-0x4], 0x0     ; n = 0
mov   dword ptr [rbp-0x8], 0x0     ; i = 0
jmp   .Lcond
.Lbody:
mov   eax, dword ptr [rbp-0x8]
movsx rdx, eax
mov   rax, qword ptr [rbp+0x10]
add   rax, rdx
movzx eax, byte ptr [rax]          ; s[i]
cmp   byte ptr [rbp+0x18], al      ; == c ?
jne   .Lnext
add   dword ptr [rbp-0x4], 0x1     ; n++
.Lnext:
add   dword ptr [rbp-0x8], 0x1     ; i++
.Lcond:
mov   eax, dword ptr [rbp-0x8]
movsx rdx, eax
mov   rax, qword ptr [rbp+0x10]
add   rax, rdx
movzx eax, byte ptr [rax]          ; s[i]
test  al, al                       ; end of the string?
jne   .Lbody
mov   eax, dword ptr [rbp-0x4]     ; return n
```

At `-O2` the loop is **rotated**: one test before the loop decides whether to enter it, and the test at the bottom loops back. This is a `do`-`while` inside an `if`. The counter `i` became a pointer in RCX, and the `if` inside the loop became `sete` with no jump:

```
movzx eax, byte ptr [rcx]          ; s[0]
test  al, al
je    .Lempty                      ; the extra test before the loop
add   rcx, 0x1                     ; p = s + 1: the counter is now a pointer
xor   r8d, r8d                     ; n = 0, kept in R8D
.Lloop:
cmp   dl, al                       ; character == c ?
sete  al                           ; AL = 1 if equal, else 0
add   rcx, 0x1
movzx eax, al
add   r8d, eax                     ; n += (character == c)
movzx eax, byte ptr [rcx-0x1]      ; next character
test  al, al
jne   .Lloop                       ; the test is at the bottom
mov   eax, r8d
ret
.Lempty:
xor   r8d, r8d
mov   eax, r8d
ret
```

Note that `c` arrived in EDX, and the loop compares DL, its low byte. Primer: [Loops: do-while](primers/06-control-flow.md#loops-do-while) and [cmp, test and conditional jumps](primers/02-registers-and-flags.md#cmp-test-and-conditional-jumps).

**Unrolling.** A loop with a small, fixed count can disappear altogether. This one runs exactly four times:

```c
unsigned hash4(const unsigned char *p) {
    unsigned h = 5381;
    for (int i = 0; i < 4; i++)
        h = h * 33 + p[i];
    return h;
}
```

At `-O0` the test is `cmp dword ptr [rbp-0x8], 0x3` and `jle`, the usual `i <= 3` form. At `-O2`, GCC 13 keeps a loop but walks a pointer up to an end address:

```
lea   r8, [rcx+0x4]                ; end = p + 4
mov   eax, 0x1505                  ; h = 5381
.Lloop:
mov   edx, eax
add   rcx, 0x1
shl   edx, 0x5                     ; h << 5
add   eax, edx                     ; h + (h << 5) = h * 33
movzx edx, byte ptr [rcx-0x1]      ; p[i]
add   eax, edx
cmp   rcx, r8                      ; stop when the pointer reaches the end
jne   .Lloop
ret
```

At `-O3` the loop is **unrolled**: the body is repeated four times and the backward jump is gone. GCC even works out the first step at compile time, since 5381 × 33 is 177573 (`0x2b5a5`):

```
movzx eax, byte ptr [rcx]
add   eax, 0x2b5a5                 ; 5381*33 + p[0]
mov   edx, eax
shl   edx, 0x5
add   edx, eax                     ; h * 33
movzx eax, byte ptr [rcx+0x1]
add   eax, edx                     ; + p[1]
...                                ; the same three lines for p[2] and p[3]
```

A run of near-identical blocks with offsets `+0x1`, `+0x2`, `+0x3` is an unrolled loop. An unfamiliar start value may be a known constant already put through the first step.

### Exercise 1.1: ex1 at -O2, side by side (15 min)

1. Open `ex1o2.exe` in the CodeBrowser. Open Day 1's `ex1.exe` in the same CodeBrowser with File → Open. Each program gets its own tab above the Listing.
2. Find `main` in `ex1o2` from the "Access granted!" string, as on Day 1, and rename it.
3. Compare the two `main` functions in the Listing. Does the `-O2` one start with `push rbp`? Where do the input buffer and the `strcmp` arguments come from?
4. Compare the decompiler output. It should look almost the same, even though the instructions differ.
5. Open Analysis → Auto Analyze for `ex1o2` and read the list of analyzers. Find **Decompiler Parameter ID**; it uses the decompiler to work out each function's parameters. If it is not ticked, tick it and click Analyze.

**Write down:** the number of instructions in each `main`, and one difference you can see in the Listing but not in the decompiler.

**What to look at.** Read the first five or six instructions of each `main`. At `-O0`, the arguments for each call are built in RAX and copied, as in the primer's [worked example](primers/05-stack-and-calls.md#worked-example-ex3s-main). At `-O2`, look for addresses that are loaded straight into RCX or RDX, or kept in a non-volatile register.

**Common mistakes.** The decompiler follows the tab you clicked last, so you may be reading the wrong program's `main`. Check the tab name above the Listing before you compare. To count instructions, count the instruction lines in the Listing from the first one to the last `ret`.

### Exercise 1.2: Where did make\_serial go? (25 min)

1. Open `ex2o2.exe` and find `main` from "Invalid serial."
2. On Day 1, `main` called `make_serial`. Look for that call now. Is there one?
3. Find the loop inside `main` that walks the name. Open the Function Graph and point out the loop.
4. Find the three constants you know from Day 1: `0x1337`, 31 and `0xC0FFEE`. One of them may not appear as a number. Work out how the multiply by 31 is done instead.
5. Run your Day 1 keygen for a new name and check the serial against `ex2o2.exe`. The code changed; the algorithm did not.

**Write down:** what replaced the call to `make_serial`, and the instructions that do `h * 31`.

**Why this step matters.** Small helpers get inlined, so real algorithms hide inside large functions. Recognizing one by its constants and its loop is how you find hashes, checksums and decoders.

**What to look at.** In the Function Graph, a loop is a block with an arrow back to itself or to a block above it. The constants that survive are your anchors; the arithmetic between them is the loop body. Worked example 3 shows how a multiply by a small constant can turn into shifts and adds.

**Common mistakes.** A search for `0x1f` that finds nothing doesn't mean the multiply is gone. It means it is no longer a multiply instruction. If the keygen disagrees with `ex2o2.exe`, check that you typed the serial in hex, as on Day 1.

### Exercise 1.3: ex3 at -O2 (15 min)

1. Open `ex3o2.exe` and find `main` from "Bad license key."
2. Find the `IsDebuggerPresent` call and the branch to "Debugger detected. Bye."
3. Find the XOR with `0x42`. On Day 1 it was in its own `decode` function. Where is it now?
4. If the loop uses XMM registers and `pxor`, the compiler is working on 16 bytes at a time. Find where it handles the bytes that are left over.

**Write down:** whether `decode` still exists, and where the decoded key is written.

**Why this step matters.** Decoders for hidden strings are small, so the optimizer often inlines them. Finding the decode loop and the buffer it writes is the skill you need for string obfuscation on Day 14.

**What to look at.** The `IsDebuggerPresent` call is still made through the IAT, as on Day 1, because a DLL function can't be inlined. Primer: [Imports and the IAT](primers/04-memory-layout.md#imports-and-the-iat). For the XOR, look for `0x42` in `main`'s Listing and read the instructions around it.

**Common mistakes.** A loop that handles 16 bytes at a time is usually followed by a plain loop or a few single-byte steps for the rest. Both parts are the same source loop; don't treat them as two algorithms. If you see no XMM registers at all, your compiler chose a plain loop, and step 4 doesn't apply.

### Exercise 1.4: Match ex2 and ex2o2 with Version Tracking (20 min)

Version Tracking compares two programs and pairs up functions and data that correspond. It carries your renames and comments from one build to another, such as from an old version of a program to a new one.

1. In the Ghidra project window, open the Version Tracking tool with Tools → Run Tool → Version Tracking.
2. Start a session with File → New Session. Choose `ex2.exe` (Day 1) as the source and `ex2o2.exe` as the destination.
3. Add correlators to the session and run **Exact Function Bytes Match** first. Count the matches. Most are MinGW runtime functions, which are the same in both builds because they come precompiled.
4. Look for `main` in the matches. It isn't there, because its bytes changed.
5. Run **Exact Data Match**. It pairs identical data, such as the "Invalid serial." strings. Select those matches and accept them.
6. Run **Data Reference Match**. It pairs functions that use the same accepted data. `main` should now be matched.
7. Open the `main` match and look at its markup items. Apply the function name, so the name you gave `main` in `ex2.exe` appears in `ex2o2.exe`.
8. Look for a match for `make_serial`. There is none. Explain why in your notes.

**Write down:** how many exact byte matches you got, which correlator matched `main`, and why `make_serial` has no partner.

**Why this step matters.** You will often get version 2 of a program you already reversed. Version Tracking moves your work across, so you only study what changed.

**How the correlators build on each other.** Exact byte matches are certain but rare once code is optimized. Data matches are safe because strings don't change with `-O2`. Reference matches then use the accepted data to pair the code around it, so the order of steps 3, 5 and 6 matters.

**Common mistakes.** If you swap source and destination, names flow the wrong way, from the build you haven't renamed. Start a new session with the right order. If Data Reference Match finds nothing, go back to step 5 and check that the data matches were accepted, not just selected.

## Module 2: The stack and the calling convention (1 h 35 min)

### 2A. Stack frames and arguments (35 min)

The stack grows toward lower addresses. RSP points at its top, the lowest address in use.

- `call` pushes the return address, the address of the next instruction, and jumps to the function. `ret` pops it and jumps back.
- A function's **frame** is the part of the stack it owns: saved registers, local variables, and space for the arguments of the calls it makes.
- At `-O0`, GCC builds every frame the same way: `push rbp`, `mov rbp, rsp`, `sub rsp, N`. Locals sit below RBP at `[rbp-0x4]` and so on. `leave` and `ret` undo it at the end.

Primer: [What the stack is](primers/05-stack-and-calls.md#what-the-stack-is), [Push and pop](primers/05-stack-and-calls.md#push-and-pop), [Call and ret](primers/05-stack-and-calls.md#call-and-ret) and [Stack frames](primers/05-stack-and-calls.md#stack-frames).

**Why the stack matters in real RE.** Reading a frame tells you what a function stores and what its caller handed it. The return addresses on it are the history of calls a debugger shows you.

**The Windows x64 calling convention** (Day 1 covered the first point):

- The first four integer or pointer arguments go in RCX, RDX, R8 and R9. A 32-bit argument uses the lower half: ECX, EDX, R8D, R9D.
- Arguments five and up go on the stack. Floating-point arguments use XMM0 to XMM3 instead; today's programs have none.
- The caller always reserves 32 bytes just above the return address, the **shadow space** (also called home space). The callee may save RCX, RDX, R8 and R9 there.
- So at the `call`, argument 5 is at `[rsp+0x20]` and argument 6 at `[rsp+0x28]`. Inside the callee, the return address moves them 8 bytes up, to `[rsp+0x28]` and `[rsp+0x30]`.
- The result comes back in RAX (EAX for 32 bits).
- RAX, RCX, RDX and R8 to R11 can be changed by any call. RBX, RBP, RDI, RSI and R12 to R15 must be preserved. A function that uses them pushes them first and pops them at the end.

Primer: [The Windows x64 calling convention](primers/05-stack-and-calls.md#the-windows-x64-calling-convention) covers argument slots, shadow space and stack arguments. [Volatile and non-volatile registers](primers/05-stack-and-calls.md#volatile-and-non-volatile-registers) covers the last point.

**Alignment.** RSP must be a multiple of 16 at every `call`, but `call` itself pushes 8 bytes. So at a function's first instruction RSP ends in `8`, and the pushes and `sub rsp` that follow restore the multiple of 16. That explains odd `-O2` frame sizes, such as `sub rsp, 0x28` after two pushes.

Primer: [Stack alignment](primers/05-stack-and-calls.md#stack-alignment).

Some functions that keep arrays on the stack start with `push rbp`, `mov rbp, rsp` and `and rsp, -16`. The `and` rounds RSP down to a multiple of 16, and RBP keeps the old value so the epilogue can undo it. Such a function uses RBP even at `-O2`, but its locals are still addressed from RSP.

This is what a frame looks like inside a function built at `-O0`, after its `push rbp` and `mov rbp, rsp`:

| Address | Holds |
| --- | --- |
| `[rbp+0x38]` | argument 6 |
| `[rbp+0x30]` | argument 5 |
| `[rbp+0x10]` to `[rbp+0x28]` | shadow space: where `-O0` code saves RCX, RDX, R8 and R9 |
| `[rbp+0x8]` | return address |
| `[rbp]` | the caller's RBP |
| `[rbp-0x4]` and below | local variables |

**The same frame without RBP.** At `-O2` there is often no RBP frame, so the same slots are addressed from RSP. RSP moves with every `push` and `sub rsp`, so one stack slot can appear at different RSP offsets in different parts of a function. Work out each offset from the instructions above it, counting 8 bytes per `push` plus the `sub rsp` amount.

**Ghidra's stack names.** Ghidra measures stack offsets from RSP at the function's first instruction, not from RBP or the current RSP. So a stack argument gets the same `Stack[...]` offset in both builds, whatever register addresses it. Primer: [Locals and how Ghidra names them](primers/05-stack-and-calls.md#locals-and-how-ghidra-names-them).

**Function signatures in Ghidra.** Ghidra guesses each function's parameters. When it guesses wrong, the decompiler shows missing or extra arguments. Right-click the function name in the Decompiler → Edit Function Signature, and type the prototype as C, for example `int check(char *name, int len)`. The same dialog has a Calling Convention setting; for 64-bit Windows code it should be `__fastcall`, Ghidra's name for the convention above.

Two signs show a wrong guess. The call shows fewer arguments than the registers loaded before it, or the callee reads stack slots named `in_stack_...`. Either one tells you to set the signature yourself.

**x64dbg's call stack.** The Call Stack tab lists the return addresses on the stack. That is the chain of calls that led to the current instruction. Double-click a line to go to that place in the caller. Labels you add with `:` show up in it.

x64dbg builds that list by walking return addresses on the stack, so it only knows about calls that left one. Keep that in mind for Module 3. Primer: [Seeing it in x64dbg](primers/05-stack-and-calls.md#seeing-it-in-x64dbg).

#### Worked example 5: seven arguments

This is not one of today's programs. It shows how arguments beyond the fourth travel in both builds.

```c
int mix7(int a, int b, int c, int d, int e, int f, int g) {
    return a + b*2 + c*3 + d*4 + e*5 + f*6 + g*7;
}

int call_mix(void) {
    return mix7(1, 2, 3, 4, 5, 6, 7) + 1;
}
```

Reverser's pseudo-code for the caller, read from the argument setup:

```
r = mix7(1, 2, 3, 4, 5, 6, 7)   // 1-4 in ECX, EDX, R8D, R9D; 5-7 on the stack
return r + 1
```

**The caller.** At `-O0`, `call_mix` writes the stack arguments from the last to the first, then the registers:

```
push rbp
mov  rbp, rsp
sub  rsp, 0x40                     ; 32 bytes of shadow space + 3 stack arguments, rounded up
mov  dword ptr [rsp+0x30], 0x7     ; argument 7
mov  dword ptr [rsp+0x28], 0x6     ; argument 6
mov  dword ptr [rsp+0x20], 0x5     ; argument 5
mov  r9d, 0x4                      ; argument 4
mov  r8d, 0x3                      ; argument 3
mov  edx, 0x2                      ; argument 2
mov  ecx, 0x1                      ; argument 1
call mix7
add  eax, 0x1
leave
ret
```

At `-O2` the same writes are mixed together, but each argument lands in the same place:

```
sub  rsp, 0x48                     ; 8 (call) + 0x48 = 0x50: aligned, no push needed
mov  r9d, 0x4
mov  r8d, 0x3
mov  edx, 0x2
mov  dword ptr [rsp+0x30], 0x7     ; argument 7
mov  ecx, 0x1
mov  dword ptr [rsp+0x28], 0x6     ; argument 6
mov  dword ptr [rsp+0x20], 0x5     ; argument 5
call mix7
add  rsp, 0x48
add  eax, 0x1
ret
```

The rule to remember: at the `call`, argument *n* (for *n* ≥ 5) is at `[rsp + 0x20 + 8*(n-5)]`. Each slot is 8 bytes, even for an `int`.

**The callee.** At `-O0`, `mix7` saves its four register arguments in the shadow space, as in the 2A table. It reads `e`, `f` and `g` from `[rbp+0x30]`, `[rbp+0x38]` and `[rbp+0x40]`.

At `-O2`, `mix7` has no frame at all. RSP is still where `call` left it. The arguments are 8 bytes above where the caller wrote them:

```
mov  r11d, edx                     ; b
mov  eax, ecx                      ; a
mov  r10d, dword ptr [rsp+0x28]    ; e, argument 5
lea  r8d, [r8+r8*2]                ; c * 3
lea  eax, [rax+r11*2]              ; a + b*2
mov  edx, dword ptr [rsp+0x30]     ; f, argument 6
mov  ecx, dword ptr [rsp+0x38]     ; g, argument 7
add  eax, r8d
lea  r8d, [r10+r10*4]              ; e * 5
lea  eax, [rax+r9*4]               ; + d*4
lea  edx, [rdx+rdx*2]              ; f * 3
add  eax, r8d
lea  eax, [rax+rdx*2]              ; + f*3*2 = f*6
lea  edx, [rcx*8]
sub  edx, ecx                      ; g*8 - g = g*7
add  eax, edx
ret
```

Notice that no `-O2` instruction saves the register arguments; the shadow space goes unused. Notice also that every multiply here is a `lea` or a shift, as in worked example 3. In Ghidra, both builds should show `e`, `f` and `g` as `Stack[0x28]`, `Stack[0x30]` and `Stack[0x38]`.

### Exercise 2.1: Map the call chain in ex4 (20 min)

1. Open `ex4.exe` in the CodeBrowser and find `main` from "Door open."
2. Find the call that receives the number you typed. Follow it, then keep following calls until you reach the function that makes the final comparison.
3. Rename each function by what it does. Suggested names, from the top: `check_access`, `check_zone`, `zone_key`, `check_door`, and a small helper `rotl`.
4. In `check_zone`, read the prologue and epilogue in the Listing. Find `push rbp`, `mov rbp, rsp`, the `sub rsp` and the `leave`.
5. Find where `check_zone` saves ECX and EDX in the shadow space.

**Write down:** the chain of calls from `main` to the comparison, and the frame size each function reserves with `sub rsp`.

**Why this step matters.** Real checks are rarely in `main`. They sit several calls deep, behind wrappers that each add a little. Mapping the chain first, before reading any one function in detail, tells you where to spend your time.

**What to look at.** Calls to library functions such as `printf`, `fgets` or `puts` go through stubs or the IAT; they are not part of the chain. A `call` whose target is a `FUN_` address inside `.text` is one of the program's own functions. A function with no `sub rsp` makes no calls of its own and needs no call area.

**Common mistakes.** It is easy to lose your place after following several calls. Use Alt+← to go back, and rename each function as soon as you leave it.

### Exercise 2.2: Six arguments (20 min)

1. In `check_zone`, find the call to `zone_key`. Just before it, find the four values moved into ECX, EDX, R8D and R9D.
2. Find the two values written to `[rsp+0x20]` and `[rsp+0x28]`. These are arguments 5 and 6.
3. Go into `zone_key` and find where it reads arguments 5 and 6. Check the offsets against the table in 2A.
4. Edit `zone_key`'s signature to `uint zone_key(uint zone, uint floor, uint door, uint shift, uint salt, uint pepper)`. Go back to `check_zone` and check that the decompiler shows six arguments in the call.
5. Edit `rotl`'s signature too. Work out what it does to its first argument.
6. Read `zone_key` in the decompiler and work out the access code from the six values. Python is fine for the arithmetic. Run `ex4.exe` with your answer.

**Write down:** the six argument values in order, where each one travels, and the access code.

**Why this step matters.** Many Windows API calls take more than four arguments; `CreateFileW` takes seven. Fixing a signature also fixes every caller in the decompiler at once.

**What to look at.** Compare `check_zone`'s argument setup with worked example 5. The values written to the stack can be small numbers that the Listing shows in hex; right-click them to see them in decimal. Inside `zone_key`, follow each argument from its home slot to where it is used.

**Common mistakes.** Doing the arithmetic in Python without wrapping to 32 bits gives a wrong code, because `uint` overflows at 2^32. Mask each step with `& 0xFFFFFFFF`, as in Day 1's keygen. If the call in `check_zone` still shows the old arguments, check that you edited `zone_key` and not `check_zone`.

### Exercise 2.3: The call stack in x64dbg (20 min)

1. Open `ex4.exe` in x64dbg. Line up the addresses with Ghidra as on Day 1 (Exercise 2.3), then set a breakpoint on the first instruction of `check_door`.
2. Put labels on the five functions you renamed: go to each start address and press `:`.
3. Press F9 and type any number in the console window.
4. When it stops, open the Call Stack tab. Read the chain of callers and compare it with your notes from Exercise 2.1.
5. Double-click each line to see the instruction after each `call`. Add a comment with `;` on the comparison in `check_door`.
6. Read ECX and EDX. One is the number you typed; the other is the right code, in hex. Convert it to decimal and check it against Exercise 2.2.
7. In the stack pane, find the return address into `check_zone` and the shadow space above it.

**Why this step matters.** The call stack is the fastest way to answer "how did I get here?" in a program you don't know. Module 4 relies on it.

**What to look at.** At the first instruction of a function, `[rsp]` is the return address and the 32 bytes above it are the caller's shadow space. Compare what you see with the diagram in [Stack frames](primers/05-stack-and-calls.md#stack-frames). At `-O0`, a callee only writes its home slots once its prologue has run, so step a few instructions to see them filled.

**Common mistakes.** Windows loads the program at a new base on each run, so line up the addresses again after every restart. If nothing happens after F9, the program is waiting for input in its console window, which may be behind x64dbg.

Primer: [ASLR: why x64dbg's addresses differ](primers/04-memory-layout.md#aslr-why-x64dbgs-addresses-differ).

## Module 3: Inlining and tail calls (55 min)

**Inlining**, again: a small function's body is copied into the caller. When the helper is short enough, it can shrink to a single instruction.

Worked example 2 showed a helper with two checks turning into two conditional moves inside its caller.

**A tail call** is a call that is the last thing a function does, as in `return other(x);`. At `-O2` the compiler replaces `call other` followed by `ret` with `jmp other`. The current function's frame is gone before the jump, so `other` returns straight to the original caller. This saves stack space and time, but the middle function leaves no return address behind. A debugger's call stack skips it.

A call can only become a tail call when nothing is left to do after it. For example, the callee must not use the caller's local variables, because that frame no longer exists.

Primer: [Call and ret](primers/05-stack-and-calls.md#call-and-ret) explains why a `jmp` leaves no return address: only `call` pushes one. [What -O2 changes](primers/06-control-flow.md#what--o2-changes) lists tail calls with the other changes.

**Why this matters in real RE.** Wrappers that only forward to another function are everywhere, and at `-O2` most of them end in `jmp`. Trust the call stack blindly and you will miss steps in the chain.

**Telling a tail call from an ordinary jump.** Every function has jumps inside it, for `if` and loops. A tail call is a `jmp` to the start of another function, usually as the last instruction of a block. In Ghidra its target is a function name, not a `LAB_` label, and the decompiler shows it as a call whose result is returned.

#### Worked example 6: a tail call

This is not one of today's programs.

```c
int validate(int v);           /* a separate function */

int check_input(int v) {
    if (v < 0) return 0;
    return validate(v * 2);
}
```

Reverser's pseudo-code, the same for both builds:

```
if (v < 0) return 0
return validate(v * 2)
```

At `-O0`, `check_input` calls `validate` and then returns through its own epilogue:

```
check_input:
push rbp
mov  rbp, rsp
sub  rsp, 0x20                     ; shadow space for the call
mov  dword ptr [rbp+0x10], ecx     ; v
cmp  dword ptr [rbp+0x10], 0x0
jns  .Lcall                        ; v >= 0: go and call validate
mov  eax, 0x0                      ; return 0
jmp  .Lend
.Lcall:
mov  eax, dword ptr [rbp+0x10]
add  eax, eax                      ; v * 2
mov  ecx, eax
call validate                      ; pushes a return address into check_input
.Lend:
leave
ret
```

At `-O2`, there is no frame to undo, so the call and the return become one `jmp`:

```
check_input:
test ecx, ecx
js   .Lneg                         ; v < 0
add  ecx, ecx                      ; v * 2, built in the argument register
jmp  validate                      ; tail call: no return address pushed
.Lneg:
xor  eax, eax                      ; return 0
ret
```

When `validate` runs its `ret`, it pops the return address that `check_input`'s caller pushed. So it returns straight to that caller, with its result already in EAX. In x64dbg's Call Stack tab, `check_input` never appears while `validate` runs.

Two details are worth noting. The `-O0` test `jns` and the `-O2` test `js` jump in opposite directions, because the blocks were swapped. And at `-O2` the argument is computed directly in ECX, since `validate` takes it from there.

**Stepping through a tail call in x64dbg.** F7 and F8 both follow a `jmp`; F8 only differs on a `call`. Ctrl+F9 in the callee runs to its `ret`, and the next step lands in the caller of the function that jumped. That skip is expected, not a mistake.

### Exercise 3.1: ex4 at -O2 in Ghidra (20 min)

1. Open `ex4o2.exe` and find `main` from "Door open." Follow the calls down, as in Exercise 2.1, and give the functions the same names.
2. Which of the five functions still exist? Find the `rol` instruction in `zone_key` and explain where `rotl` went.
3. Find the last instruction of `check_access` and of `check_zone`. What replaced `call` and `ret`?
4. In `zone_key`, find where arguments 5 and 6 are read now that there is no `push rbp`. Check the offsets against 2A.
5. Find the multiply by `0x55e63b89` and the shift after it. Which part of the source line does it implement? Check whether `ex4.exe` has the same trick.

**Write down:** which functions were inlined, which calls became `jmp`, and the offsets of arguments 5 and 6 in each build.

**Why this step matters.** Spotting known jobs in a reshaped build is the core skill of the day. With real software, you won't have the `-O0` build to help.

**What to look at.** For step 2, a rotate by a variable amount takes its count in CL, the low byte of RCX. For step 5, use the method from worked example 3 to recover the divisor, then see what the code does with the quotient.

**Common mistakes.** The functions may sit in a different order than in the `-O0` build, so match them by what they do, not by address. If a `jmp` target shows as a `LAB_` label instead of a function, Ghidra did not create a function there. Check whether the target is the start of a function you already know.

### Exercise 3.2: The shorter call stack (15 min)

1. Open `ex4o2.exe` in x64dbg, line up the addresses, and break on the first instruction of `check_door`.
2. Run it and type any number. Open the Call Stack tab. Compare it with Exercise 2.3. Which callers are missing?
3. Restart it (Ctrl+F2). Break on the call to `check_access` in `main`, and step with F7 until you reach `check_door`. Watch RSP at each `jmp`.
4. Read EDX at `check_door`. It should be the same code as in `ex4.exe`.

**Stretch goal:** run Version Tracking with `ex4.exe` as the source and `ex4o2.exe` as the destination. Which correlators match the functions that survived?

**What to look at.** Write down RSP at each `call` and each `jmp` as you step, in a small table. Compare it with RSP at the same point in `ex4.exe`. The difference is the frames the `-O2` build never built.

**Common mistakes.** Stepping with F8 at the `call` to `check_access` runs the whole chain at once and you miss it. Use F7 there. If you overshoot, restart with Ctrl+F2 and run to your breakpoint again.

## Module 4: Capstone, the boarding pass in ex5 (1 h)

`ex5.exe` is built only at `-O2`. Its boarding pass is put together on the stack at runtime and is never stored as one string. Use Ghidra to find how it is built, then x64dbg to read it from memory.

**Why this matters in real RE.** Programs sometimes build strings on the stack so that a strings search misses them, and compilers do it on their own for short copies. Either way, you have to read the stores.

### Part A: Static analysis in Ghidra (25 min)

1. Import and analyze `ex5.exe`. Search Defined Strings for anything that looks like a pass. You won't find the whole pass.
2. Find `main` from "Boarding pass rejected." Follow the call that receives your input, and rename the functions you find.
3. In the function that builds the pass, find the local buffer on the stack and every value written into it. Some writes put several characters at once, as one large number. A value may first be loaded from a constant in `.rdata`; follow the reference to read it.
4. Turn those numbers into characters. x86 is little-endian, so the lowest byte of each number is the first character in memory. Right-click a number in the Listing and use Convert to see it as characters, or decode it with Python.
5. The function that builds the pass then calls a function that calls `strcmp`. Why is that not a tail call, even at `-O2`? Look at what it passes.

Primer: [Little-endian byte order](primers/01-numbers-and-data.md#little-endian-byte-order) for step 4. [RIP-relative addressing](primers/03-reading-assembly.md#rip-relative-addressing) explains how a load from `.rdata` is encoded, for step 3.

**What to look at.** Sort the writes by their stack offset, not by their order in the Listing; the optimizer may write the second part first. Each write's size tells you how many characters it holds: a `qword` holds 8, a `dword` 4, a `word` 2 and a `byte` 1. The size is in the memory operand, such as `dword ptr`, or in the register name.

In Python, `(0x34333231).to_bytes(4, "little")` prints `b'1234'`; use the same pattern for each value you find.

**Common mistakes.** Reading the hex digits from left to right gives the characters in reverse order. Missing one write leaves a gap, so check that the offsets cover the whole pass with no holes. The zero byte at the end is the terminator, not part of the pass.

### Part B: Dynamic analysis in x64dbg (25 min)

1. Open `ex5.exe` in x64dbg and press F9 to reach the entry point.
2. Open the Symbols tab, select the C runtime DLL (`msvcrt.dll`), find `strcmp`, and press F2 on it.
3. Press F9 and type any pass. If it stops before you have typed anything, press F9 again.
4. Now you are inside the DLL. Open the Call Stack tab and read the chain back to `main`.
5. Follow RCX and RDX in the dump. One is your input. The other is the pass, in a buffer close to RSP: it lives in a caller's frame. Which caller?
6. Use Run to user code (Alt+F9). x64dbg stops back in `ex5.exe`, right after the call to `strcmp`. Label the functions with `:`.
7. Run `ex5.exe` without the debugger and enter the pass.

**Why this step matters.** Breaking on a library function and walking back up is how you find the interesting code in a large program. You only need to know which API the check must use.

**What to look at.** A breakpoint on a DLL function stops for every caller, including the C runtime's own startup code. Check the Call Stack tab each time it stops; only continue when the chain leads back to `ex5.exe`. To decide which caller's frame holds the pass, compare its address with RSP at each level of the call stack.

**Deliverable:** a half-page write-up. Cover the pass, how and where it is built, and which functions were inlined. Add the call chain from `main` to `strcmp`, and why the last call is not a tail call.

## Beyond this lesson

These challenges are extra credit, outside the day's schedule. They use today's programs, or your own copies of their sources built with different options. Hints and expected results are in [lab/solutions/day2/extra-credit.md](../lab/solutions/day2/extra-credit.md); it contains spoilers, so try each one first.

**Building your own copies.** Work in the Devkit shell, which starts in the `lab` folder. Build a copy with a different optimization level like this:

```bash
gcc -s -Wall -O1 day2/ex4_chain.c -o bin/day2/ex4o1.exe
```

To change a source, copy it into a folder of your own first, such as `lab/mine`, and never edit the course sources. To see GCC's own assembly without Ghidra, add `-S -masm=intel` and name the output `.s` instead of `.exe`.

| # | Challenge | Difficulty |
| --- | --- | --- |
| 1 | The optimization ladder for `ex2` | ★ |
| 2 | Which functions survive in `ex4`? | ★★ |
| 3 | Recover a division from its magic number | ★★ |
| 4 | Break the tail call | ★★★ |
| 5 | `ex4`'s code from the `-O2` Listing alone | ★★★ |

### 1. The optimization ladder for ex2 (★)

**Goal:** see how each optimization level changes the same function. Build `ex2_serial.c` at `-O1`, `-O3` and `-Os` as `ex2o1.exe`, `ex2o3.exe` and `ex2os.exe`.

**What to check:** for each build, whether `make_serial` exists as its own function, and which instructions do `h * 31`. Count the instructions in `main` and compare the four builds, including `ex2o2.exe`. Confirm that your Day 1 keygen still works for every build.

### 2. Which functions survive in ex4? (★★)

**Goal:** learn which optimizations each level turns on. Build `ex4_chain.c` at `-O1`, `-O3` and `-Os`, and find the five functions from Exercise 2.1 in each.

**What to check:** make a table with one row per build, from `-O0` to `-O3` and `-Os`. Record which functions exist, which ones end in `jmp`, and how the final remainder is computed. Find the level that keeps every call as `call` and `ret`, and the one that uses no magic number; explain the second choice.

### 3. Recover a division from its magic number (★★)

**Goal:** recover a divisor from the Listing alone, then prove it. Ask a classmate to write a small function that divides by a secret constant, and to build it at `-O2`. Or write three yourself, put them aside for a day, and work from the `.exe`.

**What to check:** for each function, write down the magic number, the total shift and the divisor you calculate. Say whether the division is signed or unsigned, and which instructions told you. Check your answer by running the program on a few inputs, including a negative one for signed code.

### 4. Break the tail call (★★★)

**Goal:** find out exactly what stops GCC from making a tail call. Copy `ex4_chain.c` and make one change at a time to `check_access`, rebuilding at `-O2` after each:

- return `check_zone(code, 7) + 1` instead of `check_zone(code, 7)`;
- return the result of `check_zone` negated with `!`;
- pass the address of a local variable to a new helper and return its result;
- call `zone_key` directly, with all six arguments, and return its result;
- change `check_access` to return `long long` while `check_zone` still returns `int`.

**What to check:** before each build, predict whether the last instruction will be `jmp` or `ret`, and write down why. Then check the Listing. For each case that stays a `call`, explain what prevents the `jmp`.

### 5. ex4's code from the -O2 Listing alone (★★★)

**Goal:** reverse a function from optimized assembly without the decompiler or the `-O0` build. Close the Decompiler window and open only `ex4o2.exe`.

**What to check:** write `zone_key` as pseudo-code from the Listing alone, turning every multiply and shift back into C operators. Turn it into a Python function and check that it prints the code `ex4o2.exe` accepts. Compare it with your Exercise 2.2 notes only at the end.

## Answer key and hints

Try each exercise for at least 15 minutes before you look here. Addresses and exact instructions depend on your compiler version, so they're left out.

| Exercise | Hint | Answer |
| --- | --- | --- |
| 1.1 | Look at the first few instructions of each `main` | `ex1o2`'s `main` has no RBP frame and fewer instructions; the decompiler output is nearly the same; the password is still `hunter2-ghidra` |
| 1.2 | Search `main` for `shl` and `sub`, or `imul` | `make_serial` was inlined into `main`; `h * 31` is done as `(h << 5) - h` or with `imul`; the keygen still works |
| 1.3 | The XOR is no longer in a function of its own | `decode` was inlined into `main`; the key is decoded into a buffer on `main`'s stack; it is still `R3v3rs1ng_D4y1` |
| 1.4 | Reference correlators only use matches you have accepted | Exact bytes match the runtime functions; Data Reference Match pairs `main` through its strings; `make_serial` has no partner because it no longer exists in `ex2o2` |
| 2.1 | Start from the call that gets the result of `strtoul` | `main` → `check_access` → `check_zone` → `zone_key`, then `check_zone` → `check_door`; `zone_key` calls `rotl` |
| 2.2 | `0xc0de` is 49374 and `0x2026` is 8230 | `zone_key(7, 4, 12, 5, 0xC0DE, 0x2026)`: 7, 4, 12, 5 in ECX, EDX, R8D, R9D; `0xC0DE` at `[rsp+0x20]` and `0x2026` at `[rsp+0x28]`. The code is **25039268** |
| 2.2 formula | `rotl(x, n)` rotates `x` left by `n` bits | `k = zone*1000003 + floor*7919 + door`, then `k = rotl(k, shift) ^ salt`, then the code is `(k + pepper) % 100000000` (32-bit) |
| 2.3 | ECX is the first argument of `check_door` | ECX holds your number and EDX the code, `0x17E11A4` = 25039268 |
| 3.1 | Look at the last instruction of each small function | `rotl` was inlined as `rol`; `check_access` and `check_zone` end in `jmp`; arguments 5 and 6 are at `[rbp+0x30]` and `[rbp+0x38]` in `ex4`, and `[rsp+0x28]` and `[rsp+0x30]` in `ex4o2`; the multiply implements `% 100000000` in both builds |
| 3.2 | A `jmp` pushes nothing | Only `main` (and the runtime) is above `check_door`; `check_access` and `check_zone` left no return address. RSP doesn't change at the `jmp` instructions |
| 4A | Read the bytes of each number from lowest to highest | The pass is built in a local buffer of the function that `main` calls, as a few large values plus a zero byte. The pass is `FR4ME-W4LK3R` |
| 4A tail call | Where does the second `strcmp` argument live? | The callee gets a pointer into the caller's own frame, so that frame must stay alive until the call returns |
| 4B | `strcmp` gets the input in RCX and the pass in RDX | The chain is `main` → `check_pass` → `same` → `strcmp`; the pass is in `check_pass`'s frame |

A script that computes the access code for Exercise 2.2 is in [lab/solutions/day2/ex4\_code.py](../lab/solutions/day2/ex4_code.py).

Hints and expected results for the extra-credit challenges are in [lab/solutions/day2/extra-credit.md](../lab/solutions/day2/extra-credit.md).

## Cheat sheet additions and Day 3

Add these rows to your Day 1 cheat sheet.

| Task | Ghidra | x64dbg |
| --- | --- | --- |
| Re-run analysis or change analyzers | Analysis → Auto Analyze | n/a |
| Run one analyzer | Analysis → One Shot | n/a |
| Set a function's prototype | Right-click the name in the Decompiler → Edit Function Signature | n/a |
| Compare two builds | Tools → Run Tool → Version Tracking | n/a |
| See how you got here | n/a | Call Stack tab |
| Return to the program's own code | n/a | Alt+F9 (Run to user code) |
| Label an address | `L` | `:` |
| Comment an instruction | `;` | `;` |

**Remember for x64:** arguments 1 to 4 in RCX, RDX, R8, R9; arguments 5 and 6 at `[rsp+0x20]` and `[rsp+0x28]` at the call; 32 bytes of shadow space; the result in RAX; a `jmp` at the end of a function is often a tail call.

**Remember for `-O2`:** `lea` and shifts are often multiplies; a large constant then a shift is a division; a `push` of RBX or RSI means a value outlives a call; a missing function was probably inlined.

**Day 3 preview:** a menu program with a `switch`, loops of each kind, recursion and global data. You will recover jump tables, recognize loop shapes in assembly, and read code without the decompiler. In x64dbg you add conditional breakpoints, the command line and the graph view.

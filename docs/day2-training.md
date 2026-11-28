# Day 2: Optimized Code and the Stack

Nov 27, 2026

## Overview

On Day 1 every program was built with `-O0`, so the code followed the source line by line. Real programs are built with optimization. Today you read the same programs at `-O2` and learn how functions pass arguments and use the stack. You also see how inlining and tail calls change what both tools show.

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

**Lab rules**

- Work in your Windows VM and take a snapshot before you start.
- Only analyze the practice programs in this guide.
- Keep notes as you go: addresses, what each function does, and how you found it.

## Schedule

The day runs about 7 hours with breaks, and roughly half of it is hands-on exercise time.

| Time | Block | What you do |
| --- | --- | --- |
| 0:00–0:20 | Module 0: Setup | Snapshot the VM, build the Day 2 programs |
| 0:20–0:50 | Module 1A: What `-O2` changes | Inlining, registers, arithmetic, loops; analyzer options |
| 0:50–2:05 | Exercise 1.1–1.4 | Compare `ex1o2`, `ex2o2`, `ex3o2` with Day 1; Version Tracking on `ex2` |
| 2:05–2:20 | Break |  |
| 2:20–2:50 | Module 2A: The stack and the calling convention | Frames, shadow space, stack arguments, function signatures |
| 2:50–3:50 | Exercise 2.1–2.3 | Map the call chain in `ex4`; read stack arguments; the call stack in x64dbg |
| 3:50–4:35 | Lunch |  |
| 4:35–5:25 | Module 3: Inlining and tail calls | Exercise 3.1–3.2 on `ex4o2` |
| 5:25–6:25 | Module 4: Capstone | Recover the boarding pass from `ex5` with both tools |
| 6:25–6:45 | Review | Go over the answer key and write up your notes |
| 6:45–7:00 | Wrap-up | Cheat sheet additions and the plan for Day 3 |

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

**Compile** with `make`. Open `RE-Portable\Devkit.cmd`; its shell starts in the repo's `lab` folder. Then run:

```bash
make day1     # rebuilds bin/day1/ if you cleaned it
make day2     # builds bin/day2/ex1o2.exe ... ex5.exe
```

The executables go into `bin/day2`. Every program gets the usual `-O0 -s -Wall`. For the optimized ones, the Day 2 Makefile adds `-O2` after it, and the last `-O` option wins. Plain `make` builds every day at once.

Run each new program once with a wrong answer: `ex4` asks for an access code and `ex5` for a boarding pass. Then import all six into your Day 1 Ghidra project and analyze them. Leave the analysis options at their defaults for now; Exercise 1.1 looks at them.

## Module 1: Optimized code (1 h 45 min)

### 1A. What `-O2` changes (30 min)

The optimizer keeps what the program does and changes how it does it. These are the changes you will meet today:

- **Inlining.** A small function's body is copied into its caller, and the call disappears. A function you renamed on Day 1 may not exist at all in the `-O2` build.
- **Registers instead of the stack.** At `-O0` every variable lives in memory, such as `[rbp-0x4]`, and is loaded and stored on each use. At `-O2` values stay in registers, so there are far fewer memory accesses.
- **No frame pointer.** At `-O0` each function starts with `push rbp` and `mov rbp, rsp`. At `-O2` RBP is often a normal register, and locals are addressed from RSP.
- **Cheaper arithmetic.** `h * 31` can become a shift and a subtract: `(h << 5) - h`. Division by a constant becomes a multiply by a large "magic" number and a shift. GCC does the division trick even at `-O0`.
- **Reshaped loops.** The loop test often moves to the bottom, with one extra check before the loop. Counters can turn into pointers that walk the data.
- **Reordering.** Instructions from different source lines are mixed together, and branches can be flipped. The order in the Listing no longer follows the source.

The decompiler hides some of this, because it rebuilds C from the instructions either way. The Listing shows all of it. Today you read both.

**Analyzer options.** When Ghidra asks to analyze a program, it shows a list of analyzers with a tick box each. You can come back to the list at any time with Analysis → Auto Analyze, and re-run analysis after you change something. Analysis → One Shot runs a single analyzer once.

### Exercise 1.1: ex1 at -O2, side by side (15 min)

1. Open `ex1o2.exe` in the CodeBrowser. Open Day 1's `ex1.exe` in the same CodeBrowser with File → Open. Each program gets its own tab above the Listing.
2. Find `main` in `ex1o2` from the "Access granted!" string, as on Day 1, and rename it.
3. Compare the two `main` functions in the Listing. Does the `-O2` one start with `push rbp`? Where do the input buffer and the `strcmp` arguments come from?
4. Compare the decompiler output. It should look almost the same, even though the instructions differ.
5. Open Analysis → Auto Analyze for `ex1o2` and read the list of analyzers. Find **Decompiler Parameter ID**; it uses the decompiler to work out each function's parameters. If it is not ticked, tick it and click Analyze.

**Write down:** the number of instructions in each `main`, and one difference you can see in the Listing but not in the decompiler.

### Exercise 1.2: Where did make\_serial go? (25 min)

1. Open `ex2o2.exe` and find `main` from "Invalid serial."
2. On Day 1, `main` called `make_serial`. Look for that call now. Is there one?
3. Find the loop inside `main` that walks the name. Open the Function Graph and point out the loop.
4. Find the three constants you know from Day 1: `0x1337`, 31 and `0xC0FFEE`. One of them may not appear as a number. Work out how the multiply by 31 is done instead.
5. Run your Day 1 keygen for a new name and check the serial against `ex2o2.exe`. The code changed; the algorithm did not.

**Write down:** what replaced the call to `make_serial`, and the instructions that do `h * 31`.

### Exercise 1.3: ex3 at -O2 (15 min)

1. Open `ex3o2.exe` and find `main` from "Bad license key."
2. Find the `IsDebuggerPresent` call and the branch to "Debugger detected. Bye."
3. Find the XOR with `0x42`. On Day 1 it was in its own `decode` function. Where is it now?
4. If the loop uses XMM registers and `pxor`, the compiler is working on 16 bytes at a time. Find where it handles the bytes that are left over.

**Write down:** whether `decode` still exists, and where the decoded key is written.

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

## Module 2: The stack and the calling convention (1 h 30 min)

### 2A. Stack frames and arguments (30 min)

The stack grows toward lower addresses. RSP points at its top, the lowest address in use.

- `call` pushes the return address, the address of the next instruction, and jumps to the function. `ret` pops it and jumps back.
- A function's **frame** is the part of the stack it owns: saved registers, local variables, and space for the arguments of the calls it makes.
- At `-O0`, GCC builds every frame the same way: `push rbp`, `mov rbp, rsp`, `sub rsp, N`. Locals sit below RBP at `[rbp-0x4]` and so on. `leave` and `ret` undo it at the end.

**The Windows x64 calling convention** (Day 1 covered the first point):

- The first four integer or pointer arguments go in RCX, RDX, R8 and R9. A 32-bit argument uses the lower half: ECX, EDX, R8D, R9D.
- Arguments five and up go on the stack. Floating-point arguments use XMM0 to XMM3 instead; today's programs have none.
- The caller always reserves 32 bytes just above the return address, the **shadow space** (also called home space). The callee may save RCX, RDX, R8 and R9 there.
- So at the `call`, argument 5 is at `[rsp+0x20]` and argument 6 at `[rsp+0x28]`. Inside the callee, the return address moves them 8 bytes up, to `[rsp+0x28]` and `[rsp+0x30]`.
- The result comes back in RAX (EAX for 32 bits).
- RAX, RCX, RDX and R8 to R11 can be changed by any call. RBX, RBP, RDI, RSI and R12 to R15 must be preserved. A function that uses them pushes them first and pops them at the end.

This is what a frame looks like inside a function built at `-O0`, after its `push rbp` and `mov rbp, rsp`:

| Address | Holds |
| --- | --- |
| `[rbp+0x38]` | argument 6 |
| `[rbp+0x30]` | argument 5 |
| `[rbp+0x10]` to `[rbp+0x28]` | shadow space: where `-O0` code saves RCX, RDX, R8 and R9 |
| `[rbp+0x8]` | return address |
| `[rbp]` | the caller's RBP |
| `[rbp-0x4]` and below | local variables |

**Function signatures in Ghidra.** Ghidra guesses each function's parameters. When it guesses wrong, the decompiler shows missing or extra arguments. Right-click the function name in the Decompiler → Edit Function Signature, and type the prototype as C, for example `int check(char *name, int len)`. The same dialog has a Calling Convention setting; for 64-bit Windows code it should be `__fastcall`, Ghidra's name for the convention above.

**x64dbg's call stack.** The Call Stack tab lists the return addresses on the stack. That is the chain of calls that led to the current instruction. Double-click a line to go to that place in the caller. Labels you add with `:` show up in it.

### Exercise 2.1: Map the call chain in ex4 (20 min)

1. Open `ex4.exe` in the CodeBrowser and find `main` from "Door open."
2. Find the call that receives the number you typed. Follow it, then keep following calls until you reach the function that makes the final comparison.
3. Rename each function by what it does. Suggested names, from the top: `check_access`, `check_zone`, `zone_key`, `check_door`, and a small helper `rotl`.
4. In `check_zone`, read the prologue and epilogue in the Listing. Find `push rbp`, `mov rbp, rsp`, the `sub rsp` and the `leave`.
5. Find where `check_zone` saves ECX and EDX in the shadow space.

**Write down:** the chain of calls from `main` to the comparison, and the frame size each function reserves with `sub rsp`.

### Exercise 2.2: Six arguments (20 min)

1. In `check_zone`, find the call to `zone_key`. Just before it, find the four values moved into ECX, EDX, R8D and R9D.
2. Find the two values written to `[rsp+0x20]` and `[rsp+0x28]`. These are arguments 5 and 6.
3. Go into `zone_key` and find where it reads arguments 5 and 6. Check the offsets against the table in 2A.
4. Edit `zone_key`'s signature to `uint zone_key(uint zone, uint floor, uint door, uint shift, uint salt, uint pepper)`. Go back to `check_zone` and check that the decompiler shows six arguments in the call.
5. Edit `rotl`'s signature too. Work out what it does to its first argument.
6. Read `zone_key` in the decompiler and work out the access code from the six values. Python is fine for the arithmetic. Run `ex4.exe` with your answer.

**Write down:** the six argument values in order, where each one travels, and the access code.

### Exercise 2.3: The call stack in x64dbg (20 min)

1. Open `ex4.exe` in x64dbg. Line up the addresses with Ghidra as on Day 1 (Exercise 2.3), then set a breakpoint on the first instruction of `check_door`.
2. Put labels on the five functions you renamed: go to each start address and press `:`.
3. Press F9 and type any number in the console window.
4. When it stops, open the Call Stack tab. Read the chain of callers and compare it with your notes from Exercise 2.1.
5. Double-click each line to see the instruction after each `call`. Add a comment with `;` on the comparison in `check_door`.
6. Read ECX and EDX. One is the number you typed; the other is the right code, in hex. Convert it to decimal and check it against Exercise 2.2.
7. In the stack pane, find the return address into `check_zone` and the shadow space above it.

## Module 3: Inlining and tail calls (50 min)

**Inlining**, again: a small function's body is copied into the caller. When the helper is short enough, it can shrink to a single instruction.

**A tail call** is a call that is the last thing a function does, as in `return other(x);`. At `-O2` the compiler replaces `call other` followed by `ret` with `jmp other`. The current function's frame is gone before the jump, so `other` returns straight to the original caller. This saves stack space and time, but the middle function leaves no return address behind. A debugger's call stack skips it.

A call can only become a tail call when nothing is left to do after it. For example, the callee must not use the caller's local variables, because that frame no longer exists.

### Exercise 3.1: ex4 at -O2 in Ghidra (20 min)

1. Open `ex4o2.exe` and find `main` from "Door open." Follow the calls down, as in Exercise 2.1, and give the functions the same names.
2. Which of the five functions still exist? Find the `rol` instruction in `zone_key` and explain where `rotl` went.
3. Find the last instruction of `check_access` and of `check_zone`. What replaced `call` and `ret`?
4. In `zone_key`, find where arguments 5 and 6 are read now that there is no `push rbp`. Check the offsets against 2A.
5. Find the multiply by `0x55e63b89` and the shift after it. Which part of the source line does it implement? Check whether `ex4.exe` has the same trick.

**Write down:** which functions were inlined, which calls became `jmp`, and the offsets of arguments 5 and 6 in each build.

### Exercise 3.2: The shorter call stack (15 min)

1. Open `ex4o2.exe` in x64dbg, line up the addresses, and break on the first instruction of `check_door`.
2. Run it and type any number. Open the Call Stack tab. Compare it with Exercise 2.3. Which callers are missing?
3. Restart it (Ctrl+F2). Break on the call to `check_access` in `main`, and step with F7 until you reach `check_door`. Watch RSP at each `jmp`.
4. Read EDX at `check_door`. It should be the same code as in `ex4.exe`.

**Stretch goal:** run Version Tracking with `ex4.exe` as the source and `ex4o2.exe` as the destination. Which correlators match the functions that survived?

## Module 4: Capstone, the boarding pass in ex5 (1 h)

`ex5.exe` is built only at `-O2`. Its boarding pass is put together on the stack at runtime and is never stored as one string. Use Ghidra to find how it is built, then x64dbg to read it from memory.

### Part A: Static analysis in Ghidra (25 min)

1. Import and analyze `ex5.exe`. Search Defined Strings for anything that looks like a pass. You won't find the whole pass.
2. Find `main` from "Boarding pass rejected." Follow the call that receives your input, and rename the functions you find.
3. In the function that builds the pass, find the local buffer on the stack and every value written into it. Some writes put several characters at once, as one large number. A value may first be loaded from a constant in `.rdata`; follow the reference to read it.
4. Turn those numbers into characters. x86 is little-endian, so the lowest byte of each number is the first character in memory. Right-click a number in the Listing and use Convert to see it as characters, or decode it with Python.
5. The function that builds the pass then calls a function that calls `strcmp`. Why is that not a tail call, even at `-O2`? Look at what it passes.

### Part B: Dynamic analysis in x64dbg (25 min)

1. Open `ex5.exe` in x64dbg and press F9 to reach the entry point.
2. Open the Symbols tab, select the C runtime DLL (`msvcrt.dll`), find `strcmp`, and press F2 on it.
3. Press F9 and type any pass. If it stops before you have typed anything, press F9 again.
4. Now you are inside the DLL. Open the Call Stack tab and read the chain back to `main`.
5. Follow RCX and RDX in the dump. One is your input. The other is the pass, in a buffer close to RSP: it lives in a caller's frame. Which caller?
6. Use Run to user code (Alt+F9). x64dbg stops back in `ex5.exe`, right after the call to `strcmp`. Label the functions with `:`.
7. Run `ex5.exe` without the debugger and enter the pass.

**Deliverable:** a half-page write-up. Cover the pass, how and where it is built, and which functions were inlined. Add the call chain from `main` to `strcmp`, and why the last call is not a tail call.

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

**Day 3 preview:** a menu program with a `switch`, loops of each kind, recursion and global data. You will recover jump tables, recognize loop shapes in assembly, and read code without the decompiler. In x64dbg you add conditional breakpoints, the command line and the graph view.

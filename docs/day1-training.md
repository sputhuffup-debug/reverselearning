# Day 1: Reverse Engineering with Ghidra and x64dbg

Nov 26, 2026

## Overview

By the end of Day 1 you will find, understand and bypass a license check in a Windows program, first by reading it in Ghidra and then by stepping through it in x64dbg. You will practice on three small programs you compile yourself, so you know exactly what is inside them.

**Goals for the day**

1. Load a program into Ghidra, let it analyze, and find the code that matters using strings and cross-references.
2. Read decompiled code, then rename and retype it until it reads like source.
3. Run a program in x64dbg: set breakpoints, step through code, and read registers, the stack and memory.
4. Match the same address in both tools and switch between them as you work.
5. Change a program's behavior at runtime and save a patched copy.

**What you need**

- The portable kit built by `Build-PortableRE.ps1`: Ghidra, its JDK, x64dbg, and the w64devkit GCC toolchain with `make`.
- A copy of the course repo. Its `lab` folder holds the three practice programs and the Makefile that builds them.
- Basic C. No assembly is needed in advance; you learn what you need as you go.

**Lab rules**

- Work in a Windows VM with a snapshot taken before you start, and roll back if anything gets messy.
- Only analyze the practice programs in this guide. Real malware comes later, on an isolated network, once these basics are solid.
- Keep notes as you go: every address you find, what it does, and how you found it.

## Schedule

The day runs about 7 hours with breaks, and roughly half of it is hands-on exercise time.

| Time | Block | What you do |
| --- | --- | --- |
| 0:00–0:30 | Module 0: Setup | Snapshot the VM, start the kit, compile the three practice programs |
| 0:30–1:15 | Module 1A: Ghidra tour | Project, import, auto-analysis, the main windows |
| 1:15–2:15 | Exercise 1.1–1.2 | Find the password in `ex1`; clean up `ex2` in the decompiler |
| 2:15–2:30 | Break |  |
| 2:30–3:15 | Module 2A: x64dbg tour | Layout, breakpoints, stepping, registers and stack |
| 3:15–4:15 | Exercise 2.1–2.3 | Debug `ex1` and `ex2`; match addresses with Ghidra |
| 4:15–5:00 | Lunch |  |
| 5:00–6:15 | Module 3: Capstone | Solve and patch `ex3` with both tools |
| 6:15–6:45 | Review | Go over the answer key and write up your notes |
| 6:45–7:00 | Wrap-up | Cheat sheet and the plan for Day 2 |

## Module 0: Build the practice programs (30 min)

You will reverse three programs that get harder in turn: a hardcoded password, a serial number worked out from a name, and a hidden key with an anti-debugging check. Their sources are in the repo's `lab` folder and linked below. Don't reread the source once it's compiled; the aim is to recover it with the tools.

[**ex1\_password.c**](../lab/ex1_password.c): a password stored as plain text

[**ex2\_serial.c**](../lab/ex2_serial.c): the serial is calculated from the name

[**ex3\_crackme.c**](../lab/ex3_crackme.c): a key that is only decoded at runtime, plus a debugger check

**Compile** with `make`. Open `RE-Portable\Devkit.cmd`; its shell starts in the repo's `lab` folder. Then run:

```bash
make          # builds bin/ex1.exe, bin/ex2.exe and bin/ex3.exe
make clean    # deletes them
```

The `.c` files stay where they are; only the executables go into `bin`. The Makefile compiles with `-O0`, which keeps the code close to the source, and `-s`, which strips the function names so you have to recover them yourself. After you change a source, run `make` again; it rebuilds only what changed.

Run each `.exe` in `bin` once with a wrong answer so you know what failure looks like. Then close the `.c` files and leave them closed until the answer key.

## Module 1: Ghidra fundamentals (1 h 45 min)

Ghidra reads a program without running it (static analysis). It turns machine code into readable assembly and C-like pseudocode, and lets you rename things as you work out what they do.

### 1A. Tour (45 min)

1. **Create a project.** Start `Ghidra.cmd`, then File → New Project → Non-Shared, and put it in the kit's `projects` folder. A project holds any number of programs plus your notes and renames.
2. **Import.** Drag `ex1.exe` into the project window and accept the detected format (Portable Executable, x86:LE:64).
3. **Analyze.** Double-click the program to open the CodeBrowser and click Yes to analyze with the defaults. Wait for the progress bar at the bottom right to finish.
4. **Learn the four main windows:**
   - **Listing** (center): the disassembly, one instruction per line with its address.
   - **Decompiler** (right): C-like pseudocode for the function the cursor is in. Clicking in one window highlights the matching line in the other.
   - **Symbol Tree** (left): functions, imports and exports. Imports tell you a lot; `strcmp`, `IsDebuggerPresent` or `CreateFileW` hint at what the program does.
   - **Defined Strings** (Window → Defined Strings): every text string Ghidra found. This is usually the fastest way into a program.
5. **Move around.** Double-click a name to follow it, press Alt+← to go back, and press `G` to jump to an address.
6. **Find who uses something.** Right-click a string or function → References → Show References to (Ctrl+Shift+F). The code that prints "Access denied" is usually right next to the check you want.
7. **Annotate as you go.** Press `L` to rename, Ctrl+L to change a type, and `;` to add a comment. Renaming is how pseudocode turns into something you can read, so do it all the time.

The programs are stripped, so `main` shows up with a name like `FUN_140001450`. MinGW's startup code runs first and calls `main` later. Don't trace the startup code; find `main` from its strings.

### Exercise 1.1: Find the password in ex1 (20 min)

1. Open Defined Strings and filter for `Access`.
2. Double-click "Access granted!", then follow its reference to the function that uses it.
3. Rename that function to `main`. In the decompiler, find the `strcmp` call and the string it compares your input with.
4. Run `ex1.exe` with that password to confirm.

**Write down:** the address of `main`, the password, and the address of the conditional jump that picks granted or denied.

### Exercise 1.2: Recover the serial algorithm in ex2 (40 min)

1. Import and analyze `ex2.exe`, then find `main` from the "Invalid serial" string.
2. Find the function whose return value is compared with the number you typed. Rename it `make_serial`.
3. Clean it up until it reads like source: set its parameter's type to `char *` and call it `name`, rename the loop counter to `i` and the running value to `h`.
4. Note each constant. Right-click a number to show it in hex or decimal; some constants are easier to recognize in one or the other.
5. Write a small keygen (Python is fine) that prints the right serial for a given name. Test it on three names.

**Stretch goal:** Open the Function Graph (Window → Function Graph) for `make_serial` and point out the loop as boxes and arrows.

## Module 2: x64dbg fundamentals (1 h 45 min)

x64dbg runs the program and lets you pause it at any instruction (dynamic analysis). Ghidra tells you what the code could do; x64dbg shows what it actually does with real values.

### 2A. Tour (45 min)

1. **Open a program.** Start `x64dbg.cmd` and use File → Open on `ex1.exe`. It pauses first at a system breakpoint inside Windows. Press F9 once to reach the program's own entry point.
2. **Learn the CPU tab:**
   - **Disassembly** (top left): the current instruction is highlighted and RIP points at it.
   - **Registers** (top right): RAX, RCX, RDX and the rest, plus flags like ZF. Values that just changed turn red.
   - **Dump** (bottom left): raw memory. Right-click a register → Follow in Dump to see what it points at.
   - **Stack** (bottom right): local variables and return addresses.
3. **Control execution:**
   - F9 runs until the next breakpoint.
   - F8 steps over one instruction and doesn't follow calls inside it.
   - F7 steps into calls.
   - Ctrl+F9 runs until the current function returns.
   - F2 sets or clears a breakpoint.
   - Ctrl+F2 restarts the program.
4. **Find code by its strings.** Right-click in the disassembly → Search for → Current Module → String references. Double-click a result to jump to the code that uses it.
5. **Know the calling convention.** On 64-bit Windows, a function receives its first four arguments in **RCX, RDX, R8 and R9**, and returns its result in **RAX**. When you pause on a `call`, those registers tell you what is being passed.
6. **Change things while it runs.** Double-click a register to edit it, or double-click a flag like ZF to flip it. Press Space on an instruction to rewrite it.

Windows loads the program at a random address each run (ASLR), so x64dbg's addresses won't match Ghidra's `0x140000000` base. Exercise 2.3 fixes that.

### Exercise 2.1: Watch the password check in ex1 (20 min)

1. Use String references to find "Access denied." and jump to it.
2. Scroll up to the `call` to `strcmp` and press F2 on it.
3. Press F9, then type a wrong password in the program's console window.
4. When it pauses, follow RCX and RDX in the dump. One is your input; the other is the real password.
5. Press F8 to step over the call and read the result in RAX. Step to the conditional jump just after it, flip ZF, and press F9. Check that you see "Access granted!" with the wrong password.

### Exercise 2.2: Fish a valid serial from ex2 (20 min)

1. Find the call to `make_serial`, the function you renamed in Exercise 1.2, by searching for its strings.
2. Set a breakpoint on the instruction right after that call.
3. Run it, enter your name and any serial.
4. Read RAX when it stops. That is the correct serial for your name, in hex. Run the program again without the debugger and check it, then compare it with what your keygen prints.

### Exercise 2.3: Line up the addresses in both tools (20 min)

1. In x64dbg, open the Symbols tab and note the base address of `ex2.exe`.
2. In Ghidra, open Window → Memory Map, click the house icon (Set Image Base), and enter that base.
3. Pick an instruction in `make_serial` in Ghidra, press Ctrl+G in x64dbg, and go to the same address. Check that it's the same instruction.
4. Without changing the base: offset = Ghidra address − `0x140000000`, and the x64dbg address = base + offset. Work out one address this way and check it.

Restart the program and the base changes. Redo step 2 or use the offset method.

## Module 3: Capstone, solving and patching ex3 (1 h 15 min)

In `ex3.exe`, searching for strings won't turn up the key, and the program refuses to run under a debugger. You will use Ghidra to understand it, x64dbg to get past its defenses, and then save a patched copy that accepts any key.

### Part A: Static analysis in Ghidra (25 min)

1. Import and analyze `ex3.exe`. In the Symbol Tree, open Imports and note anything unusual. Which API suggests anti-debugging?
2. Search Defined Strings for the key. You won't find it. Find `main` from "Bad license key." instead.
3. In `main`, find the debugger check and the branch that leads to "Debugger detected. Bye."
4. Find the function called just before `strcmp` and rename it `decode`. Work out what it does to each byte and where it reads the bytes from.
5. Double-click the source array to see its bytes, then decode them by hand or with a few lines of Python. That gives you the key with static analysis alone.

### Part B: Dynamic analysis in x64dbg (25 min)

1. Open `ex3.exe` in x64dbg and press F9 until it exits. Confirm that it prints "Debugger detected."
2. Restart it (Ctrl+F2). Find the call to `IsDebuggerPresent` in `main` (line up the addresses as in Exercise 2.3, or search for the "Debugger detected" string). Break on the instruction just after the call and set RAX to `0`.
3. Set a breakpoint on the `strcmp` call, run it, and enter any key.
4. When it stops, follow RCX and RDX in the dump. The decoded key is sitting in memory. Check that it matches what you got in Part A.

x64dbg can also hide itself from this check: Debug → Advanced → Hide debugger (PEB). Try it after you have done the bypass by hand.

### Part C: Patch the program (25 min)

1. Find the conditional jump after the `IsDebuggerPresent` call. Select it, press Space and change it so the program always continues; usually that means `nop` with "Fill with NOPs" ticked, or reversing the jump.
2. Do the same to the jump after `strcmp`, so the program always reaches "License OK. Welcome!"
3. Save it with File → Patch file (Ctrl+P) → Patch File, as `ex3_patched.exe`. Never overwrite the original.
4. Close x64dbg, run `ex3_patched.exe` normally and enter any key. It should accept it.

**Deliverable:** a half-page write-up covering the key, how the key is hidden, how the debugger check works, the two addresses you patched (as offsets from the image base), and what each patch changed.

## Answer key and hints

Try each exercise for at least 15 minutes before you look here. Addresses depend on your compiler, so they're left out.

| Exercise | Hint | Answer |
| --- | --- | --- |
| 1.1 | The password is one of the arguments to `strcmp` | `hunter2-ghidra` |
| 1.2 | `0x1f` is 31; the result is XORed with `0xC0FFEE`; `h` starts at `0x1337` | `h = 0x1337`, then `h = h*31 + c` for each character, and the result is `h ^ 0xC0FFEE` (32-bit) |
| 1.2 check | Test your keygen with these names | alice → `cfb71247`, student → `97734cca`, ghidra → `294a7d0c` |
| 2.1 | At -O0, the result goes into EAX and is followed by `test eax, eax` and `jne`/`jnz` | RCX holds your input and RDX the password; flipping ZF takes the granted branch |
| 2.2 | Break on the instruction straight after the `call` | RAX holds the serial; for "alice" it's `0xCFB71247` |
| 3A | Look for `^ 0x42` in the decode loop | Each of the 14 bytes is XORed with `0x42`; the key is `R3v3rs1ng_D4y1` |
| 3B | `IsDebuggerPresent` returns 1 in RAX when a debugger is attached | Setting RAX to 0 after the call skips the exit; the decoded key is in the second `strcmp` argument (RDX) |
| 3C | Patch the jumps, not the calls | NOP the jump that leads to "Debugger detected" and the jump that leads to "Bad license key"; saving with Patch File keeps the original intact |

A keygen for Exercise 1.2 (also in [lab/solutions/keygen_ex2.py](../lab/solutions/keygen_ex2.py)):

```python
import sys

def serial(name: str) -> int:
    h = 0x1337
    for c in name.encode():
        h = (h * 31 + c) & 0xFFFFFFFF
    return h ^ 0xC0FFEE

print(format(serial(sys.argv[1]), "x"))
```

## Cheat sheet and Day 2

These are the defaults for both tools; you can change any of them in each tool's key bindings settings.

| Task | Ghidra | x64dbg |
| --- | --- | --- |
| Go to an address | `G` | Ctrl+G |
| Go back | Alt+← | `-` (minus) |
| Rename | `L` | `:` (label) |
| Comment | `;` | `;` |
| References to the selection | Ctrl+Shift+F | `X` |
| Find strings | Window → Defined Strings | Right-click → Search for → Current Module → String references |
| Change a type | Ctrl+L | n/a |
| Breakpoint | n/a | F2 |
| Run / step over / step into | n/a | F9 / F8 / F7 |
| Run until the function returns | n/a | Ctrl+F9 |
| Edit an instruction | Ctrl+Shift+G (Patch Instruction) | Space |
| Save patches | File → Export Program (Original File) | Ctrl+P → Patch File |

**Day 2 preview:** compile the same programs with `-O2` and see how much harder the code is to read, write your first Ghidra script to decode `ex3`'s key automatically, and solve beginner crackmes from [crackmes.one](https://crackmes.one) in your VM.

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
- A copy of the course repo. Its `lab/day1` folder holds today's three practice programs, and `lab/Makefile` builds them.
- Basic C. No assembly is needed in advance: the primers below teach what you need.

**Before you start**

Read these primers first, ideally the day before. They take about 2 hours together, and every exercise today assumes them.

- [Numbers and data](primers/01-numbers-and-data.md): hex, bytes, little-endian, signed values, XOR.
- [Registers and flags](primers/02-registers-and-flags.md): RAX to R15, RIP, and the flags that decide a jump.
- [Reading assembly](primers/03-reading-assembly.md): Intel syntax, memory operands and the instructions you will see today.
- [A program in memory](primers/04-memory-layout.md): sections, the stack and the heap, and why x64dbg's addresses differ from Ghidra's.
- [The stack and the calling convention](primers/05-stack-and-calls.md): read up to the calling convention; Day 2 covers the rest.

During the day, **Background** lines point to the primer section behind a step. Open one when a step doesn't make sense.

**Lab rules**

- Work in a Windows VM with a snapshot taken before you start, and roll back if anything gets messy.
- Only analyze the practice programs in this guide. Real malware comes later, on an isolated network, once these basics are solid.
- Keep notes as you go: every address you find, what it does, and how you found it.

**How the sections are laid out**

Around each set of numbered steps you will find why it matters, what you should see, and common mistakes. **Another example** sections apply the same technique to a different small program, so they give nothing away.

## Schedule

The day runs about 7 hours with breaks, and roughly half of it is hands-on exercise time. The extra-credit challenges in [Beyond this lesson](#beyond-this-lesson) are outside these hours.

| Time | Block | What you do |
| --- | --- | --- |
| 0:00–0:30 | Module 0: Setup | Snapshot the VM, start the kit, compile the three practice programs |
| 0:30–1:20 | Module 1A: Ghidra tour | Project, import, auto-analysis, the main windows |
| 1:20–2:25 | Exercise 1.1–1.2 | Find the password in `ex1`; clean up `ex2` in the decompiler |
| 2:25–2:40 | Break |  |
| 2:40–3:30 | Module 2A: x64dbg tour | Layout, breakpoints, stepping, registers and stack |
| 3:30–4:30 | Exercise 2.1–2.3 | Debug `ex1` and `ex2`; match addresses with Ghidra |
| 4:30–5:15 | Lunch |  |
| 5:15–6:35 | Module 3: Capstone | Solve and patch `ex3` with both tools |
| 6:35–7:00 | Review | Go over the answer key and write up your notes |
| 7:00–7:15 | Wrap-up | Cheat sheet and the plan for Day 2 |

## Module 0: Build the practice programs (30 min)

You will reverse three programs that get harder in turn: a hardcoded password, a serial number worked out from a name, and a hidden key with an anti-debugging check. Their sources are in the repo's `lab/day1` folder and linked below. Don't reread the source once it's compiled; the aim is to recover it with the tools.

[**ex1\_password.c**](../lab/day1/ex1_password.c): a password stored as plain text

[**ex2\_serial.c**](../lab/day1/ex2_serial.c): the serial is calculated from the name

[**ex3\_crackme.c**](../lab/day1/ex3_crackme.c): a key that is only decoded at runtime, plus a debugger check

**Compile** with `make`. Open `RE-Portable\Devkit.cmd`; its shell starts in the repo's `lab` folder. Then run:

```bash
make day1     # builds bin/day1/ex1.exe, ex2.exe and ex3.exe
make clean    # deletes them
```

The `.c` files stay where they are; only the executables go into `bin/day1`. Plain `make` builds every day's programs at once. The Makefile compiles with `-O0`, which keeps the code close to the source, and `-s`, which strips the function names so you have to recover them yourself. After you change a source, run `make` again; it rebuilds only what changed.

Run each `.exe` in `bin/day1` once with a wrong answer so you know what failure looks like. Then close the `.c` files and leave them closed until the answer key.

**Why it matters.** The `-s` flag gives you what a real stripped program gives you: no function names, only imports and strings.

**What you should see.** `make day1` prints a `gcc` command line for each program and returns to the prompt without errors. Each program asks for input and prints one failure line for a wrong answer.

**If it doesn't match.**

- "make: command not found" means you are in an ordinary Command Prompt. Open `Devkit.cmd` instead.
- "No rule to make target" means the shell is not in the repo's `lab` folder. `Devkit.cmd` prints the folder it used.
- Write down each failure message exactly; you will search for these strings next.

**Background:** [Patterns you'll see a lot](primers/03-reading-assembly.md#patterns-youll-see-a-lot) describes what `-O0` code looks like, including the `__main` call at the top of `main`.

## Module 1: Ghidra fundamentals (1 h 55 min)

Ghidra reads a program without running it (static analysis). It turns machine code into readable assembly and C-like pseudocode, and lets you rename things as you work out what they do.

### 1A. Tour (50 min)

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

**Why it matters.** A real program has thousands of functions, mostly compiler runtime. Strings and imports are the cheapest ways to find the few that matter.

**What you should see.**

- After step 3, the Listing's addresses all start with `14000`: the default image base `0x140000000` plus an offset.
- The Symbol Tree's Functions folder holds many `FUN_` entries. Most belong to MinGW's runtime, not to your code.
- Under Imports, names such as `puts` and `strcmp` survive stripping, because Windows needs them to load the program.

**Reading the Listing.** Ghidra writes the destination first: `MOV RCX,RAX` copies RAX into RCX. A string is loaded with a `LEA`, shown with a label such as `s_Access_denied._1400...`.

**Background:** [The image and its base](primers/04-memory-layout.md#the-image-and-its-base), [Sections](primers/04-memory-layout.md#sections), [Imports and the IAT](primers/04-memory-layout.md#imports-and-the-iat). For the Listing: [Intel syntax](primers/03-reading-assembly.md#intel-syntax), [Memory operands](primers/03-reading-assembly.md#memory-operands), [RIP-relative addressing](primers/03-reading-assembly.md#rip-relative-addressing).

**If it doesn't match.**

- If you clicked No to analysis, run Analysis → Auto Analyze now. Without it there are no functions and few strings.
- If the Decompiler window is empty, the cursor is not inside a function. Click an instruction in the Listing first.

### Exercise 1.1: Find the password in ex1 (25 min)

1. Open Defined Strings and filter for `Access`.
2. Double-click "Access granted!", then follow its reference to the function that uses it.
3. Rename that function to `main`. In the decompiler, find the `strcmp` call and the string it compares your input with.
4. Run `ex1.exe` with that password to confirm.

**Write down:** the address of `main`, the password, and the address of the conditional jump that picks granted or denied.

**Why it matters.** "Find the message, then walk back to the decision" is the most common first move in reverse engineering. The decision is nearly always a compare or a call, then a conditional jump.

**What you should see.**

- Step 2 lands on the string in `.rdata`. To its right is an XREF entry; double-click it to reach the code that uses the string.
- The decompiled `main` fills a local buffer (named something like `local_48`) with `fgets`, then passes it to `strcmp` with a quoted string.
- `main` starts with a call to an unnamed `FUN_`: MinGW's `__main`. `printf` may also be a `FUN_`, because MinGW links its own copy into the program.

To find the jump, click the `if` line in the decompiler. The Listing highlights `CALL strcmp`, `TEST EAX,EAX`, then a `JNZ` or `JZ`.

**Background:** [cmp, test and conditional jumps](primers/02-registers-and-flags.md#cmp-test-and-conditional-jumps) explains the `TEST` and the jump. [Worked example: a string check at -O0](primers/03-reading-assembly.md#worked-example-a-string-check-at--o0) reads the same shape line by line.

**If it doesn't match.** The jump usually tests the opposite of the `if`. The source grants on "equal"; the jump goes to "denied" on "not equal". `strcmp` returns 0 for a match, so the granted branch is the `== 0` one.

#### Another example: a length check, then memcmp

Not every password check is one `strcmp`. This door-code checker tests the length first, then compares a fixed number of bytes:

```c
int check_pin(const char *s) {
    if (strlen(s) != 9)
        return 0;
    if (memcmp(s, "swordfish", 9) != 0)
        return 0;
    return 1;
}
```

Built with MinGW GCC at `-O0`, Ghidra's decompiler shows something like this (names and layout vary):

```c
undefined8 FUN_140001450(char *param_1)
{
  size_t sVar1;
  int iVar2;

  sVar1 = strlen(param_1);
  if (sVar1 == 9) {
    iVar2 = memcmp(param_1,"swordfish",9);
    if (iVar2 == 0) {
      return 1;
    }
  }
  return 0;
}
```

The reverser's notes:

```
check_pin(s):                        ; renamed from FUN_140001450
  len(s) != 9            -> return 0
  memcmp(s, secret, 9) != 0 -> return 0  ; count in R8
  otherwise              -> return 1; caller tests EAX
```

Two things differ from `strcmp`. The count travels in R8 as a third argument, so the secret need not end in a zero byte. And there are two failure paths, so one patched jump is not enough.

**Background:** [The Windows x64 calling convention](primers/05-stack-and-calls.md#the-windows-x64-calling-convention) explains why the count goes in R8D.

### Exercise 1.2: Recover the serial algorithm in ex2 (40 min)

1. Import and analyze `ex2.exe`, then find `main` from the "Invalid serial" string.
2. Find the function whose return value is compared with the number you typed. Rename it `make_serial`.
3. Clean it up until it reads like source: set its parameter's type to `char *` and call it `name`, rename the loop counter to `i` and the running value to `h`.
4. Note each constant. Right-click a number to show it in hex or decimal; some constants are easier to recognize in one or the other.
5. Write a small keygen (Python is fine) that prints the right serial for a given name. Test it on three names.

**Stretch goal:** Open the Function Graph (Window → Function Graph) for `make_serial` and point out the loop as boxes and arrows.

**Why it matters.** Many checks compute the answer instead of storing it, so you read the recipe instead. A keygen proves you understood every step.

**What you should see.**

- In `main`, `scanf` reads your number into a local. The function you want takes the name buffer and its result is compared with that local.
- Before cleanup, `make_serial` looks something like `uint FUN_14000xxxx(longlong param_1)`, with locals such as `local_c` and `local_18`.
- After Ctrl+L to `char *`, `*(byte *)(param_1 + local_18)` becomes `name[i]`. One retype often makes a function readable.

**Background:** [Bits, bytes and the C types behind them](primers/01-numbers-and-data.md#bits-bytes-and-the-c-types-behind-them) covers `undefined4`, and [Locals and how Ghidra names them](primers/05-stack-and-calls.md#locals-and-how-ghidra-names-them) covers `local_c`. For step 4, see [Why reverse engineering uses hex](primers/01-numbers-and-data.md#why-reverse-engineering-uses-hex). The Day 3 primer's [Loops: for and while](primers/06-control-flow.md#loops-for-and-while) helps with the stretch goal.

**If it doesn't match.**

- A multiplication by a small constant may compile to shifts and an add or subtract. The decompiler usually shows a single `*` again.
- If your keygen fails only on longer names, mask to 32 bits with `& 0xFFFFFFFF` after each step.
- The program reads the serial in hex, so print your keygen's result in hex, without `0x`.

#### Another example: a shift-and-XOR checksum

This checksum is not `ex2`'s algorithm, but it has the same parts: a start value, a loop over the name, and a final step.

```c
unsigned int checksum(const char *s) {
    unsigned int h = 0;
    for (int i = 0; s[i]; i++)
        h = (h << 3) ^ (s[i] * (i + 1));
    return h + 0xBEEF;
}
```

The loop body at `-O0`, with `h` at `[rbp-0x4]` and `i` at `[rbp-0x8]` (offsets vary):

```
lea   ecx, [rax*8]                   ; h << 3, done with LEA
...                                  ; load s[i] (movzx, then movsx eax, al)
imul  eax, edx                       ; s[i] * (i + 1)
xor   eax, ecx                       ; ^ (h << 3)
mov   dword ptr [rbp-0x4], eax       ; store h
add   dword ptr [rbp-0x8], 0x1       ; i++
```

After retyping and renaming, the decompiler shows something close to:

```c
uint checksum(char *name)
{
  uint h;
  int i;

  h = 0;
  for (i = 0; name[i] != '\0'; i = i + 1) {
    h = (int)name[i] * (i + 1) ^ h * 8;
  }
  return h + 0xbeef;
}
```

`h * 8` is the source's `h << 3`; Ghidra picks one form. In C, `*` binds tighter than `^`, so read it as `(name[i] * (i + 1)) ^ (h * 8)`. The reverser's notes become a keygen almost line for line:

```python
def checksum(name: str) -> int:
    h = 0                                         # start value
    for i, c in enumerate(name.encode()):         # i from 0
        h = ((h << 3) ^ (c * (i + 1))) & 0xFFFFFFFF
    return (h + 0xBEEF) & 0xFFFFFFFF              # final step
```

**Background:** [Sub-registers](primers/02-registers-and-flags.md#sub-registers) covers EAX, AL and the `movsx` family. [The core instructions](primers/03-reading-assembly.md#the-core-instructions) shows `lea` doing arithmetic.

## Module 2: x64dbg fundamentals (1 h 50 min)

x64dbg runs the program and lets you pause it at any instruction (dynamic analysis). Ghidra tells you what the code could do; x64dbg shows what it actually does with real values.

### 2A. Tour (50 min)

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

**Why it matters.** Most debugging is this loop: find code, set a breakpoint, run, read the state, step. The argument registers at a `call` often explain a function faster than its code.

**What you should see.**

- Addresses are long, such as `00007FF6A1B21500`. The low digits match Ghidra's offsets; the high digits are the random base.
- x64dbg writes hex without `0x`, in lower case, and says `je`/`jne` where Ghidra says `JZ`/`JNZ`. They are the same instructions.
- The Registers pane shows full 64-bit registers. For an `int`, read only the low 8 hex digits.

**Reading the dump.** Each line shows an address, 16 bytes in hex, and the same bytes as text on the right. Text is easy to spot on the right; numbers are stored little-endian, so reverse a value's bytes to read it.

**Background:**

- Registers pane: [The 16 general-purpose registers](primers/02-registers-and-flags.md#the-16-general-purpose-registers), [RIP, the instruction pointer](primers/02-registers-and-flags.md#rip-the-instruction-pointer), [RFLAGS](primers/02-registers-and-flags.md#rflags).
- Step 5: [The Windows x64 calling convention](primers/05-stack-and-calls.md#the-windows-x64-calling-convention), [Volatile and non-volatile registers](primers/05-stack-and-calls.md#volatile-and-non-volatile-registers).
- Stack pane: [Call and ret](primers/05-stack-and-calls.md#call-and-ret).
- Dump: [Little-endian byte order](primers/01-numbers-and-data.md#little-endian-byte-order), [Text in a dump](primers/01-numbers-and-data.md#text-in-a-dump).

**If it doesn't match.**

- If F7 takes you into a DLL such as `ntdll.dll`, press Ctrl+F9 to run to its end, then F8 to return. Use F8 on calls you don't need to see inside.
- If the program seems frozen, it is probably waiting for input in its own console window, which may be behind x64dbg.

### Exercise 2.1: Watch the password check in ex1 (20 min)

1. Use String references to find "Access denied." and jump to it.
2. Scroll up to the `call` to `strcmp` and press F2 on it.
3. Press F9, then type a wrong password in the program's console window.
4. When it pauses, follow RCX and RDX in the dump. One is your input; the other is the real password.
5. Press F8 to step over the call and read the result in RAX. Step to the conditional jump just after it, flip ZF, and press F9. Check that you see "Access granted!" with the wrong password.

**Why it matters.** Data a program hides on disk must sit in memory, readable, when it is used. The debugger shows it to you.

**What you should see.**

- The two pointers look different. Your input is on the stack, at a low address such as `000000xxxxxxxxxx`. The password is in `.rdata`, near the module's base.
- In the dump, both are readable text in the right-hand column, each ending with a `00` byte.
- After F8, EAX is nonzero for a wrong password, often 1 or `FFFFFFFF` (-1). Only zero means equal.

**Background:** [Day 1: flipping ZF to take the other branch](primers/02-registers-and-flags.md#day-1-flipping-zf-to-take-the-other-branch) walks through step 5. [Signed and unsigned numbers](primers/01-numbers-and-data.md#signed-and-unsigned-numbers) explains why -1 shows as `FFFFFFFF`.

**If it doesn't match.**

- Flip ZF while paused on the jump itself. If you flip it on the `test`, running the `test` resets it.
- If RCX doesn't point at text, you are past the `call`. RCX and RDX are volatile, so restart and stop exactly on the `call`.

#### Another example: three arguments at a call

Pause the door-code checker from Exercise 1.1's extra example on its `call memcmp`, with the input "swordfiss". You would see something like:

```
RCX = 000000000061FDF0   dump: 73 77 6F 72 64 66 69 73 73 00   swordfiss.
RDX = 00007FF7E5C1A000   dump: 73 77 6F 72 64 66 69 73 68 00   swordfish.
R8  = 0000000000000009   a count, not a pointer
```

Your note: "arg1 = my input (stack), arg2 = secret (`.rdata`), arg3 = 9 = length". Following R8 in the dump would show nothing useful. Small values like this are usually counts or sizes.

### Exercise 2.2: Fish a valid serial from ex2 (20 min)

1. Find the call to `make_serial`, the function you renamed in Exercise 1.2, by searching for its strings.
2. Set a breakpoint on the instruction right after that call.
3. Run it, enter your name and any serial.
4. Read RAX when it stops. That is the correct serial for your name, in hex. Run the program again without the debugger and check it, then compare it with what your keygen prints.

**Why it matters.** Sometimes you only need an algorithm's output, not its details. Letting the program compute the answer is called serial fishing, and it is a quick way to test a keygen.

**What you should see.** The breakpoint stops on the instruction that uses the result, usually a `mov` from EAX. RAX's top 8 hex digits are zero, because the function returns a 32-bit value and writing EAX clears the top half.

**Background:** [Writing a piece: what happens to the rest](primers/02-registers-and-flags.md#writing-a-piece-what-happens-to-the-rest) explains the zeroed top half.

**If it doesn't match.**

- With the breakpoint on the `call` itself, RAX holds an old value. Press F8 once.
- If your keygen and RAX disagree, trust RAX. Look for a missing mask, a wrong start value, or a constant read in decimal instead of hex.

### Exercise 2.3: Line up the addresses in both tools (20 min)

1. In x64dbg, open the Symbols tab and note the base address of `ex2.exe`.
2. In Ghidra, open Window → Memory Map, click the house icon (Set Image Base), and enter that base.
3. Pick an instruction in `make_serial` in Ghidra, press Ctrl+G in x64dbg, and go to the same address. Check that it's the same instruction.
4. Without changing the base: offset = Ghidra address − `0x140000000`, and the x64dbg address = base + offset. Work out one address this way and check it.

Restart the program and the base changes. Redo step 2 or use the offset method.

**Why it matters.** You will switch tools all day: Ghidra to read and name, x64dbg to test. Address mapping saves searching for strings at every switch.

**What you should see.** After step 2, every Ghidra address changes to match x64dbg, and your renames and comments stay on the right instructions.

**Another conversion.** Ghidra shows `0x140001A7C`, and the base is `00007FF7E5C10000`. The offset is `0x1A7C`, so x64dbg shows `00007FF7E5C11A7C`. In reverse, x64dbg's `00007FF7E5C1162B` is offset `0x162B`, which is `0x14000162B` in Ghidra.

**Background:** [ASLR: why x64dbg's addresses differ](primers/04-memory-layout.md#aslr-why-x64dbgs-addresses-differ) works through the sum. [In x64dbg](primers/04-memory-layout.md#in-x64dbg) describes the Memory Map and Symbols tabs.

**If it doesn't match.**

- Use the base of `ex2.exe`, not of `ntdll.dll` or `kernel32.dll`. A base always ends in `0000`; one ending in `1000` is the start of `.text`.
- If the instructions differ, check that both tools have the same `.exe`. A rebuild with `make` makes a new file.

## Module 3: Capstone, solving and patching ex3 (1 h 20 min)

In `ex3.exe`, searching for strings won't turn up the key, and the program refuses to run under a debugger. You will use Ghidra to understand it, x64dbg to get past its defenses, and then save a patched copy that accepts any key.

Real protections follow the same pattern on a larger scale: hide the data, detect the analyst, and decide with one branch. You beat each layer with a technique you practiced this morning.

### Part A: Static analysis in Ghidra (25 min)

1. Import and analyze `ex3.exe`. In the Symbol Tree, open Imports and note anything unusual. Which API suggests anti-debugging?
2. Search Defined Strings for the key. You won't find it. Find `main` from "Bad license key." instead.
3. In `main`, find the debugger check and the branch that leads to "Debugger detected. Bye."
4. Find the function called just before `strcmp` and rename it `decode`. Work out what it does to each byte and where it reads the bytes from.
5. Double-click the source array to see its bytes, then decode them by hand or with a few lines of Python. That gives you the key with static analysis alone.

**Why it matters.** Hidden strings are the most common anti-analysis trick. Read the decoder once and you can decode everything it protects, without running the program.

**What you should see.**

- In the Listing, the debugger check is a `CALL RAX` after a `MOV` from the IAT. The decompiler shows a plain call to `IsDebuggerPresent`.
- `decode` takes a pointer to a buffer in `main`'s frame and a number. Its loop reads a byte from a global array, changes it, and writes it to the buffer.
- The source array is in `.rdata`, labeled `DAT_` plus its address, shown as bytes rather than text.

**Background:** [XOR](primers/01-numbers-and-data.md#xor) covers the operation and how to undo it. [Imports and the IAT](primers/04-memory-layout.md#imports-and-the-iat) explains the `CALL RAX`.

**If it doesn't match.**

- The byte count is not stored with the array; it is the loop's bound. Find where the bound is set, often an argument passed in EDX.
- If your decoded key ends in odd characters, you decoded too many bytes. Stop at the loop's bound.

#### Another example: an in-place XOR decoder that stops at zero

This decoder is shaped differently from `ex3`'s. It changes the buffer in place, walks it with a pointer, and stops at the first zero byte instead of after a count.

```c
static unsigned char msg[] = { 0x12, 0x3F, 0x36, 0x36, 0x35, 0x7B, 0x00 };

static void unhide(unsigned char *p) {
    while (*p) {
        *p ^= 0x5A;
        p++;
    }
}
```

The loop body at `-O0` (offsets vary):

```
mov   rax, qword ptr [rbp+0x10]      ; p
movzx eax, byte ptr [rax]            ; load *p
xor   eax, 0x5a                      ; the key
mov   edx, eax
mov   rax, qword ptr [rbp+0x10]
mov   byte ptr [rax], dl             ; store it back in place
add   qword ptr [rbp+0x10], 0x1      ; p++
```

The reverser's notes and decode:

```
unhide(p): each byte until 0 ^= 0x5A, in place; msg is in .data (writable)
```

```python
data = bytes([0x12, 0x3F, 0x36, 0x36, 0x35, 0x7B])
print(bytes(b ^ 0x5A for b in data))   # b'Hello!'
```

The array is in `.data`, not `.rdata`, because the program writes to it. For any XOR decoder you need the same three facts: where the bytes are, the key, and how many bytes.

**Background:** [Where each kind of variable lives](primers/04-memory-layout.md#where-each-kind-of-variable-lives) explains `.data` versus `.rdata`.

### Part B: Dynamic analysis in x64dbg (25 min)

1. Open `ex3.exe` in x64dbg and press F9 until it exits. Confirm that it prints "Debugger detected."
2. Restart it (Ctrl+F2). Find the call to `IsDebuggerPresent` in `main` (line up the addresses as in Exercise 2.3, or search for the "Debugger detected" string). Break on the instruction just after the call and set RAX to `0`.
3. Set a breakpoint on the `strcmp` call, run it, and enter any key.
4. When it stops, follow RCX and RDX in the dump. The decoded key is sitting in memory. Check that it matches what you got in Part A.

x64dbg can also hide itself from this check: Debug → Advanced → Hide debugger (PEB). Try it after you have done the bypass by hand.

**Why it matters.** An anti-debugging check is just code with an answer in a register; find it and you control the answer.

**What you should see.** RAX is 1 just after the `IsDebuggerPresent` call. After you set it to 0, the `test` sets ZF and the jump skips the exit. At step 4 the key is in a stack buffer, not `.rdata`, because it only exists after `decode` runs.

**Background:** [cmp, test and conditional jumps](primers/02-registers-and-flags.md#cmp-test-and-conditional-jumps) shows how a return value becomes a branch. [Day 1: flipping ZF to take the other branch](primers/02-registers-and-flags.md#day-1-flipping-zf-to-take-the-other-branch) ends with this exact RAX trick.

**If it doesn't match.** If you set RAX before the call runs, the call overwrites it. Set it while paused on the instruction after the call.

### Part C: Patch the program (30 min)

1. Find the conditional jump after the `IsDebuggerPresent` call and work out where it goes. Then apply the rule below: select it, press Space and rewrite it so the program never reaches "Debugger detected", whether or not a debugger is attached.
2. Do the same for the jump after `strcmp`, so the program always reaches "License OK. Welcome!" Check where that jump goes too; the two jumps don't need the same fix.
3. Save it with File → Patch file (Ctrl+P) → Patch File, as `ex3_patched.exe`. Never overwrite the original.
4. Close x64dbg, run `ex3_patched.exe` normally and enter any key. It should accept it.

**Deliverable:** a half-page write-up covering the key, how the key is hidden, how the debugger check works, the two addresses you patched (as offsets from the image base), and what each patch changed.

**Why it matters.** A flag flip lasts one run; a patch lasts. Patching also tests a theory: if one changed jump changes the behavior, you found the decision.

**Choosing NOP or jmp.** First ask where you want execution to go. If the path you want is the fall-through, NOP the jump. If the path you want is the jump's target, make it an unconditional `jmp`.

**What you should see.** Before saving, the Patch dialog lists every changed byte with its old and new value. The saved copy runs without x64dbg and accepts any key.

**Background:** [cmp, test and conditional jumps](primers/02-registers-and-flags.md#cmp-test-and-conditional-jumps) defines falling through. Question 8 in [Reading assembly's Check yourself](primers/03-reading-assembly.md#check-yourself) patches a jump the same way.

#### Another example: patching the door-code checker

The first jump in Exercise 1.1's extra example, with its bytes (offsets from the function start):

```
18:  48 83 f8 09     cmp  rax, 0x9
1c:  74 07           je   0x25          ; length ok: go to the compare
1e:  b8 00 00 00 00  mov  eax, 0x0      ; length wrong: return 0
23:  eb 29           jmp  <end>
```

The path you want is the target, `0x25`. NOPing `74 07` would always fall into `return 0`. Changing `74` (`je`) to `EB` (`jmp`) keeps the size and always skips the failure; the `memcmp` check needs the same fix.

Short jumps are 2 bytes: `74` is `je`, `75` is `jne` and `EB` is `jmp`; `90` is `nop`. Longer jumps start with `0F 84`, `0F 85` or `E9`.

**If it doesn't match.**

- If the patched copy always prints "Debugger detected", that patch sent execution the wrong way. Check where the original jump went, then apply the rule above.
- For the write-up, subtract the base from each x64dbg address. The offsets then match Ghidra's addresses minus `0x140000000`.

## Beyond this lesson

These optional challenges go past the day's exercises and get harder in turn. They are outside the 7 hours. Hints and expected results are in [lab/solutions/day1/extra-credit.md](../lab/solutions/day1/extra-credit.md), which contains spoilers.

Never edit the files in `lab/day1`. For challenges that change a program, copy the source to a scratch folder and build the copy from the Devkit shell:

```bash
mkdir -p ~/scratch && cp day1/ex2_serial.c ~/scratch/
cd ~/scratch
gcc -O0 -s ex2_serial.c -o ex2_mine.exe
```

### 1. Two ways to break ex1 (★)

**Goal:** make two patched copies of `ex1.exe`. In one, NOP the jump after `strcmp`; in the other, reverse it (`jne` to `je`, or the other way round).

**Hand in:** both files, and a table of what each prints for the right password and two wrong ones. Explain the difference in one sentence.

### 2. Let short names into ex2 (★)

**Goal:** `ex2.exe` refuses names shorter than 4 characters. Find that check in Ghidra, patch it in x64dbg so a 2-character name passes, and save the copy.

**Hand in:** the offset of the check and the instruction before and after your patch. Add a serial for the name `ab` from your keygen, accepted by your patched copy.

### 3. Catch the key as it is written (★★)

**Goal:** get `ex3`'s key in x64dbg without a breakpoint on `strcmp`. Stop on the call to `decode`, note where its output buffer is, step over the call, and read the buffer in the dump.

**Hand in:** the buffer's offset from RBP, taken from the instruction that loads it, and the buffer's dump line before and after `decode` runs.

### 4. Swap serial algorithms (★★)

**Goal:** copy `ex2_serial.c` to your scratch folder and change the start value, the multiplier and the final XOR to values of your choice. Build it as `ex2_mine.exe` and give only the `.exe` to a partner.

**Hand in:** a keygen for your partner's program, written from Ghidra alone, that works on three names they pick. Your partner checks it against their source.

### 5. Make ex3 tell you its key (★★★)

**Goal:** patch a copy of `ex3.exe` so that a wrong key prints the real key instead of "Bad license key.". Change only the instruction that loads the message for `puts`.

**Hand in:** the patched file, the instruction's original and new text and bytes, and a run of the patched copy outside the debugger.

### 6. Write a crackme for a partner (★★★)

**Goal:** write a small C program that checks a password with two of today's ideas, such as a length check and an XOR-hidden secret. Build it with `gcc -O0 -s` and swap `.exe` files with a partner. Keep it benign: no file, network or registry access.

**Hand in:** your partner's secret, a half-page write-up of how you found it, and the offsets of anything you patched.

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
| 3C | Patch the jumps, not the calls. Ask where each jump goes | The jump after `IsDebuggerPresent` (`je`/`jz`) skips the "Debugger detected" exit, so its target is the path you want: change it to an unconditional `jmp`. NOPing it, or reversing it, sends every run into the exit. The jump after `strcmp` (`jne`/`jnz`) leads to "Bad license key", so NOP it. Saving with Patch File keeps the original intact |

A keygen for Exercise 1.2 (also in [lab/solutions/day1/keygen_ex2.py](../lab/solutions/day1/keygen_ex2.py)):

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

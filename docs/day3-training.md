# Day 3: Control Flow and Data

## Overview

Day 3 follows Day 2's work on optimized code and the stack. Today you learn to recognize the shapes C control flow takes in machine code: a `switch` compiled to a jump table, the three kinds of loop, a function that calls itself, and data that lives in global variables. You will practice on four small programs, and you will solve one of them from the Listing alone with the decompiler closed.

**Goals for the day**

1. Recognize a jump table in the Listing, and read the cases Ghidra recovers from it.
2. Tell a `for`, a `while` and a `do`-`while` loop apart by where their condition sits.
3. Follow a recursive function and work out what it computes.
4. Find global variables, tables of pointers and strings, and see which code uses them.
5. Read a short function from its assembly without the decompiler.
6. Use x64dbg's conditional breakpoints, its command line and its graph view to stop exactly where you need.

**What you need**

- The portable kit, as on Day 1: Ghidra, x64dbg and the w64devkit toolchain with `make`.
- The course repo. Today's programs are in `lab/day3`.
- Day 1's skills: strings and references, renaming, breakpoints and stepping. Day 2's work on stack frames helps with Module 3.

**Before you start**

Read [How C control flow compiles](primers/06-control-flow.md): if-else, the three loop shapes, switch and jump tables, and recursion. Refresh the jump table in [Registers and flags](primers/02-registers-and-flags.md) and where globals live in [A program in memory](primers/04-memory-layout.md).

**Lab rules**

- Work in your VM, and take a snapshot before you start.
- Only analyze the practice programs in this guide.
- Keep notes: every address you find, what it does, and how you found it.

## Schedule

The day runs about 7 hours with breaks, and roughly half of it is hands-on exercise time.

| Time | Block | What you do |
| --- | --- | --- |
| 0:00–0:20 | Module 0: Setup | Snapshot the VM, compile the four practice programs |
| 0:20–1:00 | Module 1A: Switches and jump tables | How a `switch` compiles, switch recovery, bookmarks, Listing fields |
| 1:00–2:00 | Exercise 1.1–1.3 | Map the menu in `ex1`; open the vault with a conditional breakpoint |
| 2:00–2:15 | Break |  |
| 2:15–2:45 | Module 2A: Loop shapes | `for`, `while` and `do`-`while` in assembly; the x64dbg command line |
| 2:45–3:45 | Exercise 2.1–2.2 | Find the three loops in `ex2`; read the door code at runtime |
| 3:45–4:30 | Lunch |  |
| 4:30–5:30 | Module 3: Recursion | Solve `ex3` from the Listing alone; Function Call Trees |
| 5:30–6:30 | Module 4: Global data and strings | Recover the passphrase table in `ex4` |
| 6:30–6:50 | Review | Go over the answer key and write up your notes |
| 6:50–7:00 | Wrap-up | Update your references and the plan for Day 4 |

## Module 0: Build the practice programs (20 min)

Today's four programs each hide one answer. Their sources are in the repo's `lab/day3` folder and linked below. As on Day 1, don't read the source until you have finished with the tools.

[**ex1\_vault.c**](../lab/day3/ex1_vault.c): a menu driven by a `switch`; the right sequence of options opens the vault

[**ex2\_loops.c**](../lab/day3/ex2_loops.c): a door code built and checked by three different loops

[**ex3\_tower.c**](../lab/day3/ex3_tower.c): a level number checked with a recursive function

[**ex4\_phrase.c**](../lab/day3/ex4_phrase.c): a passphrase made of words from a global table

**Compile** with `make`. Open `RE-Portable\Devkit.cmd`; its shell starts in the repo's `lab` folder. Then run:

```bash
make day3     # builds bin/day3/ex1.exe to ex4.exe
```

The executables go into `bin/day3`. They are built like Day 1's: `-O0` and `-s`, so the code is close to the source and the function names are gone.

Run each `.exe` in `bin/day3` once with a wrong answer. `ex1` reads one option per line; type `0` to quit it. `ex4` gives you three tries.

## Module 1: Switches and jump tables (1 h 40 min)

A `switch` with only a few cases compiles to a chain of compares and jumps. With many cases close together, the compiler builds a jump table instead. It is an array with one entry per case value, and one indirect `jmp` uses the value to pick an entry.

### 1A. How a switch looks (40 min)

1. **The range check.** Before the table, the code compares the value with the highest case and jumps to the default case if it's larger. It uses an unsigned jump (`ja`), so negative values also go to the default.
2. **The table lookup.** The code loads the table's address, reads the entry for the value, and jumps through a register, for example `jmp rax`. You can't follow that jump by reading one instruction; you need the table.
3. **Switch recovery.** Ghidra's analysis finds the table and works out every target. In the Listing it labels the indirect jump `switchD`, and each target `caseD_1`, `caseD_2` and so on. The decompiler then shows an ordinary `switch` statement.
4. **When recovery fails.** If the decompiler shows a warning that it could not recover the jump table, the cases are missing. Note the address and read the table by hand from the Listing.
5. **Bookmarks.** Press Ctrl+D on any address to add a bookmark with a short note. Window → Bookmarks lists them all, and double-clicking one takes you back. Use them for places you will return to.
6. **Listing fields.** The Listing is built from fields: address, bytes, mnemonic, operands, comments, references. Click the Edit the Listing fields button at the top of the Listing to show the field header. Right-click a field there to turn it off, for example the Bytes field. Edit → Tool Options → Listing Fields holds each field's settings. For example, XREFs Field → Maximum Number of XREFs to Display sets how many references are listed before Ghidra says "more".

### Exercise 1.1: Map the menu in ex1 (25 min)

1. Import and analyze `ex1.exe`. Find `main` from the "Unknown option." string.
2. In the Listing, find the compare against the highest case and the indirect `jmp`. Write down the highest case value.
3. Look at the decompiler's `switch`. For each case, write down what it prints and what it does to the global variable it reads and writes. Rename that global `stage`.
4. Add a bookmark at each `caseD_` label with what the case does, such as "4: pull lever, 0 → 1".
5. Turn off the Bytes field so the Listing has room for the operands, and raise the XREFs limit to 10.

**Write down:** the order of options that takes `stage` from 0 to the value that opens the vault.

### Exercise 1.2: Read the jump table itself (15 min)

1. Double-click the table's address in the instruction that loads it. You land on the table data, labeled `switchdataD`.
2. Count its entries. Check the count against the range check from Exercise 1.1, plus one for case 0.
3. Pick the entry for case 7. Find which `caseD_` label it leads to, and confirm it's the code that opens the vault.

### Exercise 1.3: Stop on one option in x64dbg (20 min)

1. Open `ex1.exe` in x64dbg and press F9 to reach the entry point. Find `main` from the "Unknown option." string reference.
2. Press `G` in the disassembly to switch to graph view. Find the block with the indirect jump; the case blocks fan out from it. Press `G` again to go back.
3. Set a breakpoint with F2 on the compare against the highest case. Open the Breakpoints tab, right-click your breakpoint → Edit, and set Break Condition to `eax == 7`. If your build compares a stack variable instead of EAX, read the operand and use it, for example `[rbp-0x14] == 7`.
4. Press F9 and enter options. The program only stops when you choose 7.
5. When it stops, step with F8 through the indirect jump and see which case it lands on. Then enter your sequence from Exercise 1.1 and check that the vault opens.

## Module 2: Loop shapes (1 h 30 min)

At `-O0`, GCC lays out every loop in one of two shapes. Learn both and you can spot loops without the decompiler.

### 2A. Three loops, two shapes (30 min)

1. **`for` and `while`.** The code jumps forward to the condition first. The body sits above the condition, and a conditional jump at the bottom goes back up to the body. A `for` loop also sets its counter before the first jump, and changes it just before the condition.
2. **`do`-`while`.** There is no jump to the condition first. The body runs once, then the condition at the bottom jumps back up. That missing first jump is how you tell them apart.
3. **Conditions with `&&`.** A loop condition such as `i < 8 && a[i] == b[i]` becomes two compares in a row. Either one can leave the loop.
4. **Division by a constant.** Compilers turn `x / 10` and `x % 10` into a multiply by a "magic" constant and a shift. They do it even at `-O0`. `0xCCCCCCCD` means divide by 10. The decompiler usually turns these back into `/` and `%`.
5. **The x64dbg command line.** The Command box at the bottom of x64dbg runs commands and works out expressions. Type a register or a sum like `rsp+0x20` and press Enter to see its value in the Log tab. `[rsp+0x20]` reads the 8 bytes at that address, and `byte:[rcx]` reads one byte. `bp address` sets a breakpoint, and `bpcnd address, condition` gives it a condition. `dump address` shows that address in the dump.

### Exercise 2.1: Find the three loops in ex2 (35 min)

1. Import and analyze `ex2.exe`. Find `main` from "Wrong code.", then the function `main` calls with your input. Rename it `check`.
2. In the Listing, find each backward jump in `check`. Each one closes a loop. Bookmark each loop's first instruction.
3. For each loop, decide whether it is a `for`, a `while` or a `do`-`while`. Use the rule from 2A: is there a jump forward to the condition before the body?
4. Open the Function Graph and check your answer: a loop is a block with an arrow back to an earlier block.
5. Use the decompiler to work out what each loop does: one builds an array of digits, one rearranges it, one compares it with your input.

**Write down:** each loop's address, its kind, and what it does.

### Exercise 2.2: Read the door code at runtime (25 min)

1. Open `ex2.exe` in x64dbg. Go to `check` using the offset method from Day 1.
2. Find the compare inside the last loop, the one that compares one byte of your input with one byte of the expected code. Set a breakpoint on it with the condition that the two bytes differ, for example `dl != al`.
3. Run it and enter `12345678`. When it stops, the expected digit is in one of the two registers. Use the command line to read the whole expected array: find its stack offset in the Listing and type `dump` with that address, for example `dump rbp-0x11`.
4. Read the eight digits from the dump, restart and enter them. Check that the door unlocks.

**Stretch goal:** work out the code with static analysis alone from the first two loops, using a few lines of Python.

## Module 3: Recursion (1 h)

A recursive function calls itself. In the Listing that is a `call` whose target is the start of the function it is in. Each call gets its own stack frame, which you met on Day 2.

### Exercise 3.1: Solve ex3 from the Listing alone (35 min)

Close the Decompiler window before you start (Window → Decompiler opens it again later). Use only the Listing and your notes.

1. Import and analyze `ex3.exe`. Find `main` from "Not this level." in Defined Strings.
2. In `main`, find the range check on your input and write down the two limits.
3. Find the `call` that takes your number, and the compare after it. Write down the constant the result is compared with, in hex and decimal.
4. Follow the call. Rename the function `weave`. Find the instruction that tests the argument at the start, and the value it returns in that case.
5. Find the two calls `weave` makes to itself. For each one, work out which argument it passes. Then find how their results are combined with the argument to make the return value.
6. Write `weave` as three lines of C. Write a few lines of Python that compute it for 1 to 30 and print the level that matches the constant.
7. Open the decompiler again and compare its version with yours.

**Write down:** your C for `weave`, the constant, and the level.

### Exercise 3.2: See the recursion in both tools (25 min)

1. In Ghidra, put the cursor in `weave` and open Window → Function Call Trees. Look at Incoming Calls and Outgoing Calls. `weave` shows up inside its own outgoing calls, and you can keep expanding it.
2. Open the Function Call Trees for `main` too. Note which library functions it calls.
3. In x64dbg, open `ex3.exe` and set a breakpoint on the first instruction of `weave`. Edit it and set Break Condition to `ecx == 1`.
4. Run it and enter `5`. Each time it stops, RCX holds 1, and the arguments of the calls still waiting are on the stack. Press Ctrl+F9 and read RAX to see what `weave(1)` returns.
5. Clear the condition and press F9 a few times. Watch RCX change as the calls go deeper and come back.

**Stretch goal:** set the condition to `0` so the breakpoint never stops. Run with level 10 and read the hit count in the Breakpoints tab. Explain the number.

## Module 4: Global data and strings (1 h)

Globals live in the program's data sections, not on the stack. Initialized globals go in `.data`, constants and string literals in `.rdata`, and zeroed globals in `.bss`. In the Listing, code reaches them with an address relative to RIP, such as `[rip+0x2e85]`, and Ghidra shows the target as a `DAT_` label.

### Exercise 4.1: Recover the passphrase table in ex4 (35 min)

1. Import and analyze `ex4.exe`. In Defined Strings, find the eight words that look like a word list. Find `main` from "Passphrase accepted.".
2. Open Function Call Trees for `main` and list the functions it calls. Rename them as you work out what each does. One changes your input, one splits it, one compares a single word.
3. In the function that compares one word, find the two globals it reads. One is a table of pointers to the words, the other a table of small numbers.
4. Go to the pointer table. Press `P` on the first entry to make it a pointer, then `[` to make an array of eight. Rename it `words`.
5. Go to the table of numbers, make it an array of four integers, and rename it `order`.
6. Find the other globals `main` uses. One counts something down; one is the buffer your input is read into. Note which section each is in from the Memory Map.

**Write down:** the passphrase, the character that separates its words, and whether case matters.

### Exercise 4.2: Read the globals at runtime (25 min)

1. Open `ex4.exe` in x64dbg and find the `strcmp` call in the word-compare function.
2. Set a breakpoint on it and run. Enter `aaa-bbb-ccc-ddd`.
3. When it stops, follow RCX and RDX in the dump. One is the current word from your input, the other the word it must match.
4. Use the command line to read the tables directly. Work out the address of `words` from Ghidra and the image base. Then type expressions such as `[address+8*5]` to get the pointer for entry 5, and `dump` that pointer.
5. Enter the passphrase you found and check that it is accepted.

## Answer key and hints

Try each exercise for at least 15 minutes before you look here. Addresses depend on your compiler, so they're left out. The checks CI runs are in [lab/solutions/day3/checks.psd1](../lab/solutions/day3/checks.psd1), and [lab/solutions/day3/solve\_day3.py](../lab/solutions/day3/solve_day3.py) computes the answers for `ex2` and `ex3`.

| Exercise | Hint | Answer |
| --- | --- | --- |
| 1.1 | Each case either moves `stage` on by one or sets it back to 0 | Highest case 9. Option 4 takes `stage` 0 → 1, then 1 takes it to 2, 6 to 3 and 3 to 4. Option 7 opens the vault when `stage` is 4. Options 2, 5 and 9 reset it; 8 only prints a hint |
| 1.1 answer | Enter one option per line | `4`, `1`, `6`, `3`, `7` |
| 1.2 | The table has one entry for each value from 0 to the highest case | 10 entries, for cases 0 to 9; values outside that range go to the default |
| 1.3 | The condition is checked on every hit, but x64dbg only stops when it is true | It stops only on option 7, and the indirect jump lands on case 7 |
| 2.1 | Look for a jump forward just before each loop body | First loop: `for`, builds 8 digits. Second: `do`-`while`, swaps them end to end. Third: `while`, compares them with your input |
| 2.1 detail | `0x65` is 101 | `x` starts at `0x2A`; each step is `x = (x*37 + 11) % 101`, and the digit is `x % 10`. That gives `03798311`, reversed to `11389730` |
| 2.2 | Break when the bytes differ, not when they match | The door code is `11389730` |
| 3.1 | The test at the start checks for `n < 2` | `weave(n)` is `n + 2` for `n < 2`, else `weave(n-1) + weave(n-2) + n`. The constant is `0xA4B5` (42165), and the level is `19` |
| 3.2 | Count the calls for small levels first: level 1 makes 1 call, level 2 makes 3 | Calls for level `n` = calls for `n-1` + calls for `n-2` + 1, so level 10 makes 177 calls |
| 4.1 | The order table holds indexes into the word table | `order` is {5, 2, 7, 0}, so the passphrase is `meadow-falcon-tundra-amber`. Words are separated by `-`. Case doesn't matter, because the input is made lower case first |
| 4.1 globals | Check each `DAT_` address against the Memory Map | The word table, `order` and the try counter (starts at 3) are in `.data`; the input buffer is in `.bss`; the words themselves are in `.rdata` |
| 4.2 | Each table entry is 8 bytes, because it is a pointer | RDX holds the expected word, `meadow` for the first one |

## Day 4

Add today's features to your notes: switch recovery, bookmarks, Listing fields and Function Call Trees in Ghidra; conditional breakpoints, the command line and graph view in x64dbg. The [Ghidra reference](ghidra-reference.md) and [x64dbg reference](x64dbg-reference.md) list them all.

**Day 4 preview:** an inventory program built from structs, arrays of structs and a linked list. You will recover the structs with Ghidra's Data Type Manager and Structure Editor, and share the types between programs. In x64dbg you will follow them through the dump and the Watch view.

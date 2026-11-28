# Day 3: Control Flow and Data

## Overview

Day 3 follows Day 2's work on optimized code and the stack. Today you learn to recognize the shapes C control flow takes in machine code: a `switch` compiled to a jump table, the three kinds of loop, a function that calls itself, and data that lives in global variables. You also meet two kinds of data that Windows programs use everywhere: wide (UTF-16) text and command-line arguments.

You will practice on five small programs, and you will solve one of them from the Listing alone with the decompiler closed. The day ends with a checkpoint: a sixth program you solve without its source.

Why shapes? The decompiler's output is a guess, and sometimes a wrong one. If you can see "a loop that runs at least once" in the raw Listing, you can check the guess and work without it.

**Goals for the day**

1. Recognize a jump table in the Listing, and read the cases Ghidra recovers from it.
2. Tell a `for`, a `while` and a `do`-`while` loop apart by where their condition sits.
3. Follow a recursive function and work out what it computes.
4. Find global variables, tables of pointers and strings, and see which code uses them.
5. Read a short function from its assembly without the decompiler.
6. Use x64dbg's conditional breakpoints, its command line and its graph view to stop exactly where you need.
7. Read UTF-16 strings in both tools, and tell the A and W versions of a Windows function apart.
8. Find where a program's command-line arguments arrive, and run it with arguments in x64dbg.
9. Solve an unseen program on your own and write it up.

**What you need**

- The portable kit, as on Day 1: Ghidra, x64dbg and the w64devkit toolchain with `make`.
- The course repo. Today's programs are in `lab/day3`.
- Day 1's skills: strings and references, renaming, breakpoints and stepping. Day 2's work on stack frames helps with Module 3.

**Before you start**

Read [How C control flow compiles](primers/06-control-flow.md): if-else, the three loop shapes, switch and jump tables, and recursion. Refresh the jump table in [Registers and flags](primers/02-registers-and-flags.md) and where globals live in [A program in memory](primers/04-memory-layout.md).

For Module 5, read [Wide text (UTF-16)](primers/01-numbers-and-data.md#wide-text-utf-16) and [The command line and environment](primers/04-memory-layout.md#the-command-line-and-environment). For the checkpoint, have the method from [Day 0's primer](primers/00-approach.md) and a copy of the [analysis notes template](templates/analysis-notes.md) ready.

Each module below also links to the exact primer section it builds on, at the point where you need it. If a step stops making sense, follow that link first.

**How to read the worked examples**

The worked examples are not exercise programs. Each shows C, the pseudo-code a reverser would write, and real MinGW GCC `-O0` output, trimmed, with labels such as `.Lbody` for addresses. Your build may use other registers and offsets, or `add rsp` and `pop rbp` where these show `leave`; see the primer's [notes on the examples](primers/06-control-flow.md#how-to-read-the-examples).

**Lab rules**

- Work in your VM, and take a snapshot before you start.
- Only analyze the practice programs in this guide.
- Keep notes: every address you find, what it does, and how you found it.

## Schedule

The day runs about 7.5 hours with breaks, and more than half of it is hands-on exercise time.

| Time | Block | What you do |
| --- | --- | --- |
| 0:00–0:15 | Module 0: Setup | Snapshot the VM, compile the practice programs |
| 0:15–0:55 | Module 1A: Switches and jump tables | How a `switch` compiles, switch recovery, bookmarks, Listing fields |
| 0:55–1:55 | Exercise 1.1–1.3 | Map the menu in `ex1`; open the vault with a conditional breakpoint |
| 1:55–2:10 | Break |  |
| 2:10–2:40 | Module 2A: Loop shapes | `for`, `while` and `do`-`while` in assembly; the x64dbg command line |
| 2:40–3:40 | Exercise 2.1–2.2 | Find the three loops in `ex2`; read the door code at runtime |
| 3:40–4:25 | Lunch |  |
| 4:25–5:05 | Module 3: Recursion | Solve `ex3` from the Listing alone |
| 5:05–5:45 | Module 4: Global data and strings | Recover the passphrase table in `ex4`; Function Call Trees |
| 5:45–6:30 | Module 5: Wide text and the command line | UTF-16 strings, A and W functions, `argv`; solve `ex5` with arguments |
| 6:30–7:15 | Checkpoint | Solve `checkpoint.exe` without its source and write it up |
| 7:15–7:25 | Review | Go over the answer key and compare your checkpoint notes with the model write-up |
| 7:25–7:30 | Wrap-up | Update your references and the plan for Day 4 |

The worked examples are part of each module's teaching time; read them, don't type them in. The challenges in [Beyond this lesson](#beyond-this-lesson) are extra credit, outside the 7.5 hours.

## Module 0: Build the practice programs (15 min)

Today's five programs each hide one answer. Their sources are in the repo's `lab/day3` folder and linked below. As on Day 1, don't read the source until you have finished with the tools.

[**ex1\_vault.c**](../lab/day3/ex1_vault.c): a menu driven by a `switch`; the right sequence of options opens the vault

[**ex2\_loops.c**](../lab/day3/ex2_loops.c): a door code built and checked by three different loops

[**ex3\_tower.c**](../lab/day3/ex3_tower.c): a level number checked with a recursive function

[**ex4\_phrase.c**](../lab/day3/ex4_phrase.c): a passphrase made of words from a global table

[**ex5\_wide.c**](../lab/day3/ex5_wide.c): a badge reader that takes a name and a code on its command line, as wide strings

The build also makes `checkpoint.exe`, the program for the [Checkpoint](#checkpoint). Its source is with the spoilers, so don't look for it, and don't open the program until then.

**Compile** with `make`. Open `RE-Portable\Devkit.cmd`; its shell starts in the repo's `lab` folder. Then run:

```bash
make day3     # builds bin/day3/ex1.exe to ex5.exe, and checkpoint.exe
```

The executables go into `bin/day3`. They are built like Day 1's: `-O0` and `-s`, so the code is close to the source and the function names are gone. `ex5` also gets `-municode`, which Module 5 explains.

Run `ex1` to `ex4` in `bin/day3` once with a wrong answer. `ex1` reads one option per line; type `0` to quit it. `ex4` gives you three tries.

`ex5` reads nothing from the keyboard: run it once with no arguments, and once as `bin/day3/ex5.exe alice 1234`.

Write down what each program prints on a wrong answer: every exercise starts by finding `main` from one of those messages.

## Module 1: Switches and jump tables (1 h 40 min)

A `switch` with only a few cases compiles to a chain of compares and jumps. With many cases close together, the compiler builds a jump table instead. It is an array with one entry per case value, and one indirect `jmp` uses the value to pick an entry.

Menus, command parsers and protocol handlers are built on `switch`. Find the table and you have every command the program understands. Miss it, and whole branches look like dead code.

### Before the switch: if-else and inverted conditions

A compare chain is just a run of if-else blocks, so start there. At `-O0`, GCC jumps around each body, so every conditional jump tests the opposite of the C condition. The primer's [if](primers/06-control-flow.md#if) and [if-else](primers/06-control-flow.md#if-else) sections show the basic shapes. The jump names and the flags they read are in [cmp, test and conditional jumps](primers/02-registers-and-flags.md#cmp-test-and-conditional-jumps).

#### Worked example: an else-if ladder

```c
int classify(int temp) {
    int kind;
    if (temp < 10)       kind = 0;
    else if (temp <= 25) kind = 1;
    else                 kind = 2;
    return kind;
}
```

```text
classify(temp):            temp is signed (jg)
    temp <= 9   -> kind = 0
    temp <= 25  -> kind = 1
    otherwise   -> kind = 2
    return kind
```

```nasm
classify:
    push rbp
    mov  rbp, rsp
    sub  rsp, 0x10
    mov  dword ptr [rbp+0x10], ecx    ; save temp in its home slot
    cmp  dword ptr [rbp+0x10], 9      ; "temp < 10" became "temp > 9?"
    jg   .Lnot_cold                   ; inverted: skip the first body
    mov  dword ptr [rbp-0x4], 0       ; kind = 0
    jmp  .Lend                        ; jump over the other two bodies
.Lnot_cold:
    cmp  dword ptr [rbp+0x10], 0x19   ; temp <= 25 ?
    jg   .Lhot                        ; inverted again
    mov  dword ptr [rbp-0x4], 1       ; kind = 1
    jmp  .Lend
.Lhot:
    mov  dword ptr [rbp-0x4], 2       ; kind = 2
.Lend:
    mov  eax, dword ptr [rbp-0x4]     ; return kind
    leave
    ret
```

GCC rewrote `temp < 10` as `temp > 9` and jumped on it, so read every condition backwards. Each body ends with a `jmp` to the same `.Lend`: the mark of an else-if ladder. `jg` rather than `ja` says `temp` is signed; see [Signed and unsigned numbers](primers/01-numbers-and-data.md#signed-and-unsigned-numbers).

### 1A. How a switch looks (40 min)

Read the primer's [switch: a chain of compares](primers/06-control-flow.md#switch-a-chain-of-compares) and [switch: a jump table](primers/06-control-flow.md#switch-a-jump-table) alongside this section.

1. **The range check.** Before the table, the code compares the value with the highest case and jumps to the default case if it's larger. It uses an unsigned jump (`ja`), so negative values also go to the default.
2. **The table lookup.** The code loads the table's address, reads the entry for the value, and jumps through a register, for example `jmp rax`. You can't follow that jump by reading one instruction; you need the table.
3. **Switch recovery.** Ghidra's analysis finds the table and works out every target. In the Listing it labels the indirect jump `switchD`, and each target `caseD_1`, `caseD_2` and so on. The decompiler then shows an ordinary `switch` statement.
4. **When recovery fails.** If the decompiler shows a warning that it could not recover the jump table, the cases are missing. Note the address and read the table by hand from the Listing.
5. **Bookmarks.** Press Ctrl+D on any address to add a bookmark with a short note. Window → Bookmarks lists them all, and double-clicking one takes you back. Use them for places you will return to.
6. **Listing fields.** The Listing is built from fields: address, bytes, mnemonic, operands, comments, references. Click the Edit the Listing fields button at the top of the Listing to show the field header. Right-click a field there to turn it off, for example the Bytes field. Edit → Tool Options → Listing Fields holds each field's settings. For example, XREFs Field → Maximum Number of XREFs to Display sets how many references are listed before Ghidra says "more".

**Why `ja`.** Read as unsigned, -1 is `0xFFFFFFFF`, above any case value, so one `ja` rejects both "too big" and "negative". The flags behind it are in [RFLAGS](primers/02-registers-and-flags.md#rflags).

**Reading a table by hand.** MinGW stores each entry as a 4-byte offset from the start of the table, not a full address. The table sits in `.rdata`, after the code, so the offsets are negative and show as large hex values such as `0xFFFFD4A0`. Target = table address + entry, with the entry read as a signed number.

**When recovery fails, recover it yourself.** Write down the table's address, the number of entries (the range-check constant plus one) and each 4-byte entry. Add each entry to the table's address and go to the result with `G`. If Ghidra shows undefined bytes there instead of instructions, disassemble them (press `D`) and check that the code looks like a case body. Bookmark each target with its case value so the work isn't lost.

**Common mistakes.** The range-check constant is the highest index, not the number of entries: add one for index 0. If a `sub` comes first, add its constant back to get the case values. Assuming every value below the maximum has its own code is also wrong: missing case values get table entries that point to `default`. When two cases share a body, two entries hold the same offset.

#### Worked example: a sparse switch stays a compare chain

```c
const char *status_text(int code) {
    switch (code) {
    case 200: return "OK";
    case 301: return "Moved";
    case 404: return "Not found";
    case 500: return "Server error";
    default:  return "Unknown";
    }
}
```

```text
status_text(code):                  signed compares (jg)
    500 -> "Server error"    404 -> "Not found"
    200 -> "OK"              301 -> "Moved"
    anything else -> "Unknown"
```

```nasm
status_text:
    push rbp
    mov  rbp, rsp
    mov  dword ptr [rbp+0x10], ecx
    cmp  dword ptr [rbp+0x10], 0x1f4  ; 500
    je   .Lcase500
    cmp  dword ptr [rbp+0x10], 0x1f4
    jg   .Ldefault                    ; above 500: no case left
    cmp  dword ptr [rbp+0x10], 0x194  ; 404
    je   .Lcase404
    cmp  dword ptr [rbp+0x10], 0x194
    jg   .Ldefault                    ; between 405 and 499
    cmp  dword ptr [rbp+0x10], 0xc8   ; 200
    je   .Lcase200
    cmp  dword ptr [rbp+0x10], 0x12d  ; 301
    je   .Lcase301
    jmp  .Ldefault
.Lcase200:
    lea  rax, [rip+...]               ; "OK"
    jmp  .Lend
    ...                               ; one block per case, each ending jmp .Lend
.Ldefault:
    lea  rax, [rip+...]               ; "Unknown"
.Lend:
    pop  rbp
    ret
```

A table for 200 to 500 would need 301 entries for four cases, so GCC compares instead. It also splits the chain with `jg` into a small search tree, so the compares don't come in case order. Note each `je` target and its constant; the `jg` lines only narrow the search. Ghidra shows the constants in hex, so right-click them to see decimal.

#### Worked example: a jump table that doesn't start at 0

```c
int cost(int room) {
    switch (room) {
    case 101: return 40;    case 102: return 45;
    case 103: return 40;    case 104: return 60;
    case 105: return 75;    case 106: return 45;
    default:  return -1;
    }
}
```

```text
cost(room):
    i = room - 101                     unsigned compare: room < 101 wraps to huge
    if i > 5 -> return -1
    return [40, 45, 40, 60, 75, 45][i] (one case block per entry)
```

```nasm
    mov  dword ptr [rbp+0x10], ecx
    mov  eax, dword ptr [rbp+0x10]
    sub  eax, 0x65                    ; room - 101: the lowest case becomes index 0
    cmp  eax, 5                       ; range check: indexes 0 to 5
    ja   .Ldefault                    ; also catches room < 101
    mov  eax, eax                     ; clear the top half of RAX
    lea  rdx, [rax*4]                 ; 4 bytes per entry
    lea  rax, [rip+.Ltable]
    mov  eax, dword ptr [rdx+rax]     ; read the entry: an offset
    cdqe                              ; sign-extend it
    lea  rdx, [rip+.Ltable]
    add  rax, rdx                     ; target = table + offset
    jmp  rax
```

The `sub` before the range check shifts the cases down so the table starts at index 0. Add it back when you name the cases: index 3 is case 104. Ghidra does this for you in its `caseD_` labels. When the lowest case is small, such as 1, GCC may skip the `sub` and point entry 0 at `default` instead.

### Exercise 1.1: Map the menu in ex1 (25 min)

Map what every option does. On a real target, this is how you find hidden commands that the help text never mentions.

1. Import and analyze `ex1.exe`. Find `main` from the "Unknown option." string.
2. In the Listing, find the compare against the highest case and the indirect `jmp`. Write down the highest case value.
3. Look at the decompiler's `switch`. For each case, write down what it prints and what it does to the global variable it reads and writes. Rename that global `stage`.
4. Add a bookmark at each `caseD_` label with what the case does, such as "4: pull lever, 0 → 1".
5. Turn off the Bytes field so the Listing has room for the operands, and raise the XREFs limit to 10.

**Write down:** the order of options that takes `stage` from 0 to the value that opens the vault.

**What you should see.** The `default` block prints "Unknown option.", so its reference lands among the cases, not at the top of `main`. Scroll up to find the input call and the compare. The global shows up as a `DAT_` name until you rename it.

**If you get stuck.** Treat `stage` as a state machine: draw a box for each value and an arrow for each option that changes it. The order of options falls out of the drawing. The state machine example in Module 4 shows the same idea in assembly.

### Exercise 1.2: Read the jump table itself (15 min)

1. Double-click the table's address in the instruction that loads it. You land on the table data, labeled `switchdataD`.
2. Count its entries. Check the count against the range check from Exercise 1.1, plus one for case 0.
3. Pick the entry for case 7. Find which `caseD_` label it leads to, and confirm it's the code that opens the vault.

For step 3, use the sum from "Reading a table by hand" and compare the result with Ghidra's `caseD_` label. If they disagree, read the entry again as a signed 4-byte value; [Little-endian byte order](primers/01-numbers-and-data.md#little-endian-byte-order) explains why its bytes look reversed.

### Exercise 1.3: Stop on one option in x64dbg (20 min)

A breakpoint in a busy loop is useless if you press F9 a hundred times. A conditional breakpoint stops only on the pass you care about.

1. Open `ex1.exe` in x64dbg and press F9 to reach the entry point. Find `main` from the "Unknown option." string reference.
2. Press `G` in the disassembly to switch to graph view. Find the block with the indirect jump; the case blocks fan out from it. Press `G` again to go back.
3. Set a breakpoint with F2 on the compare against the highest case. Open the Breakpoints tab, right-click your breakpoint → Edit, and set Break Condition to `eax == 7`. If your build compares a stack variable instead of EAX, read the operand and use it, for example `[rbp-0x14] == 7`.
4. Press F9 and enter options. The program only stops when you choose 7.
5. When it stops, step with F8 through the indirect jump and see which case it lands on. Then enter your sequence from Exercise 1.1 and check that the vault opens.

**What you should see.** In graph view the indirect jump's block has many arrows leaving it, one per distinct case target. A compare chain would look like a staircase instead. x64dbg's addresses differ from Ghidra's because of ASLR; [ASLR: why x64dbg's addresses differ](primers/04-memory-layout.md#aslr-why-x64dbgs-addresses-differ) shows the offset sum.

**If it never stops.** Check that the breakpoint sits on the `cmp` itself, after the value has been loaded. Check that the condition names the same register or memory operand as the `cmp`. Numbers in x64dbg expressions are hex, which doesn't matter for 7 but does for 10 and up.

## Module 2: Loop shapes (1 h 30 min)

At `-O0`, GCC lays out every loop in one of two shapes. Learn both and you can spot loops without the decompiler.

Loops do the real work: decoding, hashing, comparing. Knowing where the condition is tested tells you how often the body runs, including zero times.

### 2A. Three loops, two shapes (30 min)

Background: [Loops: for and while](primers/06-control-flow.md#loops-for-and-while), [Loops: do-while](primers/06-control-flow.md#loops-do-while), [break and continue](primers/06-control-flow.md#break-and-continue) and [&& and ||](primers/06-control-flow.md#-and-).

1. **`for` and `while`.** The code jumps forward to the condition first. The body sits above the condition, and a conditional jump at the bottom goes back up to the body. A `for` loop also sets its counter before the first jump, and changes it just before the condition.
2. **`do`-`while`.** There is no jump to the condition first. The body runs once, then the condition at the bottom jumps back up. That missing first jump is how you tell them apart.
3. **Conditions with `&&`.** A loop condition such as `i < 8 && a[i] == b[i]` becomes two compares in a row. Either one can leave the loop.
4. **Division by a constant.** Compilers turn `x / 10` and `x % 10` into a multiply by a "magic" constant and a shift. They do it even at `-O0`. `0xCCCCCCCD` means divide by 10. The decompiler usually turns these back into `/` and `%`.
5. **The x64dbg command line.** The Command box at the bottom of x64dbg runs commands and works out expressions. Type a register or a sum like `rsp+0x20` and press Enter to see its value in the Log tab. `[rsp+0x20]` reads the 8 bytes at that address, and `byte:[rcx]` reads one byte. `bp address` sets a breakpoint, and `bpcnd address, condition` gives it a condition. `dump address` shows that address in the dump.

**The one rule.** A conditional jump to a lower address closes a loop; that jump is the back edge. Find every back edge first, then look at the instruction just before the loop's first block. A `jmp` forward to the test means `for` or `while`; no such jump means `do`-`while`.

**Mistaking a do-while for a while.** The decompiler sometimes writes a `do`-`while` as `while (true) { ...; if (!cond) break; }`, or the other way round. Trust the Listing: the question is only whether the body can run zero times. At `-O2`, GCC often turns a `while` into a test before the loop plus a `do`-`while`. The primer's [What -O2 changes](primers/06-control-flow.md#what--o2-changes) lists this as "reshaped loops".

**Magic division, more generally.** `0xCCCCCCCD` followed by a shift of 32 + 3 is `/ 10`. Some divisors, such as 7, need a longer sequence: a multiply, a subtract, a shift, an add and another shift. When you see a large odd constant feeding `imul` and `shr`, suspect a division and let the decompiler confirm it.

#### Worked example: a for loop with break

```c
int first_negative(const int *a, int n) {
    int i;
    for (i = 0; i < n; i++)
        if (a[i] < 0)
            break;
    return i;
}
```

```text
first_negative(a, n):          a is int*, n is int (signed compares)
    i = 0
    while i < n:
        if a[i] < 0: leave loop    (break)
        i++
    return i                   n if no negative was found
```

```nasm
    mov  dword ptr [rbp-0x4], 0       ; i = 0
    jmp  .Lcond                       ; for: go to the test first
.Lbody:
    mov  eax, dword ptr [rbp-0x4]
    cdqe                              ; widen i to 64 bits
    lea  rdx, [rax*4]                 ; i * sizeof(int)
    mov  rax, qword ptr [rbp+0x10]    ; a
    add  rax, rdx
    mov  eax, dword ptr [rax]         ; a[i]
    test eax, eax
    js   .Lafter                      ; sign flag set: a[i] < 0, break
    add  dword ptr [rbp-0x4], 1       ; i++
.Lcond:
    mov  eax, dword ptr [rbp-0x4]
    cmp  eax, dword ptr [rbp+0x18]    ; i < n ?
    jl   .Lbody                       ; yes: back edge
.Lafter:
    mov  eax, dword ptr [rbp-0x4]     ; return i
```

The loop has two exits: the back edge falling through, and the `js` from the middle of the body. A forward jump out of the body to the code after the loop is a `break` (or a `return`). `test eax, eax` followed by `js` is GCC's way of asking "is it negative?" without a `cmp`. In real output the `break` may land on a `nop` just before `.Lafter`; it is the same place.

#### Worked example: nested loops

```c
int count_pairs(const int *a, int n, int target) {
    int count = 0;
    for (int i = 0; i < n; i++)
        for (int j = i + 1; j < n; j++)
            if (a[i] + a[j] == target)
                count++;
    return count;
}
```

```text
count_pairs(a, n, target):
    count = 0
    for i in 0 .. n-1:
        for j in i+1 .. n-1:
            if a[i] + a[j] == target: count++
    return count
```

```nasm
    mov  dword ptr [rbp-0x4], 0       ; count = 0
    mov  dword ptr [rbp-0x8], 0       ; i = 0
    jmp  .Lcond_i                     ; outer loop: test first
.Lbody_i:
    mov  eax, dword ptr [rbp-0x8]
    add  eax, 1
    mov  dword ptr [rbp-0xc], eax     ; j = i + 1
    jmp  .Lcond_j                     ; inner loop: test first
.Lbody_j:
    ...                               ; edx = a[i], eax = a[j]
    add  eax, edx
    cmp  dword ptr [rbp+0x20], eax    ; target == a[i] + a[j] ?
    jne  .Lnext_j                     ; inverted: skip count++
    add  dword ptr [rbp-0x4], 1       ; count++
.Lnext_j:
    add  dword ptr [rbp-0xc], 1       ; j++
.Lcond_j:
    mov  eax, dword ptr [rbp-0xc]
    cmp  eax, dword ptr [rbp+0x18]    ; j < n ?
    jl   .Lbody_j                     ; inner back edge
    add  dword ptr [rbp-0x8], 1       ; i++
.Lcond_i:
    mov  eax, dword ptr [rbp-0x8]
    cmp  eax, dword ptr [rbp+0x18]    ; i < n ?
    jl   .Lbody_i                     ; outer back edge
```

There are two back edges, and the inner loop's whole shape sits inside the outer loop's body. Match each back edge with its counter: the one whose counter is reset inside the other loop is the inner one. The third argument arrived in R8 and was saved at `[rbp+0x20]`; see [The Windows x64 calling convention](primers/05-stack-and-calls.md#the-windows-x64-calling-convention).

#### Worked example: a do-while that counts digits

```c
int count_digits(unsigned int x) {
    int d = 0;
    do {
        d++;
        x /= 10;
    } while (x != 0);
    return d;
}
```

```text
count_digits(x):               x is unsigned (shr, not sar)
    d = 0
    repeat:
        d++
        x = x / 10
    until x == 0
    return d                   count_digits(0) is 1, not 0
```

```nasm
    mov  dword ptr [rbp-0x4], 0       ; d = 0
.Lbody:                               ; no jmp before the body: do-while
    add  dword ptr [rbp-0x4], 1       ; d++
    mov  eax, dword ptr [rbp+0x10]    ; x
    mov  edx, eax
    mov  eax, 0xcccccccd              ; the magic number for / 10
    imul rax, rdx
    shr  rax, 0x20                    ; keep the high 32 bits ...
    shr  eax, 3                       ; ... and shift 3 more: x / 10
    mov  dword ptr [rbp+0x10], eax    ; x = x / 10
    cmp  dword ptr [rbp+0x10], 0
    jne  .Lbody                       ; while (x != 0): back edge
```

The body starts right after the setup, with no `jmp` past it. That matters: with `x = 0` the body still runs once and the function returns 1. A `while` version would return 0. When the exact count matters, as in a key check, this one jump is the difference between right and wrong.

### Exercise 2.1: Find the three loops in ex2 (35 min)

1. Import and analyze `ex2.exe`. Find `main` from "Wrong code.", then the function `main` calls with your input. Rename it `check`.
2. In the Listing, find each backward jump in `check`. Each one closes a loop. Bookmark each loop's first instruction.
3. For each loop, decide whether it is a `for`, a `while` or a `do`-`while`. Use the rule from 2A: is there a jump forward to the condition before the body?
4. Open the Function Graph and check your answer: a loop is a block with an arrow back to an earlier block.
5. Use the decompiler to work out what each loop does: one builds an array of digits, one rearranges it, one compares it with your input.

**Write down:** each loop's address, its kind, and what it does.

**What you should see.** `check` is short, and the three loops follow one another rather than nesting. The array they share is a local: an offset from RBP plus an index, such as `[rbp+rax-0x20]`. [Memory operands](primers/03-reading-assembly.md#memory-operands) explains the form. Expect a long run of `imul`, `shr` and `sub` in one loop: that is division by constants, item 4 of 2A.

**If you get stuck.** Decide each loop's kind from the Listing before you look at the decompiler, then compare. Where they disagree, the Listing wins. A loop whose test has two exits fits item 3 of 2A.

### Exercise 2.2: Read the door code at runtime (25 min)

1. Open `ex2.exe` in x64dbg. Go to `check` using the offset method from Day 1.
2. Find the compare inside the last loop, the one that compares one byte of your input with one byte of the expected code. Set a breakpoint on it with the condition that the two bytes differ, for example `dl != al`.
3. Run it and enter `12345678`. When it stops, the expected digit is in one of the two registers. Use the command line to read the whole expected array: find its stack offset in the Listing and type `dump` with that address, for example `dump rbp-0x11`.
4. Read the eight digits from the dump, restart and enter them. Check that the door unlocks.

**Stretch goal:** work out the code with static analysis alone from the first two loops, using a few lines of Python.

**Why this works.** The program builds the expected code in memory before comparing. "Let it compute, then read" often beats reversing the maths.

**What you should see.** The digits are ASCII: bytes `0x30` to `0x39`, shown as digits in the text column. See [Text in a dump](primers/01-numbers-and-data.md#text-in-a-dump). If the dump shows something else, your offset is wrong: check it against the `lea` or `movzx` that reads the array in the Listing. A condition on `dl` and `al` compares single bytes, which is right here because the array is `char`.

## Module 3: Recursion (40 min)

A recursive function calls itself. In the Listing that is a `call` whose target is the start of the function it is in. Each call gets its own stack frame, which you met on Day 2.

Recursion turns up in parsers, tree and directory walkers, sorting, and puzzle checks. It is easy to read once you separate the two jobs: the **base case** that stops, and the **recursive case** that combines smaller answers. Read the primer's [Recursion](primers/06-control-flow.md#recursion) and, for frames, [Stack frames](primers/05-stack-and-calls.md#stack-frames).

#### Worked example: a recursive tree walk

```c
struct node { int value; struct node *left; struct node *right; };

int depth(const struct node *t) {
    if (t == NULL)
        return 0;
    int l = depth(t->left);
    int r = depth(t->right);
    return 1 + (l > r ? l : r);
}
```

```text
depth(t):                      t points to a struct; fields at +8 and +0x10 are pointers
    if t == NULL: return 0     base case
    l = depth([t+8])           first self-call
    r = depth([t+0x10])        second self-call
    return 1 + max(l, r)
```

```nasm
depth:
    push rbp
    mov  rbp, rsp
    sub  rsp, 0x30                    ; locals l and r, plus shadow space for the calls
    mov  qword ptr [rbp+0x10], rcx    ; save t in its home slot
    cmp  qword ptr [rbp+0x10], 0      ; base case: t == NULL ?
    jne  .Lrecurse
    mov  eax, 0                       ; return 0
    jmp  .Lend
.Lrecurse:
    mov  rax, qword ptr [rbp+0x10]
    mov  rax, qword ptr [rax+8]       ; t->left
    mov  rcx, rax
    call depth                        ; first call to itself
    mov  dword ptr [rbp-0x4], eax     ; l: saved before the next call can overwrite EAX
    mov  rax, qword ptr [rbp+0x10]
    mov  rax, qword ptr [rax+0x10]    ; t->right
    mov  rcx, rax
    call depth                        ; second call to itself
    mov  dword ptr [rbp-0x8], eax     ; r
    mov  edx, dword ptr [rbp-0x8]
    mov  eax, dword ptr [rbp-0x4]
    cmp  edx, eax
    cmovge eax, edx                   ; eax = the larger of l and r, without a jump
    add  eax, 1
.Lend:
    leave
    ret
```

Read it in three passes. First, find the test that returns without calling: the base case. Second, for each `call depth`, see what goes into RCX. Third, see where each result is stored and how they are combined.

Two details catch people out. The first result is saved in a local because the second call would overwrite EAX; see [Function calls and return values](primers/06-control-flow.md#function-calls-and-return-values). And `cmovge` picks a value without jumping, so a `max` can hide in one instruction even at `-O0`.

**Losing track in recursion.** Don't try to follow the calls in your head. Write the call tree on paper for a tiny input, one line per call, indented by depth:

```text
depth(A)            A has children B and C; B and C have none
  depth(B)
    depth(NULL) -> 0
    depth(NULL) -> 0
  -> 1
  depth(C)
    depth(NULL) -> 0
    depth(NULL) -> 0
  -> 1
-> 2
```

In x64dbg, the Call Stack tab shows one line per call still waiting. Each frame has its own `[rbp+0x10]`, holding its own argument. When lost, press Ctrl+F9 until you are back in a frame you recognize.

### Exercise 3.1: Solve ex3 from the Listing alone (35 min)

Close the Decompiler window before you start (Window → Decompiler opens it again later). Use only the Listing and your notes.

Obfuscated code or an unusual compiler can leave you with no useful decompiler output. This exercise builds the habit of reading the Listing first.

1. Import and analyze `ex3.exe`. Find `main` from "Not this level." in Defined Strings.
2. In `main`, find the range check on your input and write down the two limits.
3. Find the `call` that takes your number, and the compare after it. Write down the constant the result is compared with, in hex and decimal.
4. Follow the call. Rename the function `weave`. Find the instruction that tests the argument at the start, and the value it returns in that case.
5. Find the two calls `weave` makes to itself. For each one, work out which argument it passes. Then find how their results are combined with the argument to make the return value.
6. Write `weave` as three lines of C. Write a few lines of Python that compute it for 1 to 30 and print the level that matches the constant.
7. Open the decompiler again and compare its version with yours.

**Write down:** your C for `weave`, the constant, and the level.

**What you should see.** The range check in step 2 is two compares, one per limit, in the shape of an `||`; see the primer's [&& and ||](primers/06-control-flow.md#-and-). `weave` returns a 64-bit value, so look for RAX rather than EAX, and `add rax, ...` when the results are combined. Signed or unsigned compares (`jle` versus `jbe`) tell you how the argument is typed.

**If you get stuck.** Follow the three passes from the tree walk example. Annotate each instruction with `;` as you go: "arg n", "first result", and so on. Then check your C by hand for the two smallest inputs, comparing it with what the Listing would return for them.

## Module 4: Global data and strings (40 min)

Globals live in the program's data sections, not on the stack. Initialized globals go in `.data`, constants and string literals in `.rdata`, and zeroed globals in `.bss`. In the Listing, code reaches them with an address relative to RIP, such as `[rip+0x2e85]`, and Ghidra shows the target as a `DAT_` label.

Globals hold what a program remembers between calls: settings, counters, state and tables. A global's cross-references list every function that reads or changes it. Background: [Sections](primers/04-memory-layout.md#sections), [Where each kind of variable lives](primers/04-memory-layout.md#where-each-kind-of-variable-lives), [RIP-relative addressing](primers/03-reading-assembly.md#rip-relative-addressing) and [C strings and arrays of strings](primers/07-data-in-memory.md#c-strings-and-arrays-of-strings).

#### Worked example: a state machine driven by a global

```c
enum { IDLE, RUNNING, DONE };
static int state;          /* starts at 0: .bss */
static int retries = 3;    /* has a value: .data */

int pump(int event) {
    switch (state) {
    case IDLE:
        if (event == 1) state = RUNNING;
        break;
    case RUNNING:
        if (event == 2) state = DONE;
        else if (event == 3 && --retries == 0) state = DONE;
        break;
    }
    return state;
}
```

```text
globals: G1 (.bss, starts 0), G2 (.data, starts 3)
pump(event):
    G1 == 0:  event 1 -> G1 = 1
    G1 == 1:  event 2 -> G1 = 2
              event 3 -> G2--, and if G2 == 0 -> G1 = 2
    return G1
states: 0 --1--> 1 --2--> 2     (or three 3s from 1 -> 2)
```

```nasm
pump:
    push rbp
    mov  rbp, rsp
    mov  dword ptr [rbp+0x10], ecx    ; event
    mov  eax, dword ptr [rip+state]   ; Ghidra: [DAT_...] in .bss
    test eax, eax
    je   .Lidle                       ; case IDLE (0)
    cmp  eax, 1
    je   .Lrunning                    ; case RUNNING (1)
    jmp  .Lend                        ; any other state: nothing to do
.Lidle:
    cmp  dword ptr [rbp+0x10], 1      ; event == 1 ?
    jne  .Lend
    mov  dword ptr [rip+state], 1     ; state = RUNNING
    jmp  .Lend
.Lrunning:
    cmp  dword ptr [rbp+0x10], 2
    jne  .Lnot2
    mov  dword ptr [rip+state], 2     ; state = DONE
    jmp  .Lend
.Lnot2:
    cmp  dword ptr [rbp+0x10], 3
    jne  .Lend
    mov  eax, dword ptr [rip+retries] ; --retries: load, subtract, store
    sub  eax, 1
    mov  dword ptr [rip+retries], eax
    mov  eax, dword ptr [rip+retries]
    test eax, eax
    jne  .Lend
    mov  dword ptr [rip+state], 2     ; out of retries: DONE
.Lend:
    mov  eax, dword ptr [rip+state]   ; return state
    pop  rbp
    ret
```

The switch on `state` has two cases, so it is a short compare chain, not a table. Every access to a global is RIP-relative, so it has no RBP in it; that is how you tell a global from a local at a glance. Draw the states as boxes and the writes as arrows, as in the pseudo-code. The same kind of drawing helps in Exercise 1.1.

**String handling in the Listing.** String loops read one byte at a time with `movzx eax, byte ptr [...]` and stop on `test al, al`, the zero terminator. A pointer that is advanced with `add qword ptr [...], 1` walks the string itself. Calls such as `strcmp`, `strtok` and `tolower` keep their names in a stripped program, because they are imports. A table of strings is an array of pointers, read with a scale of 8, such as `qword ptr [rdx+rax*8]`.

#### Worked example: a string loop

```c
int count_char(const char *s, char c) {
    int n = 0;
    while (*s) {
        if (*s == c) n++;
        s++;
    }
    return n;
}
```

```text
count_char(s, c):              s is char*, c is a byte
    n = 0
    while byte [s] != 0:
        if byte [s] == c: n++
        s = s + 1
    return n
```

```nasm
    mov  dword ptr [rbp-0x4], 0       ; n = 0
    jmp  .Lcond                       ; while: test first
.Lbody:
    mov  rax, qword ptr [rbp+0x10]    ; s
    movzx eax, byte ptr [rax]         ; *s
    cmp  byte ptr [rbp+0x18], al      ; c == *s ?
    jne  .Lskip
    add  dword ptr [rbp-0x4], 1       ; n++
.Lskip:
    add  qword ptr [rbp+0x10], 1      ; s++: the pointer itself moves
.Lcond:
    mov  rax, qword ptr [rbp+0x10]
    movzx eax, byte ptr [rax]         ; *s
    test al, al                       ; the terminator?
    jne  .Lbody                       ; no: back edge
```

The `char` argument arrived in DL and was saved as a single byte at `[rbp+0x18]`. The loop has no counter at all; the pointer is the counter. The decompiler may show it as a `for` or a `while`; both are right.

### Exercise 4.1: Recover the passphrase table in ex4 (35 min)

1. Import and analyze `ex4.exe`. In Defined Strings, find the eight words that look like a word list. Find `main` from "Passphrase accepted.".
2. With the cursor in `main`, open Window → Function Call Trees. It shows Incoming Calls (who calls `main`) and Outgoing Calls (what `main` calls). List the functions it calls. Rename them as you work out what each does. One changes your input, one splits it, one compares a single word.
3. In the function that compares one word, find the two globals it reads. One is a table of pointers to the words, the other a table of small numbers.
4. Go to the pointer table. Press `P` on the first entry to make it a pointer, then `[` to make an array of eight. Rename it `words`.
5. Go to the table of numbers, make it an array of four integers, and rename it `order`.
6. Find the other globals `main` uses. One counts something down; one is the buffer your input is read into. Note which section each is in from the Memory Map.

**Write down:** the passphrase, the character that separates its words, and whether case matters.

**What you should see.** In the compare function, one table is read with a scale of 4 and the other with a scale of 8. The scale tells you which is which. When one table read feeds the address of another, read the expression from the inside out.

**Common mistakes.** The order of the words in Defined Strings is the order they are stored, not the order of the passphrase. Another trap is calling the pointer table a string: before you press `P`, its bytes look like gibberish, because they are little-endian addresses. The Listing's left margin and the Memory Map both tell you a global's section; [In Ghidra](primers/04-memory-layout.md#in-ghidra) lists the clues.

## Module 5: Wide text and the command line (45 min)

So far every program has read its input from the keyboard, as 8-bit text. Real Windows programs often do neither: they keep their text as UTF-16, and they take their options on the command line.

Windows' own functions work in UTF-16, so most Windows code does too. Search such a program for 8-bit strings only and you miss most of its text. Miss its arguments, and a tool that prints nothing when double-clicked looks broken.

### 5A. Wide strings and argv (15 min)

Background: [Wide text (UTF-16)](primers/01-numbers-and-data.md#wide-text-utf-16) and [The command line and environment](primers/04-memory-layout.md#the-command-line-and-environment).

1. **`wchar_t` and `L"..."`.** On Windows, `wchar_t` is 2 bytes and holds one UTF-16 character. A literal with an `L` in front, such as `L"open"`, is a wide string. In a dump, plain English text has a `00` after every letter and ends with `00 00`.
2. **The wide C functions.** `wcslen`, `wcscmp` and `wcscpy` work like `strlen`, `strcmp` and `strcpy`, on `wchar_t`. They are imports from `msvcrt.dll`, so they keep their names in a stripped program.
3. **A and W.** Windows functions that take text come in pairs: `CreateFileA` and `CreateFileW`, `MessageBoxA` and `MessageBoxW`. The W version takes UTF-16 and the A version 8-bit text. Most Windows code calls the W version; Symbol Tree → Imports shows which one a program uses.
4. **Wide strings in Ghidra.** Defined Strings lists them with the data type `unicode`, and shows them as `u"..."`. If one is missing, go to its first byte, press `T` and enter `unicode`.
5. **Wide strings in x64dbg.** The dump's text column shows ASCII by default, so wide text reads `o.p.e.n.`. Right-click the dump and switch the text view to Unicode to read it plainly.
6. **`argc` and `argv`.** `main(int argc, char **argv)` is an ordinary function: `argc` arrives in ECX and `argv` in RDX. `argv[1]` is the pointer at `argv + 8`, `argv[2]` the one at `argv + 0x10`. `argc` counts the program's name too.
7. **`wmain`.** Built with `-municode`, a program starts at `wmain(int argc, wchar_t **argv)`, and each argument is a wide string. Its imports include `__wgetmainargs`, where a `main` program has `__getmainargs`.
8. **Where the command line lives.** Windows keeps the whole command line as one UTF-16 string in the process parameters, which the PEB points to. `GetCommandLineW` returns it. The C runtime splits it into `argv` before `main` runs.
9. **Arguments in x64dbg.** Open the program, and while it waits at the system breakpoint, use File → Change Command Line. Keep the program's path at the start and type the arguments after it. Then press F9.

**Check the command line.** Type `dump [[peb()+0x20]+0x78]` in the Command box. `peb()` is the PEB's address; the primer's table explains the two offsets. The dump then shows the command line the program will split into `argv`.

**Common mistakes.** A wide string handed to `strlen` has length 1, so a check that mixes the two kinds always fails. Arguments are split once, at startup, so changing the command line after `main` has started does nothing. And an `argc` of 3 means two arguments, not three.

#### Worked example: a wide string loop and wmain

```c
int count_wide(const wchar_t *s) {
    int n = 0;
    while (s[n] != 0)
        n++;
    return n;
}

int wmain(int argc, wchar_t **argv) {
    if (argc < 2)
        return 2;
    if (wcscmp(argv[1], L"open") == 0)
        return 0;
    return count_wide(argv[1]);
}
```

```text
count_wide(s):                 s points to 2-byte characters (word ptr, index * 2)
    n = 0
    while word [s + n*2] != 0: n++
    return n                   a character count, like wcslen

wmain(argc, argv):             ECX = argc, RDX = argv
    if argc <= 1 -> return 2   no argument typed
    if wcscmp([argv+8], u"open") == 0 -> return 0
    return count_wide([argv+8])
```

```nasm
count_wide:
    mov  qword ptr [rbp+0x10], rcx    ; s
    mov  dword ptr [rbp-0x4], 0       ; n = 0
    jmp  .Lcond                       ; while: test first
.Lbody:
    add  dword ptr [rbp-0x4], 1       ; n++
.Lcond:
    mov  eax, dword ptr [rbp-0x4]
    cdqe
    lea  rdx, [rax+rax]               ; n * 2: each character is 2 bytes
    mov  rax, qword ptr [rbp+0x10]
    add  rax, rdx
    movzx eax, word ptr [rax]         ; s[n], 2 bytes
    test ax, ax                       ; the 2-byte terminator?
    jne  .Lbody

wmain:
    mov  dword ptr [rbp+0x10], ecx    ; argc
    mov  qword ptr [rbp+0x18], rdx    ; argv
    cmp  dword ptr [rbp+0x10], 1      ; "argc < 2" became "argc > 1?"
    jg   .Lhave_arg
    mov  eax, 2
    jmp  .Lend
.Lhave_arg:
    mov  rax, qword ptr [rbp+0x18]    ; argv
    add  rax, 8
    mov  rax, qword ptr [rax]         ; argv[1]
    lea  rdx, [rip+...]               ; u"open" in .rdata
    mov  rcx, rax
    call wcscmp
    test eax, eax
    jne  .Lcount
    mov  eax, 0                       ; matched: return 0
    jmp  .Lend
.Lcount:
    ...                               ; argv[1] again, then call count_wide
```

This is the string loop from Module 4 with two changes: `word ptr` instead of `byte ptr`, and the index doubled before it is added. Those two details are how you spot wide text in code. The `add rax, 8` followed by a load is `argv[1]`; an `add rax, 0x10` would be `argv[2]`.

### Exercise 5.1: Read the badge check in ex5 (20 min)

1. Import and analyze `ex5.exe`. Open Defined Strings and sort by the Data Type column. Note which strings are wide (`unicode`) and which are plain.
2. Find the function that prints "Unknown name." and rename it `wmain`. Find the compare on `argc` and write down how many arguments it expects.
3. Find where `argv[1]` and `argv[2]` are read. Follow `argv[1]` into the function it is passed to.
4. That function loops over a table of pointers to wide strings. Make it an array (`P`, then `[`) and rename it `staff`. Back in `wmain`, find the second table read with the index it returns, and rename it `clearance`.
5. Find the function that builds the expected code. Work out, for one character, how the code character is made from the name character.
6. In Symbol Tree → Imports, find the Windows function `wmain` calls first, and whether it is the A or the W version. Note the text it passes.

**Write down:** each name that is accepted, its code, and the rule that turns a name into a code.

**What you should see.** The code builder reads with `word ptr` and doubles its index, as in the worked example. `0x4EC4EC4F` with `sar edx, 3` is the magic number for dividing by 26, and the `imul` by `0x1a` and `sub` after it make a `%`. GCC folds constants together, so one `sub` may stand for two steps of the C.

**If you get stuck.** Work out the code for one name on paper, one character at a time. Then check one character against the Listing by following the arithmetic with a real value. The decompiler shows the same rule as one line of C, which is a good check once you have your own.

### Exercise 5.2: Run ex5 with arguments in x64dbg (10 min)

1. Open `ex5.exe` in x64dbg. At the system breakpoint, use File → Change Command Line and add a name you found and the code `AAAAA` after the path.
2. Type `dump [[peb()+0x20]+0x78]` in the Command box. Read the command line in the dump, first as ASCII, then with the text view switched to Unicode.
3. Find `wmain` from the "Wrong code." string reference and set a breakpoint on its first instruction. Press F9 until it stops there. Read ECX, then follow RDX in the dump and then `argv[1]`.
4. Set a breakpoint on the `call` to `wcscmp` in `wmain`, just before "Wrong code.", and press F9. Follow RCX and RDX in the dump: one is your code, the other the expected one.
5. Open the Log tab and find the text from the Windows function of Exercise 5.1, step 6.
6. Set the command line again with the right code, restart and check that the door opens.

**What you should see.** In step 3, RDX points at an array of 8-byte pointers; the first is the program's path. If you picked a name with too little clearance in step 1, `wcscmp` is never reached; pick another. After a restart (Ctrl+F2), check whether x64dbg kept your command line, and set it again if not.

## Checkpoint

You have 45 minutes for one program you haven't seen, with no source and no hints in this guide. It needs only what you used today: a `switch` or loops, wide strings, and command-line arguments. It tells you what you can already do alone, and what to revisit.

**The task.** `bin/day3/checkpoint.exe` takes one command-line argument. Find an argument that makes it print its success message, and explain why it works.

**Rules.**

- Don't read its source or its answer. Both are in `lab/solutions/day3`, for afterwards.
- Use Ghidra, x64dbg and your notes from Days 1 to 3.
- Work with the method from [Day 0's primer](primers/00-approach.md), and record your work in a copy of the [analysis notes template](templates/analysis-notes.md).
- Stop at 45 minutes, finished or not, and write down where you got to.

**Hand in:** the argument, and notes on how you found it. Say where `main` is, what each check on the argument does, and what data it uses and where that lives. Then say how you confirmed the answer by running the program.

When the time is up, compare your notes with the answer and model write-up in [lab/solutions/day3/checkpoint.md](../lab/solutions/day3/checkpoint.md). Where your notes differ, find which module covers the step you missed.

## Beyond this lesson

Extra credit, outside the 7.5 hours. Each challenge uses today's programs or a copy you change and rebuild. Hints and expected results are in [lab/solutions/day3/extra-credit.md](../lab/solutions/day3/extra-credit.md); try each one first.

Put each changed copy in a folder of your own, outside the repo. Build it from the Devkit shell with the Makefile's flags, for example `gcc -O0 -s -Wall ex1_sparse.c -o ex1_sparse.exe`. Never edit the files in `lab/day3`; CI checks them.

### 1. The table that disappears (★)

**Goal:** see the point where GCC stops building a jump table.

Copy `ex1_vault.c` and change only the case labels to values far apart, such as 10, 200 and 3000. Rebuild it and open it in Ghidra. Then make a second copy where only one case moves far away and all the others stay put.

**What to check:** is there still a `switchD` label and an indirect `jmp`? How many compares does the chain use, and in what order? In the second copy, what happens to the one case that moved?

### 2. Moving the word table (★)

**Goal:** see how `const` decides where a global lives.

Copy `ex4_phrase.c` and add `const` so the word table becomes `const char *const words[]` and the order table `const int order[]`. Rebuild it and find both tables again.

**What to check:** compare the section of each table, and of the strings, in the Memory Map of both builds. Does the code that reads them change?

### 3. ex1 at -O2 (★★)

**Goal:** find the jump table in optimized code.

From the `lab` folder, build `gcc -O2 -s -Wall day3/ex1_vault.c -o <your folder>/ex1o2.exe`. Find `main` from its strings and locate the range check, the table and the indirect jump.

**What to check:** which register holds the table's address, and where is it loaded? Does Ghidra still recover the switch, and does it name the same cases? Can you solve the vault from this build alone?

### 4. Recursion versus a loop (★★)

**Goal:** compare a recursive function with the same calculation done in a loop.

Copy `ex3_tower.c` and rewrite `weave` without recursion, using the C you wrote in Exercise 3.1. Rebuild it and check that the same level is still accepted. Then open both builds side by side in Ghidra.

**What to check:** what does Function Call Trees show for each? How many times is the new `weave` called for level 10, compared with the stretch goal of challenge 7? Which loop shape did your version compile to?

### 5. ex2 from x64dbg alone (★★★)

**Goal:** solve `ex2` without opening Ghidra.

Find `check` from string references and map its loops in graph view. Get the door code with conditional breakpoints, the command line and the dump. Set at least one breakpoint with `bpcnd` rather than through the Breakpoints tab.

**What to check:** can you find the expected array before the compare loop starts? Can you get all eight digits in a single run, with one wrong guess?

### 6. Where did the recursion go? (★★★)

**Goal:** see what `-O2` does to a function with two self-calls.

Build `ex3_tower.c` at `-O2` into your own folder. Find `weave` again and count how many `call` instructions in it target `weave` itself.

**What to check:** how many self-calls are left, and what replaced the others? How long is the function compared with the `-O0` build? Does the decompiler's version still look like your three lines of C?

### 7. See the recursion in both tools (★)

**Goal:** watch `ex3`'s recursion from both sides: the call tree in Ghidra and the live calls in x64dbg.

1. In Ghidra, put the cursor in `weave` and open Window → Function Call Trees. Look at Incoming Calls and Outgoing Calls. `weave` shows up inside its own outgoing calls, and you can keep expanding it.
2. Open the Function Call Trees for `main` too. Note which library functions it calls.
3. In x64dbg, open `ex3.exe` and set a breakpoint on the first instruction of `weave`. Edit it and set Break Condition to `ecx == 1`.
4. Run it and enter `5`. Each time it stops, RCX holds 1, and the arguments of the calls still waiting are on the stack. Press Ctrl+F9 and read RAX to see what `weave(1)` returns.
5. Clear the condition and press F9 a few times. Watch RCX change as the calls go deeper and come back.

**Stretch goal:** set the condition to `0` so the breakpoint never stops. Run with level 10 and read the hit count in the Breakpoints tab. Explain the number.

**Why the condition is on ECX.** At the first instruction of `weave`, the prologue has not run yet, so the argument is still in ECX. A few instructions later it has been copied to the home slot and ECX may be reused. Conditions on arguments belong on the function's first instruction.

**What to check:** what does `weave(1)` return, and why does the breakpoint stop more than once? Explain the stretch goal's hit count.

**What you should see.** With level 5, the breakpoint stops several times, because `weave(1)` is reached along more than one path. Open the Call Stack tab at each stop: the number of `weave` lines changes from stop to stop. The stretch goal's count grows fast with the level, which is why recursion like this is slow for large inputs.

### 8. Read ex4's globals at runtime (★)

**Goal:** read `ex4`'s word table from x64dbg's command line while the program runs.

1. Open `ex4.exe` in x64dbg and find the `strcmp` call in the word-compare function.
2. Set a breakpoint on it and run. Enter `aaa-bbb-ccc-ddd`.
3. When it stops, follow RCX and RDX in the dump. One is the current word from your input, the other the word it must match.
4. Use the command line to read the tables directly. Work out the address of `words` from Ghidra and the image base. Then type expressions such as `[address+8*5]` to get the pointer for entry 5, and `dump` that pointer.
5. Enter the passphrase you found and check that it is accepted.

**What to check:** which register holds the expected word, and what is the first one? Which expression reads entry 5 of `words`?

**What you should see.** The breakpoint stops once per word until a compare fails, so a wrong first word gives one stop per try. `[address]` reads 8 bytes, which is exactly one pointer; reading a 4-byte table entry needs `dword:[address]`. The address from step 4 changes every run, because of ASLR; [In x64dbg](primers/04-memory-layout.md#in-x64dbg) shows where to find the base.

### 9. ex5 without wide strings (★★)

**Goal:** see exactly what changes in the machine code when the same program uses 8-bit text.

Copy `ex5_wide.c` and make a narrow version. Change `wmain` to `main` and `wchar_t` to `char`, drop every `L` before a quote, and use `strcmp`, `strlen` and `OutputDebugStringA`. Build it without `-municode`, then open both builds side by side in Ghidra.

**What to check:** how do the strings differ in Defined Strings? In the code builder, how do the load, the index and the store change? Which imports change, and what call does the narrow `main` make that `wmain` doesn't?

## Answer key and hints

Try each exercise for at least 15 minutes before you look here. Addresses depend on your compiler, so they're left out. The checks CI runs are in [lab/solutions/day3/checks.psd1](../lab/solutions/day3/checks.psd1), and [lab/solutions/day3/solve\_day3.py](../lab/solutions/day3/solve_day3.py) computes the answers for `ex2` and `ex3`.

Hints and answers for the challenges in [Beyond this lesson](#beyond-this-lesson) are in [lab/solutions/day3/extra-credit.md](../lab/solutions/day3/extra-credit.md).

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
| 4.1 | The order table holds indexes into the word table | `order` is {5, 2, 7, 0}, so the passphrase is `meadow-falcon-tundra-amber`. Words are separated by `-`. Case doesn't matter, because the input is made lower case first |
| 4.1 globals | Check each `DAT_` address against the Memory Map | The word table, `order` and the try counter (starts at 3) are in `.data`; the input buffer is in `.bss`; the words themselves are in `.rdata` |
| 5.1 | Read the name table and the clearance table at the same index | `argc` must be 3: a name and a code. Clearance must be 3 or more, so only `grace` and `barbara` pass. Each code letter is the name's letter moved 3 places on in the alphabet and made upper case: `(c - 'a' + 3) % 26 + 'A'` |
| 5.1 answer | Pass both on the command line | `ex5.exe grace JUDFH` or `ex5.exe barbara EDUEDUD`. The code is case-sensitive, because it is compared with `wcscmp` |
| 5.1 import | Its name ends in a letter | `OutputDebugStringW`, from `kernel32.dll`, with the wide text "Badge reader started." |
| 5.2 | RCX is the first argument of `wcscmp`, RDX the second | RCX holds your code (`argv[2]`), RDX the expected code, built in a local array on the stack |
| Checkpoint | No hints here | The answer and a model write-up are in [lab/solutions/day3/checkpoint.md](../lab/solutions/day3/checkpoint.md) |

## Day 4

Add today's features to your notes; the [Ghidra reference](ghidra-reference.md) and [x64dbg reference](x64dbg-reference.md) list them all. In Ghidra: switch recovery, bookmarks, Listing fields, Function Call Trees and wide strings. In x64dbg: conditional breakpoints, the command line, graph view, the Unicode dump and Change Command Line.

**Day 4 preview:** an inventory program built from structs, arrays of structs and a linked list. You will recover the structs with Ghidra's Data Type Manager and Structure Editor, and share the types between programs. In x64dbg you will follow them through the dump and the Watch view.

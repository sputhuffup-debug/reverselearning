# Day 0: Setup and method

Nov 28, 2026

## Overview

Day 0 runs before Day 1 and takes about 3.5 hours. By the end you will have a working lab: a Windows VM with snapshots, the portable kit, and the course repo. You will also have a method for any unknown program, used once with the source in view and once without.

**Goals for the day**

1. Set up a Windows VM, take snapshots, and build the kit with `Build-PortableRE.ps1`.
2. Know what each launcher starts, and build the practice programs with `make` from `Devkit.cmd`.
3. Read the primers that Day 1 assumes, and know what to take from each.
4. Triage a program: file type, sections, imports, strings and signs of packing.
5. Turn triage findings into hypotheses, test them, and keep notes in the course template.
6. Solve a small program blind, using only the method.

**What you need**

- A computer that can run a Windows 10 or 11 VM. Allow 60 GB of disk for the VM and the kit.
- Internet access in the VM while the kit builds. The build downloads Ghidra, a JDK, x64dbg and w64devkit.
- Basic C. No assembly is needed yet: Module 1 starts the primers that teach it.

**Before you start**

Nothing. Today's Module 1 is reading time for the primers, and it tells you which parts to finish before Day 1:

- [How to approach an unknown program](primers/00-approach.md): the method used today and on every later day.
- [Numbers and data](primers/01-numbers-and-data.md), [Registers and flags](primers/02-registers-and-flags.md), [Reading assembly](primers/03-reading-assembly.md), [A program in memory](primers/04-memory-layout.md) and [The stack and the calling convention](primers/05-stack-and-calls.md): the background Day 1 assumes.

**Lab rules**

- Work in a Windows VM. Take a snapshot before you build the kit and another once it works, and roll back if anything gets messy.
- Only analyze the practice programs in this course. They are small and benign, written so the answers are known.
- Don't open `lab/solutions/day0` until you have finished the checkpoint. It holds the checkpoint's source and answer.
- Keep notes in the [analysis notes template](templates/analysis-notes.md), one copy per program.

## Schedule

The day runs about 3.5 hours with one break. The extra-credit challenges in [Beyond this lesson](#beyond-this-lesson) and the rest of the primer reading are outside these hours.

| Time | Block | What you do |
| --- | --- | --- |
| 0:00–0:45 | Module 0: Setup | VM and snapshots, clone the repo, build the kit, `make day0` |
| 0:45–1:50 | Module 1: Primers | Read the method in full, and the key sections of primers 01 to 05 |
| 1:50–2:00 | Break |  |
| 2:00–2:40 | Module 2: The method, worked | Triage `sample` step by step, then confirm the answer in both tools |
| 2:40–3:25 | Module 3: Checkpoint | Triage and solve `checkpoint` blind, filling in the notes template |
| 3:25–3:35 | Wrap-up | Check your notes against the answer key; plan the reading for Day 1 |

## Module 0: Set up the lab (45 min)

You build everything once today, so Day 1 can start on the programs. The kit is portable: nothing is installed on Windows, and you can move its folder later.

### 0.1 A Windows VM and its snapshots (15 min)

1. **Create the VM.** Use any hypervisor you know, such as Hyper-V, VirtualBox or VMware. Install Windows 10 or 11 (64-bit), with at least 4 GB of memory and 60 GB of disk.
2. **Finish setup.** Install Windows updates and reboot once.
3. **Install Git for Windows**, or plan to download the repo as a ZIP in step 0.2.
4. **Take a snapshot** called "clean". This is the state to roll back to if the kit build goes wrong.

**Why it matters.** A snapshot turns every mistake into a two-minute rollback. Later in the course you will run programs that are built to resist analysis, and the habit has to be in place by then.

**If it doesn't match.** If the VM is slow, give it two CPU cores. Also check that hardware virtualization is turned on in the host's firmware settings.

### 0.2 Clone the course repo (5 min)

Open PowerShell in the VM and clone the repo to a short path with no spaces:

```powershell
mkdir C:\RE
cd C:\RE
git clone <the course repo's URL> reverselearning
cd reverselearning
```

Without Git, download the ZIP from the repo's GitHub page and extract it to `C:\RE\reverselearning`.

**Why a short path.** `make` can't handle spaces in paths, and a short path keeps the commands in this guide readable.

### 0.3 Build the kit (15 min)

From the repo folder, run the build script with the command from the repo's README:

```powershell
# first build, or fill in anything missing
powershell -ExecutionPolicy Bypass -File .\scripts\Build-PortableRE.ps1 -Destination .\RE-Portable
```

It finds the latest release of each tool through the GitHub and Adoptium APIs, downloads it and checks its SHA-256 hash. It prints one line per step, `[1/4] Ghidra` to `[4/4] w64devkit`, and ends with "Done" and the list of launchers.

Run it from inside the cloned repo, as above. The script saves the repo's `lab` folder in `RE-Portable\data\lab-path.txt`, so `Devkit.cmd` can open its shell there.

You can run the script again at any time. Tools that are already installed are skipped, and nothing is ever deleted. To update every tool to its latest version, add `-Force`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Build-PortableRE.ps1 -Destination .\RE-Portable -Force
```

**What you should see.** A folder `RE-Portable` inside the repo, with `ghidra`, `jdk`, `x64dbg`, `w64devkit`, `data`, `projects` and `lab` folders and four `.cmd` launchers. Git ignores the whole folder.

**If it doesn't match.**

- "running scripts is disabled on this system" means `-ExecutionPolicy Bypass` was left out. Use the command exactly as shown.
- An error about the GitHub API rate limit means too many unauthenticated requests from your network. Wait an hour, or set the `GITHUB_TOKEN` environment variable to a GitHub token first.
- A "SHA-256 mismatch" means a download was damaged. Run the script again; it fetches the file again.

### 0.4 The launchers (5 min)

Each launcher sets up its tool's environment from the kit's folder, wherever that folder is now.

| Launcher | Starts | Notes |
| --- | --- | --- |
| `Ghidra.cmd` | Ghidra, with the kit's own JDK | Updates Ghidra's paths for the kit's current location first, and keeps its settings in `data\`. Save projects in `projects\`. |
| `x64dbg.cmd` | x64dbg, the 64-bit debugger | For PE32+ programs, which means every course program |
| `x32dbg.cmd` | x32dbg, the 32-bit debugger | Same layout and keys, for PE32 programs |
| `Devkit.cmd` | A w64devkit shell with GCC, `make` and binutils on the PATH | Opens in the repo's `lab` folder, from `data\lab-path.txt`. Pass a folder to open somewhere else: `Devkit.cmd D:\path\to\lab` |

Start `Ghidra.cmd` once now and close it again; the first start takes longer. Then take a second **snapshot**, called "kit ready".

**If it doesn't match.** If `Devkit.cmd` prints "Lab folder not found", the repo moved after the build. Edit `RE-Portable\data\lab-path.txt` to the new `lab` path.

### 0.5 Build today's programs (5 min)

Open `RE-Portable\Devkit.cmd`. Its shell starts in the repo's `lab` folder. Then run:

```bash
make day0     # builds bin/day0/sample.exe and bin/day0/checkpoint.exe
make          # builds every day's programs, including Day 1's
```

The Makefile compiles with `-O0`, which keeps the code close to the source, and `-s`, which strips the function names. Run `sample.exe` once with any input to see it work:

```bash
./bin/day0/sample.exe
```

`sample`'s source, [lab/day0/sample.c](../lab/day0/sample.c), is open on purpose: Module 2 uses it to show what each triage step finds. `checkpoint`'s source is in `lab/solutions/day0`, and you don't open it until the end.

**What you should see.** `make day0` prints two `gcc` command lines and returns to the prompt without errors. `sample.exe` prints `Config line: `, waits for a line, then prints one result.

**If it doesn't match.**

- "make: command not found" means you are in an ordinary Command Prompt. Open `Devkit.cmd` instead.
- "No rule to make target" means the shell is not in the repo's `lab` folder. See 0.4.

## Module 1: Read the primers (1 h 5 min)

The primers teach the background the day guides assume. Read the method primer in full now. For primers 01 to 05, read the sections listed under "Now" today, and the rest before Day 1; together they take about 2 hours.

Take notes as you read, one line per idea you expect to use. For example: "`test eax, eax` then `jne`: jumps when EAX is not 0".

| Primer | Take from it | Now (in class) | Before Day 1 |
| --- | --- | --- | --- |
| [00 How to approach an unknown program](primers/00-approach.md) | The steps you follow for every program, and how to keep notes | All of it (25 min) | Its Check yourself |
| [01 Numbers and data](primers/01-numbers-and-data.md) | Reading hex and dumps without a calculator | [Why reverse engineering uses hex](primers/01-numbers-and-data.md#why-reverse-engineering-uses-hex), [Text in a dump](primers/01-numbers-and-data.md#text-in-a-dump) (5 min) | The rest, including [XOR](primers/01-numbers-and-data.md#xor) |
| [02 Registers and flags](primers/02-registers-and-flags.md) | Which register holds what, and how a jump decides | [The 16 general-purpose registers](primers/02-registers-and-flags.md#the-16-general-purpose-registers), [cmp, test and conditional jumps](primers/02-registers-and-flags.md#cmp-test-and-conditional-jumps) (10 min) | The rest |
| [03 Reading assembly](primers/03-reading-assembly.md) | Reading a short `-O0` sequence back into C | [Intel syntax](primers/03-reading-assembly.md#intel-syntax), [Worked example: a string check at -O0](primers/03-reading-assembly.md#worked-example-a-string-check-at--o0) (10 min) | The rest |
| [04 A program in memory](primers/04-memory-layout.md) | Sections, imports and why addresses differ between tools | [Sections](primers/04-memory-layout.md#sections), [Imports and the IAT](primers/04-memory-layout.md#imports-and-the-iat) (10 min) | The rest |
| [05 The stack and the calling convention](primers/05-stack-and-calls.md) | Where arguments and results are at a `call` | [The Windows x64 calling convention](primers/05-stack-and-calls.md#the-windows-x64-calling-convention) (5 min) | Up to and including that section; Day 2 needs the rest |

**What to look for in 00.** Learn the seven steps of [The method in one page](primers/00-approach.md#the-method-in-one-page). Learn the two passes over imports in [Triage: imports](primers/00-approach.md#triage-imports). Copy the naming table in [Name things as you go](primers/00-approach.md#name-things-as-you-go) into your notes; you will use it all course.

**Why it matters.** Modules 2 and 3 use all six sections listed under "Now". On Day 1 every step has a **Background** link to a primer section. Those steps go much faster if you have read it once.

## Module 2: The method, worked on sample (40 min)

This module applies each step of the method to `sample.exe`, and shows what each step finds. The source is open, so you can check every finding against it. Follow along in your own Devkit shell, Ghidra and x64dbg, and fill in a notes file as you go.

```bash
mkdir -p ~/notes && cp ../docs/templates/analysis-notes.md ~/notes/sample.md
```

The output below comes from a MinGW GCC 13 build. The kit's GCC may be newer, so sizes, hashes and addresses will differ; the findings won't.

### Step 1: Record the target (2 min)

```bash
ls -l bin/day0/sample.exe
sha256sum bin/day0/sample.exe
```

Write the size and the hash in the Target table. The goal for `sample` is "find a config line it accepts".

**Why it matters.** A rebuild makes a new file. The hash ties your notes to the exact file you analyzed.

### Step 2: What kind of file it is (3 min)

```bash
objdump -f bin/day0/sample.exe
```

```
bin/day0/sample.exe:     file format pei-x86-64
architecture: i386:x86-64, flags 0x00000103:
HAS_RELOC, EXEC_P, D_PAGED
start address 0x0000000140001410
```

`pei-x86-64` means PE32+, so it goes in x64dbg, not x32dbg. The start address is the entry point, MinGW's startup code, and it is inside `.text` (next step). It is a console program: it ran in the shell and printed text.

**Background:** [Triage: what kind of file it is](primers/00-approach.md#triage-what-kind-of-file-it-is).

### Step 3: Sections and packing (5 min)

```bash
objdump -h bin/day0/sample.exe
```

```
Idx Name          Size      VMA               LMA               File off  Algn
  0 .text         00006c88  0000000140001000  0000000140001000  00000400  2**4
                  CONTENTS, ALLOC, LOAD, READONLY, CODE, DATA
  1 .data         000000c0  0000000140008000  0000000140008000  00007200  2**4
                  CONTENTS, ALLOC, LOAD, DATA
  2 .rdata        00000e20  0000000140009000  0000000140009000  00007400  2**4
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  ...
  5 .bss          00000b80  000000014000c000  000000014000c000  00000000  2**4
                  ALLOC
  ...
```

All ten names are the usual MinGW sections. Only `.bss` has no `CONTENTS`, so it takes no bytes in the file, which is normal. `CODE` appears only on `.text`, and `.text` and `.rdata` are `READONLY`.

The entry point `0x140001410` is inside `.text`, which runs from `0x140001000` to `0x140007c88`.

In Ghidra, the same list is in Window → Memory Map, after the import in Step 7. Check its flags there: `.text` is R X, and no section is both W and X.

Verdict for the notes: **not packed**. The sections are normal, and Steps 4 and 5 find a normal import list and readable strings.

**Background:** [Triage: sections](primers/00-approach.md#triage-sections), [Triage: signs of packing](primers/00-approach.md#triage-signs-of-packing).

### Step 4: Imports (5 min)

```bash
objdump -p bin/day0/sample.exe | sed -n '/Import Tables/,/Function Table/p'
```

`objdump -p` prints all the PE headers; the `sed` keeps only the import tables. Each DLL starts with a `DLL Name:` line, followed by one line per function.

The list has two DLLs, `KERNEL32.dll` and `msvcrt.dll`, and about 50 functions. Most are MinGW runtime: `DeleteCriticalSection`, `TlsGetValue`, `VirtualProtect`, `__getmainargs`, `_initterm`, `malloc` and the like.

Some names, such as `strlen` and `memset`, could belong to the program or to the runtime. The surest first pass is a **baseline**: build a program that does almost nothing, and remove its imports from the list.

```bash
mkdir -p ~/scratch
printf '#include <stdio.h>\nint main(void) { printf("hi"); return 0; }\n' > ~/scratch/base.c
gcc -O0 -s ~/scratch/base.c -o ~/scratch/base.exe
imports() { objdump -p "$1" | sed -n '/Import Tables/,/Function Table/p' | awk '$1 ~ /^[0-9a-f]+$/ && NF == 3 { print $3 }' | sort; }
imports ~/scratch/base.exe > ~/scratch/base.txt
imports bin/day0/sample.exe > ~/scratch/sample.txt
comm -13 ~/scratch/base.txt ~/scratch/sample.txt
```

The `imports` function prints one function name per line, and `comm -13` keeps the lines found only in the second file. The baseline calls `printf` because MinGW's own `printf` brings imports of its own.

In the second pass, the five names left say what the program does:

| Import | Suggests |
| --- | --- |
| `fgets` | Reads a line of input |
| `puts` | Prints a line |
| `strchr` | Looks for one character in a string |
| `strcmp` | Compares two strings exactly |
| `strcspn` | Measures up to a set of characters, often to cut the newline |

There are no file, registry, network or debugger-check imports. `printf` is not imported at all, because MinGW links its own copy into the program. Keep `~/scratch/base.txt`; it works for the checkpoint too.

**Background:** [Triage: imports](primers/00-approach.md#triage-imports), [Imports and the IAT](primers/04-memory-layout.md#imports-and-the-iat).

### Step 5: Strings (5 min)

```bash
strings -n 6 bin/day0/sample.exe | head -100
```

About 180 lines come out, and most are noise from code bytes and the runtime. The program's own strings sit together, in this order:

```
Config line: 
Bad format: expected key=value.
channel
Unknown key.
stable
Config OK: channel is stable.
Config rejected.
```

In Ghidra, Window → Defined Strings shows the same strings with their addresses in `.rdata`. String literals are stored in about the order the code uses them, so this list is a rough outline of `main`.

**Background:** [Triage: strings](primers/00-approach.md#triage-strings), [Text in a dump](primers/01-numbers-and-data.md#text-in-a-dump).

### Step 6: Hypotheses, then a test (5 min)

From Steps 4 and 5, write the hypotheses with their evidence and the cheapest test:

| # | Hypothesis | Evidence | Test |
| --- | --- | --- | --- |
| H1 | Input is one `key=value` line | "Bad format: expected key=value.", `fgets`, `strchr` | Run with `stable`: expect "Bad format" |
| H2 | The key must be `channel` | `channel` next to "Unknown key.", `strcmp` | Run with `mode=stable`: expect "Unknown key." |
| H3 | The value must be `stable` | `stable` next to "Config OK", "channel is stable" | Run with `channel=beta`, then `channel=stable` |

Running is the cheapest test. In the Devkit shell, `echo` sends a line to the program, and `echo $?` prints its exit code:

```bash
echo stable | ./bin/day0/sample.exe; echo $?
echo mode=stable | ./bin/day0/sample.exe; echo $?
echo channel=beta | ./bin/day0/sample.exe; echo $?
echo channel=stable | ./bin/day0/sample.exe; echo $?
```

Each run gives the message the hypothesis predicted. The last prints "Config OK: channel is stable." with exit code 0, so the candidate answer is `channel=stable`. Mark H1 to H3 confirmed by running, and record the four exit codes: 2, 1, 1 and 0.

**Why it matters.** Four runs settled three hypotheses in under a minute. A run only shows what happens, though, not why. Steps 7 and 8 find the code and check that nothing else decides the result.

**Background:** [Form hypotheses](primers/00-approach.md#form-hypotheses), [Static or dynamic?](primers/00-approach.md#static-or-dynamic).

### Step 7: Find and read the code in Ghidra (10 min)

1. Start `Ghidra.cmd`, create a project in the kit's `projects` folder (File → New Project → Non-Shared), and drag `sample.exe` in. The import dialog shows the format, Portable Executable, and the language, `x86:LE:64`.
2. Double-click the program, click Yes to analyze, and wait for the progress bar at the bottom right to finish.
3. Open Window → Defined Strings, find "Config line: ", and follow its reference (Ctrl+Shift+F) to the code that uses it.
4. That function is `main`. Press `L` and rename it. Read it top-down in the decompiler: one `fgets`, one `strchr`, two `strcmp` calls, and a `puts` per outcome.
5. Rename the locals as you learn them: the 64-byte buffer to `line`, the result of `strchr` to `eq`. Add a comment on `0x3d`: it is `'='`.

After renaming, the decompiler shows something like this:

```c
  printf("Config line: ");
  pFVar1 = (FILE *)(*(code *)PTR_FUN_1400080b0)(0);
  pcVar2 = fgets(line,0x40,pFVar1);
  if (pcVar2 == (char *)0x0) {
    return 2;
  }
  sVar3 = strcspn(line,"\r\n");
  line[sVar3] = '\0';
  eq = strchr(line,0x3d);
  if (eq == (char *)0x0) {
    puts("Bad format: expected key=value.");
    return 2;
  }
  *eq = '\0';
  iVar4 = strcmp(line,"channel");
  if (iVar4 != 0) {
    puts("Unknown key.");
    return 1;
  }
  iVar4 = strcmp(eq + 1,"stable");
  ...
```

`*eq = '\0'` is the step no run could show. It overwrites the `=` with a zero byte, so `line` now ends after the key, and `eq + 1` is the value. That explains why both `strcmp` calls compare whole strings.

Write `main` in your Functions table with its offset, "known", and "xref from Config line:".

**What you should see.** Names, casts and the order of the branches vary. The call through `PTR_FUN_...` gets `stdin`, as [Getting stdin](primers/05-stack-and-calls.md#getting-stdin) explains. The locals start as names like `local_58` and `local_10`.

**Background:** [Find the code that matters](primers/00-approach.md#find-the-code-that-matters), [Locals and how Ghidra names them](primers/05-stack-and-calls.md#locals-and-how-ghidra-names-them).

### Step 8: Confirm it in x64dbg (5 min)

1. Start `x64dbg.cmd`, File → Open `sample.exe`, and press F9 once to pass the system breakpoint.
2. Right-click in the disassembly → Search for → Current Module → String references. Double-click "Config OK: channel is stable.".
3. Scroll up to the nearest `call` to `strcmp`, the second of the two, and press F2 on it.
4. Press F9 and type `channel=beta` in the program's console window.
5. When it stops, right-click RCX → Follow in Dump, then do the same for RDX.

RCX points at `beta` and RDX at `stable`. Scroll the dump back 8 bytes from RCX to see the whole input buffer:

```
63 68 61 6E 6E 65 6C 00 62 65 74 61 00     channel.beta.
```

The `=` (`3D`) has become `00`, just as the decompiler said. The value alone is compared with `stable`, which confirms H3 from inside the program.

**Background:** [The Windows x64 calling convention](primers/05-stack-and-calls.md#the-windows-x64-calling-convention), [Little-endian byte order](primers/01-numbers-and-data.md#little-endian-byte-order).

**If it doesn't match.** If the program seems frozen after F9, it is waiting for input. Its console window may be behind x64dbg.

### Step 9: Finish the notes (2 min)

Fill in the Answer, `channel=stable`, with the run that proves it. Under Open questions, note anything you saw but didn't explain. For `sample`, that might be the first call in `main`, which Day 1 identifies.

Check your notes against the template: every claim marked known or guessed, and every known claim saying how you checked it.

## Checkpoint

Triage and solve `checkpoint.exe` without its source, using only the method (45 min). Work alone, and don't open `lab/solutions/day0` until you have an answer or the time is up.

```bash
cp ../docs/templates/analysis-notes.md ~/notes/checkpoint.md
```

**Goal:** find the input that makes `checkpoint.exe` print a success message and exit with code 0.

**Deliverable:** your filled-in `checkpoint.md`. It needs the Target and Triage sections and at least three hypotheses with their tests and results. It also needs `main` in the Functions table, and the answer with the run that shows it.

Suggested timing:

| Minutes | Step |
| --- | --- |
| 0–5 | Record the target. Run it three times with different inputs, and note each output and exit code |
| 5–15 | Triage: file type, sections, imports and strings |
| 15–20 | Write your hypotheses, each with its evidence and a test |
| 20–40 | Test them: runs first, then Ghidra or x64dbg for what a run can't settle |
| 40–45 | Finish the notes and the answer |

**Why it matters.** This is the method without a safety net. On every later day, and in the Day 15 capstone, you start from a program like this one.

**If you get stuck.**

- Test every candidate string you find, and write down what each one does, including its exit code. A refuted guess is a result.
- Ask what each import that is left after the first pass would be used for here.
- Find the code that prints the success message, then look just above it for the decision.
- Constants in Ghidra are usually shown in hex. Right-click one to see it in decimal.

Hints in order, and a model write-up, are in [lab/solutions/day0/checkpoint.md](../lab/solutions/day0/checkpoint.md), which contains spoilers.

## Beyond this lesson

These optional challenges go past the day's exercises and get harder in turn. They are outside the 3.5 hours. Hints and expected results are in [lab/solutions/day0/extra-credit.md](../lab/solutions/day0/extra-credit.md), which contains spoilers.

Never edit the files in `lab/day0`. For challenges that change a program, copy the source to a scratch folder first:

```bash
mkdir -p ~/scratch && cp day0/sample.c ~/scratch/
```

### 1. Triage the Day 1 programs (★)

**Goal:** before Day 1, run Module 2's Steps 1 to 5 on `bin/day1/ex1.exe`, `ex2.exe` and `ex3.exe`. Don't solve them; triage only.

**Hand in:** a Triage section for each program, and a prediction: which program checks for a debugger, and which hides its key? Give the evidence for each.

### 2. Measure section entropy (★★)

**Goal:** write a short Python script that lists the sections of a PE file. For each, print its size in memory, its size in the file, and the entropy of its bytes.

**Hand in:** the script and its output for `sample.exe` and `checkpoint.exe`. In one sentence, say what a packed program's output would look like.

### 3. Stripped and unstripped (★★)

**Goal:** build `sample.c` without `-s` in your scratch folder, import both builds into Ghidra, and compare them.

**Hand in:** a list of what the unstripped build shows that the stripped one doesn't, and of what is the same. Say which triage steps depended on names.

### 4. Swap blind programs (★★★)

**Goal:** write a small benign C program with one input check, in the style of `checkpoint`. Build it with `gcc -O0 -s` and swap `.exe` files with a partner. No file, network or registry access.

**Hand in:** your partner's answer and your notes file for their program. Then grade their notes on your program against the template.

## Answer key

Try each step yourself before you look here. Addresses depend on your compiler, so they're left out.

| Part | Answer |
| --- | --- |
| Step 2 | PE32+ (`pei-x86-64`), a console program; debug it in x64dbg |
| Step 3 | The usual ten MinGW sections, entry point in `.text`, nothing W and X: not packed |
| Step 4 | Telling imports: `fgets`, `strcspn`, `strchr`, `strcmp`, `puts`. The rest is MinGW runtime |
| Step 5 | Seven program strings, from "Config line: " to "Config rejected." |
| Step 6 | Exit codes 2 (`stable`), 1 (`mode=stable`), 1 (`channel=beta`) and 0 (`channel=stable`) |
| Step 7 | `main` splits the line at `=` by writing a zero byte there, then compares the key with `channel` and the value with `stable` |
| Step 8 | At the second `strcmp`, RCX points at your value and RDX at `stable` |
| Answer | `channel=stable` prints "Config OK: channel is stable." and exits with 0 |
| Checkpoint | See [lab/solutions/day0/checkpoint.md](../lab/solutions/day0/checkpoint.md) |

## Day 1 preview

Day 1 goes deeper into the two tools you used today. You will rename and retype until decompiled code reads like source, and step through code in x64dbg. You will also line up addresses between the tools, and patch a program so a check always passes.

Its three programs are already built in `bin/day1`, and its "Before you start" list is the primer reading from Module 1.

Before Day 1, finish the "Before Day 1" column of the Module 1 table. Then answer the Check yourself questions at the end of each primer.

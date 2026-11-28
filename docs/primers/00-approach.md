# How to approach an unknown program

A repeatable method for the first hour with a program you know nothing about. Triage it, guess, test the guesses, and write down what you learn. [Day 0](../day0-training.md) teaches it on two small programs, and every later day uses it, up to [Day 15](../roadmap.md)'s unseen capstone.

Reading time: about 25 minutes. The terms used here (sections, imports, the IAT) are explained in [A program in memory](04-memory-layout.md).

## The method in one page

Reverse engineering goes faster when you follow the same steps every time. Each step answers one question and feeds the next.

1. **Record the target.** Name, size and SHA-256 hash, so you know exactly which file your notes describe.
2. **Triage.** What kind of file is it, what does it import, what text does it contain, and is it packed? This takes minutes and needs no deep reading.
3. **Form hypotheses.** Turn the triage findings into guesses you can test: "it reads one line and compares it with a fixed string".
4. **Choose static or dynamic analysis** for each guess, whichever answers it fastest.
5. **Find the code that matters** from strings, imports and cross-references. Ignore the rest.
6. **Read it** top-down or bottom-up, and **name things as you go**.
7. **Keep notes** throughout: what you know, what you guess, and what you checked.

You will loop through steps 3 to 7 many times. A test that fails is useful: it removes a guess and usually suggests the next one.

## Triage: what kind of file it is

Start by finding out what the file is, before you open it in any tool that runs it. A Windows program is a **PE** file (Portable Executable). It comes in two kinds:

| Kind | Also called | CPU | Debugger | Ghidra's language |
| --- | --- | --- | --- | --- |
| **PE32** | 32-bit | x86 | `x32dbg.cmd` | `x86:LE:32` |
| **PE32+** | 64-bit | x86-64 | `x64dbg.cmd` | `x86:LE:64` |

Every course program is PE32+. A 32-bit program won't open in x64dbg; use x32dbg instead, which has the same layout and keys.

Three quick ways to tell:

- In the Devkit shell, `objdump -f program.exe` prints `file format pei-x86-64` for PE32+ and `pei-i386` for PE32.
- In Ghidra, the import dialog shows the detected format and language before you click OK.
- A PE file starts with the bytes `4D 5A` (`MZ`). If it doesn't, it is not a Windows program, whatever its name says.

Also note whether it is a console program or a window program, and whether it is an `.exe` or a `.dll`. A DLL has no `main` to find; you start from its exports instead, as Day 8 shows.

## Triage: sections

The section list tells you how the file is laid out and whether anything looks unusual. `objdump -h program.exe` prints it in the Devkit shell. In Ghidra, Window → Memory Map shows the same list with R, W and X flags.

A normal MinGW program has `.text`, `.data`, `.rdata`, `.pdata`, `.xdata`, `.bss`, `.idata`, `.CRT`, `.tls` and `.reloc`. [Sections](04-memory-layout.md#sections) says what each one holds. Things that should make you look closer:

- Section names you don't recognize, such as `UPX0` and `UPX1`, or random names.
- A section that is both writable and executable. Normal code is R X, and normal data is R W.
- A section with a large size in memory but zero bytes in the file, apart from `.bss`.
- A program entry point outside `.text`. `objdump -f` prints it as the start address.

## Triage: imports

Imports are the Windows and C library functions a program asks the loader for. Stripping a program removes its own function names but not its imports, because the loader needs them. [Imports and the IAT](04-memory-layout.md#imports-and-the-iat) explains why.

`objdump -p program.exe` lists them under each `DLL Name`. In Ghidra, open Symbol Tree → Imports. In x64dbg, calls through the IAT show the function's name in the disassembly.

Read the list in two passes. First set aside the runtime noise. Every MinGW program imports these, whatever it does:

- From `KERNEL32.dll`: `DeleteCriticalSection`, `EnterCriticalSection`, `TlsGetValue`, `Sleep`, `SetUnhandledExceptionFilter`, `VirtualProtect`, `VirtualQuery` and a few more.
- From the C runtime (`msvcrt.dll` or a `ucrt` DLL): `__getmainargs`, `_initterm`, `malloc`, `free`, `exit` and similar.

When you can, build a **baseline**: a program that does almost nothing, built with the same compiler. Its imports are the noise, so anything the target imports beyond them is the target's own. [Day 0](../day0-training.md) does this in its worked triage.

Then look at what is left and ask what each function suggests:

| Imports | Suggest |
| --- | --- |
| `fgets`, `scanf`, `ReadConsoleA` | Reads input from the user |
| `strcmp`, `strncmp`, `memcmp` | Compares input with something |
| `strtol`, `atoi`, `sscanf` | Turns text into a number |
| `strchr`, `strtok`, `strstr` | Splits or searches text |
| `CreateFileW`, `ReadFile`, `WriteFile` | Works with files |
| `RegOpenKeyExW`, `RegQueryValueExW` | Reads the registry |
| `IsDebuggerPresent`, `CheckRemoteDebuggerPresent` | Looks for a debugger |
| `LoadLibraryA`, `GetProcAddress` | Finds more functions at runtime |

An import is a hint, not proof. `VirtualProtect` in a MinGW program is startup code, not something your target chose. Mark import-based ideas as guesses until you find the call that uses them.

## Triage: strings

Strings are the cheapest clue there is. Messages, prompts, format strings and file names tell you what a program talks about.

In Ghidra, Window → Defined Strings lists them. In the Devkit shell, `strings -n 6 program.exe` prints every run of 6 or more printable characters.

Most of the output is runtime noise: MinGW error messages, section names and short random runs from code bytes. The program's own strings usually sit together near the start of `.rdata`. Look for:

- Prompts and results: "Enter password:", "Access denied.".
- Format strings with `%d`, `%s` or `%x`: they show what gets printed and as what type.
- Words that look like answers. Treat them as candidates and test them; a program can carry a decoy.

What is missing matters too. If you know the program prints "Access granted!" but no string says so, the text is hidden or built at runtime. Day 1's `ex3` hides its key this way.

## Triage: signs of packing

A **packed** program stores its real code compressed or encrypted and unpacks it when it runs. Static analysis of a packed file shows only the unpacker. The signs are usually obvious together:

- **Few imports.** Often only `LoadLibraryA`, `GetProcAddress`, `VirtualAlloc` and `VirtualProtect`, because the real list is rebuilt at runtime.
- **Few readable strings**, even though the program prints messages when it runs.
- **Odd sections**, as listed under [Triage: sections](#triage-sections).
- **High entropy.** Entropy measures how random a section's bytes look, from 0 to 8 bits per byte. Machine code is usually 5 to 6.5, text and tables lower, and compressed or encrypted data close to 8.
- **Few functions in Ghidra** after analysis, and a decompiler that shows nonsense for most of them.

None of the course programs before Day 14 is packed. Check anyway, so that the check becomes a habit. Day 14 covers unpacking.

## Form hypotheses

A **hypothesis** is a guess precise enough to test. "It checks a password" is too vague; "it compares the whole input line with the string `hunter2-ghidra`" can be tested in one run.

Write each one down with the evidence behind it and the test that would confirm or refute it:

```
H1  input is "key=value"     evidence: "Bad format: expected key=value.", strchr import
    test: run with "abc" and with "a=b"; expect different messages
```

Prefer the test that is cheapest and most decisive. Running a program with a guessed input takes seconds. Reading a long function takes much longer, so save it for guesses that a quick run can't settle.

## Static or dynamic?

**Static analysis** reads the program without running it: Ghidra, `objdump`, `strings`. **Dynamic analysis** runs it and watches: x64dbg, or just running it with chosen inputs. Each answers some questions better.

| Question | Usually faster |
| --- | --- |
| What does this function do in general? | Static: read the decompiler |
| What value does this argument have right now? | Dynamic: break on the call and read the register |
| What text is hidden and decoded at runtime? | Dynamic: break after the decoder and read memory |
| What do all the paths through this code do? | Static: a run shows only one path |
| Is my guess about the input right? | Dynamic: run it with that input |

Switch between them often. A typical loop: find a call in Ghidra, break on it in x64dbg and read the arguments. Then go back to Ghidra and rename what you learned.

Only run programs you trust in your VM; the course programs are safe by design.

## Find the code that matters

A small MinGW program has a few hundred functions, and almost all of them are runtime. You want the handful that do the program's work. Find them from the clues triage gave you, not by reading from the entry point.

- **From a string.** Find a message in Defined Strings, then References → Show References to (Ctrl+Shift+F) to reach the code that prints it. The decision is usually just before.
- **From an import.** Select the import in the Symbol Tree and show references to it. Every call to `strcmp` is a candidate check.
- **From a breakpoint.** In x64dbg, set a breakpoint on the call to an interesting import and run. See where it stops and with what arguments.
- **From the output.** Run it, note the exact text it prints, and search for that text.

In a stripped program `main` has a name like `FUN_140001450`. Find it from a string it uses, and rename it at once.

## Top-down or bottom-up

**Top-down** starts at a high level, such as `main`, and reads its outline. Which functions does it call, in what order, and what does it do with their results? You don't open the callees until you need to. Use it to get the shape of a program fast.

**Bottom-up** starts at a small, interesting piece, such as one `strcmp` call or one loop, and works out to its callers. Use it when a clue points straight at the code that matters.

Most analyses mix the two. Find a clue bottom-up, then read its function top-down. A callee you haven't read gets a temporary name from what you can see at the call, such as `maybe_check_input`.

## Name things as you go

Renaming is how unreadable code becomes readable. Rename as soon as you have a reason, even a weak one. Use a convention, so that the name also says how sure you are.

| What | Convention | Example |
| --- | --- | --- |
| Function you understand | verb and noun, lower case with underscores | `check_key`, `parse_line` |
| Function you only guess at | prefix `maybe_` | `maybe_decode` |
| Function you skipped | prefix `lib_` if it looks like runtime code | `lib_printf_impl` |
| Global variable | prefix `g_` | `g_secret`, `g_tries` |
| Local variable | what it holds | `input`, `len`, `i` |
| Constant you recognize | a comment with its meaning | `; 0x3d = '='` |

Drop the `maybe_` once a test confirms the guess. Use the same names in Ghidra (press `L`) and in x64dbg (press `:` for a label), so your notes match both tools.

## Keep notes

Notes are what you hand in, and what lets you stop and pick up later. Keep three kinds of statement apart:

- **Known:** you checked it, and you say how. "`main` is at offset `0x14d4`; found from the "Config line: " xref."
- **Guessed:** you believe it but haven't tested it. "`FUN_140001600` probably decodes the key; it XORs bytes in a loop."
- **Checked and wrong:** a guess you tested and refuted. Keep these; they stop you testing the same idea twice.

Record addresses as offsets from the image base, because those don't change between runs or tools. [ASLR: why x64dbg's addresses differ](04-memory-layout.md#aslr-why-x64dbgs-addresses-differ) explains why. The course's [analysis notes template](../templates/analysis-notes.md) has a place for each of these.

## Check yourself

1. `objdump -f` prints `file format pei-i386`. Which debugger do you open the program in, and why?
2. A program's imports include `DeleteCriticalSection`, `TlsGetValue`, `fgets`, `strtol` and `puts`. Which of these tell you something about what it does, and what?
3. A program has three sections named `UPX0`, `UPX1` and `.rsrc`, and imports six functions. What do you suspect, and what would you check next?
4. Strings show "Enter PIN:", "Wrong PIN." and "1234". Write one hypothesis and the cheapest test for it.
5. You want to know which string `strcmp` receives as its second argument at runtime. Static or dynamic, and how?
6. You found a function that you think validates a serial, but you haven't read it yet. What do you name it?
7. Why should notes record addresses as offsets rather than as the addresses x64dbg shows?
8. You tested the guess "the password is `admin`" and it was wrong. Should it stay in your notes?

<details><summary>Answers</summary>

1. x32dbg (`x32dbg.cmd`). `pei-i386` means PE32, a 32-bit program, and x64dbg only debugs 64-bit programs.
2. `fgets` (it reads a line of input), `strtol` (it turns text into a number) and `puts` (it prints a line). `DeleteCriticalSection` and `TlsGetValue` are MinGW runtime noise.
3. It is probably packed with UPX. Check the entropy of `UPX1`, the number of readable strings, and where the entry point is.
4. For example: "the PIN is 1234; evidence: the string next to the prompt and the message". Test: run the program and type 1234. It takes seconds and settles the guess either way.
5. Dynamic. Set a breakpoint on the `call strcmp` in x64dbg, run, and follow RDX in the dump.
6. Something like `maybe_check_serial`. Drop the `maybe_` once a test confirms it.
7. ASLR loads the program at a different base on each run, so x64dbg's addresses change. The offset from the image base stays the same in every run and in both tools.
8. Yes, marked as checked and wrong, with how you tested it. It stops you, or a reader, testing it again.

</details>

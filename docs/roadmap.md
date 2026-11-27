# Development roadmap

The course runs 15 days. By the end, a student can take an unfamiliar Windows x64 program, work out what it does and how, defeat common protections, and write it up. They also know Ghidra and x64dbg well beyond the basics, and can write Ghidra scripts in Java that they understand line by line.

Each day follows Day 1's format: about 7 hours, roughly half hands-on, on practice programs built from source in `lab/` so the answers are known and checked by CI.

Status: Day 1 is written ([day1-training.md](day1-training.md)). Days 2 to 15 are planned below.

## Where the course ends up

By the end of Day 15 a student can:

1. Navigate any PE file: headers, sections, imports, exports, relocations, TLS, resources.
2. Read optimized compiler output (`-O2`) and recognize the C constructs behind it: loops, switch tables, structs, arrays, inlined calls.
3. Recover data structures and C++ classes (vtables, RTTI) and model them as types in Ghidra.
4. Follow how a program uses DLLs and the Windows API, including imports resolved at runtime.
5. Recognize common algorithms from their code and constants: CRC, XOR schemes, RC4, AES, hashes.
6. Reverse an undocumented file format or protocol and write a working parser for it.
7. Detect and defeat anti-debugging, string encryption, control-flow obfuscation and a basic packer.
8. Write Ghidra scripts in Java, and x64dbg scripts, that automate steps they already know how to do by hand.
9. Use Ghidra fully: analyzer options, the Data Type Manager and type archives, the Structure Editor, function signatures and calling conventions, equates, Function ID, Version Tracking, patching and export, the Script Manager and the scripting API, and headless analysis.
10. Use x64dbg fully: every breakpoint kind (software, hardware, memory, conditional, logging), tracing, the memory map, modules and symbols, threads, the call stack and exception handling, patching, its scripting language, and the Scylla and ScyllaHide plugins.
11. Analyze an unseen binary end to end and produce a clear technical write-up.

## Course plan

The 15 days fall into three five-day blocks. Each block ends with a day that consolidates it (scripting on Days 5 and 10, the capstone on Day 15).

| Day | Theme | Practice programs (`lab/dayN/`) | Skills added |
| --- | --- | --- | --- |
| **Block 1** | **Reading code** | | |
| 1 | Foundations (done) | ex1 password, ex2 serial, ex3 XOR key + `IsDebuggerPresent` | Ghidra and x64dbg basics, strings and xrefs, breakpoints, flipping flags, patching |
| 2 | Optimized code and the stack | Day 1 programs at `-O2`; a program with deep call chains | Stack frames, the x64 calling convention in depth, inlining, tail calls, spotting the same code at `-O0` and `-O2` |
| 3 | Control flow and data | A menu program with a `switch`, loops of each kind, recursion, globals and string handling | Jump tables, loop shapes, recursion, global data, reading assembly without the decompiler |
| 4 | Data structures | An inventory program with structs, arrays of structs and a linked list | Struct recovery, pointers to pointers, arrays versus structs, sharing types between programs |
| 5 | Ghidra scripting I (guided, Java) | Days 1 to 4 programs | The Script Manager, the `GhidraScript` API, walking functions, strings and references; a script that decodes ex3's key |
| **Block 2** | **Programs and Windows** | | |
| 6 | C++ reversing | A small class hierarchy with virtual functions, `std::string` and `std::vector`, an exception | `this` pointers, vtables, RTTI, constructors and destructors, name demangling, templates |
| 7 | The PE format and the loader | Programs with resources, TLS callbacks, relocations and delay-loaded imports | PE headers, sections, the IAT, ASLR and relocations, TLS, what runs before `main` |
| 8 | DLLs and the Windows API | A program and its own DLL; imports resolved at runtime with `GetProcAddress`; a benign API-hashing example | Exports, `LoadLibrary`/`GetProcAddress` patterns, analyzing an EXE and DLL together, common API call patterns |
| 9 | x64dbg in depth | Programs built to need each breakpoint kind: a value changed in memory, a hot loop, a multithreaded program | Hardware, memory, conditional and logging breakpoints, tracing, threads, attaching to a running process, guided x64dbg scripts |
| 10 | Ghidra scripting II (guided, Java) | Days 6 to 9 programs | Scripts that create data types, rename and comment, find constants; running a script headless with `analyzeHeadless` |
| **Block 3** | **Protections and real-world skills** | | |
| 11 | Algorithms and crypto | Keygen-mes using CRC32, a custom hash, RC4, and AES via Windows CNG | Constant hunting, recognizing crypto loops, writing keygens, a guided constant-finding script |
| 12 | File formats and protocols | A program that saves and loads a custom file format; a client and server talking a custom protocol over localhost | Following data from input to parser, rebuilding a format as Ghidra types, writing a parser in Python |
| 13 | Anti-debugging and anti-analysis | Layered checks: PEB flags, `NtQueryInformationProcess`, timing, TLS-callback checks, exception tricks | Bypassing each check by hand, then with ScyllaHide; SEH and vectored exception handlers |
| 14 | Obfuscation and packing | Encrypted strings, control-flow flattening, opaque predicates; a program packed with UPX and with a small custom packer | A guided string-decryption script, untangling flattened code, finding the OEP, dumping and fixing imports with Scylla |
| 15 | Capstone | One unseen program combining Days 2 to 14, then beginner crackmes from crackmes.one in the VM | End-to-end analysis under time pressure, the write-up |

All practice programs stay benign and written for this course (see CLAUDE.md). Real-world malware is out of scope for this repo; Day 15 points students to dedicated malware-analysis courses as a next step.

## How scripting is taught

Scripts automate what the student already understands; they never replace the analysis. Every scripting exercise follows the same five steps:

1. **By hand first.** The student solves the task manually in Ghidra (or x64dbg) and writes down the result, for example the decoded key or the list of functions that call `strcmp`.
2. **Plan in words.** They write the steps a script would take, in plain language, before writing code.
3. **Build from a skeleton.** `lab/dayN/scripts/` holds a Java skeleton with the class, the imports and numbered `TODO` comments, one per step. The student fills in one `TODO` at a time.
4. **Check each step.** After each `TODO` they run the script and compare its output with the manual result. The guide says what each step should print.
5. **Explain it.** They add a comment to every line they wrote, saying what it does and why. The finished script goes in their notes.

The guides introduce one API call at a time, with a link to Ghidra's API documentation, and never print a complete script. Complete solutions are in `lab/solutions/` for checking afterwards. Scripts are Java, run from the Script Manager; Ghidra compiles them with the kit's JDK, so nothing else needs installing. x64dbg scripts on Day 9 follow the same five steps.

## Tool mastery

Each day teaches the tool features its exercises need, so every feature is learned on a real problem. A feature first appears in that day's guide and then goes into a running reference: `docs/ghidra-reference.md` and `docs/x64dbg-reference.md` (task, how to do it, shortcut, which day covers it). By Day 15 these replace the Day 1 cheat sheet.

| Day | Ghidra | x64dbg |
| --- | --- | --- |
| 1 (done) | Projects, import, auto-analysis, Listing, Decompiler, Symbol Tree, Defined Strings, references, rename, retype, comments, Function Graph, Memory Map and image base | CPU view, F2 breakpoints, stepping, registers and flags, dump and stack, string references, editing instructions, Patch File |
| 2 | Analyzer options and re-analysis, function signatures and calling conventions, Version Tracking (match `-O0` to `-O2`) | Call stack, run to user code, labels and comments |
| 3 | Switch recovery, Function Call Trees, bookmarks, the Listing's field options | Conditional breakpoints, the command line and expressions, graph view |
| 4 | Data Type Manager, Structure Editor, auto-create structure, type archives (`.gdt`) | Watch view, following structures in the dump |
| 5 | Script Manager, the script editor, the `GhidraScript` API, the console | |
| 6 | C++ class recovery, vtables as structures, the RTTI analyzer, demangler options | Following `this` through calls |
| 7 | Program header and PE structures, sections, Function ID, loading PDBs | Memory map, modules and symbols, TLS callbacks, breaking before `main` |
| 8 | Imports and exports, linked programs (EXE and DLL together), external locations | Breaking on DLL load, symbols for loaded DLLs |
| 9 | | Hardware, memory and logging breakpoints, trace into and trace over, threads, attaching, x64dbg scripts |
| 10 | Scripts that create types, rename and comment; `analyzeHeadless` with a script | |
| 11 | Searching memory, scalars and instruction patterns, equates and enums | Logging breakpoints to record a hash as it is computed |
| 12 | Data types for a file format, applying structures to buffers | Breakpoints on file and socket APIs, memory breakpoints on a buffer |
| 13 | | ScyllaHide, exception handling and SEH, conditional tracing |
| 14 | String-decryption scripts that patch the listing, importing a memory dump, overlays and manual memory blocks | Finding the OEP with memory and hardware breakpoints, Scylla dump and import fixing |
| 15 | Ghidra's own debugger (optional), exporting a full project | The whole workflow under time pressure |

## Milestones

Each day ships as one milestone. A day is done when:

- its guide is in `docs/dayN-training.md`, with an answer key
- its programs are in `lab/dayN/`, and `make` builds them
- CI builds them on Windows and checks each one with its known answers
- its script skeletons (if any) are in `lab/dayN/scripts/`, and CI runs the matching solutions headless
- spoilers (keygens, decoders, solution scripts) are in `lab/solutions/`
- every tool feature it teaches is added to the Ghidra and x64dbg references
- any new tool the day needs is in the kit, installed and tested like the others

| Milestone | Delivers | Depends on |
| --- | --- | --- |
| M0: Kit and CI (in progress) | Portable kit, Windows CI, Makefile, Day 1 guide | |
| M1: Lab layout and references (done) | `lab/day1/` folders, a top-level Makefile that builds every day, CI testing each day; the Ghidra and x64dbg references started from Day 1's features | M0 |
| M2 to M4: Days 2 to 4 | Guides and programs for optimized code, control flow, data structures | M1 |
| M5: Day 5 | First guided scripting day: skeletons, solutions, headless script runs in CI | M4 |
| M6 to M9: Days 6 to 9 | C++, PE, DLLs, x64dbg in depth (adds `g++` builds, already in w64devkit) | M5 |
| M10: Day 10 | Second guided scripting day | M9 |
| M11 to M14: Days 11 to 14 | Crypto, file formats, anti-analysis, obfuscation and packing; kit adds ScyllaHide (M13) and UPX (M14) | M10 |
| M15: Day 15 | Capstone program and grading notes | M14 |

## Kit and repo backlog

Work on the kit that supports the course, in priority order. Items marked done came from the original handoff.

| Item | Needed by | Status |
| --- | --- | --- |
| Windows CI: lint, build, compile, smoke-test, re-run, relocation | M0 | In progress (headless Ghidra still failing) |
| `lab/Makefile` and `Devkit.cmd` opening in the repo's `lab` folder | M0 | Done (replaces the planned `lab/build.cmd`) |
| Version-aware updates: `data\versions.json`, `-Update`, `-Check` | M2 | Not started |
| Check the Day 1 guide's menus and shortcuts against Ghidra 12.2 and x64dbg 2026.05 | M2 | Not started |
| Check each day's Ghidra and x64dbg features against the versions the kit installs before writing that day | Each day | Not started |
| Lab layout per day, with CI that runs each day's answer checks | M1 | Not started |
| Show the repo's script folders in Ghidra's Script Manager (Script Directories), set up by `Ghidra.cmd` | M5 | Not started |
| CI runs solution scripts with `analyzeHeadless -postScript` and checks their output | M5 | Not started |
| Portable Python in the kit (embeddable package, found through python.org, checksum verified, `Python.cmd` launcher), added with the first milestone whose exercises need it: Day 12's parser at the latest. Day 1's keygen exercise already says "Python is fine", so it may come sooner | M12 or earlier | Not started |
| ScyllaHide plugin for x64dbg | M13 | Not started |
| UPX in the kit | M14 | Not started |
| Optional `-IncludeRetSync` (Ghidra and x64dbg stay in step) | Any | Not started |

## Decisions

| Decision | Choice |
| --- | --- |
| Course length | 15 days, about 7 hours each |
| Ghidra scripting language | Java, taught step by step (see How scripting is taught) |
| Packing on Day 14 | Both UPX and a small custom packer written for the course |
| Helper language (keygens, decoders, parsers) | Python; the kit adds a portable Python when the first day that needs it is built |

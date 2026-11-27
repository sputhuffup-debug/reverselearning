# Development roadmap

The course runs eight days. By the end, a student can take an unfamiliar Windows x64 program, work out what it does and how, defeat common protections, and write it up, and knows Ghidra and x64dbg well beyond the basics. Each day follows Day 1's format: about 7 hours, roughly half hands-on, on practice programs built from source in `lab/` so the answers are known and checked by CI.

Status: Day 1 is written ([day1-training.md](day1-training.md)). Days 2 to 8 are planned below.

## Where the course ends up

By the end of Day 8 a student can:

1. Navigate any PE file: headers, sections, imports, exports, relocations, TLS, resources.
2. Read optimized compiler output (`-O2`) and recognize the C constructs behind it: loops, switch tables, structs, arrays, inlined calls.
3. Recover data structures and C++ classes (vtables, RTTI) and model them as types in Ghidra.
4. Recognize common algorithms from their code and constants: CRC, XOR schemes, RC4, AES, hashes.
5. Detect and defeat anti-debugging, string encryption, control-flow obfuscation and a basic packer.
6. Automate analysis with Ghidra scripts (Java or Python) and x64dbg scripts.
7. Reverse an undocumented file format or protocol and write a working parser for it.
8. Analyze an unseen binary end to end and produce a clear technical write-up.
9. Use Ghidra fully: analyzer options, the Data Type Manager and type archives, the Structure Editor, function signatures and calling conventions, equates, Function ID, Version Tracking, patching and export, scripting, and headless analysis.
10. Use x64dbg fully: every breakpoint kind (software, hardware, memory, conditional, logging), tracing, the memory map, modules and symbols, threads, the call stack and exception handling, patching, its scripting language, and the Scylla and ScyllaHide plugins.

## Tool mastery

Each day teaches the tool features its exercises need, so every feature is learned on a real problem. A feature first appears in that day's guide and then goes into a running reference: `docs/ghidra-reference.md` and `docs/x64dbg-reference.md` (task, how to do it, shortcut, which day covers it). By Day 8 these replace the Day 1 cheat sheet.

| Day | Ghidra | x64dbg |
| --- | --- | --- |
| 1 (done) | Projects, import, auto-analysis, Listing, Decompiler, Symbol Tree, Defined Strings, references, rename, retype, comments, Function Graph, Memory Map and image base | CPU view, F2 breakpoints, stepping, registers and flags, dump and stack, string references, editing instructions, Patch File |
| 2 | Analyzer options and re-analysis, function signatures and calling conventions, switch recovery, Version Tracking (match `-O0` to `-O2`), Script Manager and a first script | Call stack, conditional breakpoints, run to user code, labels and comments, the command line and expressions |
| 3 | Data Type Manager, Structure Editor, auto-create structure, type archives (`.gdt`), C++ class and vtable recovery, RTTI analyzer | Watch view, following structures in the dump, memory breakpoints on fields |
| 4 | Program header and PE structures, sections, imports and exports, Function ID, loading PDBs, linked programs (DLL and EXE together) | Memory map, modules and symbols, breaking on DLL load, attaching to a running process, threads, TLS callbacks |
| 5 | Searching memory, scalars and instruction patterns, equates and enums, bookmarks, a constant-finding script | Hardware breakpoints, logging breakpoints (log without stopping), trace into and trace over |
| 6 | Scripts that decrypt strings and patch the listing, headless analysis with `analyzeHeadless` | ScyllaHide, exception handling and SEH, conditional tracing, x64dbg scripts |
| 7 | Importing a memory dump, overlays and manual memory blocks, data types for a file format | Finding the OEP with memory and hardware breakpoints, Scylla dump and import fixing |
| 8 | Ghidra's own debugger (optional), a full project export | Whole workflow under time pressure |

## Course plan

| Day | Theme | Practice programs (`lab/dayN/`) | Skills added |
| --- | --- | --- | --- |
| 1 | Foundations (done) | ex1 password, ex2 serial, ex3 XOR key + `IsDebuggerPresent` | Ghidra and x64dbg basics, strings and xrefs, breakpoints, flipping flags, patching |
| 2 | Optimized code and the stack | Day 1 programs at `-O2`; a menu program with a `switch`; recursion | Stack frames, calling convention in depth, jump tables, inlining, first Ghidra script (decode ex3's key) |
| 3 | Data structures | Inventory program with structs, arrays and a linked list; a small C++ class hierarchy | Struct recovery, Data Type Manager, pointers to pointers, vtables, RTTI, `std::string` |
| 4 | The PE format and the loader | Programs with exports (a DLL), TLS callbacks, delay-loaded imports, resources | PE headers, IAT, relocations and ASLR, TLS, DLL loading, `LoadLibrary`/`GetProcAddress` patterns |
| 5 | Algorithms and crypto | Keygen-mes using CRC32, a custom hash, RC4, and AES via Windows CNG | Constant hunting, recognizing crypto loops, findcrypt-style scripts, writing keygens |
| 6 | Anti-analysis | Layered anti-debug (PEB, `NtQueryInformationProcess`, timing, TLS check), encrypted strings, control-flow flattening | Bypassing each check by hand and with ScyllaHide, string-decryption scripts, untangling flattened code |
| 7 | Packing and file formats | A program packed with UPX and with a small custom packer; a program with a custom save-file format | Finding the OEP, dumping and fixing imports with Scylla, reversing a format and writing a parser |
| 8 | Capstone | One unseen program combining Days 2 to 7, plus beginner crackmes from crackmes.one in the VM | End-to-end analysis under time pressure, the write-up |

All practice programs stay benign and written for this course (see CLAUDE.md). Real-world malware is out of scope for this repo; Day 8 points students to dedicated malware-analysis courses as a next step.

## Milestones

Each day ships as one milestone. A day is done when:

- its guide is in `docs/dayN-training.md`, with an answer key
- its programs are in `lab/dayN/`, and `make` builds them
- CI builds them on Windows and checks each one with its known answers
- spoilers (keygens, decoders, solution scripts) are in `lab/solutions/`
- every tool feature it teaches is added to the Ghidra and x64dbg references
- any new tool the day needs is in the kit, installed and tested like the others

| Milestone | Delivers | Depends on |
| --- | --- | --- |
| M0: Kit and CI (in progress) | Portable kit, Windows CI, Makefile, Day 1 guide | |
| M1: Lab layout and references | `lab/day1/` folders, a top-level Makefile that builds every day, CI testing each day; the Ghidra and x64dbg references started from Day 1's features | M0 |
| M2: Day 2 | Guide, `-O2` builds, switch and recursion programs, first Ghidra script | M1 |
| M3: Day 3 | Guide, struct and C++ programs (adds `g++` builds, already in w64devkit) | M2 |
| M4: Day 4 | Guide, DLL, TLS and resource programs | M3 |
| M5: Day 5 | Guide, crypto keygen-mes, a constant-finding script | M4 |
| M6: Day 6 | Guide, anti-analysis programs; kit adds ScyllaHide | M5 |
| M7: Day 7 | Guide, packed programs, file-format program; kit adds UPX | M6 |
| M8: Day 8 | Capstone program and grading notes | M7 |

## Kit and repo backlog

Work on the kit that supports the course, in priority order. Items marked done came from the original handoff.

| Item | Needed by | Status |
| --- | --- | --- |
| Windows CI: lint, build, compile, smoke-test, re-run, relocation | M0 | In progress (headless Ghidra still failing) |
| `lab/Makefile` and `Devkit.cmd` opening in the repo's `lab` folder | M0 | Done (replaces the planned `lab/build.cmd`) |
| Version-aware updates: `data\versions.json`, `-Update`, `-Check` | M2 | Not started |
| Check the Day 1 guide's menus and shortcuts against Ghidra 12.1 and x64dbg 2026.05 | M2 | Not started |
| Lab layout per day, with CI that runs each day's answer checks | M1 | Not started |
| Check each day's Ghidra and x64dbg features against the versions the kit installs before writing that day | Each day | Not started |
| Python for Ghidra scripting (PyGhidra needs a Python install; bundle an embeddable Python, or teach Java scripts) | M2 | Decision needed |
| ScyllaHide plugin for x64dbg | M6 | Not started |
| UPX in the kit | M7 | Not started |
| Optional `-IncludeRetSync` (Ghidra and x64dbg stay in step) | Any | Not started |

## Open questions

- Pace: is eight days the right length, and is a 7-hour day right for self-study?
- Ghidra scripting: Python (needs a bundled Python) or Java (works with the kit as it is)?
- Should Day 7's custom packer be in scope, or is UPX alone enough for a beginner course?

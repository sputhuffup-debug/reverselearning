# A program in memory

This primer shows how Windows lays out a 64-bit program once it is loaded. It covers sections, the heap, the stack and DLLs. [Day 1](../day1-training.md) relies on it when you line up addresses between Ghidra and x64dbg, and [Day 3](../day3-training.md) when you look for global data. Reading time: about 20 minutes.

## From file to memory

A Windows program is stored in the **PE** (Portable Executable) format. The `.exe` file holds code, data and a header that tells Windows how to load them. The **loader** is the part of Windows that reads that header, maps the file into memory and starts it.

Each running program is a **process**, and each process gets its own **address space**. That is a private range of addresses, so two programs can both use address `0x140001000` without clashing. Everything in this primer lives inside that one address space.

Addresses are 64 bits wide but written in hex, so they look like `0x140001500` or `00007FF6A1B21500`. If hex is new to you, read [Numbers and data](01-numbers-and-data.md) first.

## The map at a glance

This is a typical layout for one of the course programs while it runs. The exact addresses change from run to run; the order and the kinds of region stay the same.

```
high addresses
  00007FFx xxxxxxxx   DLLs: ntdll.dll, kernel32.dll, msvcrt.dll ...
  00007FF6 xxxx0000   the program itself (the "image"), in sections:
                        Headers   the PE header
                        .text     code
                        .data     initialized globals
                        .rdata    read-only data and string literals
                        .bss      zeroed globals
                        .idata    imports and the IAT
  000001xx xxxxxxxx   heap: memory from malloc and calloc
  000000xx xxxxxxxx   stack of the main thread (grows down)
low addresses
```

The regions are not touching. There are large gaps between them, and reading a gap crashes the program with an access violation.

## The image and its base

The **image** is the program file as mapped into memory. The **image base** is the address of its first byte, where the PE header sits. MinGW's linker writes a preferred base of `0x140000000` into every 64-bit program it builds.

Ghidra reads the file without running it, so it uses that preferred base. That is why every address you see in Ghidra starts with `0x14000`. For example, `ex3`'s `main` starts near `0x1400014f3`.

Everything inside the image keeps the same distance from the base. That distance is the **offset**: offset = address − image base. The `main` above is at offset `0x14f3` in Ghidra, in x64dbg and on any run.

## Sections

The image is split into **sections**: named blocks that each hold one kind of content. Each section has its own permissions: readable (R), writable (W) and executable (X). A typical MinGW build has these, in this order:

| Section | Holds | Permissions | Example from `ex3` |
| --- | --- | --- | --- |
| `.text` | Machine code: your functions and MinGW's runtime | R X | `main`, `decode`, `printf` |
| `.data` | Global and static variables that start with a value | R W | `static int tries = 3;` in Day 3's `ex4` |
| `.rdata` | Read-only data: `const` globals, string literals, jump tables | R | `"License key: "`, the `secret` array |
| `.pdata`, `.xdata` | Tables that describe each function's stack frame for exception handling | R | (not used by your code directly) |
| `.bss` | Global and static variables with no starting value; Windows fills them with zeros | R W | `static char phrase[64];` in Day 3's `ex4` |
| `.idata` | The import tables, including the IAT | R W | the pointer to `IsDebuggerPresent` |
| `.CRT`, `.tls` | Small MinGW startup tables | R W | (runtime only) |
| `.reloc` | The places to fix up if the image is loaded somewhere else | R | (used by the loader) |

`.bss` takes no space in the file. The header only records its size, and the loader hands out zeroed memory for it. Ghidra marks it as uninitialized for the same reason.

## Imports and the IAT

Your program calls functions that live in DLLs, such as `IsDebuggerPresent` in `kernel32.dll`. A **DLL** (dynamic-link library) is a file of code that many programs share. The program can't know where the DLL will be loaded, so it can't hold that function's address when it is built.

Instead, `.idata` lists each DLL and the functions the program needs from it. The loader finds each function and writes its address into a table of pointers, the **IAT** (Import Address Table). The code then calls through that table:

```
MOV RAX, qword ptr [0x14000e238]   ; read the IAT slot for IsDebuggerPresent
CALL RAX                           ; call whatever address the loader put there
```

Some calls go through a small **stub** in `.text` instead, a single `jmp qword ptr [IAT slot]`. Both forms end up at the same place. [The stack and the calling convention](05-stack-and-calls.md) shows both in `ex3`'s `main`.

## The heap

The **heap** is memory the program asks for while it runs. `malloc(n)` returns a pointer to `n` bytes; `calloc` does the same and fills them with zeros; `free` gives them back. The C runtime gets this memory from Windows in large blocks and hands it out in small pieces.

Heap memory has no name in the program, only an address held in a pointer. The pointer itself is a normal variable on the stack or in `.data`. In x64dbg you find heap data by following that pointer in the dump.

## The stack

The **stack** holds local variables, saved registers and return addresses. Each **thread** (one path of execution through the program) has its own stack. The course programs have one thread, so one stack.

The stack **grows down**: each new item goes at a lower address than the last. The register RSP always points at the current top, which is its lowest address in use. The linker sets the stack's maximum size; MinGW's default is 2 MB. [The stack and the calling convention](05-stack-and-calls.md) covers it in detail.

## DLLs

Every program gets `ntdll.dll` and `kernel32.dll`, and MinGW programs also load a C runtime DLL such as `msvcrt.dll`. Each DLL is an image too, with its own header and sections. Windows maps them high in the address space, usually at addresses starting `00007FF`.

When you step into a call in x64dbg and land in one of these, you have left your program. Ctrl+F9 runs to the end of the function, and one more F8 takes you back.

## ASLR: why x64dbg's addresses differ

**ASLR** (Address Space Layout Randomization) makes Windows load each image at a random base instead of the preferred one. It is a security feature: an attacker can't guess where code is. MinGW turns it on by default, so the course programs use it.

When the image moves, the loader uses `.reloc` to fix every absolute address inside it. Offsets don't change, because the whole image moves as one block. So Ghidra shows `main` at `0x1400014f3`, while x64dbg might show it at `00007FF6A1B214F3`.

To convert, use the offset:

```
offset         = Ghidra address  - 0x140000000      0x1400014f3 - 0x140000000 = 0x14f3
x64dbg address = x64dbg base     + offset           0x7FF6A1B20000 + 0x14f3   = 0x7FF6A1B214F3
```

The base can change each time Windows loads the program, so recheck it after a restart. Day 1's Exercise 2.3 practices both this and Ghidra's Set Image Base.

## Where each kind of variable lives

Here is one small program with every kind of variable:

```c
#include <stdio.h>
#include <stdlib.h>

int counter = 7;                   // global, with a starting value
int total;                         // global, no starting value
static const int limits[] = {1, 2, 3};

int main(void) {
    static int calls = 0;          // static local
    char name[16];                 // local
    const char *msg = "hello";     // msg is local; "hello" is a string literal
    int *nums = malloc(4 * sizeof(int));  // nums is local; the 16 bytes are on the heap

    calls++;
    snprintf(name, sizeof name, "%s %d", msg, counter + total + limits[0]);
    free(nums);
    return 0;
}
```

| Variable | Kind | Where it lives | How it shows up in Ghidra |
| --- | --- | --- | --- |
| `counter` | Global, initialized | `.data` | `DAT_140008010`, holds 7 |
| `total` | Global, uninitialized | `.bss` | `DAT_14000c030`, no value in the file |
| `limits` | `const` global | `.rdata` | `DAT_...` in `.rdata` |
| `calls` | Static local, starts at 0 | `.bss` (a static that starts at 0 counts as uninitialized) | `DAT_...`, like any global |
| `name` | Local array | Stack, in `main`'s frame | `local_28`, or `[RBP + -0x20]` |
| `msg` | Local pointer | Stack (or a register at `-O2`) | `local_10` |
| `"hello"` | String literal | `.rdata` | `s_hello_14000a000` in Defined Strings |
| `*nums` | Heap block | Heap | Nothing; only the pointer `nums` exists in the code |

The addresses and offsets in the table are made up; yours will differ. A **static local** works like a global: it lives in `.data` or `.bss` and keeps its value between calls. Only the C compiler limits which code may use its name, and a stripped program has no names anyway.

## In Ghidra

- **Window → Memory Map** lists the blocks: `Headers`, then each section with its start, end and R, W, X flags. The house icon sets the image base.
- **Window → Defined Strings** lists strings, and almost all of them are in `.rdata`. Its Location column tells you where each one is.
- Labels hint at the section. `FUN_` names code in `.text`. `DAT_` and `PTR_` name data in `.data`, `.rdata` or `.bss`. `s_` names a string.
- Double-click any address in an instruction and check the section name in the Listing's left margin.

## In x64dbg

- The **Memory Map** tab lists every region of the process: the image and its sections, each DLL, the heap and the thread stacks.
- Its columns give each region's address, size and contents (the Info column). The Protection column shows `ER---` for code and `-RW--` for data.
- Right-click a region → Follow in Dump to see its bytes. The base of your program is the first row with its name.
- The **Symbols** tab lists loaded modules with their bases, which Day 1 uses to line up addresses.

## Check yourself

1. Ghidra shows a function at `0x140001a20`. x64dbg shows the program's base as `00007FF71C3D0000`. Where is the function in x64dbg?
2. Which section holds the text of `puts("Wrong code.")`?
3. A global `int score;` has no starting value. Which section is it in, and what is its value when `main` starts?
4. Why does `.bss` take no space in the `.exe` file?
5. A local `char buf[32]` in `main` and a `static char buf[32]` in `main`: where does each one live?
6. What does the loader write into the IAT, and why can't the linker write it?
7. Why do two runs of the same program in x64dbg show different addresses for `main`, but the same offset?

<details><summary>Answers</summary>

1. Offset = `0x140001a20 − 0x140000000 = 0x1a20`. In x64dbg it's `00007FF71C3D0000 + 0x1a20 = 00007FF71C3D1A20`.
2. `.rdata`. String literals are read-only data.
3. `.bss`. Windows fills `.bss` with zeros, so `score` is 0.
4. Its contents are all zeros, so there is nothing to store. The header records only its size, and the loader allocates zeroed memory.
5. The local one is on the stack, in `main`'s frame. The static one is in `.bss`, like a global.
6. The address of each imported function in its DLL. The DLL's load address isn't known until the program runs.
7. ASLR loads the image at a different base each time. The whole image moves as one block, so the distance from the base stays the same.

</details>

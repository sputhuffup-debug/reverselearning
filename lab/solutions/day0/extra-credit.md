# Day 0 extra credit: hints and expected results

SPOILERS for the challenges in [Beyond this lesson](../../../docs/day0-training.md#beyond-this-lesson). Try each challenge first.

## 1. Triage the Day 1 programs (★)

**Hints**

- Use the same commands as Module 2: `objdump -f`, `objdump -h`, `objdump -p` and `strings -n 6`, on each of `bin/day1/ex1.exe`, `ex2.exe` and `ex3.exe`.
- Compare the import lists with each other. Anything one program has and the others don't is worth a line in your notes.

**Expected results**

- All three are PE32+ console programs with the usual MinGW sections. None is packed.
- `ex1` imports `fgets`, `strcspn`, `strcmp` and `puts`; its strings include its prompt, both results, and a likely password candidate.
- `ex2` also imports `strlen` and `scanf`, and has a "Serial (hex): " prompt. Guess: the serial is a number read in hex, worked out from the name.
- `ex3` is the only one that imports `IsDebuggerPresent` from `KERNEL32.dll`, and its strings include "Debugger detected. Bye.". No string looks like a key. Guess: the key is hidden and only built at runtime.

## 2. Measure section entropy (★★)

**Hints**

- The PE header starts at the offset stored at `0x3C`. The section table follows the optional header, one 40-byte entry per section.
- Each entry starts with the name (8 bytes), the size in memory and the address. Then come the size in the file and the file offset of its data.
- Entropy of a block is −Σ p·log₂(p) over the 256 byte values, where p is each value's share of the block.

**Expected results**

A script along these lines (Python 3, standard library only):

```python
import math, struct, sys

data = open(sys.argv[1], "rb").read()
pe = struct.unpack_from("<I", data, 0x3C)[0]
count = struct.unpack_from("<H", data, pe + 6)[0]
table = pe + 24 + struct.unpack_from("<H", data, pe + 20)[0]
for i in range(count):
    name, vsize, _, rsize, roff = struct.unpack_from("<8sIIII", data, table + 40 * i)
    block = data[roff:roff + rsize]
    counts = [block.count(b) for b in range(256)]
    ent = abs(sum(c / len(block) * math.log2(c / len(block)) for c in counts if c)) if block else 0.0
    label = name.rstrip(b"\x00").decode()
    print(f"{label:8} memory {vsize:#8x}  file {rsize:#8x}  entropy {ent:.2f}")
```

For `sample.exe` built with MinGW GCC 13, `.text` is about 6.3, `.rdata` about 4.3 and `.data` below 1. `.bss` has no bytes in the file, so it prints 0. Nothing comes close to 8.

## 3. Stripped and unstripped (★★)

**Hints**

- Build the copy outside the repo: `cp day0/sample.c ~/scratch/` and then `gcc -O0 sample.c -o ~/scratch/sample_sym.exe` (no `-s`).
- Import both into the same Ghidra project and compare their Symbol Trees and Defined Strings.

**Expected results**

- The unstripped copy shows `main` and many runtime functions by name, such as `__main` and `printf`. The stripped one shows `FUN_` names.
- Imports, strings, sections and the code of `main` are the same in both. Triage did not need the names.
- `strings -n 6` on the unstripped copy also shows symbol names, such as `main`, near the end of the output.

## 4. Swap blind programs (★★★)

**Hints**

- Keep it to one input check and about 30 lines. Use one of today's ideas, such as a number compared with a constant, or a `key=value` line.
- Keep it benign: no file, network or registry access. Build it with `gcc -O0 -s` and give your partner only the `.exe`.
- Grade your partner's notes against the template: is every claim marked known or guessed, and does each known claim say how it was checked?

**Expected results**

- Your partner's answer, shown by one run, and a filled-in notes file with at least two hypotheses and their tests.
- A sentence on which triage step gave the most away. For small programs it is usually strings or imports.

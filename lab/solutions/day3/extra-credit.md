# Day 3 extra credit: hints and expected results

SPOILERS for the challenges in [Beyond this lesson](../../../docs/day3-training.md#beyond-this-lesson). Try each challenge first, then read the hint, and only then the expected result.

The expected results were checked with MinGW-w64 GCC 13 at the flags given. The kit's w64devkit may ship a newer GCC, so registers, offsets, the order of blocks and sometimes the exact shape can differ. If yours differs, describe what you see and why; that is the point of the exercise.

Build every copy in a folder of your own, outside the repo, with the Makefile's flags:

```bash
gcc -O0 -s -Wall ex1_sparse.c -o ex1_sparse.exe
```

## 1. The table that disappears (★)

**Hint.** Search the Listing for `switchD` and for a `jmp` through a register. If neither is there, look for a run of `cmp eax, <constant>` with a `je` after each one. GCC decides per switch, so try more than one layout.

**Expected result.**

- With every label far apart, for example 10, 200, 3000, 40, 500, 6000, 77, 800 and 9999 for cases 1 to 9, the table is gone. There is no `switchD`, no `switchdataD` and no indirect `jmp`.
- In its place is a small search tree. GCC tests the largest value first: `cmp eax, 0x270f` (9999), `je`, then the same `cmp` with `jg` to the default, then the next value down. The last few values get a plain `cmp` and `je`. Our build used about 20 compares for 10 cases.
- Case 0 is tested near the end of the chain, with `test eax, eax` and `je`.
- The decompiler still shows a `switch` or a chain of `if`s; it rebuilds the C either way.
- With only one label moved, for example case 9 to 90 or to 200, GCC 13 kept a table for cases 0 to 8 (9 entries) and tested the moved case with its own compare. The code checks `cmp eax, 8` and `jg` to that compare first, then `js` and `ja` to the default, then the table.
- The rule of thumb: when most entries of a table would point to `default`, GCC compares instead. The exact threshold depends on the GCC version.
- The vault still opens, with the new labels in the old order. With the labels above, that is `40`, `10`, `6000`, `3000`, `77`.

## 2. Moving the word table (★)

**Hint.** Open the Memory Map in both builds and look up the address of each `DAT_` label. The Listing's left margin also names the section.

**Expected result.**

| Global | Original `ex4` | With `const` added |
| --- | --- | --- |
| `words` (8 pointers) | `.data` | `.rdata` |
| `order` (4 ints) | `.data` | `.rdata` |
| The word strings | `.rdata` | `.rdata` |
| `tries` | `.data` | `.data` |
| `phrase` | `.bss` | `.bss` |

- The code that reads the tables is the same: RIP-relative `lea` and `mov` with scales of 4 and 8. Only the target addresses change.
- `const char *words[]` makes the strings constant but not the table. The second `const` in `const char *const words[]` makes the table itself constant.
- The pointers in `.rdata` still need fixing up when ASLR moves the program. The loader does this through `.reloc`, before the program runs.
- The passphrase is unchanged: `meadow-falcon-tundra-amber`.

## 3. ex1 at -O2 (★★)

**Hint.** The range check and the indirect `jmp` are still close together, but the table's address may be loaded much earlier, before the menu loop starts. Look for a `lea` of a `.rdata` address into a register that survives calls (RBX, RSI, RDI, R12 to R15).

**Expected result.**

- The jump table is still there, with 10 entries for cases 0 to 9.
- The range check reads the option from the stack, because `sscanf` writes it through a pointer: `cmp dword ptr [rsp+0x2c], 9` and `ja` to the default.
- In our build, `lea rsi, [table]` sits in `main`'s prologue, once, before the loop. The lookup is then `movsx rax, dword ptr [rsi+rax*4]`, `add rax, rsi`, `jmp rax`. Day 2's "values kept in registers" in action.
- Ghidra should still recover the switch and name the cases; check this on Windows. If it doesn't, read the table by hand as in Module 1A.
- The case bodies lose their `if`s. `stage = (stage == 2) ? 3 : 0` becomes `cmp`, `sete al` and `lea eax, [rax+rax*2]`: a 0 or 1 times 3. The other cases use `add eax, eax` (times 2) and `sal eax, 2` (times 4) the same way.
- `main` may sit in a section called `.text.startup` in the object file; in the `.exe` it is part of `.text`.
- The vault answer is unchanged: `4`, `1`, `6`, `3`, `7`.

## 4. Recursion versus a loop (★★)

**Hint.** Keep the two previous values in two variables and move them along on each step. The Python in [solve\_day3.py](solve_day3.py) does exactly this.

**Expected result.** One way to write it:

```c
static unsigned long long weave(int n) {
    unsigned long long a = 2, b = 3;     /* weave(0), weave(1) */
    if (n < 2) return (unsigned long long)n + 2;
    for (int k = 2; k <= n; k++) {
        unsigned long long c = a + b + k;
        a = b;
        b = c;
    }
    return b;
}
```

- Level `19` is still the one that matches `0xA4B5`.
- Function Call Trees no longer list `weave` among its own outgoing calls; it calls nothing.
- The new `weave` is called once per level, where the recursive one makes 177 calls for level 10 (challenge 7's stretch goal). For level 30 the recursive version makes 2,692,537 calls.
- At `-O0` the `for` loop has the usual shape: counter set, `jmp` forward to the test, body, `add` to the counter, `cmp` and `jle` back up.
- The base case is now a test before the loop, not a test at the top of each call.

## 5. ex2 from x64dbg alone (★★★)

**Hint.** Find "Wrong code." in the string references; the `call` just above the `test eax, eax` before it is `check`. In graph view, each loop is a block with an arrow back up. Put a breakpoint on the instruction just after the second loop's back edge: by then the expected array is built and reversed.

**Expected result.**

- A command such as `bpcnd <address>, dl != al` on the compare in the third loop works as in Exercise 2.2. Any address works with `bp`, then `bpcnd` to add the condition.
- With a breakpoint after the second loop, one `dump` of the array's address, such as `dump rbp-0x16` in our build, shows all eight digits in the text column of the dump before any compare runs.
- So one run with one wrong guess is enough. The door code is `11389730`.
- If the dump shows `03798311`, the breakpoint is between the first and second loops: those are the digits before they are reversed.

## 6. Where did the recursion go? (★★★)

**Hint.** Count the `call` instructions in `weave` whose target is `weave` itself, and look at the registers saved with `push` at the start. Then look for back edges: loops that weren't in the source.

**Expected result.**

- At `-O2`, GCC 13 left only one self-call in `weave`. It turned the rest of the recursion into loops and unrolled them, so the function grew from about 25 instructions to about 380.
- It saves eight registers (R15, R14, R13, R12, RBP, RDI, RSI, RBX) and reserves a large frame. That is the sign of a function doing a lot of work in registers.
- `main` still calls `weave` once, and the answer is unchanged: level `19`.
- The decompiler's version is long and hard to match to the three lines of C. This is why Day 2 recommends finding the same function at `-O0` first and comparing.
- A newer GCC may keep both calls, keep neither, or unroll differently. Whatever you get, the base case (`n < 2` returning `n + 2`) should still be visible near the start.

## 7. See the recursion in both tools (★)

**Hint.** Count the calls for small levels first: level 1 makes 1 call, level 2 makes 3. For the stops with `ecx == 1`, count how many times `weave(1)` appears in the call tree for level 5.

**Expected result.**

- Function Call Trees shows `weave` among its own outgoing calls, and it can be expanded without end. Its only incoming call is from `main`.
- `main` calls `printf`, `scanf`, `puts` and `weave`. It also calls MinGW's `__main` helper, which may show as a `FUN_` name.
- `weave(1)` returns 3 (`n + 2`), in RAX after Ctrl+F9.
- With level 5 the breakpoint stops 5 times. `weave(1)` is reached once for each path down the tree that ends at 1. For levels 1 to 5 that is 1, 1, 2, 3 and 5 times: the Fibonacci numbers.
- The stretch goal: calls for level `n` = calls for `n-1` + calls for `n-2` + 1, so level 10 makes 177 calls. The hit count in the Breakpoints tab is 177.

## 8. Read ex4's globals at runtime (★)

**Hint.** Each table entry is 8 bytes, because it is a pointer. The word-compare function calls `strcmp(token, expected)`, so the arguments are in that order.

**Expected result.**

- RCX holds the current word from your input (`aaa` on the first stop). RDX holds the expected word, `meadow` for the first one.
- `[address+8*5]` reads entry 5 of `words`, the pointer to `meadow`. `dump` with that pointer shows the text. Reading an entry of `order` needs `dword:[address]`, because those entries are 4 bytes.
- With a wrong first word the breakpoint stops once per try, three times in all, before "Locked out.".
- The passphrase is unchanged: `meadow-falcon-tundra-amber`.

## 9. ex5 without wide strings (★★)

**Hint.** Compare the code builder in the two builds instruction by instruction. Look at the size keyword on each memory operand, and at how the index is turned into an offset.

**Expected result.** With MinGW-w64 GCC 13 at `-O0 -s -Wall`:

| | `ex5` (wide) | Narrow copy |
| --- | --- | --- |
| Strings in Defined Strings | Names and "Badge reader started." are `unicode`, shown as `u"..."`; the messages printed by `puts` stay plain | All plain strings |
| Reading a name character | `movzx eax, word ptr [rax]`, then `movzx eax, ax` | `movzx eax, byte ptr [rax]`, then `movsx eax, al` (plain `char` is signed) |
| Index to offset | `lea rdx, [rax+rax]`: index times 2 | The index is added as it is |
| Storing a code character | `mov word ptr [rax], dx` | `mov byte ptr [rax], dl` |
| The terminator | `mov word ptr [rax], 0` | `mov byte ptr [rax], 0` |
| Imports | `wcscmp`, `wcslen`, `__wgetmainargs`, `OutputDebugStringW` | `strcmp`, `strlen`, `__getmainargs`, `OutputDebugStringA` |
| The code buffer on the stack | 32 bytes (16 `wchar_t`) | 16 bytes |

- The arithmetic is the same in both. `sub eax, 0x5e` comes first; `0x5e` is `'a' - 3` folded into one constant. Then the magic number `0x4EC4EC4F` divides by 26, `imul` by `0x1a` and `sub` make the `%`, and `lea` with `+0x41` adds `'A'`.
- The narrow `main` starts with a `call` to MinGW's `__main` helper, as every course program has so far. GCC adds that call only to a function named `main`, so the wide build's `wmain` has none. MinGW's startup code calls `__main` as well, and the helper does its work only once, so nothing is lost.
- The right answers don't change: `grace JUDFH` and `barbara EDUEDUD`.

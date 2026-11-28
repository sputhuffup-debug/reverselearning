# Day 4 extra credit: hints and expected results

SPOILERS for the challenges in [Beyond this lesson](../../../docs/day4-training.md#beyond-this-lesson). This file also repeats Day 4's answers, so finish the day first.

Offsets are for Windows x64 with MinGW-w64 GCC. Instruction choices and registers can differ with your GCC version; offsets and sizes don't. The full Day 4 layouts are in [structs.h](structs.h).

Build every modified copy outside the repo, as the guide says. Use `(int)sizeof(...)` with `%d` when you print sizes; it works with every C runtime the kit might use.

## Challenge 1: Squeeze the padding out (★)

**Hints**

- Add up the field sizes first, with no padding. Then round up to a multiple of the largest alignment. No ordering can beat that number.
- You don't need the whole program to test an order. A small file with only the struct and a `main` that prints `sizeof` and `offsetof` is enough.
- If you reorder the fields in the full program, reorder the values in each row of the table too. Designated initializers (`.id = 1001, .stock = 40, ...`) avoid the problem.

**Expected results**

| Struct | Sum of field sizes | Largest alignment | Smallest possible size | Today's size |
| --- | --- | --- | --- | --- |
| `item` | 4 + 2 + 10 + 1 + 2 + 4 + 8 + 2 = 33 | 8 (the `alt` pointer) | 40 (0x28) | 0x28 |
| `node` | 2 + 1 + 4 + 8 + 5 = 20 | 8 (the `next` pointer) | 24 (0x18) | 0x18 |

Neither struct can get smaller by reordering. Both already waste only the bytes that rounding forces: 7 in `item` and 4 in `node`. Their padding just sits in different places depending on the order.

The one-field change: `bin` only ever holds a letter from `'A'` to `'K'`, so it can be a `char`. The data is then 32 bytes, a multiple of 8. An order with no gaps reaches 32 (0x20), for example:

```c
struct item {               /* 0x20 (32) */
    struct item *alt;       /* 0x00 */
    int   id;               /* 0x08 */
    int   price;            /* 0x0c */
    short stock;            /* 0x10 */
    short reorder;          /* 0x12 */
    char  name[10];         /* 0x14 */
    unsigned char flags;    /* 0x1e */
    char  bin;              /* 0x1f */
};
```

Largest-first ordering (8-byte fields, then 4, then 2, then 1) is a reliable rule of thumb. It always leaves padding only at the end.

## Challenge 2: Add a field and watch the offsets move (★★)

**Hints**

- `int weight` needs a multiple of 4. `flags` ends at 0x11, so the next multiple of 4 is 0x14.
- Every field after `weight` moves, but not all by the same amount. Recompute each one with the primer's method rather than adding a constant.
- At `-O0` the new stride shows up as "times 3, then shift left by 4" in `find_item`.

**Expected results**

| Field | Original offset | With `weight` |
| --- | --- | --- |
| `id` | 0x00 | 0x00 |
| `stock` | 0x04 | 0x04 |
| `name` | 0x06 | 0x06 |
| `flags` | 0x10 | 0x10 |
| padding | 0x11 | 0x11–0x13 |
| `weight` | | 0x14 |
| `reorder` | 0x12 | 0x18 |
| `price` | 0x14 | 0x1c |
| `alt` | 0x18 | 0x20 |
| `bin` | 0x20 | 0x28 |
| tail padding | 0x22–0x27 | 0x2a–0x2f |
| size (stride) | 0x28 | 0x30 |

In `main`, the reads of `stock`, `name` and `flags` keep their offsets (4, 6 and 0x10). The `alt` read moves from 0x18 to 0x20, and `bin` from 0x20 to 0x28.

With the old `item` applied, the first element looks half right: `id`, `stock`, `name` and `flags` are fine, but `alt` now covers `reorder` and `price` and shows a nonsense pointer. Each later element starts 8 bytes further from where the old type expects, so by the second element even `id` is wrong. This is the drift described in "When the types look wrong".

Part `4417` with quantity `12` is still accepted. Only the layout changed, not the data or the check.

## Challenge 3: Walk the list from the command line (★★)

**Hints**

- Don't change RCX to move along the list. The program is paused on the call to `matches`, and RCX is the argument it is about to pass.
- Keep the current node in a variable of your own instead. x64dbg's `var` command creates one, and `mov` sets it, for example `var node` then `mov $node, rcx`.
- The `log` command writes formatted text to the Log tab. `{x:expr}` prints an expression in hex and `{d:expr}` in decimal.
- Mask a narrow field out of an 8-byte read: `[$node]&FFFF` is the key, `[$node+2]&FF` the letter. Numbers in x64dbg commands are hex by default.

**A command sequence that works**

Type these one at a time in the Command box. Repeat the last two until `$node` is 0.

```text
var node
mov $node, rcx
log "node {p:$node}  key {x:[$node]&FFFF}  letter {x:[$node+2]&FF}"
mov $node, [$node+8]
```

The same lines work as an x64dbg script with a loop. Day 9 covers scripts properly; this is a preview:

```text
var node
mov $node, rcx
next_node:
log "node {p:$node}  key {x:[$node]&FFFF}  letter {x:[$node+2]&FF}"
mov $node, [$node+8]
cmp $node, 0
jne next_node
ret
```

**Expected results**

The Log tab shows 13 lines. Keys and letters, in list order:

| Key (hex) | Key (decimal) | Letter (hex) | Letter |
| --- | --- | --- | --- |
| 0x78 | 120 | 0x57 | W |
| 0xa8 | 168 | 0x34 | 4 |
| 0xc0 | 192 | 0x4c | L |
| 0xcd | 205 | 0x4b | K |
| 0x102 | 258 | 0x2d | - |
| 0x155 | 341 | 0x54 | T |
| 0x18c | 396 | 0x48 | H |
| 0x19a | 410 | 0x33 | 3 |
| 0x1f9 | 505 | 0x2d | - |
| 0x1ff | 511 | 0x4c | L |
| 0x24e | 590 | 0x31 | 1 |
| 0x296 | 662 | 0x53 | S |
| 0x346 | 838 | 0x54 | T |

The letters spell `W4LK-TH3-L1ST`, the pick code from the answer key. The node addresses are heap addresses and change on every run.

## Challenge 4: Make the list doubly linked (★★★)

**Hints**

- Setting `prev` inside `insert` is awkward, because `insert` holds a `node **`, not the previous node. A second pass after the build loop is simpler:

  ```c
  struct node *prev = NULL;
  for (struct node *n = head; n; n = n->next) { n->prev = prev; prev = n; }
  ```

- Recover the new layout the same way as Exercise 2.2: the `calloc` size first, then auto-create on `insert`'s parameter, then the fields `main` writes.
- `prev` is easy to confuse with `next` in Ghidra. The field `insert` and `matches` follow is `next`; the field only your new loop writes is `prev`.

**Expected results**

| Field | Original offset | With `prev` |
| --- | --- | --- |
| `key` | 0x00 | 0x00 |
| `letter` | 0x02 | 0x02 |
| `weight` | 0x04 | 0x04 |
| `next` | 0x08 | 0x08 |
| `prev` | | 0x10 |
| `tag` | 0x10 | 0x18 |
| tail padding | 0x15–0x17 | 0x1d–0x1f |
| size (`calloc`) | 0x18 | 0x20 |

The `calloc` call now asks for 0x20 (32) bytes. In x64dbg, follow `[node+8]` from the head 12 times to reach the last node, whose `next` is 0. Then follow `[node+0x10]` back; the head's `prev` is 0.

Read backwards, the letters are `TS1L-3HT-K4LW`. The program still accepts `W4LK-TH3-L1ST`, because `matches` only follows `next`.

## Challenge 5: One archive for the whole day, applied to -O2 builds (★★★)

**Hints**

- Drag `node` and `arrival` from `ex2.exe` onto `day4`, as you did with `item`, then save the archive.
- At `-O2`, GCC inlines small `static` functions that are called once. Expect `find_item`, `insert`, `matches` and `worst_shortfall` to be gone, with their loops inside `main`.
- With no helper to retype, apply the types where the data is: `item` as an array on the catalog, `item *` as an array on the shelf, `arrival` as an array on the table. Then retype the variables in `main`'s decompiled code.
- Optimized loops often walk a pointer instead of an index. The stride is then the constant added to the pointer each time round, and the loop ends at a fixed address after the array.

**Expected results**

These are from GCC 13-era MinGW-w64 at `-O2`. Your build may differ in detail.

- `ex1_o2.exe`: `find_item` is inlined. `read_int` usually survives as its own function. The catalog loop adds 0x28 to a pointer and stops at the catalog's start plus 0x140 (8 × 0x28). `main` reads `word [reg+4]`, `byte [reg+0x10]`, `qword [reg+0x18]` and `word [reg+0x20]` straight from that pointer.
- `ex2_o2.exe`: `insert` and `matches` are inlined into `main`, sometimes more than once. The `calloc` size is still 0x18 and `next` is still read at offset 8.
- `ex3_o2.exe`: `worst_shortfall` is inlined and runs before the first prompt. The shelf loop adds 8 to a pointer and stops at the shelf's start plus 0x30 (6 × 8). Each element is loaded with a `qword` read and then used as a base for `word [reg+0x12]`, `word [reg+4]` and `byte [reg+0x10]`. GCC may use `cmov` instead of a branch to keep the best gap.
- Each `-O2` build accepts the same answer as its `-O0` build: `4417` and `12`, `W4LK-TH3-L1ST`, and `7002` and `13`.

**Checking the archive against structs.h.** File → Parse C Source can read `structs.h`, as its header comment says. Parse it into a new archive, not into `day4.gdt`, so you can compare the two side by side. Field names may differ; offsets, sizes and types should match. Your `node.tag` may be any size from 4 to 8 and still be right.

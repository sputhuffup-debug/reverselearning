# Day 4 checkpoint: answer and model write-up

SPOILERS for the [Day 4 checkpoint](../../../docs/day4-training.md#checkpoint). Finish your own notes before you read this.

Offsets are for Windows x64 with MinGW-w64 GCC at `-O0`. Registers and stack slots can differ with your GCC version; offsets, sizes and the answer don't.

## Answer

| Prompt | Answer |
| --- | --- |
| Lead crate | `1211` |
| Load weight | `132` |

The program prints `Truck sealed: vases first.` and exits with 0.

## The recovered struct

`checkpoint.exe` keeps 11 crate records in `.data`. Each record is 0x20 (32) bytes: the loops index it with `sal rax, 5`, which is times 32.

```c
enum route { ROUTE_NORTH, ROUTE_SOUTH, ROUTE_EAST, ROUTE_WEST };   /* 4 bytes; main asks for 2 */

#define CRATE_URGENT   0x01
#define CRATE_FRAGILE  0x02
#define CRATE_HELD     0x04
#define CRATE_COLD     0x08     /* set on one crate; no code tests it */
#define CRATE_CLEARED  0x40

struct crate {                  /* size 0x20 (32) */
    unsigned short id;          /* 0x00  1201 to 1211 */
    unsigned char  flags;       /* 0x02  CRATE_* bits */
    char           bay;         /* 0x03  a letter, 'A' to 'D'; no code reads it */
    enum route     route;       /* 0x04 */
    int            weight;      /* 0x08  compared with 30 (signed: jle) */
                                /* 0x0c  4 bytes of padding: next must be 8-aligned */
    struct crate  *next;        /* 0x10  NULL in the file; set at runtime */
    char           label[8];    /* 0x18  printed with %s */
};
```

Your names can differ. Your offsets, sizes and the stride should match. `label` may be 7 or 8 bytes: the longest label, "mirror", needs 7 with its terminator, and the struct ends at 0x20.

The names of the flag bits are guesses from how the code uses them. What matters is the value of each bit and what the code does with it.

## How the program decides

1. **`inspect(yard, 11)`** goes over every record once. A crate with bit 0x02 and a weight above 30 gets bit 0x04 set (`or edx, 4`). Then a crate with bit 0x40 has bit 0x04 cleared (`and edx, -5`, which is `0xfffffffb`, `~4`).
2. **`load_truck(yard, 11, 2)`** keeps the crates whose flags give 1 after `and eax, 5`: bit 0x01 set and bit 0x04 clear. It also needs `route` equal to its third argument, 2.
   Each crate it keeps goes in at the front: `c->next = head; head = c`. So the list runs in the reverse of the table order.
3. **`main`** walks the list from its head, counts the crates and adds up `weight`. It prints the count, then compares your two numbers with `head->id` and the total.

## Working the data

| id | flags in the file | after `inspect` | route | weight | On the truck? |
| --- | --- | --- | --- | --- | --- |
| 1201 | 0x01 | 0x01 | 2 | 12 | yes |
| 1202 | 0x03 | 0x07 (heavy and fragile: held) | 2 | 35 | no, held |
| 1203 | 0x01 | 0x01 | 0 | 20 | no, wrong route |
| 1204 | 0x43 | 0x43 (held, then cleared) | 2 | 41 | yes |
| 1205 | 0x04 | 0x04 | 2 | 8 | no, not urgent |
| 1206 | 0x05 | 0x05 | 2 | 16 | no, held |
| 1207 | 0x09 | 0x09 | 2 | 22 | yes |
| 1208 | 0x00 | 0x00 | 2 | 5 | no, not urgent |
| 1209 | 0x45 | 0x41 (cleared) | 2 | 27 | yes |
| 1210 | 0x03 | 0x03 | 3 | 18 | no, wrong route |
| 1211 | 0x03 | 0x03 (30 is not above 30) | 2 | 30 | yes |

The truck carries 5 crates, which matches the count the program prints. In list order they are 1211, 1209, 1207, 1204 and 1201, so the head is `1211`. The weights add up to 12 + 41 + 22 + 27 + 30 = `132`.

## Common wrong answers

| Answer | The mistake |
| --- | --- |
| `1201`, 132 | Taking the first crate in the table. The list is built by inserting at the front, so the last match is the head. |
| `1211`, 64 | Skipping the clear in `inspect`. Then 1204 and 1209 stay held, and the truck has 3 crates, not 5. |
| `1211`, 167 | Missing the hold for heavy fragile crates, so 1202 goes on the truck. |
| `1209`, 102 | Reading `weight > 30` as `>= 30`, so 1211 is held. The `jle` jumps past the hold when the weight is 30 or less. |

The printed crate count catches most of these before you enter anything.

## A model write-up

This is the kind of note the [analysis notes template](../../../docs/templates/analysis-notes.md) asks for. Yours can be shorter.

> **Question.** What lead crate and load weight does `checkpoint.exe` accept?
>
> **Where I started.** "Seal rejected." in Defined Strings led to `main`. Before the prompts, `main` calls two functions. I named them `inspect` (a `.data` address and 11) and `load_truck` (the same address, 11 and 2).
>
> **The record.** Both helpers index the array with `sal rax, 5`, so each record is 0x20 bytes. The accesses, by offset:
>
> - `+0x00`, `word`: compared with my lead crate.
> - `+0x02`, `byte`: masked with `&`, changed with `or` and `and`.
> - `+0x04`, `dword`: compared with 2.
> - `+0x08`, `dword`: compared with 30, and added up in `main`.
> - `+0x10`, `qword`: written with a pointer, and followed in `main`'s loop.
> - `+0x18`: printed with `%s`.
>
> I built `crate` in Ghidra and applied it as `crate[11]` on the table. Every label then showed as text, and every `next` was 0.
>
> **The flags.** `inspect` sets 0x04 when 0x02 is set and the weight is over 30, then clears 0x04 when 0x40 is set. `load_truck` keeps a record when `flags & 5` is 1 and the route is 2. I made an enum `crate_flags` (1 byte) and a `route` enum (4 bytes) and applied them to the two fields.
>
> **The list.** `load_truck` writes the old head into the record's `+0x10`, then makes the record the new head. That is insertion at the front, so the list is in reverse table order.
>
> **Prediction.** Five crates qualify: 1201, 1204, 1207, 1209 and 1211. The head is 1211, and the weights total 132.
>
> **Check.** In x64dbg I broke after `load_truck` returned and followed RAX through `[rax+0x10]` five times to a null pointer. The ids came out 1211, 1209, 1207, 1204, 1201. The program printed "5 crates loaded" and accepted `1211` and `132`.
>
> **Open questions.** The byte at +3 is a letter that nothing reads. Bit 0x08 is set on crate 1207 but never tested.

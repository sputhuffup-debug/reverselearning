# Day 4: Data Structures

Nov 27, 2026

## Overview

Day 4 follows Day 3. Until now you have read code that works on single values. Today you read code that works on records: structs, arrays of structs, and a linked list built at runtime. You will rebuild each record as a type in Ghidra and share one type between two programs. Then you follow the same records through memory in x64dbg.

**Goals for the day**

1. Work out a struct's field offsets, sizes and padding from the code that uses it.
2. Tell an array of values, a struct, and an array of structs apart in disassembly.
3. Build structures in Ghidra by hand and with auto-create, then apply them to code and data.
4. Read pointers to pointers: a list head passed by address, and an array of pointers.
5. Save a type to a type archive (`.gdt`) and apply it in a second program.
6. Watch struct fields in x64dbg and follow a struct and a linked list in the dump.

**What you need**

- The portable kit built by `Build-PortableRE.ps1`, as on Day 1.
- The course repo. Its `lab/day4` folder holds today's three practice programs.
- Day 1's skills: finding `main` from strings, renaming, retyping, breakpoints, and lining up addresses in both tools.

**Lab rules**

The Day 1 rules still apply. Work in a VM with a snapshot, analyze only the practice programs, and keep notes. Today your notes should include a sketch of every struct you recover: offset, size, type and name of each field.

## Schedule

The day runs about 7 hours with breaks, and roughly half of it is hands-on exercise time.

| Time | Block | What you do |
| --- | --- | --- |
| 0:00–0:20 | Module 0: Setup | Build the three practice programs and run each once |
| 0:20–1:00 | Module 1: Structs in memory | Offsets, alignment, padding, arrays of structs, pointers to pointers; Exercise 1.1 on paper |
| 1:00–1:30 | Module 2A: Ghidra's type tools | Data Type Manager, Structure Editor, auto-create, type archives |
| 1:30–2:15 | Exercise 2.1 | Build `ex1`'s part record by hand and apply it |
| 2:15–2:30 | Break |  |
| 2:30–3:15 | Exercise 2.2 | Auto-create `ex2`'s list node and type the list head |
| 3:15–3:45 | Module 3A: Structs in x64dbg | The watch view, expressions, following pointers in the dump |
| 3:45–4:30 | Exercise 3.1–3.2 | Watch `ex1`'s fields; walk `ex2`'s list in the dump |
| 4:30–5:15 | Lunch |  |
| 5:15–6:30 | Module 4: Capstone | Share the part record with `ex3` through a `.gdt` archive and solve it |
| 6:30–6:50 | Review | Go over the answer key and compare your structs with the solution |
| 6:50–7:00 | Wrap-up | Reference updates and the plan for Day 5 |

## Module 0: Build the practice programs (20 min)

Today's programs model a small parts warehouse. Their sources are in the repo's `lab/day4` folder and linked below. As on Day 1, don't reread a source once it's compiled.

[**ex1\_inventory.c**](../lab/day4/ex1_inventory.c): a parts catalog stored as an array of structs, and an order check

[**ex2\_picklist.c**](../lab/day4/ex2_picklist.c): a linked list built at runtime, whose nodes spell out a pick code

[**ex3\_restock.c**](../lab/day4/ex3_restock.c): a second warehouse that uses the same part record as `ex1`, reached through an array of pointers

**Compile** with `make`. Open `RE-Portable\Devkit.cmd`; its shell starts in the repo's `lab` folder. Then run:

```bash
make day4     # builds bin/day4/ex1.exe, ex2.exe and ex3.exe
```

The executables go into `bin/day4`. The build uses `-O0 -s` as on Day 1, so the code stays close to the source and the names are gone.

Run each program once with a wrong answer. `ex1` and `ex3` ask for a part number and a quantity; `ex2` asks for a pick code. Then close the `.c` files.

## Module 1: Structs in memory (40 min)

A struct is a block of memory with its fields at fixed offsets. The compiler turns `p->field` into "read the right number of bytes at `p` plus a constant". Recovering a struct means collecting those constants and sizes.

1. **Field access.** `mov eax, dword ptr [rcx+0x14]` reads 4 bytes at offset `0x14`. `movzx eax, word ptr [rcx+4]` reads 2 bytes at offset 4. The size of the read tells you the size of the field.
2. **Alignment.** On Windows x64, each field starts at a multiple of its own size: 2 for `short`, 4 for `int`, 8 for a pointer. `char` and `char` arrays can start anywhere.
3. **Padding.** When the next field needs alignment, the compiler leaves unused bytes. A struct's total size is also rounded up to a multiple of its largest field, so the next array entry is aligned too.
4. **Arrays of structs.** `base + i * 0x28 + 0x10` reads the field at offset `0x10` of entry `i`, in an array of `0x28`-byte elements. The multiplier is the struct's size, padding included.
5. **Arrays versus structs.** Equal-sized reads at `base + i * size` are an array. Reads of different sizes at fixed offsets from one pointer are a struct. Both together are an array of structs.
6. **Pointers to pointers.** A function that changes the caller's pointer gets that pointer's address, so its parameter is `T **`. An array of pointers looks the same: 8-byte addresses that each lead to a struct.
7. **Sizes on Windows.** Windows x64 is LLP64: `int` and `long` are both 4 bytes, pointers are 8. Linux x86-64 makes `long` 8 bytes, so structs with `long` differ between the two. Today's programs avoid `long`.

### Exercise 1.1: Lay out a struct on paper (10 min)

Work out the offset of each field and the total size on Windows x64. Mark every padding byte.

```c
struct sample {
    char  tag;
    int   count;
    short kind;
    char *label;
};
```

Then reorder the fields to make the struct as small as possible, and give its new size.

## Module 2: Recovering structs in Ghidra (2 h)

### 2A. Tour of the type tools (30 min)

1. **Data Type Manager.** Open it with Window → Data Type Manager; it usually sits at the bottom left of the CodeBrowser. It lists archives: one named after your program, `BuiltInTypes`, and any Windows or C library archives Ghidra opened during analysis.
2. **The program's archive.** Types you create go into the archive named after the program, such as `ex1.exe`. They are saved with the program.
3. **Structure Editor.** Right-click the program's archive → New → Structure. The editor shows one row per field: offset, length, data type, name and comment. Double-click a Data Type cell and type a type name, such as `int`, `short`, `char[10]` or `item *`.
4. **Size and padding.** Set the structure's size at the bottom of the editor. Bytes you don't assign stay `undefined`; that is how padding shows up. The editor can also pack the structure for you, adding padding the way the compiler does.
5. **Applying a type.** In the Decompiler, select a variable and press Ctrl+L to retype it, for example as `item *`. In the Listing, put the cursor on data and press `T` to choose a data type, then `[` to turn it into an array.
6. **Auto-create.** In the Decompiler, right-click a pointer variable → Auto Create Structure. Ghidra builds a structure from every offset the function reads or writes through that pointer. Fields get names like `field_0x8`; you rename and fix them.
7. **Type archives.** A `.gdt` file is an archive outside any program. The arrow menu at the top right of the Data Type Manager creates one (New File Archive) or opens one (Open File Archive). Any program can then use its types.

### Exercise 2.1: Build ex1's part record by hand (45 min)

1. Import and analyze `ex1.exe`. Find `main` from the "Order refused." string and rename it.
2. Find the function `main` calls with an address, a count and your part number. Rename it `find_item`.
3. Read its loop. Note the multiplier on the index and the size of the value it compares with your number. That multiplier is the size of one record.
4. Back in `main`, list every offset read through the pointer `find_item` returns. Note the size of each read and how the value is used. It may be compared, printed with `%s` or `%c`, masked with `&`, or followed as a pointer.
5. In the Data Type Manager, right-click `ex1.exe` → New → Structure. Name it `item` and set its size to the stride from step 3.
6. Add a row at each offset you found, with the matching type: `int`, `short`, `byte`, a `char` array, or `item *`. Name each field after how it's used. Leave the gaps `undefined` for now; some are padding and some are fields `ex1` never reads.
7. Retype `find_item`'s first parameter and `main`'s result variable as `item *` (Ctrl+L). The decompiler should now read like `it->stock`.
8. Double-click the address `main` passes to `find_item` to reach the catalog. Press `T`, choose `item`, then press `[` and make it an array with the count from step 2.
9. Read the catalog in the Listing. Find the one part whose flags pass the check in `main`, and the quantity the check expects.
   Look at the undefined bytes too. Values that change between entries are unread fields; bytes that are always zero are likely padding.
10. Run `ex1.exe` with that part number and quantity.

**Write down:** the struct's size, each field's offset and type, where the padding is, and the answer.

**Stretch goal:** Open the editor's packing option and compare the offsets Ghidra computes with your own.

### Exercise 2.2: Auto-create ex2's list node (45 min)

1. Import and analyze `ex2.exe`. Find `main` from "Wrong pick code." and rename it.
2. Find the loop that calls `calloc`. Note the size it asks for. Rename the function called with the new block as its second argument `insert`.
3. Open `insert`. Right-click its second parameter → Auto Create Structure. Find the new structure in the Data Type Manager under `ex2.exe` and rename it `node`.
4. Open `node` in the Structure Editor (double-click it). Set its size to the `calloc` size. Give the fields Ghidra found real names and types; the pointer at offset 8 is `node *next`.
5. Back in `main`, retype the `calloc` result as `node *`. Add the fields `main` writes that `insert` never touches: a `char`, an `int`, and a `char` array that `main` fills with a short string.
6. Retype `insert`'s first parameter as `node **`. Read the loop again and explain in your notes why the loop variable is a `node **` too.
7. Find the function `main` calls with the list head and your input. Rename it `matches` and work out what it compares at each step.

**Write down:** the node layout with offsets, what `insert` keeps the list sorted by, and how `matches` decides.

**Stretch goal:** The list is built from a static table. Build a 4-byte `arrival` structure for it, apply it as an array, and work out the pick code without running the program.

## Module 3: Structs in x64dbg (1 h 15 min)

Ghidra gives you the layout. x64dbg shows the live values in it, including heap blocks that only exist while the program runs.

### 3A. Tour (30 min)

1. **Expressions.** x64dbg reads memory in expressions with square brackets. `[rax]` reads 8 bytes, `dword:[rax+0x14]` reads 4, `word:[rax+4]` reads 2, `byte:[rax+0x10]` reads 1.
2. **Nested reads.** Brackets nest. `[[rcx+8]+8]` reads the `next` pointer of the node after the one RCX points at.
3. **Go to an address in the dump.** Click in the dump and press Ctrl+G. Type an address or any expression, such as `rax` or `[rcx+8]`.
4. **Follow a register.** Right-click a register → Follow in Dump, as on Day 1.
5. **Change the dump's display.** Right-click the dump to show it as hex bytes, as 16-bit or 32-bit integers, or as addresses. Pick the view that matches the field you're reading.
6. **Watch view.** Open the Watch 1 tab next to the dump tabs. Right-click → Add and enter an expression. Its value updates every time the program pauses.
7. **Little-endian.** An `int` of `4417` (`0x1141`) sits in memory as `41 11 00 00`. Pointers read the same way, lowest byte first.

Stack slots and heap addresses change between runs. Write down offsets, not absolute addresses.

### Exercise 3.1: Watch ex1's fields (20 min)

1. Open `ex1.exe` in x64dbg. Find `main` from "Order refused." in String references.
2. Find the call to `find_item` and set a breakpoint on the instruction just after it.
3. Run, and enter part `1001` and quantity `50`. When it stops, RAX holds the address of the record.
4. Right-click RAX → Follow in Dump. Find the `id`, `stock` and `name` fields at the offsets you recovered in Exercise 2.1.
5. Step over the instruction that saves RAX into a local, and note its stack slot, such as `[rbp-0x10]`.
6. In Watch 1, add `word:[[rbp-0x10]+4]` and `byte:[[rbp-0x10]+0x10]`, using your slot. Check they show the stock and the flags.
7. Follow the `alt` field: press Ctrl+G in the dump and enter `[[rbp-0x10]+0x18]`. Which part is the substitute? Check against the message the program prints.

### Exercise 3.2: Walk ex2's linked list in the dump (25 min)

1. Open `ex2.exe` in x64dbg. Find the call to `matches` and set a breakpoint on it.
2. Run and enter any pick code. When it stops, RCX holds the list head.
3. Click in the dump, press Ctrl+G and enter `rcx`. Read the node's key, letter and `next` pointer.
4. Press Ctrl+G again and enter the `next` pointer, or the expression `[rcx+8]`. Read the second node.
5. Keep following `next` until you reach a null pointer. Write down each node's letter in order.
6. Add a watch for the current node's letter inside `matches`, then step through its loop. Check it compares your input with the letters in the order you wrote down.
7. Run `ex2.exe` without the debugger and enter the letters as the pick code.

## Module 4: Capstone, sharing a type with ex3 (1 h 15 min)

`ex3.exe` uses the same part record as `ex1`, but its data is different and it reaches the parts through an array of pointers. You won't rebuild the record. You'll carry it over in a type archive.

### Part A: Save the record to a type archive (15 min)

1. In `ex1.exe`'s CodeBrowser, open the Data Type Manager's arrow menu → New File Archive. Save it as `day4.gdt` in the kit's `projects` folder.
2. Drag `item` from `ex1.exe` onto `day4`. The archive now holds a copy.
3. Right-click `day4` → Save Archive.

### Part B: Apply it in ex3 with Ghidra (35 min)

1. Import and analyze `ex3.exe`. In its Data Type Manager, use the arrow menu → Open File Archive and open `day4.gdt`.
2. Find `main` from "Restock rejected." Find the function that takes an address, a count and the address of a local. Rename it `worst_shortfall`.
3. Double-click the address it receives. Each 8-byte value there points somewhere else in `.data`. Press `T` and choose a pointer to `item`, then press `[` for the count.
4. Follow one of the pointers to the records. Apply `item` from `day4` and make it an array that covers every record.
5. Retype `worst_shortfall`'s parameters as `item **`, `int` and `item **`. One `item **` is the array of pointers; the other is an out parameter.
6. Read the loop. It reads a field at offset `0x12` that `ex1` never used. Double-click `item` under `ex3.exe` and add that field.
7. Right-click `item` under `ex3.exe` → Commit to Archive, so `day4.gdt` gets the new field too. Save the archive.
8. Work out which part on the shelf the loop picks and what it returns.
9. Back in `main`, work out the part number and quantity it expects. Don't run it yet.

### Part C: Check it in x64dbg (25 min)

1. Open `ex3.exe` in x64dbg. Line up the addresses with Ghidra and set a breakpoint inside `worst_shortfall`'s loop.
2. In Ghidra's Listing, find the stack slots that hold the best gap so far and the out parameter. x64dbg shows the same instructions with plain offsets, such as `[rbp-4]`.
3. In Watch 1, add the best gap as a `dword`, and the `id` of the part the out parameter points at. Press F9 to go round the loop and watch both change.
4. Break after the call returns in `main` and follow the chosen record in the dump. Check its stock and reorder fields.
5. Run `ex3.exe` without the debugger and enter your answer.

**Deliverable:** a half-page write-up. Include the `item` layout and its padding, how `ex1` and `ex3` use it, and all three answers. Add one sentence on why the shelf parameter is `item **`.

## Answer key and hints

Try each exercise for at least 15 minutes before you look here. Offsets are for Windows x64 and don't depend on the compiler version; addresses do, so they're left out. The full recovered structs are in [lab/solutions/day4/structs.h](../lab/solutions/day4/structs.h).

| Exercise | Hint | Answer |
| --- | --- | --- |
| 1.1 | `count` needs a 4-byte boundary and `label` an 8-byte one | `tag` 0x00, 3 bytes padding, `count` 0x04, `kind` 0x08, 6 bytes padding, `label` 0x10; size 0x18 (24). Ordered `label`, `count`, `kind`, `tag` it is 0x10 (16) |
| 2.1 stride | The index is multiplied by 40 | `sizeof(item)` = 0x28 (40), 8 entries |
| 2.1 layout | `main` reads offsets 0x04, 0x06, 0x10, 0x18 and 0x20 | `int id` 0x00, `short stock` 0x04, `char name[10]` 0x06, `byte flags` 0x10, pad 0x11, `short reorder` 0x12, `int price` 0x14, `item *alt` 0x18, `short bin` 0x20, pad 0x22–0x27. `ex1` never reads 0x12 or 0x14: `reorder` turns up in `ex3`, and no program reads `price`, whose values look like prices in cents |
| 2.1 answer | The check is `(flags & 4) != 0` and quantity equal to `stock` | Part `4417` ("keystone"), quantity `12` |
| 2.2 layout | `calloc` asks for 0x18 bytes | `ushort key` 0x00, `char letter` 0x02, pad 0x03, `int weight` 0x04, `node *next` 0x08, `char tag[5]` 0x10, pad 0x15–0x17. The code only writes 4 bytes of `tag` ("BOX"), so any size from 4 to 8 fits |
| 2.2 logic | `insert` walks while `(*pp)->key` is smaller than the new key | The list is sorted by key, smallest first. `matches` compares input character `i` with node `i`'s letter and requires the input to end with the list |
| 2.2 stretch | Each letter is `enc ^ (key & 0x1f)` | Sorted by key, the letters spell the pick code below |
| 3.1 | `1001` has a substitute; its `alt` points at the next record | Stock 40, flags 0x01; `alt` leads to part `1002` |
| 3.2 | Stop when `next` is 0 | 13 nodes; pick code `W4LK-TH3-L1ST` |
| 4B shelf | The shelf holds 6 pointers, the records array has 7 entries | Part `7007` has the biggest gap but isn't on the shelf; `7003` isn't tracked (flags 0) |
| 4B answer | The gap is `reorder - stock`, only for parts with flag 0x01 | Part `7002` ("valve"): reorder 15, stock 2, quantity `13` |
| 4C | Watch the gap change from 0 to 6, 9 and 13 as the loop finds bigger gaps | The out parameter ends pointing at `7002`'s record |

## Wrap-up and Day 5

Today's Ghidra and x64dbg features are in the running references: [ghidra-reference.md](ghidra-reference.md) under Data types, and [x64dbg-reference.md](x64dbg-reference.md) under Reading state and Watching values.

**Day 5 preview:** your first Ghidra scripts, in Java. You'll use the Script Manager and the `GhidraScript` API to walk functions, strings and references in the Days 1 to 4 programs. By the end you'll have a script that decodes Day 1's `ex3` key, built one step at a time.

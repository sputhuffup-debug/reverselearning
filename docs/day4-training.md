# Day 4: Data Structures

Nov 27, 2026

## Overview

Day 4 follows Day 3. Until now you have read code that works on single values. Today you read code that works on records: structs, arrays of structs, and a linked list built at runtime. You will rebuild each record as a type in Ghidra and share one type between two programs. You follow the same records through memory in x64dbg, then give names to the bit flags and enums inside them.

**Why this matters.** Real programs keep almost everything in records: file headers, packets, settings, C++ objects. A stripped program shows them only as offsets like `+0x18`. Once you rebuild a record as a type, every function that uses it reads better. Days 6, 7 and 12 build on this skill directly.

**Goals for the day**

1. Work out a struct's field offsets, sizes and padding from the code that uses it.
2. Tell an array of values, a struct, and an array of structs apart in disassembly.
3. Build structures in Ghidra by hand and with auto-create, then apply them to code and data.
4. Read pointers to pointers: a list head passed by address, and an array of pointers.
5. Save a type to a type archive (`.gdt`) and apply it in a second program.
6. Watch struct fields in x64dbg and follow a struct and a linked list in the dump.
7. Read bit flags, packed fields and enums, and name them in Ghidra with enums and equates.
8. Solve an unseen program on your own in the checkpoint.

**What you need**

- The portable kit built by `Build-PortableRE.ps1`, as on Day 1.
- The course repo. Its `lab/day4` folder holds today's four practice programs; the checkpoint program is built with them.
- Day 1's skills: finding `main` from strings, renaming, retyping, breakpoints, and lining up addresses in both tools.

**Before you start**

Read [Data in memory](primers/07-data-in-memory.md): arrays, pointers, structs, alignment and linked lists. Its section [Bit flags and enums](primers/07-data-in-memory.md#bit-flags-and-enums) is the background for Module 5. Refresh the type sizes in [Numbers and data](primers/01-numbers-and-data.md) and the heap in [A program in memory](primers/04-memory-layout.md).

The guide links to the exact primer section wherever a concept comes up. Follow a link when a step stops making sense.

The checkpoint at the end of the day uses the method from [The approach](primers/00-approach.md) and the [analysis notes template](templates/analysis-notes.md). Have a copy of the template ready.

**Lab rules**

The Day 1 rules still apply. Work in a VM with a snapshot, analyze only the practice programs, and keep notes. Today your notes should include a sketch of every struct you recover: offset, size, type and name of each field.

A table works well: one row per field with offset, size, type, name and where you saw it used. Add a row for each gap too, marked "padding" or "unknown", so the offsets add up to the size.

## Schedule

The day runs about 7.5 hours with breaks, and roughly half of it is hands-on exercise time. Module 1 includes 30 minutes of worked examples, so the two tours are a little shorter than on other days.

| Time | Block | What you do |
| --- | --- | --- |
| 0:00–0:15 | Module 0: Setup | Build the practice programs and run `ex1` to `ex4` once |
| 0:15–1:15 | Module 1: Structs in memory | Offsets, alignment, padding, arrays of structs, pointers to pointers; Exercise 1.1 on paper; worked examples |
| 1:15–1:40 | Module 2A: Ghidra's type tools | Data Type Manager, Structure Editor, auto-create, type archives |
| 1:40–2:25 | Exercise 2.1 | Build `ex1`'s part record by hand and apply it |
| 2:25–2:40 | Break |  |
| 2:40–3:25 | Exercise 2.2 | Auto-create `ex2`'s list node and type the list head |
| 3:25–3:45 | Module 3A: Structs in x64dbg | The watch view, expressions, following pointers in the dump |
| 3:45–4:10 | Exercise 3.1 | Walk `ex2`'s list in the dump |
| 4:10–4:55 | Lunch |  |
| 4:55–5:45 | Module 4: Capstone | Share the part record with `ex3` through a `.gdt` archive and solve it |
| 5:45–6:30 | Module 5: Flags and enums | Bit operations, packed fields, enums; Ghidra enums and equates; Exercise 5.1 on `ex4` |
| 6:30–7:15 | Checkpoint | Solve `checkpoint.exe` without its source, using the Day 0 method |
| 7:15–7:20 | Review | Compare your structs and your checkpoint notes with the solutions |
| 7:20–7:25 | Wrap-up | Reference updates and the plan for Day 5 |

The extra-credit challenges in [Beyond this lesson](#beyond-this-lesson) are outside the 7.5 hours. Do them after the day, or the evening before Day 5. Two former exercises moved there to make room for Module 5 and the checkpoint: watching `ex1`'s fields in x64dbg, and checking `ex3` in x64dbg.

## Module 0: Build the practice programs (15 min)

Today's programs model a small parts warehouse. Their sources are in the repo's `lab/day4` folder and linked below. As on Day 1, don't reread a source once it's compiled.

[**ex1\_inventory.c**](../lab/day4/ex1_inventory.c): a parts catalog stored as an array of structs, and an order check

[**ex2\_picklist.c**](../lab/day4/ex2_picklist.c): a linked list built at runtime, whose nodes spell out a pick code

[**ex3\_restock.c**](../lab/day4/ex3_restock.c): a second warehouse that uses the same part record as `ex1`, reached through an array of pointers

[**ex4\_flags.c**](../lab/day4/ex4_flags.c): a staff badge that packs bit flags, an enum and other fields into one access code

The build also makes `checkpoint.exe`, the program for the end-of-day [Checkpoint](#checkpoint). Its source is in the solutions folder. Don't open it, and don't run the program until the checkpoint.

**Compile** with `make`. Open `RE-Portable\Devkit.cmd`; its shell starts in the repo's `lab` folder. Then run:

```bash
make day4     # builds bin/day4/ex1.exe to ex4.exe, and checkpoint.exe
```

The executables go into `bin/day4`. The build uses `-O0 -s` as on Day 1, so the code stays close to the source and the names are gone.

`-O0` matters today. Each field access becomes its own load or store with a plain offset, and each pointer is saved to the stack between uses. That makes the offsets easy to collect; [What -O2 changes](primers/06-control-flow.md#what--o2-changes) explains why optimized code is harder.

Run `ex1` to `ex4` once each with a wrong answer. `ex1` and `ex3` ask for a part number and a quantity, `ex2` for a pick code, and `ex4` for an access code in hex. Then close the `.c` files.

## Module 1: Structs in memory (1 h)

A struct is a block of memory with its fields at fixed offsets. The compiler turns `p->field` into "read the right number of bytes at `p` plus a constant". Recovering a struct means collecting those constants and sizes.

The compiler throws away the names. What survives is the shape: which offsets are touched, how wide each access is, and how each value is used. That is enough to rebuild a working type.

1. **Field access.** `mov eax, dword ptr [rcx+0x14]` reads 4 bytes at offset `0x14`. `movzx eax, word ptr [rcx+4]` reads 2 bytes at offset 4. The size of the read tells you the size of the field.
   Trust the size keyword ([Operand sizes](primers/03-reading-assembly.md#operand-sizes)); a `double` or `float` goes through an XMM register with `movsd` or `movss` ([Structs](primers/07-data-in-memory.md#structs)). Signedness is a weaker clue: `-O0` code often loads a signed `short` with `movzx`, then `cwde`. A signed compare such as `jl` is better evidence ([Signed and unsigned numbers](primers/01-numbers-and-data.md#signed-and-unsigned-numbers)).
2. **Alignment.** On Windows x64, each field starts at a multiple of its own size: 2 for `short`, 4 for `int`, 8 for a pointer. `char` and `char` arrays can start anywhere.
   An array field aligns like its element, so `int vals[3]` needs 4. The sizes are in [Type sizes on Windows x64](primers/07-data-in-memory.md#type-sizes-on-windows-x64).
3. **Padding.** When the next field needs alignment, the compiler leaves unused bytes. A struct's total size is also rounded up to a multiple of its largest field, so the next array entry is aligned too.
   The method is in [Alignment and padding](primers/07-data-in-memory.md#alignment-and-padding), and [Worked example: a struct with mixed sizes](primers/07-data-in-memory.md#worked-example-a-struct-with-mixed-sizes) walks it field by field. Padding is never read, so it shows up as gaps between the offsets the code uses.
4. **Arrays of structs.** `base + i * 0x28 + 0x10` reads the field at offset `0x10` of entry `i`, in an array of `0x28`-byte elements. The multiplier is the struct's size, padding included.
   At `-O0` GCC builds the multiplier from shifts and adds (`sal`, `add`), so multiply the steps out ([Arrays of structs](primers/07-data-in-memory.md#arrays-of-structs)). A plain array of values has no field offset ([Arrays](primers/07-data-in-memory.md#arrays)).
5. **Arrays versus structs.** Equal-sized reads at `base + i * size` are an array. Reads of different sizes at fixed offsets from one pointer are a struct. Both together are an array of structs.
6. **Pointers to pointers.** A function that changes the caller's pointer gets that pointer's address, so its parameter is `T **`. An array of pointers looks the same: 8-byte addresses that each lead to a struct.
   The sign is two loads in a row, the first result becoming the address of the second ([Pointers](primers/07-data-in-memory.md#pointers)).
7. **Sizes on Windows.** Windows x64 is LLP64: `int` and `long` are both 4 bytes, pointers are 8. Linux x86-64 makes `long` 8 bytes, so structs with `long` differ between the two. Today's programs avoid `long`.
   A `long` in a struct copied from Linux code is a classic source of shifted offsets. The full table is in [Bits, bytes and the C types behind them](primers/01-numbers-and-data.md#bits-bytes-and-the-c-types-behind-them).

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

Draw it as eight-byte rows, like the primer's diagram; padding is easier to see on a grid.

### 1B. Worked examples (30 min)

These examples are not from today's programs. Each shows the C, MinGW GCC's `-O0` assembly, the reverser's pseudo-code, and the recovered struct. Registers and stack slots vary with the compiler version; offsets and sizes don't.

Read the assembly first and cover the C, as you would in Ghidra. `[rbp+0x10]` is where `-O0` code keeps the first argument.

#### Example A: a struct passed by pointer

```c
struct sensor { char id; double reading; short status; };
void reset(struct sensor *s) { s->reading = 0.0; s->status = 3; }
```

```nasm
mov     qword ptr [rbp+0x10], rcx     ; save s in its home slot
mov     rax, qword ptr [rbp+0x10]     ; rax = s
pxor    xmm0, xmm0                    ; xmm0 = 0.0
movsd   qword ptr [rax+8], xmm0       ; 8 bytes at s+8, from an XMM register
mov     rax, qword ptr [rbp+0x10]     ; -O0 reloads s every time
mov     word ptr [rax+0x10], 3        ; 2 bytes at s+0x10
```

```text
reset(p):  *(double *)(p + 0x08) = 0.0;  *(short *)(p + 0x10) = 3
```

`reset` never touches offsets 0 to 7, so it can't tell you what is there. A `double` must start on a multiple of 8, and so must the size. So the struct is at least 0x18 bytes.

```c
struct sensor {        /* size 0x18 (24), at least */
    /* 0x00  8 bytes reset never touches: leave them undefined */
    double reading;    /* 0x08 */
    short  status;     /* 0x10, then 6 bytes of padding or unused fields */
};
```

Another function that reads `byte ptr [rax]` would fill in `id`. Until then, leave the bytes `undefined` rather than guess.

#### Example B: a nested struct

```c
struct pt   { int x, y; };
struct rect { struct pt tl, br; short color; };
int height(const struct rect *r) { return r->br.y - r->tl.y; }
```

```nasm
mov     rax, qword ptr [rbp+0x10]     ; rax = r
mov     edx, dword ptr [rax+0xc]      ; 4 bytes at r+0x0c
mov     rax, qword ptr [rbp+0x10]
mov     eax, dword ptr [rax+4]        ; 4 bytes at r+0x04
sub     edx, eax
mov     eax, edx                      ; the int result goes back in EAX
```

```text
height(p):  return *(int *)(p + 0x0c) - *(int *)(p + 0x04)
```

The machine code has no trace of nesting. `r->br.y` is offset 8 (where `br` starts) plus 4 (where `y` sits in `pt`). A flat and a nested model give the same offsets.

```c
struct rect {          /* size 0x14 (20): largest alignment is 4 */
    struct pt tl;      /* 0x00: x 0x00, y 0x04 */
    struct pt br;      /* 0x08: x 0x08, y 0x0c */
    short color;       /* 0x10, then 2 bytes of tail padding */
};
```

Choose nested when the same group of fields appears in several places. In Ghidra, build `pt` first, then type `pt` in a row of `rect`.

#### Example C: a tagged record with a union

```c
struct value { int kind; union { int i; double d; const char *s; } u; };
void show(const struct value *v) {
    if (v->kind == 0) printf("%d\n", v->u.i);
    else if (v->kind == 1) printf("%f\n", v->u.d);
    else puts(v->u.s);
}
```

```nasm
mov     rax, qword ptr [rbp+0x10]     ; rax = v
mov     eax, dword ptr [rax]          ; 4 bytes at v+0
test    eax, eax
jne     not_int
mov     rax, qword ptr [rbp+0x10]
mov     eax, dword ptr [rax+8]        ; 4 bytes at v+8, printed with %d
...
not_int:                              ; v+0 is reloaded and compared with 1
...
mov     rax, qword ptr [rbp+0x10]
movsd   xmm0, qword ptr [rax+8]       ; 8 bytes at v+8, into an XMM register
...
text:
mov     rax, qword ptr [rbp+0x10]
mov     rax, qword ptr [rax+8]        ; 8 bytes at v+8, passed to puts
```

```text
show(p):  switch *(int *)(p + 0):  0: int at p+8   1: double at p+8   else: char * at p+8
```

One offset read three ways, chosen by a value at another offset, is a tagged union. The union is as big as its largest member and 8-aligned, because of the `double` and the pointer.

```c
struct value {                       /* size 0x10 (16) */
    int kind;                        /* 0x00  the tag, then 4 bytes of padding */
    union { int i; double d; const char *s; } u;   /* 0x08 */
};
```

In x64dbg, a `value` holding 2.5 dumps as `01 00 00 00 ?? ?? ?? ?? 00 00 00 00 00 00 04 40`. The `??` bytes are padding with leftover values. The rest is `0x4004000000000000`, 2.5 as a `double`, read [little-endian](primers/01-numbers-and-data.md#little-endian-byte-order).

In Ghidra, a union is a data type like a structure. Build it with three members, then make it the type of the row at offset 8.

#### Example D: a struct returned by value

Windows x64 returns a struct in RAX only if it is 1, 2, 4 or 8 bytes. Anything else comes back through a hidden pointer, passed as the first argument; see [The Windows x64 calling convention](primers/05-stack-and-calls.md#the-windows-x64-calling-convention). Struct arguments follow the same size rule.

```c
struct box { int w, h, d; };                  /* 12 bytes: too big for RAX */
struct box make_box(int w) { struct box b = { w, w * 2, w * 3 }; return b; }
int use_box(void)          { struct box b = make_box(5); return b.d; }
```

```nasm
; caller: use_box
lea     rax, [rbp-0xc]                ; space for the result, in the caller's frame
mov     edx, 5                        ; w arrives in EDX, not ECX
mov     rcx, rax                      ; hidden argument 1: where to write the box
call    make_box
mov     eax, dword ptr [rbp-4]        ; result + 8

; callee: make_box, after building b at [rbp-0xc]
mov     rax, qword ptr [rbp+0x10]     ; the hidden pointer
mov     rdx, qword ptr [rbp-0xc]
mov     qword ptr [rax], rdx          ; copy w and h, 8 bytes at once
mov     edx, dword ptr [rbp-4]
mov     dword ptr [rax+8], edx        ; copy d
mov     rax, qword ptr [rbp+0x10]     ; return the hidden pointer in RAX
```

```text
make_box(out, w):  out[+0] = w;  out[+4] = w*2;  out[+8] = w*3;  return out
```

Two signs give the hidden pointer away. The function returns the pointer it got in RCX, and the caller passes the address of an unset local, then reads fields from it.

Ghidra may show `make_box` with two parameters, returning its first. If you change the return type to `box`, it treats the first parameter as the hidden return pointer. An 8-byte struct such as `{ int lo, hi; }` comes back in RAX instead, both fields in one `mov rax, qword ptr [...]`.

#### Example E: an array of structs versus an array of pointers

```c
struct rec { int key; short qty; };           /* size 8: 2 bytes of tail padding */
int sum_arr (struct rec  *a, int n) { int t = 0; for (int i = 0; i < n; i++) t += a[i].qty;  return t; }
int sum_ptrs(struct rec **a, int n) { int t = 0; for (int i = 0; i < n; i++) t += a[i]->qty; return t; }
```

The loop bodies, side by side:

```nasm
; sum_arr: a[i].qty                       ; sum_ptrs: a[i]->qty
mov     eax, dword ptr [rbp-8]  ; i       mov     eax, dword ptr [rbp-8]  ; i
cdqe                                      cdqe
lea     rdx, [rax*8]            ; i*8     lea     rdx, [rax*8]            ; i*8
mov     rax, qword ptr [rbp+0x10]  ; a    mov     rax, qword ptr [rbp+0x10]  ; a
add     rax, rdx                ; &a[i]   add     rax, rdx                ; &a[i]
                                          mov     rax, qword ptr [rax]    ; a[i]
movzx   eax, word ptr [rax+4]   ; qty     movzx   eax, word ptr [rax+4]   ; ->qty
cwde                                      cwde
```

```text
sum_arr:   t += *(short *)(a + i*8 + 4)
sum_ptrs:  t += *(short *)(*(a + i*8) + 4)
```

This record happens to be 8 bytes, so both loops scale by 8. The only difference is the extra `qword` load: in `sum_ptrs` element `i` is a pointer, so one more read reaches the struct.

When the scale alone can't decide, look at the data. An array of pointers is a column of 8-byte values that all look like addresses, as in [C strings and arrays of strings](primers/07-data-in-memory.md#c-strings-and-arrays-of-strings). An array of structs mixes small numbers, text and zeros.

The recovered types are `rec *` for `sum_arr`'s parameter and `rec **` for `sum_ptrs`'s. Module 4 uses this difference.

## Module 2: Recovering structs in Ghidra (1 h 55 min)

The decompiler shows an untyped struct pointer as a number plus offsets, such as `*(short *)(param_1 + 4)`. Each cast is a field you haven't named yet. The goal of this module is to make those casts disappear, one structure at a time.

### 2A. Tour of the type tools (25 min)

1. **Data Type Manager.** Open it with Window → Data Type Manager; it usually sits at the bottom left of the CodeBrowser. It lists archives: one named after your program, `BuiltInTypes`, and any Windows or C library archives Ghidra opened during analysis.
2. **The program's archive.** Types you create go into the archive named after the program, such as `ex1.exe`. They are saved with the program.
   This means a type you build in `ex1.exe` doesn't exist in `ex3.exe`. Module 4 fixes that with a `.gdt` file.
3. **Structure Editor.** Right-click the program's archive → New → Structure. The editor shows one row per field: offset, length, data type, name and comment. Double-click a Data Type cell and type a type name, such as `int`, `short`, `char[10]` or `item *`.
   You can type a pointer to the structure you are editing, such as `item *` inside `item`. Ghidra accepts it because a pointer is always 8 bytes, whatever it points at.
4. **Size and padding.** Set the structure's size at the bottom of the editor. Bytes you don't assign stay `undefined`; that is how padding shows up. The editor can also pack the structure for you, adding padding the way the compiler does.
   Leave packing off while you build a structure by hand. With packing off, each row stays at the offset you chose. With it on, Ghidra recomputes the offsets from the field order, which is only right once every field is known.
5. **Applying a type.** In the Decompiler, select a variable and press Ctrl+L to retype it, for example as `item *`. In the Listing, put the cursor on data and press `T` to choose a data type, then `[` to turn it into an array.
6. **Auto-create.** In the Decompiler, right-click a pointer variable → Auto Create Structure. Ghidra builds a structure from every offset the function reads or writes through that pointer. Fields get names like `field_0x8`; you rename and fix them.
   Auto-create only sees the one function you ran it in. It sizes the structure to the highest offset it saw, so the size is usually too small. Fix the size from another clue, such as the `calloc` size or an array stride.
7. **Type archives.** A `.gdt` file is an archive outside any program. The arrow menu at the top right of the Data Type Manager creates one (New File Archive) or opens one (Open File Archive). Any program can then use its types.

**What you should see.** After retyping a pointer, the decompiler swaps `*(short *)(param_1 + 4)` for a field name, such as `it->stock`. In the Listing, a struct applied to data shows as one line with a `+` to expand it, then one line per field. An array of structs expands twice: once per element, then once per field.

### When the types look wrong

Recovered types are guesses until the code agrees with them. These are the common mistakes, how each shows up, and how to fix it.

- **A field is the wrong size.** The decompiler shows a cast on the field, such as `(short)it->field_0x4`. Check the size keyword of every access at that offset, and change the row's type to match. The editor won't grow a field over another field's bytes, so set the next row back to `undefined` first.
- **Padding is missing.** If you add fields one after another with no gaps, every field after the first missing pad sits too early. The decompiler then shows offsets like `field_0x13` or a field read at the wrong width. Compare each row's offset with the offset in the instruction, not with the row above it.
- **The structure is the wrong size.** In an array of structs in the Listing, the first element looks right and later ones drift. Names start mid-word, and pointers look like `0x6b6c6f00`. The size must equal the stride from the loop; fix it in the editor and the array lines up again.
- **An array of structs taken for an array of pointers.** An array of pointers has an extra load before the field read. If the decompiler shows `*(longlong *)` inside another dereference, you probably need `item **`, not `item *`. Example E in Module 1 compares the two side by side.
- **A type applied in the wrong place.** Retyping the wrong variable doesn't break anything; press Ctrl+L again and set it back. Undo (Ctrl+Z) also reverses most type changes.

### Exercise 2.1: Build ex1's part record by hand (45 min)

1. Import and analyze `ex1.exe`. Find `main` from the "Order refused." string and rename it.
2. Find the function `main` calls with an address, a count and your part number. Rename it `find_item`.
   The arguments arrive in RCX, RDX and R8. A global address and a constant count point to a fixed array in `.data`.
3. Read its loop. Note the multiplier on the index and the size of the value it compares with your number. That multiplier is the size of one record.
   At `-O0` the multiplier is spread across several `sal` and `add` instructions. Write each step down, such as "times 3, then shift left by 4", and multiply them out. [Arrays of structs](primers/07-data-in-memory.md#arrays-of-structs) shows the shapes to expect.
4. Back in `main`, list every offset read through the pointer `find_item` returns. Note the size of each read and how the value is used. It may be compared, printed with `%s` or `%c`, masked with `&`, or followed as a pointer.
   The use tells you the type. `%s` means a `char` array or `char *`. A value read with `qword ptr` and then used as an address is a pointer. A field masked with `&` holds bit flags; Module 5 names them ([Bit flags and enums](primers/07-data-in-memory.md#bit-flags-and-enums)).
5. In the Data Type Manager, right-click `ex1.exe` → New → Structure. Name it `item` and set its size to the stride from step 3.
6. Add a row at each offset you found, with the matching type: `int`, `short`, `byte`, a `char` array, or `item *`. Name each field after how it's used. Leave the gaps `undefined` for now; some are padding and some are fields `ex1` never reads.
   A `char` array's length isn't in any instruction. It runs from its own offset up to the next field, so work it out from the offsets around it.
7. Retype `find_item`'s first parameter and `main`'s result variable as `item *` (Ctrl+L). The decompiler should now read like `it->stock`.
8. Double-click the address `main` passes to `find_item` to reach the catalog. Press `T`, choose `item`, then press `[` and make it an array with the count from step 2.
9. Read the catalog in the Listing. Find the one part whose flags pass the check in `main`, and the quantity the check expects.
   Look at the undefined bytes too. Values that change between entries are unread fields; bytes that are always zero are likely padding.
10. Run `ex1.exe` with that part number and quantity.

**Write down:** the struct's size, each field's offset and type, where the padding is, and the answer.

**Check yourself as you go.** Every element's name field should hold readable text. Every pointer field should be either zero or an address near `0x140000000`. If either breaks, recheck the size from step 3.

**Stretch goal:** Open the editor's packing option and compare the offsets Ghidra computes with your own.

### Exercise 2.2: Auto-create ex2's list node (45 min)

The nodes in `ex2` are heap blocks from `calloc` ([The heap](primers/04-memory-layout.md#the-heap)). They don't exist until the program runs, so you recover the node from the code that builds and reads it.

1. Import and analyze `ex2.exe`. Find `main` from "Wrong pick code." and rename it.
2. Find the loop that calls `calloc`. Note the size it asks for. Rename the function called with the new block as its second argument `insert`.
   `calloc(count, size)` takes two arguments, in RCX and RDX. The product is the block size, and for a single node it is the structure's size.
3. Open `insert`. Right-click its second parameter → Auto Create Structure. Find the new structure in the Data Type Manager under `ex2.exe` and rename it `node`.
4. Open `node` in the Structure Editor (double-click it). Set its size to the `calloc` size. Give the fields Ghidra found real names and types; the pointer at offset 8 is `node *next`.
   Auto-create often picks `undefined2` or `undefined8`. Replace each with a real type of the same size.
5. Back in `main`, retype the `calloc` result as `node *`. Add the fields `main` writes that `insert` never touches: a `char`, an `int`, and a `char` array that `main` fills with a short string.
   A short string copied with `memcpy` or a single store doesn't tell you the array's declared length. Note the bytes written and the space up to the end of the node.
6. Retype `insert`'s first parameter as `node **`. Read the loop again and explain in your notes why the loop variable is a `node **` too.
   `main` passes the address of its local `head`, not `head` itself. Ask what the loop variable points at after each step; [Pointers](primers/07-data-in-memory.md#pointers) covers functions that change the caller's pointer.
7. Find the function `main` calls with the list head and your input. Rename it `matches` and work out what it compares at each step.
   Look for the loop shape from [Linked lists](primers/07-data-in-memory.md#linked-lists): a load from `[reg+8]` written back into the same variable, until it is zero.

**Write down:** the node layout with offsets, what `insert` keeps the list sorted by, and how `matches` decides.

**Stretch goal:** The list is built from a static table. Build a 4-byte `arrival` structure for it, apply it as an array, and work out the pick code without running the program.

#### Example F: a doubly linked list

Many real lists also link back, so a node can be removed without walking from the head. This example is not from `ex2`; read it once you've finished Exercise 2.2.

```c
struct dnode { int val; struct dnode *prev, *next; };
void unlink_node(struct dnode *n) {
    if (n->prev) n->prev->next = n->next;
    if (n->next) n->next->prev = n->prev;
}
```

```nasm
mov     rax, qword ptr [rbp+0x10]     ; rax = n
mov     rax, qword ptr [rax+8]        ; a = *(n+8), a pointer
test    rax, rax
je      skip
...                                   ; reload a, and n
mov     rdx, qword ptr [rdx+0x10]     ; b = *(n+0x10)
mov     qword ptr [rax+0x10], rdx     ; *(a+0x10) = b
skip:
...                                   ; the same again, with the offsets swapped
mov     rdx, qword ptr [rdx+8]        ; a = *(n+8)
mov     qword ptr [rax+8], rdx        ; *(b+8) = a
```

```text
unlink(p):  a = *(p+8);  b = *(p+0x10);  if a: *(a+0x10) = b;  if b: *(b+8) = a
```

The pointer loaded from `+8` is used with offset `+0x10`, and the one from `+0x10` with `+8`. So both lead to the same kind of struct as `n`, and they point in opposite directions: `prev` and `next`.

```c
struct dnode {          /* size 0x18 (24) */
    int val;            /* 0x00, then 4 bytes of padding */
    struct dnode *prev; /* 0x08 */
    struct dnode *next; /* 0x10 */
};
```

To tell which is which, find the code that walks from the head. The field it follows to reach the second node is `next`.

## Module 3: Structs in x64dbg (45 min)

Ghidra gives you the layout. x64dbg shows the live values in it, including heap blocks that only exist while the program runs. If a field you called `stock` holds 40 and the program prints "Only 40 in stock", your layout is right.

### 3A. Tour (20 min)

1. **Expressions.** x64dbg reads memory in expressions with square brackets. `[rax]` reads 8 bytes, `dword:[rax+0x14]` reads 4, `word:[rax+4]` reads 2, `byte:[rax+0x10]` reads 1.
   Match the size prefix to the field size from Ghidra. A plain `[rax+4]` on a 2-byte field reads 8 bytes, so the value includes the neighbouring fields.
2. **Nested reads.** Brackets nest. `[[rcx+8]+8]` reads the `next` pointer of the node after the one RCX points at.
   Read it from the inside out: `[rcx+8]` is the second node's address.
3. **Go to an address in the dump.** Click in the dump and press Ctrl+G. Type an address or any expression, such as `rax` or `[rcx+8]`.
4. **Follow a register.** Right-click a register → Follow in Dump, as on Day 1.
5. **Change the dump's display.** Right-click the dump to show it as hex bytes, as 16-bit or 32-bit integers, or as addresses. Pick the view that matches the field you're reading.
6. **Watch view.** Open the Watch 1 tab next to the dump tabs. Right-click → Add and enter an expression. Its value updates every time the program pauses.
7. **Little-endian.** An `int` of `4417` (`0x1141`) sits in memory as `41 11 00 00`. Pointers read the same way, lowest byte first.
   See [Little-endian byte order](primers/01-numbers-and-data.md#little-endian-byte-order) for a worked dump line. A heap pointer usually has a few non-zero bytes then zeros; a pointer into the program ends with `xx 7F 00 00` or similar.

Stack slots and heap addresses change between runs. Write down offsets, not absolute addresses.

The program's own addresses move too, because of ASLR. Convert them as on Day 1: offset from the image base, as in [ASLR: why x64dbg's addresses differ](primers/04-memory-layout.md#aslr-why-x64dbgs-addresses-differ).

**What a struct looks like in the dump.** Here is the dump of a made-up heap record `{ int id; short qty; char code[6]; struct rec *link; }`, not one of today's. It is 24 bytes: `link` must start at 0x10, so 0x0C to 0x0F are padding.

```text
000001E4C2A51F80  D2 04 00 00 07 00 41 42 43 00 00 00 00 00 00 00  ......ABC.......
000001E4C2A51F90  A0 1F A5 C2 E4 01 00 00 .. .. .. .. .. .. .. ..  ........
```

`D2 04 00 00` is the `int` 1234 and `07 00` the `short` 7. Then come "ABC" with its zero fill, and four padding bytes that happen to be zero. The next 8 bytes are the pointer `0x1E4C2A51FA0`: the next record, a little further on the heap.

### Exercise 3.1: Walk ex2's linked list in the dump (25 min)

1. Open `ex2.exe` in x64dbg. Find the call to `matches` and set a breakpoint on it.
2. Run and enter any pick code. When it stops, RCX holds the list head.
3. Click in the dump, press Ctrl+G and enter `rcx`. Read the node's key, letter and `next` pointer.
   Use your node layout from Exercise 2.2 to split the bytes into fields. The `next` pointer is a heap address; the nodes may not be next to each other in memory.
4. Press Ctrl+G again and enter the `next` pointer, or the expression `[rcx+8]`. Read the second node.
5. Keep following `next` until you reach a null pointer. Write down each node's letter in order.
   Keep a small table: node number, address, key, letter. The keys should rise from node to node if your reading of `insert` was right.
6. Add a watch for the current node's letter inside `matches`, then step through its loop. Check it compares your input with the letters in the order you wrote down.
7. Run `ex2.exe` without the debugger and enter the letters as the pick code.

**If you get lost in the list.** Press Ctrl+G and enter `rcx` again to return to the head. RCX still holds it while you are paused on the call.

## Module 4: Capstone, sharing a type with ex3 (50 min)

`ex3.exe` uses the same part record as `ex1`, but its data is different and it reaches the parts through an array of pointers. You won't rebuild the record. You'll carry it over in a type archive.

This is how type work scales. Programs from one code base share headers, so a structure recovered once fits every program that uses it.

### Part A: Save the record to a type archive (15 min)

1. In `ex1.exe`'s CodeBrowser, open the Data Type Manager's arrow menu → New File Archive. Save it as `day4.gdt` in the kit's `projects` folder.
2. Drag `item` from `ex1.exe` onto `day4`. The archive now holds a copy.
3. Right-click `day4` → Save Archive.

The program and the `.gdt` are saved separately: saving one doesn't save the other. Keeping `day4.gdt` in the kit's `projects` folder means it moves with the kit.

### Part B: Apply it in ex3 with Ghidra (35 min)

1. Import and analyze `ex3.exe`. In its Data Type Manager, use the arrow menu → Open File Archive and open `day4.gdt`.
   `item` should show under `day4`. If the archive is empty, it was never saved; go back to Part A, step 3.
2. Find `main` from "Restock rejected." Find the function that takes an address, a count and the address of a local. Rename it `worst_shortfall`.
   "The address of a local" is a `lea` into RCX, RDX, R8 or R9 from `[rbp-...]` just before the call. That pattern means the callee writes a result back through it.
3. Double-click the address it receives. Each 8-byte value there points somewhere else in `.data`. Press `T` and choose a pointer to `item`, then press `[` for the count.
4. Follow one of the pointers to the records. Apply `item` from `day4` and make it an array that covers every record.
   The records array may be longer than the shelf, so count records, not pointers.
5. Retype `worst_shortfall`'s parameters as `item **`, `int` and `item **`. One `item **` is the array of pointers; the other is an out parameter.
   Example E in Module 1 shows the array-of-pointers shape. The out parameter is the other kind from [Pointers](primers/07-data-in-memory.md#pointers): a function that writes the caller's pointer.
6. Read the loop. It reads a field at offset `0x12` that `ex1` never used. Double-click `item` under `ex3.exe` and add that field.
   Take its size and signedness from the instruction, as in Module 1. The row was `undefined` in `ex1`'s version, so nothing else has to move.
7. Right-click `item` under `ex3.exe` → Commit to Archive, so `day4.gdt` gets the new field too. Save the archive.
8. Work out which part on the shelf the loop picks and what it returns.
9. Back in `main`, work out the part number and quantity it expects. Write them down first, then run `ex3.exe` and enter them.

**If the archive and the program disagree.** Applying an archive type copies it into the program, and the copy remembers which archive it came from. Editing the copy under `ex3.exe` doesn't change `day4.gdt` until you commit and save. `ex1.exe` keeps its old copy until you update it from the archive.

**Common archive mistakes.** A `.gdt` that was never saved opens empty. A type that was changed but not committed leaves the archive one field behind.

If Commit to Archive isn't offered for `item`, that copy isn't linked to `day4.gdt`; it was built fresh in `ex3.exe`. Delete it, apply `item` from `day4` again, and add the field to that copy.

**Deliverable:** a half-page write-up. Include the `item` layout and its padding, how `ex1` and `ex3` use it, and all three answers. Add one sentence on why the shelf parameter is `item **`.

## Module 5: Bit flags, enums and equates (45 min)

`ex1`'s `flags` field held three yes-or-no settings in one byte. Real records do this all the time, and they keep states, such as a user's role, as enums. The compiled code keeps only the numbers; this module puts the names back.

### 5A. Flags, enums and Ghidra's names for numbers (15 min)

1. **Flags.** Each flag is one bit. OR sets a bit, AND tests it, AND with the inverted mask clears it, and XOR toggles it. The table is in [Bit flags and enums](primers/07-data-in-memory.md#bit-flags-and-enums).
   At `-O0` GCC tests a bit with `and eax, 8`, then `test eax, eax`. Optimized code uses one `test al, 8`. Bit 7 of a byte is often tested with `test al, al`, then `js` or `jns`.
2. **Inverted masks.** Clearing a bit shows the mask with every other bit set. `and eax, 0x7f` clears bit 7 of a byte, and `and eax, 0xfffffffb` clears bit 2. Flip the bits to find the flag.
3. **Combinations.** `and eax, 5` then `cmp eax, 1` tests two bits at once: bit 0 set and bit 2 clear. The mask says which bits matter; the compared value says what each must be.
4. **Packed fields.** A `shr` followed by an `and` pulls a field out of a larger value. The shift count is the field's lowest bit, and the mask gives its width.
   Write each field down as a bit range, such as "bits 8 to 11". Building the value back is then a matter of shifting each field into place.
5. **Enums.** An enum is stored as a 4-byte integer, numbered from 0. Look for a field that is only compared with a few small constants, checked with an unsigned `ja`, or used as a `switch` value.
   A `switch` over consecutive enum values often becomes a jump table ([switch: a jump table](primers/06-control-flow.md#switch-a-jump-table)).
6. **Magic constants.** Some constants are text. GCC copies a short string literal with `mov` of an immediate, so `0x6c6c6568` is "hell" read little-endian. Ghidra can show a constant as characters from its right-click menu.
   Powers of two are flags, runs of ones are masks, and printable bytes are text or a signature. The primer's [Bit flags and enums](primers/07-data-in-memory.md#bit-flags-and-enums) lists more.
7. **Enums in Ghidra.** In the Data Type Manager, right-click the program's archive → New → Enum; it sits next to Structure. The Enum Editor has one row per name and value. Set the enum's size to the size of the field it describes: 1 for a byte of flags, 4 for a C enum.
   Apply it like any type: Ctrl+L on a variable in the decompiler, or type its name in a row of the Structure Editor. The decompiler then shows names, such as `case COLOR_RED:` or `flags & FLAG_FRAGILE`.
8. **Equates in Ghidra.** In the Listing, put the cursor on a constant operand and press `E` (Set Equate), or right-click it → Set Equate. Type a name. The Listing then shows the name in place of that constant.
   The dialog can apply the name to this one place or to more uses of the same value. Choose this one place unless you are sure every use means the same thing.

**Enum or equate?** An enum is a type: it names every value a variable or field can hold, wherever the type is applied. An equate names one constant at the places you choose. Use an enum for a field's values and an equate for a lone magic number.

### Exercise 5.1: Open ex4's vault (30 min)

`ex4` checks a staff badge. You type one access code in hex. The program unpacks it into a small struct, changes the flags by the badge's level, and opens the vault for one exact combination.

1. Import and analyze `ex4.exe`. Find `main` from "Vault door open." and rename it.
2. `main` reads your code with `sscanf` and `%x`, clears a local with `memset`, then passes your number and the local's address to a function. Rename it `decode`.
   The local is a struct. The `memset` size is its size.
3. In `decode`, find each `shr` and `and` pair and the store that follows it. Write down each field's bit range in your code, and the offset and width of the store.
   One field has no shift: an `and` with `0xff`, or a plain byte store, keeps the low 8 bits.
4. Build a structure `badge` with the size from step 2, and retype `decode`'s second parameter as `badge *`. Auto Create Structure works here too.
5. `decode` returns true only if two fields pass. One is compared with a constant; show it as characters and give it an equate (`E`), such as `SITE_TAG`. The other has an unsigned range check: that is the enum field.
6. Open the function `main` calls next with the same struct. It is a `switch` on the enum field. For each case, note what it does to the flags byte: OR, AND, AND with an inverted mask, or XOR.
   Each case also writes a short string into the struct, as an immediate. Read it as text to name that enum value.
7. Create an enum `level` of 4 bytes with the names from step 6. Create a 1-byte enum `perms` with one name per bit the code uses. Apply both to the struct's fields in the Structure Editor.
   The `switch` should now show `case` labels by name. Note how the decompiler now shows a bit test in `main`.
8. Back in `main`, read the checks after the `switch`. Work out the value each field must have at the end. Then undo the `switch`'s change to get the value you must type.
9. Build the access code from your bit ranges, in hex, and run `ex4.exe` with it.

**Write down:** the struct layout, each field's bit range in the access code, the enum values, and the vault code.

**Check yourself as you go.** The program prints the zone and the level name before its checks. If the name is not the one you aimed for, your level bits are in the wrong place.

**Stretch goal:** In x64dbg, break just after the call to the `switch` function and read the flags byte in the dump. Check that the case changed it the way you predicted.

## Checkpoint

Every day ends with a blind checkpoint: an unseen program, solved on your own, without its source. It shows you which of today's skills you can use without a guide. Treat it as practice for Day 15, not as a test.

**Time:** about 45 minutes. **Program:** `bin/day4/checkpoint.exe`, built in Module 0. Its source is in the solutions folder; don't open it.

**Method.** Work the Day 0 way, as described in [The approach](primers/00-approach.md). Start a fresh copy of the [analysis notes template](templates/analysis-notes.md) and fill it in as you go, not at the end.

**The task.** `checkpoint.exe` asks for a lead crate and a load weight. Find the pair it accepts. It uses only Day 4 material: an array of records, bit flags, an enum and a linked list.

1. Run it once with any numbers and note everything it prints. Write the question you are answering at the top of your notes.
2. Find `main` from a string, and list the functions it calls before the prompts.
3. Recover the record: its stride, then each field's offset, size and use. Build it in Ghidra and apply it to the data.
4. Work out what each flag test and each change to the flags does. Name the bits with an enum if it helps.
5. Write down your prediction, with the reason for each number, before you type anything.
6. Check it: run the program, or follow the records in x64dbg if your prediction fails.

**Deliverable:** your notes in the template, with the record layout, what each function does, the answer, and one open question. If you are stuck after 30 minutes, write down where and what you would try next. That is a result too.

Then compare with the model write-up in [lab/solutions/day4/checkpoint.md](../lab/solutions/day4/checkpoint.md).

## Beyond this lesson

These challenges are extra credit, outside the 7.5-hour day. Do them once you've checked your answers, because they reuse the sources and the answer key. Hints and expected results are in [lab/solutions/day4/extra-credit.md](../lab/solutions/day4/extra-credit.md).

To change a source, copy it to a folder outside the repo, such as `day4x` in the kit's `projects` folder. Build the copy in the Devkit shell with the same flags as `make`, for example `gcc -O0 -s -Wall ex1_mod.c -o ex1_mod.exe`. Never edit the files in `lab/day4`; CI checks the originals.

### Challenge 1: Squeeze the padding out (★)

- **Goal:** find out how small `item` and `node` can get by reordering their fields.
- **What to do:** In copies of `ex1_inventory.c` and `ex2_picklist.c`, print `sizeof` and each field's `offsetof` (from `stddef.h`). Predict each size on paper first. Then reorder the fields and rebuild.
- **What to check:** your predictions match the printed sizes. Explain why one of the two structs can't get smaller, and find the one-field type change that lets `item` shrink.

### Challenge 2: Add a field and watch the offsets move (★★)

- **Goal:** see how one new field changes every offset after it, in Ghidra and in the data.
- **What to do:** In a copy of `ex1_inventory.c`, add `int weight;` to `item` right after `flags`. Add a value for it in each row of the catalog, in the same position. Rebuild, then import the new program into Ghidra next to the original.
- **What to check:** the new stride in `find_item`, and the new offset of every field `main` reads. Apply your old `item` to the new catalog and describe how it drifts. Then fix the structure and confirm the program still accepts the same answer.

### Challenge 3: Walk the list from the command line (★★)

- **Goal:** walk `ex2`'s list in x64dbg with typed commands instead of the mouse.
- **What to do:** Pause on the call to `matches` as in Exercise 3.1. Using only the Command box, show each node's key and letter, then move to the next node, until `next` is 0. Start with expressions and Day 3's `dump` command, then try x64dbg's commands for named variables and formatted Log output.
- **What to check:** the Log tab lists 13 nodes, keys rising, and the letters spell the pick code you found in Exercise 3.1. Save your commands in your notes; Day 9 turns this kind of sequence into an x64dbg script.

### Challenge 4: Make the list doubly linked (★★★)

- **Goal:** recover a changed node layout from scratch, then walk the list both ways.
- **What to do:** In a copy of `ex2_picklist.c`, add `struct node *prev;` right after `next`. After the build loop, add a second loop that sets each node's `prev` to the node before it. Rebuild, then recover the new `node` in Ghidra without looking at your old one.
- **What to check:** the new `calloc` size and the offsets of `next`, `prev` and the tag. In x64dbg, walk to the last node with `next`, then back to the head with `prev`, and read the letters in reverse.

### Challenge 5: One archive for the whole day, applied to -O2 builds (★★★)

- **Goal:** build a `.gdt` that covers every Day 4 type, and use it on optimized code that has no helper functions left.
- **What to do:** Add `node` and `arrival` from `ex2.exe` to `day4.gdt`, next to `item`, and save it. From the `lab` folder, build optimized copies, for example `gcc -O2 -s -Wall day4/ex1_inventory.c -o bin/day4/ex1_o2.exe`, and the same for `ex2` and `ex3`. Import them into Ghidra, open `day4.gdt`, and apply the types.
- **What to check:** which helper functions still exist at `-O2`, and where their loops went. Find the stride of the catalog loop in `ex1_o2.exe` and the shelf loop in `ex3_o2.exe`. Confirm each program accepts the same answer as its `-O0` build. As a last check, parse [structs.h](../lab/solutions/day4/structs.h) with File → Parse C Source, as its header comment suggests, and compare it with your archive.

### Challenge 6: Watch ex1's fields (★)

This used to be the first exercise in Module 3. It is the gentlest use of the Watch view, so start here if the Watch view still feels new.

- **Goal:** watch the fields of one `ex1` record through a pointer saved on the stack.
- **What to do:** follow the steps below.
- **What to check:** each watch matches the field Ghidra shows for part `1001`, and `alt` leads to the part the program names.

1. Open `ex1.exe` in x64dbg. Find `main` from "Order refused." in String references.
2. Find the call to `find_item` and set a breakpoint on the instruction just after it.
   x64dbg has no names in a stripped program. Find the call by its position in `main`, or convert its Ghidra address to an offset first.
3. Run, and enter part `1001` and quantity `50`. When it stops, RAX holds the address of the record.
4. Right-click RAX → Follow in Dump. Find the `id`, `stock` and `name` fields at the offsets you recovered in Exercise 2.1.
   The address in RAX should be inside the program's `.data`, not on the heap or the stack. The catalog is a global array, as described in [Where each kind of variable lives](primers/04-memory-layout.md#where-each-kind-of-variable-lives).
5. Step over the instruction that saves RAX into a local, and note its stack slot, such as `[rbp-0x10]`.
6. In Watch 1, add `word:[[rbp-0x10]+4]` and `byte:[[rbp-0x10]+0x10]`, using your slot. Check they show the stock and the flags.
   If a watch shows a huge number, the size prefix is missing or wrong. If it shows an error, the slot may not be written yet; step once more.
7. Follow the `alt` field: press Ctrl+G in the dump and enter `[[rbp-0x10]+0x18]`. Which part is the substitute? Check against the message the program prints.

### Challenge 7: Check ex3 in x64dbg (★★)

This used to be Part C of Module 4. It confirms the Module 4 answer at runtime with a three-read watch.

- **Goal:** watch `worst_shortfall` pick its part, through the out parameter.
- **What to do:** follow the steps below.
- **What to check:** the best gap and the chosen part change as the loop runs. They end on the part and quantity from Module 4.

1. Open `ex3.exe` in x64dbg. Line up the addresses with Ghidra and set a breakpoint inside `worst_shortfall`'s loop.
2. In Ghidra's Listing, find the stack slots that hold the best gap so far and the out parameter. x64dbg shows the same instructions with plain offsets, such as `[rbp-4]`.
   The out parameter's slot holds an address, the address of `main`'s local. The `item *` you want is one more read away, at that address.
3. In Watch 1, add the best gap as a `dword`, and the `id` of the part the out parameter points at. Press F9 to go round the loop and watch both change.
   The `id` watch needs three reads: the slot, then the pointer it holds, then the field. Before the first match the pointer is null, so the watch shows an error or 0 until then.
4. Break after the call returns in `main` and follow the chosen record in the dump. Check its stock and reorder fields.
5. Run `ex3.exe` without the debugger and enter your answer again.

### Challenge 8: Name the part flags in every program (★★)

- **Goal:** replace the raw flag numbers in `ex1` and `ex3` with names, using one enum shared through `day4.gdt`.
- **What to do:** In `day4.gdt`, create a 1-byte enum `item_flags` with one name per bit that `ex1` and `ex3` test. Make it the type of `item.flags`, commit it, and update both programs from the archive. Then set an equate on one constant that the enum doesn't cover, such as the entry count that `main` passes to `find_item`.
- **What to check:** how the decompiler shows each flag test before and after. Look also at catalog entries whose flags combine two bits. Note one case where the equate is clearer than an enum, and one where it isn't.

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
| 3.1 | Stop when `next` is 0 | 13 nodes; pick code `W4LK-TH3-L1ST` |
| 4B shelf | The shelf holds 6 pointers, the records array has 7 entries | Part `7007` has the biggest gap but isn't on the shelf; `7003` isn't tracked (flags 0) |
| 4B answer | The gap is `reorder - stock`, only for parts with flag 0x01 | Part `7002` ("valve"): reorder 15, stock 2, quantity `13` |
| 5.1 layout | `memset` clears 0x14 bytes | `ushort site` 0x00, `byte perms` 0x02, `byte zone` 0x03, `level` (4-byte enum) 0x04, `char role[12]` 0x08–0x13. The longest role written is 11 bytes, so 11 or 12 fits |
| 5.1 code | `decode` shifts by 16, 12 and 8, and masks with 0xf | Site in bits 16–31, zone in 12–15, level in 8–11, permissions in 0–7. The site must be 0x5744 ("WD") and the level at most 4 (`ja`) |
| 5.1 levels | The cases write "visitor", "staff", "supervisor", "manager", "auditor" | 0 visitor: `perms &= 0x01`. 1 staff: `\|= 0x01`. 2 supervisor: `\|= 0x03`. 3 manager: `&= 0x7f`, clearing 0x80. 4 auditor: `^= 0x10` |
| 5.1 checks | Bit 0x80 must be clear (`test al, al`, `jns`) and bit 0x08 set | Then zone 7, level 4 (auditor) and permissions exactly 0x1c |
| 5.1 answer | The auditor's XOR flips 0x10, so you type 0x1c ^ 0x10 | Permissions 0x0c; access code `5744740C` |
| Checkpoint | Work it blind first | The answer, the recovered record and a model write-up are in [lab/solutions/day4/checkpoint.md](../lab/solutions/day4/checkpoint.md) |

## Wrap-up and Day 5

Today's Ghidra and x64dbg features are in the running references: [ghidra-reference.md](ghidra-reference.md) under Data types, and [x64dbg-reference.md](x64dbg-reference.md) under Reading state and Watching values.

Before you close Ghidra, save each program and `day4.gdt`. Keep your checkpoint notes with the rest of your Day 4 notes. Enums and equates are in the Data types table too.

**Day 5 preview:** your first Ghidra scripts, in Java. You'll use the Script Manager and the `GhidraScript` API to walk functions, strings and references in the Days 1 to 4 programs. By the end you'll have a script that decodes Day 1's `ex3` key, built one step at a time.

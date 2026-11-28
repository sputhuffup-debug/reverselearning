# Data in memory

This primer shows how arrays, pointers, strings, structs and linked lists sit in memory. It also shows how code that uses them looks in assembly. [Day 4](../day4-training.md) relies on all of it, and [Day 5](../day5-training.md)'s capstone reads a table of records. Reading time: about 25 minutes.

It assumes you can read hex and little-endian values ([01: Numbers and data](01-numbers-and-data.md)) and simple instructions ([03: Reading assembly](03-reading-assembly.md)). Sections such as `.rdata` and `.data` are in [04: Memory layout](04-memory-layout.md).

## Type sizes on Windows x64

Every C type has a size, the number of bytes it takes in memory. Windows x64 uses a model called LLP64: only `long long` and pointers are 64 bits. In particular, `long` is 4 bytes on Windows, but 8 bytes on Linux x86-64.

| C type | Size (bytes) | Alignment | Ghidra name |
| --- | --- | --- | --- |
| `char`, `unsigned char` | 1 | 1 | `char`, `byte` |
| `short` | 2 | 2 | `short` |
| `int` | 4 | 4 | `int` |
| `long` | 4 | 4 | `long` (4 bytes on Windows) |
| `long long` | 8 | 8 | `longlong` |
| `float` | 4 | 4 | `float` |
| `double` | 8 | 8 | `double` |
| any pointer, `size_t` | 8 | 8 | `char *`, `item *`, `ulonglong` |

Alignment is explained in [Alignment and padding](#alignment-and-padding) below.

## Arrays

An array is a row of elements of the same type, stored one after another with no gaps. The address of the first element is the array's base. Element `i` is at `base + i * size`, where `size` is the size of one element.

```c
int nums[8];        /* 8 * 4 = 32 bytes */
nums[5] = 7;        /* writes 4 bytes at base + 5 * 4 = base + 0x14 */
```

In assembly, the multiplication often hides inside the address. x86-64 can add a register times 1, 2, 4 or 8, called the scale, to a base register.

```nasm
; return nums[i];   i arrives in ecx (optimized build)
movsx   rcx, ecx                     ; widen the int index to 64 bits, keeping its sign
lea     rax, [nums]                  ; rax = base of the array
mov     eax, dword ptr [rax+rcx*4]   ; read 4 bytes at base + i*4
```

The scale is the element size: `*4` with a `dword` read means an array of 4-byte values. Unoptimized (`-O0`) code, which the course builds, often splits it into two steps: `lea rdx, [rax*4]`, then `mov eax, dword ptr [rdx+rax]`. Element sizes that are not 1, 2, 4 or 8 need an `imul` or a mix of `lea` and `shl`, shown under [Arrays of structs](#arrays-of-structs).

## Pointers

A pointer is a variable that holds an address. On x64 every pointer is 8 bytes, whatever it points to. Dereferencing a pointer means reading or writing the memory at the address it holds.

```c
int  x = 42;
int *p = &x;        /* p holds the address of x */
*p = 5;             /* dereference: write 5 at that address, so x is now 5 */
```

In assembly, a pointer is just a 64-bit value in a register or in memory. Square brackets do the dereference.

```nasm
mov     rax, qword ptr [rbp-0x10]    ; load the pointer p (8 bytes)
mov     dword ptr [rax], 5           ; *p = 5: write 4 bytes at the address in rax
```

**Pointer arithmetic scales.** Adding 1 to a pointer moves it by the size of the type it points to, not by one byte. So `p + i` and `&p[i]` are the same address.

| Declaration | `p + 1` adds | `p + 3` adds |
| --- | --- | --- |
| `char *p` | 1 | 3 |
| `short *p` | 2 | 6 |
| `int *p` | 4 | 12 (0xc) |
| `long long *p`, `char **p` | 8 | 24 (0x18) |
| `struct item *p` (size 0x28) | 0x28 | 0x78 |

**Pointers to pointers.** A `char **` holds the address of a `char *`. You meet two kinds.

A function that must change the caller's pointer receives that pointer's address. An array of pointers is also used through a `T **`: each element is an 8-byte address leading to a `T`.

```c
void set_null(int **pp) { *pp = 0; }   /* changes the caller's pointer */
```

```nasm
mov     rax, qword ptr [rbp+0x10]    ; rax = pp
mov     qword ptr [rax], 0           ; *pp = NULL: write 8 bytes of zero
```

Two loads in a row, where the result of the first becomes the address of the second, are the sign of `**`.

## C strings and arrays of strings

A C string is a row of `char` bytes ended by a zero byte, called the terminator. There is no length stored anywhere; code finds the end by looking for the zero. A string literal such as `"red"` takes 4 bytes in `.rdata`: `72 65 64 00`.

An array of strings is usually an array of pointers. Each element is 8 bytes and holds the address of a string stored elsewhere.

```c
const char *names[] = { "red", "green", "blue" };   /* 3 pointers = 24 bytes */
```

```text
names (in .data)                      strings (in .rdata)
+0x00  [ 8-byte address ] ----------> "red\0"
+0x08  [ 8-byte address ] ----------> "green\0"
+0x10  [ 8-byte address ] ----------> "blue\0"
```

The table goes in `.data` here because it is not `const` itself; `const char *const names[]` would put it in `.rdata`. Reading `names[i]` is an array access with scale 8, followed by using the result as an address.

```nasm
mov     rax, qword ptr [rdx+rax*8]   ; rax = names[i], the address of a string
```

Compare `char names[3][6]`. That is one block of 18 bytes holding the characters themselves, with no pointers. In Ghidra, a table of pointers shows as `addr` entries with labels to the right; a 2D `char` array shows as text inline.

## Structs

A struct groups fields of different types in one block of memory. Each field sits at a fixed offset, its distance in bytes from the start of the struct. Code holds a pointer to the struct and adds the offset.

```c
struct item *it = ...;
short s = it->stock;          /* stock is at offset 4 */
```

```nasm
mov     rax, qword ptr [rbp+0x10]    ; rax = it
movzx   eax, word ptr [rax+4]        ; read 2 bytes at it + 4
```

The pattern is `[reg + offset]`. The offset names the field, and the size of the read (`byte`, `word`, `dword`, `qword`) gives the field's size.

`movzx` and `movsx` widen a small value into a full register: `movzx` fills with zeros (unsigned), `movsx` copies the sign bit (signed). Collecting every offset used with one pointer is how you rebuild a struct.

## Alignment and padding

Alignment is a rule about where a value may start. On Windows x64 each basic type is naturally aligned: its address is a multiple of its own size. A `short` starts on an even address, an `int` on a multiple of 4, a pointer on a multiple of 8.

Inside a struct, the compiler keeps fields in the order you wrote them. When the next field would start at a badly aligned offset, it inserts unused bytes called padding.

It also pads the end, so `sizeof` is a multiple of the struct's largest alignment. That keeps every element of an array of these structs aligned too.

## Worked example: a struct with mixed sizes

Here is an example struct with fields of 1, 2, 4 and 8 bytes. Work through it one field at a time: take the next free offset, round it up to the field's alignment, then add the field's size.

```c
struct item {
    int   id;
    short stock;
    char  name[10];
    unsigned char flags;
    short reorder;
    int   price;
    struct item *alt;
    short bin;
};
```

| Field | Type | Size | Next free offset | Aligned to | Offset |
| --- | --- | --- | --- | --- | --- |
| `id` | `int` | 4 | 0x00 | 4 | 0x00 |
| `stock` | `short` | 2 | 0x04 | 2 | 0x04 |
| `name` | `char[10]` | 10 | 0x06 | 1 | 0x06 |
| `flags` | `unsigned char` | 1 | 0x10 | 1 | 0x10 |
| `reorder` | `short` | 2 | 0x11 | 2 | 0x12 (1 byte of padding) |
| `price` | `int` | 4 | 0x14 | 4 | 0x14 |
| `alt` | `struct item *` | 8 | 0x18 | 8 | 0x18 |
| `bin` | `short` | 2 | 0x20 | 2 | 0x20 |
| end | | | 0x22 | 8 | 0x28 (6 bytes of padding) |

The largest alignment is 8, from the pointer, so the size rounds up from 0x22 to 0x28 (40 bytes).

```text
offset  +0 +1 +2 +3 +4 +5 +6 +7
0x00    [ id      ] [stk] [ name ...
0x08    ... name ............... ]
0x10    fl pd [rro] [ price   ]
0x18    [ alt (8-byte pointer)  ]
0x20    [bin] pd pd pd pd pd pd
```

`pd` marks padding. Its bytes hold whatever was there before, often zero, and code never reads them.

## Arrays of structs

In an array of structs, the distance from one element to the next is the stride, and it equals `sizeof` of the struct, padding included. Field `f` of element `i` is at `base + i * sizeof + offset_of_f`.

```c
int price_at(struct item *a, int i) { return a[i].price; }   /* a + i*0x28 + 0x14 */
```

0x28 is not 1, 2, 4 or 8, so the compiler builds the multiplication from smaller steps. The optimized build computes `i*5` with `lea`, then scales by 8:

```nasm
movsx   rdx, edx                         ; i, widened to 64 bits
lea     rax, [rdx+rdx*4]                 ; rax = i*5
mov     eax, dword ptr [rcx+rax*8+0x14]  ; a + i*40 + 0x14: the price field
```

The `-O0` build does the same with `sal` (another name for `shl`, shift left): `i*5`, then shift left by 3. Other compilers write `imul rax, rax, 0x28`.

Whatever the form, work out the total multiplier; that is the stride. The constant added on top is the field offset.

## Linked lists

A linked list is a chain of structs, called nodes, where each node holds a pointer to the next one. The last node's pointer is `NULL` (zero). Nodes usually come from `malloc` or `calloc`, so they live on the heap at addresses that change between runs.

```c
struct node { int value; struct node *next; };   /* value at 0, 4 bytes padding, next at 8 */
```

```text
head --> +0 value = 3      +--> +0 value = 9      +--> +0 value = 1
         +8 next ----------+    +8 next ----------+    +8 next = 0 (end)
```

Walking the list shows up as a loop that loads `next` into the same pointer it reads from:

```nasm
mov     rax, qword ptr [rbp+0x10]   ; rax = n
mov     rax, qword ptr [rax+8]      ; rax = n->next
mov     qword ptr [rbp+0x10], rax   ; n = n->next
cmp     qword ptr [rbp+0x10], 0     ; until n is NULL
jne     loop
```

How loops look in general is in [06: Control flow](06-control-flow.md).

## How Ghidra helps

- **Before types.** The decompiler shows raw offsets, such as `*(short *)(param_1 + 4)`. Each one is a field you still need to name.
- **Structure Editor.** In the Data Type Manager, right-click the program's archive → New → Structure. Add one row per field at its offset, and leave padding `undefined`.
- **Applying a type.** In the decompiler, select a variable and press Ctrl+L, then type `item *`. The raw offsets turn into field names like `it->stock`.
- **Auto Create Structure.** Right-click a pointer variable in the decompiler. Ghidra builds a struct from every offset the function uses; you then rename and fix the fields.
- **Data in the Listing.** On a table, press `T` to apply a type and `[` to make it an array. Each element then shows its fields.

The full steps are in [Day 4](../day4-training.md), Module 2, and in the [Ghidra reference](../ghidra-reference.md).

## How x64dbg helps

x64dbg shows the live values, including heap nodes that exist only while the program runs.

- **Follow a pointer.** Right-click a register that holds an address → Follow in Dump. The dump shows the bytes it points to.
- **Read through a pointer.** In the dump, press Ctrl+G and type an expression such as `[rax+0x18]`. Square brackets read 8 bytes there and go to that address, which follows the `alt` field.
- **Nest reads.** `[[rcx+8]+8]` reads the `next` pointer of the node after the one in RCX.
- **Sized reads.** `dword:[rax+0x14]` reads 4 bytes, `word:[rax+4]` 2, `byte:[rax+0x10]` 1. Add them to the Watch view to see fields update as you step.

Remember the bytes are little-endian: the pointer `0x00000000001d2f40` appears in the dump as `40 2f 1d 00 00 00 00 00`. More is in the [x64dbg reference](../x64dbg-reference.md).

## Check yourself

1. `int arr[10]` starts at `0x1000`. What is the address of `arr[5]`?
2. `long long *p` holds `0x2000`. What address does `p + 3` hold?
3. How many bytes is a `long` on Windows x64, and on Linux x86-64?
4. What is `sizeof(struct { char c; int i; char d; })` on Windows x64, and where is the padding?
5. A loop does `mov rax, qword ptr [rax+8]` and stops when `rax` is 0. What is it probably doing?
6. A function reads `dword ptr [rcx+rax+0x10]` after `imul rax, rax, 0x18`. What are the stride and the field offset?
7. How do `char *names[3]` and `char names[3][8]` differ in memory?

<details><summary>Answers</summary>

1. `0x1000 + 5 * 4 = 0x1014`.
2. `0x2000 + 3 * 8 = 0x2018`. Pointer arithmetic scales by the pointed-to size.
3. 4 bytes on Windows (LLP64) and 8 bytes on Linux.
4. 12 bytes. `c` is at 0, then 3 bytes of padding so `i` starts at 4. `d` is at 8, then 3 bytes of tail padding round the size up to a multiple of 4.
5. Walking a linked list: the `next` pointer is at offset 8 of each node, and NULL ends the list.
6. The stride is 0x18 (24 bytes), the size of one element. The field is at offset 0x10 in each element.
7. `char *names[3]` is 24 bytes of pointers that lead to strings stored elsewhere. `char names[3][8]` is 24 bytes holding the characters themselves, 8 per row, with no pointers.

</details>

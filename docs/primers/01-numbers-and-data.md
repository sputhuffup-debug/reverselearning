# Numbers and data

How numbers, text and raw bytes look inside a program, and how to read them in a hex dump. [Day 1](../day1-training.md) uses all of it from the first exercise: addresses, constants, the dump in x64dbg, and the XOR in `ex3`.

Reading time: about 15 minutes.

## Three ways to write a number

A number is the same value however you write it. Only the notation changes.

- **Decimal** (base 10) uses the digits 0 to 9. It is what people use day to day.
- **Binary** (base 2) uses only 0 and 1. Each digit is a **bit**, the smallest unit a computer stores.
- **Hexadecimal**, or **hex** (base 16), uses 0 to 9 and then A to F for 10 to 15. Hex numbers start with `0x` so you can tell them apart: `0x10` is 16, not ten.

| Decimal | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Hex | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | A | B | C | D | E | F |
| Binary | 0000 | 0001 | 0010 | 0011 | 0100 | 0101 | 0110 | 0111 | 1000 | 1001 | 1010 | 1011 | 1100 | 1101 | 1110 | 1111 |

To convert hex to decimal, multiply each digit by its place value: 1, 16, 256, 4096 and so on. For example, `0xB6` is 11 × 16 + 6 = 182.

To convert hex to binary, replace each hex digit with its four bits from the table. `0xB6` is `1011 0110`. To go back, split the bits into groups of four from the right.

You don't need to do this by hand often. Windows Calculator has a Programmer mode, and in Python `hex(182)` gives `'0xb6'` and `int("b6", 16)` gives `182`. In Ghidra, right-click a number to switch between hex and decimal.

## Why reverse engineering uses hex

One hex digit is exactly four bits, so one byte is always exactly two hex digits. That makes the bytes inside a value visible. In decimal, 3,405,644,031 tells you nothing; in hex it is `0xCAFE00FF`, and you can see its four bytes `CA`, `FE`, `00` and `FF`.

Addresses, dumps and machine code are all shown in hex. Some values worth knowing on sight:

| Hex | Decimal | Where you see it |
| --- | --- | --- |
| `0xFF` | 255 | The largest byte value |
| `0x100` | 256 | One more than a byte can hold |
| `0x1000` | 4096 | The size of a memory page on Windows |
| `0xFFFF` | 65535 | The largest 2-byte value |
| `0xFFFFFFFF` | 4294967295 | The largest 4-byte value, or -1 (see below) |
| `0x140000000` | | The default image base Ghidra shows for a 64-bit program |

Tools write hex in slightly different ways. Ghidra's instructions use `0x40`, and its data lines use a suffix, such as `40h`. x64dbg's disassembly usually leaves the prefix out, so `sub rsp,60` means `0x60`.

## Bits, bytes and the C types behind them

A **byte** is 8 bits and holds 0 to 255. Memory is a long row of bytes, and each byte has a number called its **address**. Larger values take several bytes in a row.

The x86 names for these sizes come from the 16-bit era, so a **word** is 2 bytes, not 4.

| Name | Bytes | Bits | C types on Windows x64 | Size keyword in assembly |
| --- | --- | --- | --- | --- |
| byte | 1 | 8 | `char`, `unsigned char`, `bool` | `byte ptr` |
| word | 2 | 16 | `short`, `unsigned short`, `wchar_t` | `word ptr` |
| dword (double word) | 4 | 32 | `int`, `unsigned int`, `long`, `float`, `DWORD`, `BOOL` | `dword ptr` |
| qword (quad word) | 8 | 64 | `long long`, `size_t`, `double`, every pointer | `qword ptr` |

Two of these catch people out:

- On 64-bit Windows, `long` is 4 bytes, the same as `int`. On 64-bit Linux it is 8. Use `long long` when you mean 8 bytes.
- Every pointer is 8 bytes, whatever it points to. A `char *` and an `int *` are the same size.

When Ghidra doesn't know a value's type yet, it calls it `undefined1`, `undefined2`, `undefined4` or `undefined8`. The number is the size in bytes. Retyping it (Ctrl+L) is part of the cleanup you do on Day 1. [Data in memory](07-data-in-memory.md) covers arrays, structs and pointers built from these types.

## Little-endian byte order

A value of more than one byte has to be stored in some order. x86-64 is **little-endian**: the lowest byte (the "little end") comes first, at the lowest address.

So the 4-byte value `0x12345678` is stored as the bytes `78 56 34 12`. To read a value out of a dump, take its bytes in order and reverse them.

Here is one line of a stack dump, as x64dbg's dump pane shows it. The address is on the left, then 16 bytes, then the same bytes as text.

```
000000000014FE20  2A 00 00 00 FF FF FF FF 00 90 00 40 01 00 00 00  *..........@....
```

Read it as one dword, another dword, then a qword:

1. Bytes 0 to 3 are `2A 00 00 00`. Reversed: `00 00 00 2A`, so the dword is `0x0000002A`, which is 42.
2. Bytes 4 to 7 are `FF FF FF FF`. Reversed they are the same: `0xFFFFFFFF`. As an `int` that is -1, as the next section explains.
3. Bytes 8 to 15 are `00 90 00 40 01 00 00 00`. Reversed: `00 00 00 01 40 00 90 00`, so the qword is `0x0000000140009000`.

The last value looks like an address inside the program (near `0x140000000`). That is a strong hint it is a pointer. Following it would lead to whatever it points at, such as a string.

The dump can't tell you where one value ends and the next starts. You decide that from the code that reads the memory, for example a `dword ptr` operand. Ghidra does the reversing for you once you give the bytes a type, and x64dbg can show the dump as dwords or qwords (right-click in the dump).

## Signed and unsigned numbers

The same bits can mean two different numbers. **Unsigned** values are never negative: a dword holds 0 to 4,294,967,295. **Signed** values use the top bit to mark negative numbers, so the range is split around zero.

| Size | Unsigned range | Signed range |
| --- | --- | --- |
| byte | 0 to 255 | -128 to 127 |
| word | 0 to 65,535 | -32,768 to 32,767 |
| dword | 0 to 4,294,967,295 | -2,147,483,648 to 2,147,483,647 |
| qword | 0 to 18,446,744,073,709,551,615 | about -9.2 × 10^18 to 9.2 × 10^18 |

Signed numbers use **two's complement**. To negate a value, flip every bit and add 1. For example, 1 is `0x00000001`; flipped it is `0xFFFFFFFE`; add 1 and you get `0xFFFFFFFF`. So -1 as an `int` is `0xFFFFFFFF`.

A few more to recognize: -2 is `0xFFFFFFFE`, -5 is `0xFFFFFFFB`, and the most negative `int` is `0x80000000`. A large hex value that starts with `F` is often a small negative number.

Two's complement means addition and subtraction work the same for signed and unsigned values. The CPU doesn't store which one a value is. The code that uses it decides, by its choice of instruction: for example `jl` compares signed and `jb` unsigned. [Registers and flags](02-registers-and-flags.md) shows how.

The same applies when a small value is widened. **Sign extension** copies the top bit into the new bytes, so the byte `0xFF` (-1) becomes the dword `0xFFFFFFFF` (still -1). **Zero extension** fills with zeros, so `0xFF` (255) becomes `0x000000FF`. GCC on Windows treats plain `char` as signed.

## Text in a dump

Text is stored as numbers too. **ASCII** gives each common character a number from 0 to 127, one byte each. Some to know:

| Character | Hex | Character | Hex |
| --- | --- | --- | --- |
| `0` to `9` | `30` to `39` | space | `20` |
| `A` to `Z` | `41` to `5A` | newline `\n` | `0A` |
| `a` to `z` | `61` to `7A` | carriage return `\r` | `0D` |

A C string is its characters followed by a single zero byte, the **terminating zero** (written `\0`). Functions like `strcmp` and `puts` stop at that zero; the string has no stored length.

Here is the start of the read-only data in a small program that asks for a door code:

```
0000000140009000  44 6F 6F 72 20 63 6F 64 65 3A 20 00 0D 0A 00 6F  Door code: ....o
0000000140009010  70 65 6E 2D 73 65 73 61 6D 65 00 57 65 6C 63 6F  pen-sesame.Welco
```

Three strings sit next to each other. `Door code: ` ends with the `00` at `0x14000900B`. Then `0D 0A 00` is `"\r\n"`. Then `open-sesame` starts at `0x14000900F` and ends at the `00` at `0x14000901A`. The right-hand column shows non-printable bytes, like `00`, as dots.

Windows also uses **wide strings** (`wchar_t`, used by API functions whose names end in `W`). Each character takes 2 bytes, so plain English text looks like `44 00 6F 00 6F 00 72 00` (`D.o.o.r.`) and ends with `00 00`. Ghidra's Defined Strings lists both kinds.

## XOR

**XOR** (exclusive or, written `^` in C) compares two values bit by bit. A result bit is 1 when the two input bits differ, and 0 when they match.

```
  0x48   0100 1000    'H'
^ 0x5A   0101 1010    the key
= 0x12   0001 0010
```

XOR has three properties you will use again and again:

- `a ^ 0 = a`. XOR with zero changes nothing.
- `a ^ a = 0`. XOR with itself gives zero. That is why `xor eax, eax` sets EAX to zero.
- `a ^ k ^ k = a`. XOR with the same key twice gives back the original. Above, `0x12 ^ 0x5A` is `0x48` again.

The last property makes XOR a cheap way to hide text. A program stores each byte XORed with a key, so the text doesn't show up in a strings search. At runtime it XORs each byte with the same key and gets the text back.

To undo it yourself, you need the stored bytes and the key; both are in the program. In Python:

```python
data = bytes([0x12, 0x33, 0x7B])
print(bytes(b ^ 0x5A for b in data))   # b'Hi!'
```

If you know one original byte, you can also find the key: `key = stored ^ original`. Day 1's `ex3` hides its key this way, and Part A of the capstone asks you to undo it.

## Check yourself

1. What is `0x2A` in decimal, and what is it in binary?
2. How many bytes is a `long` in a 64-bit Windows program? How many is a `char *`?
3. A dump shows the bytes `EF BE AD DE`. What dword value is that?
4. What is `0xFFFFFFFE` as an `int`? As an `unsigned int`?
5. The byte `0x80` is sign-extended to a dword. What is the result, in hex?
6. In a dump you see `68 69 00`. What is it?
7. What is `0x37 ^ 0x37`? What is `0x41 ^ 0x20`?
8. A program stores the byte `0x3C` and you know the original was `'a'` (`0x61`). What was the XOR key?

<details><summary>Answers</summary>

1. 2 × 16 + 10 = 42. In binary it is `0010 1010`.
2. A `long` is 4 bytes on 64-bit Windows. A `char *`, like every pointer, is 8 bytes.
3. Reverse the bytes: `0xDEADBEEF`.
4. As an `int` it is -2. As an `unsigned int` it is 4,294,967,294.
5. `0xFFFFFF80`. The top bit of `0x80` is 1, so the new bytes are filled with 1s. The value stays -128.
6. The C string `"hi"`: `h` is `0x68`, `i` is `0x69`, and `00` is the terminating zero.
7. `0x37 ^ 0x37` is `0`. `0x41 ^ 0x20` is `0x61`: `'A'` becomes `'a'`, because ASCII upper and lower case differ only in the `0x20` bit.
8. `0x3C ^ 0x61` = `0x5D`.

</details>

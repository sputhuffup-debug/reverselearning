# Reading assembly

How to read x86-64 instructions as Ghidra's Listing and x64dbg's disassembly show them, and how to turn a short sequence back into C. [Day 1](../day1-training.md) uses it whenever you look past the decompiler, and [Day 3](../day3-training.md) has you read code without the decompiler at all.

Reading time: about 20 minutes. It builds on [Registers and flags](02-registers-and-flags.md).

## Intel syntax

**Assembly** is the human-readable form of machine code: one line per instruction. Each line has a **mnemonic**, the instruction's name, followed by its **operands**, the values it works on. Ghidra and x64dbg both use **Intel syntax**, where the destination comes first:

```
mov  eax, 5          ; eax = 5
add  eax, ecx        ; eax = eax + ecx
```

Read the comma as "gets": `add eax, ecx` means EAX gets EAX + ECX. Text after `;` is a comment.

Tools differ only in style. Ghidra writes mnemonics and registers in capitals (`MOV EAX,0x5`). x64dbg uses lower case and writes numbers in hex without `0x` (`mov eax,5`).

Some tools and websites use **AT&T syntax** instead, which puts the source first and adds `%` and `$`: `movl $5, %eax`. If operands look backwards, check which syntax you are reading.

## Operand sizes

Operand sizes must match. A register name sets its own size: EAX is 4 bytes, AL is 1. When an instruction reads or writes memory and no register fixes the size, a size keyword does:

```
mov  dword ptr [rbp-0x4], 0x0     ; store a 4-byte zero
mov  byte ptr  [rcx], 0x41        ; store one byte, 'A'
mov  rax, qword ptr [rdx]         ; load 8 bytes (RAX already says 8)
```

The keywords are `byte ptr` (1), `word ptr` (2), `dword ptr` (4) and `qword ptr` (8), as in [Numbers and data](01-numbers-and-data.md). x64dbg also adds a segment such as `ss:` or `ds:` before the brackets. On 64-bit Windows you can ignore it, except `gs:`, which reaches per-thread data that later days cover.

## Memory operands

Square brackets mean "the memory at this address". The address can be built from up to four parts:

```
[ base + index*scale + displacement ]
```

- **base**: a register, often RBP, RSP or a pointer.
- **index**: a register, often a loop counter.
- **scale**: 1, 2, 4 or 8, usually the size of an array element.
- **displacement**: a signed constant, such as a field offset or a local variable's offset.

Any part can be missing. Some examples:

| Operand | Address | Typical C |
| --- | --- | --- |
| `[rcx]` | RCX | `*p` |
| `[rbp-0x40]` | RBP − 0x40 | a local variable |
| `[rax+0x8]` | RAX + 8 | `p->field` at offset 8 |
| `[rdx+rax*4]` | RDX + RAX × 4 | `a[i]` for an `int` array |
| `[rbp+rax*1-0x40]` | RBP + RAX − 0x40 | `buf[i]` for a local `char` array |

Ghidra writes the same thing with spaces and explicit signs: `[RBP + RAX*0x1 + -0x40]`. It may also show a local variable's name, such as `RAX=>local_48`. [Data in memory](07-data-in-memory.md) covers arrays and structs in depth.

## RIP-relative addressing

64-bit code reaches global data and strings relative to RIP. The displacement is counted from the address of the next instruction, because RIP has already moved there when the instruction runs.

```
14000153d   lea  rdx,[rip+0x7acb]
140001544   ...                    ; next instruction
```

The address is `0x140001544 + 0x7acb = 0x14000900f`. Because the offset between the code and its data never changes, this works wherever Windows loads the program. That is how 64-bit code copes with ASLR without fixing up every address; see [Memory layout](04-memory-layout.md).

You rarely do this sum yourself. Ghidra computes the target and shows the absolute address or a label, such as `LEA RDX,[s_open-sesame_14000900f]`. x64dbg shows the address at runtime, which differs on each run because of ASLR.

## The core instructions

Each line below is one instruction with an example. "d" is the destination and "s" the source.

**Moving data**

| Instruction | Meaning | Example |
| --- | --- | --- |
| `mov d, s` | Copy s into d. Both can't be memory. | `mov eax, dword ptr [rbp-0x4]` |
| `movzx d, s` | Copy a smaller value, filling with zeros (unsigned) | `movzx eax, byte ptr [rcx]` |
| `movsx d, s` | Copy a smaller value, extending the sign (signed) | `movsx eax, byte ptr [rcx]` |
| `movsxd d, s` | Sign-extend a dword into a 64-bit register | `movsxd rax, dword ptr [rbp-0x8]` |
| `cdqe` | Sign-extend EAX into RAX | `cdqe` (often before using an `int` as an index) |
| `lea d, [addr]` | Put the address itself in d. Reads no memory. | `lea rax, [rbp-0x40]` |
| `push s` | RSP −= 8, then store s at [RSP] | `push rbp` |
| `pop d` | Load [RSP] into d, then RSP += 8 | `pop rbp` |

`lea` only does address arithmetic. `lea rax, [rbp-0x40]` puts the address RBP − 0x40 in RAX, which is `&buf` in C. Compilers also use it for plain maths: `lea eax, [rcx+rcx*2]` computes ECX × 3 without touching memory or flags.

**Arithmetic**

| Instruction | Meaning | Example |
| --- | --- | --- |
| `add d, s` | d = d + s | `add dword ptr [rbp-0x8], 0x1` (i++ at `-O0`) |
| `sub d, s` | d = d − s | `sub rsp, 0x60` |
| `inc d` / `dec d` | d = d + 1 / d = d − 1 | `inc ecx` |
| `neg d` | d = −d (two's complement) | `neg eax` |
| `imul d, s` | d = d × s (signed; the low bits are the same for unsigned) | `imul eax, edx` |
| `imul d, s, n` | d = s × n | `imul eax, ecx, 0xc` |
| `div s` / `idiv s` | Unsigned / signed divide of EDX:EAX by s. Quotient in EAX, remainder in EDX. | `cdq` then `idiv ecx` |

Before `idiv`, `cdq` sign-extends EAX into EDX; before `div`, the code zeroes EDX. The 64-bit forms use RDX:RAX and `cqo`. GCC rarely divides by a constant this way: it multiplies by a "magic" number instead, as [Day 2](../day2-training.md) shows.

**Bit operations**

| Instruction | Meaning | Example |
| --- | --- | --- |
| `and d, s` | Bitwise AND: keep only bits set in both | `and eax, 0xff` (keep the low byte) |
| `or d, s` | Bitwise OR: set bits | `or eax, 0x20` |
| `xor d, s` | Bitwise XOR: flip bits | `xor eax, eax` (set EAX, and so RAX, to 0) |
| `not d` | Flip every bit | `not eax` |
| `shl d, n` | Shift left: d × 2ⁿ | `shl eax, 0x2` (× 4) |
| `shr d, n` | Shift right, filling with zeros: unsigned ÷ 2ⁿ | `shr eax, 0x1f` (move the top bit to bit 0) |
| `sar d, n` | Shift right, copying the sign bit: signed ÷ 2ⁿ, rounded down | `sar eax, 0x2` |

**Compares and control flow**

| Instruction | Meaning | Example |
| --- | --- | --- |
| `cmp a, b` | Compute a − b, set flags, discard the result | `cmp eax, 0x9` |
| `test a, b` | Compute a AND b, set flags, discard the result | `test eax, eax` |
| `jmp target` | Always jump | `jmp 0x14000157a` |
| `jcc target` | Jump if a condition holds (`je`, `jl`, `ja` and the rest) | `jne 0x140001566` |
| `call target` | Push the return address (the next instruction), then jump | `call strcmp` |
| `ret` | Pop the return address into RIP | `ret` |
| `nop` | Do nothing | `nop` (also longer forms such as `nop dword ptr [rax]`) |

The full list of conditional jumps and their flags is in [Registers and flags](02-registers-and-flags.md). Padding between functions is often `nop` or `int3` bytes; they never run.

## Worked example: a string check at -O0

This program asks for a door code, compares it with a fixed string and prints the result. It was built with MinGW GCC at `-O0`, like Day 1's programs. Here is the end of `main` as Ghidra's Listing shows it, with addresses and simplified labels:

```
140001534   MOV   byte ptr [RBP + RAX*0x1 + -0x40],0x0
140001539   LEA   RAX,[RBP + -0x40]
14000153d   LEA   RDX,[s_open-sesame_14000900f]
140001544   MOV   RCX,RAX
140001547   CALL  strcmp
14000154c   TEST  EAX,EAX
14000154e   JNZ   LAB_140001566
140001550   LEA   RAX,[s_Welcome._14000901b]
140001557   MOV   RCX,RAX
14000155a   CALL  puts
14000155f   MOV   EAX,0x0
140001564   JMP   LAB_14000157a
          LAB_140001566
140001566   LEA   RAX,[s_Denied._140009024]
14000156d   MOV   RCX,RAX
140001570   CALL  puts
140001575   MOV   EAX,0x1
          LAB_14000157a
14000157a   ADD   RSP,0x60
14000157e   POP   RBP
14000157f   RET
```

Line by line:

1. `MOV byte ptr [RBP + RAX*0x1 + -0x40],0x0`: a 64-byte buffer starts at RBP − 0x40. RAX holds a result from the previous call (`strcspn`), used as an index. This stores a zero byte there: `input[n] = 0`.
2. `LEA RAX,[RBP + -0x40]`: RAX gets the buffer's address, `input`. No memory is read.
3. `LEA RDX,[s_open-sesame_...]`: RDX gets the address of the string `"open-sesame"`. RDX is the second argument.
4. `MOV RCX,RAX`: RCX gets `input`, the first argument. At `-O0` GCC often goes through RAX like this.
5. `CALL strcmp`: `strcmp(input, "open-sesame")`. Its `int` result comes back in EAX.
6. `TEST EAX,EAX`: ZF becomes 1 if the result is 0, that is, if the strings are equal.
7. `JNZ LAB_140001566`: jump if ZF is 0, meaning the strings differ. That target prints "Denied.".
8. Lines `140001550` to `140001564` run when the jump is not taken: `puts("Welcome.")`, then EAX = 0 (the return value), then a jump to the end.
9. Lines `140001566` to `140001575`: `puts("Denied.")`, then EAX = 1.
10. `ADD RSP,0x60`, `POP RBP`, `RET`: the function frees its stack space, restores RBP and returns. EAX is `main`'s return value.

Read back to C:

```c
input[n] = 0;
if (strcmp(input, "open-sesame") == 0) {
    puts("Welcome.");
    return 0;
}
puts("Denied.");
return 1;
```

Notice that the source says `== 0` but the jump is `JNZ`. The compiler jumps past the "then" block when the condition is false, so the jump's condition is the opposite of the `if`. Day 1's `ex1` has the same shape.

## Patterns you'll see a lot

- **Zeroing a register:** `xor eax, eax`, or `mov eax, 0x0` at `-O0`. Both clear all of RAX.
- **Stack frame setup** (the **prologue**) at the start of an `-O0` function: `push rbp`, `mov rbp, rsp`, `sub rsp, N`. N is the space for locals plus the call area; see [The stack and calls](05-stack-and-calls.md).
- **Teardown** (the **epilogue**) at the end: `add rsp, N` and `pop rbp`, or `leave`, then `ret`. `leave` does `mov rsp, rbp` and `pop rbp` in one instruction.
- **Passing a string:** `lea rax, [string]` then `mov rcx, rax` before a `call`. The string is the first argument; with RDX it is the second.
- **Setting up arguments:** values moved into ECX/RCX, EDX/RDX, R8 and R9 just before a `call`.
- **Return value:** `mov eax, N` just before the jump to the epilogue means `return N`.
- **Checking a result:** `test eax, eax` or `test rax, rax`, then `je`/`jne`. For a pointer, this is a NULL check.
- **A local `int`:** `mov dword ptr [rbp-0x4], 0x0` is `int x = 0;`, and `add dword ptr [rbp-0x4], 0x1` is `x++`.
- **An `int` used as an index:** `mov eax, dword ptr [rbp-0x8]`, `cdqe`, then a memory operand with `rax*4`. `cdqe` widens the signed index to 64 bits.
- **MinGW's `main`:** an `-O0` `main` built with MinGW starts by calling `__main`, which runs startup code. Seeing that call early is a hint you are in `main`.

[Control flow](06-control-flow.md) adds the shapes of loops and `switch` statements.

## Check yourself

1. In Intel syntax, which operand of `sub rsp, 0x28` changes?
2. What is the difference between `mov rax, qword ptr [rbp-0x10]` and `lea rax, [rbp-0x10]`?
3. Write `mov dword ptr [rdx+rax*4], 0x7` as C, assuming RDX points to an `int` array and RAX is `i`.
4. An instruction at `0x140001600` is 7 bytes long: `lea rcx, [rip+0x100]`. What address goes into RCX?
5. Why does a function sometimes use `movzx` and sometimes `movsx` to load a byte?
6. What does `shl eax, 0x3` do to the value in EAX, in arithmetic terms?
7. Just before a `call`, you see `mov edx, 0x40` and `lea rcx, [rbp-0x50]`. What are the first two arguments?
8. In the worked example, which instruction would you patch to make every code print "Welcome.", and how?

<details><summary>Answers</summary>

1. RSP, the destination. The line means RSP = RSP − 0x28.
2. `mov` loads the 8 bytes stored at RBP − 0x10. `lea` puts the address RBP − 0x10 itself in RAX and reads no memory.
3. `a[i] = 7;`. Scale 4 is the size of an `int`.
4. The next instruction is at `0x140001607`, so RCX gets `0x140001607 + 0x100 = 0x140001707`.
5. It depends on the C type. `movzx` loads an `unsigned char`, filling with zeros. `movsx` loads a signed `char`, copying the sign bit.
6. It multiplies EAX by 2³, which is 8.
7. The first argument (RCX) is the address RBP − 0x50, probably a local buffer. The second (EDX) is the number 0x40, which is 64.
8. The `JNZ` at `14000154e`. Replace it with NOPs so execution always falls through to the "Welcome." code.

</details>

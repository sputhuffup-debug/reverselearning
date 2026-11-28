# Registers and flags

The CPU's own storage: the general-purpose registers, their smaller parts, the instruction pointer and the flags that decide every branch. [Day 1](../day1-training.md) relies on it when you read RCX, RDX and RAX in x64dbg and flip ZF to change a branch.

Reading time: about 15 minutes. Read [Numbers and data](01-numbers-and-data.md) first if hex or two's complement are new to you.

## What a register is

A **register** is a small storage slot inside the CPU. An x86-64 CPU has 16 general-purpose registers of 64 bits (8 bytes) each. Instructions work on registers far faster than on memory, so compiled code loads values into registers, works on them, and stores the results back.

Registers have no type. A register holds 64 bits, and the instruction that uses it decides whether they are a number, a character or an address.

## The 16 general-purpose registers

The names are historical, and most registers can hold anything. Compiled code still follows conventions, mostly set by the **Windows x64 calling convention**: the rules for how functions pass arguments and results. [The stack and calls](05-stack-and-calls.md) covers it in full.

| Register | Usual role in Windows x64 code | Kept across calls? |
| --- | --- | --- |
| RAX | Return value of a function; scratch work | No |
| RBX | General use | Yes |
| RCX | 1st argument | No |
| RDX | 2nd argument; high half of a multiply or divide | No |
| RSI | General use (on Linux it is an argument; not on Windows) | Yes |
| RDI | General use (on Linux it is an argument; not on Windows) | Yes |
| RBP | Frame pointer at `-O0`; general use at `-O2` | Yes |
| RSP | Stack pointer: the address of the top of the stack | Yes |
| R8 | 3rd argument | No |
| R9 | 4th argument | No |
| R10, R11 | Scratch | No |
| R12 to R15 | General use | Yes |

"Kept across calls" says whether a function must preserve the register for its caller. Registers marked No are **volatile**: any call may change them, so the caller can't rely on them afterwards. Registers marked Yes are **nonvolatile**: a function that uses one saves it first, usually with `push`, and restores it before it returns.

This is why, on Day 1, you pause on a `call` and read RCX and RDX: they hold the first two arguments. After the call returns, RAX holds the result.

## Sub-registers

Each register can also be used in smaller pieces. Writing to a piece uses the low part of the full register; they are not separate storage.

```
 bit 63                          32 31            16 15      8 7       0
+----------------------------------+----------------+---------+---------+
|                              RAX (64 bits)                            |
+----------------------------------+----------------+---------+---------+
                                   |          EAX (32 bits)             |
                                   +----------------+---------+---------+
                                                    |    AX (16 bits)   |
                                                    +---------+---------+
                                                    | AH (8)  | AL (8)  |
                                                    +---------+---------+
```

| 64-bit | 32-bit | 16-bit | High 8 bits of the 16 | Low 8 bits |
| --- | --- | --- | --- | --- |
| RAX | EAX | AX | AH | AL |
| RBX | EBX | BX | BH | BL |
| RCX | ECX | CX | CH | CL |
| RDX | EDX | DX | DH | DL |
| RSI | ESI | SI | | SIL |
| RDI | EDI | DI | | DIL |
| RBP | EBP | BP | | BPL |
| RSP | ESP | SP | | SPL |
| R8 | R8D | R8W | | R8B |
| R9 to R15 | R9D to R15D | R9W to R15W | | R9B to R15B |

The R8 to R15 pieces end in D (dword), W (word) and B (byte). Intel's manuals also call the byte piece R8L. Only the first four registers have a high-byte piece like AH.

Compiled code uses the 32-bit pieces all the time, because `int` is 32 bits. So an `int` argument arrives in ECX, not RCX, and an `int` result comes back in EAX.

## Writing a piece: what happens to the rest

The rule differs by size, and it matters when you read register values in x64dbg:

- Writing a **32-bit** register sets the top 32 bits of the full register to zero.
- Writing an **8-bit or 16-bit** register leaves the other bits unchanged.

Start with RAX = `0x1122334455667788` and run each line on its own:

```
mov eax, 0xAABBCCDD    ; RAX = 0x00000000AABBCCDD  (top half zeroed)
mov ax,  0x1234        ; RAX = 0x1122334455661234  (rest unchanged)
mov al,  0xFF          ; RAX = 0x11223344556677FF  (rest unchanged)
mov ah,  0x00          ; RAX = 0x1122334455660088  (only bits 8 to 15 change)
```

So `mov ecx, 1` sets all of RCX to 1, and `xor eax, eax` clears all of RAX. Compilers use the 32-bit forms for this because their encodings are shorter.

Tools sometimes report the full register when an instruction names a piece. In a Ghidra script, `getRegister(0)` on `MOV EDX,0xe` returns `RDX`, as you see on [Day 5](../day5-training.md). x64dbg's register pane lists the full 64-bit registers, so for an `int` read only the low 8 hex digits.

## RIP, the instruction pointer

**RIP** holds the address of the next instruction the CPU will run. You can't write it with `mov`. It changes on its own after each instruction, and `jmp`, conditional jumps, `call` and `ret` set it to a new address.

In x64dbg, the highlighted line in the disassembly is the instruction at RIP: it has not run yet. Right-clicking a line and choosing "Set New Origin Here" moves RIP there, which skips or repeats code.

Code can also address memory relative to RIP. [Reading assembly](03-reading-assembly.md) explains how that works and why Ghidra shows those addresses as absolute ones.

## RSP and RBP

**RSP** is the **stack pointer**. It holds the address of the top of the stack, the memory area where functions keep return addresses, saved registers and local variables. `push`, `pop`, `call` and `ret` move it.

**RBP** is the **frame pointer** in `-O0` code. Each function sets RBP once at its start, then reaches its locals at fixed offsets such as `[rbp-0x40]`. At `-O2` it is often an ordinary register. [The stack and calls](05-stack-and-calls.md) covers both in detail, and [Memory layout](04-memory-layout.md) shows where the stack sits.

## RFLAGS

**RFLAGS** is a special register whose bits, the **flags**, describe the result of the last arithmetic or logic instruction. Conditional jumps read them. Four matter most:

| Flag | Name | Set to 1 when the result... |
| --- | --- | --- |
| ZF | Zero flag | is zero |
| SF | Sign flag | has its top bit set (is negative, read as signed) |
| CF | Carry flag | carried out of or borrowed past the top bit (unsigned overflow) |
| OF | Overflow flag | doesn't fit as a signed number (signed overflow) |

There are others, such as PF, AF, DF and TF; you will rarely need them. x64dbg shows each flag as 0 or 1 below the registers.

Not every instruction changes the flags. This table covers the common ones:

| Instructions | Effect on the flags |
| --- | --- |
| `add`, `sub`, `cmp`, `neg` | Set ZF, SF, CF and OF from the result |
| `inc`, `dec` | Set ZF, SF and OF; leave CF unchanged |
| `and`, `or`, `xor`, `test` | Set ZF and SF; clear CF and OF to 0 |
| `shl`, `shr`, `sar` | CF gets the last bit shifted out; ZF and SF from the result (a shift by 0 changes nothing) |
| `imul`, `mul` | Set CF and OF if the full result didn't fit; ZF and SF are undefined |
| `div`, `idiv` | All four undefined |
| `mov`, `lea`, `push`, `pop`, `not`, `movzx`, `movsx`, `jmp`, `call`, `ret` | No change |

"Undefined" means the CPU may leave any value there, so code never relies on it.

## cmp, test and conditional jumps

A branch in compiled code is almost always two instructions: one that sets the flags and a **conditional jump** that reads them.

- `cmp a, b` subtracts b from a, sets the flags, and throws the result away. Neither operand changes.
- `test a, b` ANDs a and b, sets the flags, and throws the result away. `test eax, eax` is the usual way to ask "is EAX zero?" ZF is 1 only if EAX is zero.

A conditional jump goes to its target if its condition holds. Otherwise it **falls through** to the next instruction. After `cmp a, b`, the common jumps mean:

| Jump | Also written | Jumps if | Flags it reads | Kind |
| --- | --- | --- | --- | --- |
| `je` | `jz` | a == b (result zero) | ZF = 1 | Either |
| `jne` | `jnz` | a != b | ZF = 0 | Either |
| `jl` | `jnge` | a < b | SF ≠ OF | Signed |
| `jle` | `jng` | a <= b | ZF = 1 or SF ≠ OF | Signed |
| `jg` | `jnle` | a > b | ZF = 0 and SF = OF | Signed |
| `jge` | `jnl` | a >= b | SF = OF | Signed |
| `jb` | `jc`, `jnae` | a < b | CF = 1 | Unsigned |
| `jbe` | `jna` | a <= b | CF = 1 or ZF = 1 | Unsigned |
| `ja` | `jnbe` | a > b | CF = 0 and ZF = 0 | Unsigned |
| `jae` | `jnb`, `jnc` | a >= b | CF = 0 | Unsigned |
| `js` | | result negative | SF = 1 | Signed |
| `jns` | | result not negative | SF = 0 | Signed |

The names in each row are the same instruction. Tools pick different ones: Ghidra writes `JZ` and `JNZ`, and x64dbg writes `je` and `jne`. Remember "less/greater" for signed and "below/above" for unsigned.

The signed or unsigned choice comes from the C types. Suppose EAX is `0xFFFFFFFF` and EBX is 1, and the code runs `cmp eax, ebx`:

- Read as signed, EAX is -1, which is less than 1. `jl` jumps; `jg` doesn't.
- Read as unsigned, EAX is 4,294,967,295, which is above 1. `ja` jumps; `jb` doesn't.

So the jump tells you the type: `jl` or `jg` after a compare means the variables are signed, like `int`. `jb` or `ja` means unsigned, like `unsigned int`, `size_t` or a pointer.

Compilers often reverse the condition: they jump past the "then" block when the `if` is false. [Control flow](06-control-flow.md) shows how `if`, loops and `switch` turn into these jumps.

## Day 1: flipping ZF to take the other branch

At `-O0`, Day 1's checks follow the same shape: a call, then `test eax, eax`, then `jne` or `je`. For a string check, the code looks like this:

```
call  strcmp
test  eax, eax         ; ZF = 1 if strcmp returned 0 (strings equal)
jne   <denied>         ; jumps if ZF = 0 (strings differ)
```

With a wrong password, `strcmp` returns a nonzero value, so `test` sets ZF to 0 and `jne` jumps to the "denied" code. If you pause on the `jne` in x64dbg and double-click ZF to make it 1, the jump falls through to the "granted" code instead.

Flipping a flag changes one run only. To make the change permanent, you patch the jump itself, as in Day 1's Part C. Setting RAX to 0 after `IsDebuggerPresent` works the same way: it changes what `test eax, eax` sees.

## Check yourself

1. Which registers hold the first four integer arguments in Windows x64 code? Which holds the return value?
2. RCX is `0xFFFFFFFFFFFFFFFF`. What is RCX after `mov ecx, 5`? What would it be after `mov cl, 5` instead?
3. What is the difference between a volatile and a nonvolatile register? Name two of each.
4. What does `cmp eax, 10` change, apart from the flags?
5. After `test eax, eax`, EAX is 0. What is ZF, and does `jnz` jump?
6. A loop ends with `cmp eax, edx` and `jb` back to the top. Are the values signed or unsigned?
7. EAX is `0xFFFFFFFE` and the code runs `cmp eax, 3`. Does `jg` jump? Does `ja` jump?
8. You are paused on a `je` in x64dbg, and ZF is 0. What happens when you press F8, and what changes if you set ZF to 1 first?

<details><summary>Answers</summary>

1. RCX, RDX, R8 and R9, in that order (ECX, EDX, R8D and R9D for 32-bit values). The result comes back in RAX (EAX for an `int`).
2. `mov ecx, 5` gives `0x0000000000000005`, because writing a 32-bit register zeroes the top half. `mov cl, 5` gives `0xFFFFFFFFFFFFFF05`, because writing an 8-bit register leaves the rest unchanged.
3. A volatile register may be changed by any call, so the caller can't rely on it afterwards. A nonvolatile one must be the same after a call, so a function that uses it saves and restores it. Volatile: RAX, RCX, RDX, R8 to R11. Nonvolatile: RBX, RBP, RSI, RDI, R12 to R15 (and RSP).
4. Nothing. `cmp` throws away the result of its subtraction; only the flags change.
5. ZF is 1. `jnz` jumps only when ZF is 0, so it falls through.
6. Unsigned. `jb` means "below", the unsigned less-than.
7. As signed, EAX is -2, which is not greater than 3, so `jg` doesn't jump. As unsigned, it is 4,294,967,294, which is above 3, so `ja` jumps.
8. With ZF = 0, `je` doesn't jump and execution falls through to the next instruction. With ZF set to 1, `je` jumps to its target.

</details>

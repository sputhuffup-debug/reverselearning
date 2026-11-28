# Day 1 checkpoint: answer and model write-up

SPOILERS for the [Checkpoint](../../../docs/day1-training.md#checkpoint). Solve `bin/day1/checkpoint.exe` first, then check your work here. The source is [checkpoint.c](checkpoint.c).

Addresses and offsets below come from MinGW GCC at `-O0`. Your build may place things differently; the shapes stay the same.

## The answer

The code is `Br34kp01nt`.

| Input | Output | Exit code |
| --- | --- | --- |
| `Br34kp01nt` | Unlocked. Checkpoint passed. | 0 |
| `Br34kp01nx` | Wrong code. | 1 |
| `Br34k` | Wrong length. | 1 |
| `Bs57ou68v}` | Wrong code. | 1 |

## How the program checks the code

There are two checks, one after the other:

1. In `main`, `strlen` of the input must be exactly 10. Otherwise it prints "Wrong length." and returns 1.
2. A second function loops over the 10 characters. For each index `i`, `input[i] + i` must equal byte `i` of a 10-byte table in `.rdata`. The first mismatch prints "Wrong code." and returns 1.

The table holds `42 73 35 37 6F 75 36 38 76 7D`. Subtract each byte's index to get the code:

```python
table = [0x42, 0x73, 0x35, 0x37, 0x6F, 0x75, 0x36, 0x38, 0x76, 0x7D]
print("".join(chr(b - i) for i, b in enumerate(table)))   # Br34kp01nt
```

## The trap

The table bytes are printable, and the linker puts them right before the prompt. Ghidra's Defined Strings may show one string such as `Bs57ou68v}Unlock code: `. Typing `Bs57ou68v}` gives "Wrong code.", because it skips the `+ i` step.

If you tried it, that is fine; the lesson is to read the code that uses a string, not just the string.

## Model write-up

A good hand-in covers the points below. Wording and addresses will differ.

```
Program:  checkpoint.exe (stripped, -O0)
Code:     Br34kp01nt (checked: prints "Unlocked. Checkpoint passed.", exit 0)

How I found it
- Defined Strings: "Wrong length.", "Wrong code.", "Unlocked. Checkpoint passed.".
  References to "Wrong code." led to main (FUN_140001531, renamed main).
- main: fgets into a 64-byte buffer, strip the newline, strlen.
  cmp rax, 0xa / je -> length must be 10, else "Wrong length.".
- Then call FUN_1400014d4 (renamed check_code) with the buffer.
  test eax, eax / jne -> nonzero means success, zero prints "Wrong code.".
- check_code(s): for i = 0..9, if (byte)(s[i] + i) != table[i] return 0; return 1.
  Retyping the parameter to char * made it read s[i]. table is DAT_140009000 in .rdata.
- Decoded the table by subtracting i from each byte (Python above).

Confirmed in x64dbg
- Breakpoint on cmp cl, al inside check_code. With input Br34kp01nx, CL and AL
  match nine times; on the tenth, CL = 0x81 ('x' + 9) and AL = 0x7D.

Bypass
- Runtime: at the jne after check_code, set ZF to 0, so it jumps to "Unlocked".
  The length check needs ZF = 1 at its je, or a 10-character input.
- Patch (offsets from the image base):
  0x15A6  je  (74 16) -> jmp (EB 16)   length check always passes
  0x15CC  jne (75 16) -> jmp (EB 16)   code check always passes
  Both wanted paths are the jump targets, so both become jmp, not NOP.
  Saved as checkpoint_patched.exe; any input prints "Unlocked. Checkpoint passed.".
```

## Common mistakes

- Missing the `+ i`. At `-O0` it is a `lea ecx, [rdx+rax*1]` that adds the index to the character before the `cmp`.
- NOPing either jump in `main`. Both jumps lead to the path you want, so a NOP sends every run to a failure message.
- Patching only the second jump. A wrong-length input still stops at the first check.
- Patching inside `check_code` is also valid. For example, change the `je` after `cmp cl, al` to `jmp` so no byte ever fails.

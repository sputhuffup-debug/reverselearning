# Day 1 extra credit: hints and expected results

SPOILERS for the challenges in [Beyond this lesson](../../../docs/day1-training.md#beyond-this-lesson). Try each challenge first.

Addresses and stack offsets below come from MinGW GCC at `-O0`. Your build may use different offsets; the shapes stay the same.

## 1. Two ways to break ex1 (★)

**Hints**

- The jump after `test eax, eax` is a `jne` (Ghidra shows `JNZ`) to the "Access denied." code.
- NOP it with "Fill with NOPs" ticked; for the other copy, change `jne` to `je` and keep the size.

**Expected results**

| Input | NOP copy | Reversed copy |
| --- | --- | --- |
| `hunter2-ghidra` | Access granted! | Access denied. |
| `hunter2` | Access granted! | Access granted! |
| `x` | Access granted! | Access granted! |

The NOP copy never jumps, so every input reaches "granted". The reversed copy swaps the two outcomes, so only the right password is now refused.

## 2. Let short names into ex2 (★)

**Hints**

- The check follows the `strlen` call in `main`: `cmp rax, 0x3`, then `ja` (Ghidra shows `JA`) over the "at least 4 characters" message.
- `ja` is an unsigned compare, because `strlen` returns a `size_t`.
- Either change `ja` to `jmp`, or change the constant in the `cmp` to `0x1` so names of 2 or more pass.

**Expected results**

- Before: `cmp rax, 0x3` / `ja <serial prompt>`. After: `cmp rax, 0x3` / `jmp <serial prompt>`. The short jump keeps its size (`77` becomes `EB`).
- The serial for `ab` is `88d276`. For `x` it is `c2abcf`, if you let 1-character names through.
- The unpatched program still prints "Name must be at least 4 characters." for `ab`.

## 3. Catch the key as it is written (★★)

**Hints**

- Just before the call to `decode`, the code runs `lea rax, [rbp-0x4f]`, then `mov rcx, rax`, and sets EDX to `0xe`.
- Stop on the `call`, right-click RCX → Follow in Dump, and note the address. Press F8, and the dump shows the change in place.
- The key buffer sits 15 bytes below the input buffer at `[rbp-0x40]`.

**Expected results**

- Offset: `rbp-0x4f` (Ghidra's `local_57`).
- Before `decode`: leftover stack bytes, different on each run.
- After `decode`: `52 33 76 33 72 73 31 6E 67 5F 44 34 79 31 00`, which is `R3v3rs1ng_D4y1` and its terminating zero.

## 4. Swap serial algorithms (★★)

**Hints**

- The start value is the first `mov dword ptr [rbp-0x4], N` in the function. At `-O0`, GCC writes it in decimal in its own output, so convert to hex if you need to.
- A small multiplier often compiles to shifts and adds instead of `imul`. For example, `h * 33` becomes `shl eax, 5` then an `add`; a large one such as 131 stays `imul eax, edx, 0x83`. The decompiler folds both back into `*`.
- The final XOR is one `xor eax, <constant>` just before the epilogue. Right-click it in Ghidra to see it in hex.
- Keep the `& 0xFFFFFFFF` after each step in your keygen, as in `keygen_ex2.py`.

**Expected results**

- The keygen's output, in lower-case hex without `0x`, makes the partner's program print "Valid serial." for each of the three names.
- If only long names fail, the 32-bit mask is missing. If every name fails, recheck the start value and XOR constant in hex.

## 5. Make ex3 tell you its key (★★★)

**Hints**

- In the "Bad license key." branch, the code loads the message with `lea rax, [rip+...]` (7 bytes: `48 8D 05` and a 4-byte offset), then `mov rcx, rax` and `call puts`.
- The decoded key is still in `main`'s frame at that point, at the offset you found in challenge 3.
- In x64dbg, press Space on that `lea`, type `lea rax, [rbp-0x4F]`, and tick "Fill with NOPs". Save with Patch File under a new name.

**Expected results**

- Original: `lea rax, [rip+...]`, bytes `48 8D 05 xx xx xx xx`. New: `lea rax, [rbp-0x4F]`, bytes `48 8D 45 B1`, then `90 90 90`.
- Run outside the debugger with a wrong key, the patched copy prints `R3v3rs1ng_D4y1` instead of "Bad license key.".
- Under x64dbg it still prints "Debugger detected. Bye." unless you also patch or bypass the check.

## 6. Write a crackme for a partner (★★★)

**Hints for the author**

- Combine two of: a length check, `strcmp` or `memcmp`, a computed serial, an XOR-hidden secret, `IsDebuggerPresent`.
- If your decoder stops at a zero byte, pick a key that turns no character of the secret into `0x00`.
- Build with `gcc -O0 -s` and test it yourself with the right and a wrong answer before you swap.

**Hints for the solver**

- Start the same way as today: Defined Strings, then Imports, then the references to the failure message.
- For a hidden secret, find the decoder, then the three facts: where the bytes are, the key, and the count.

**Expected results**

- The solver's secret matches the author's source, and the program accepts it.
- The write-up names each check, how it was found, and the offset of any patched instruction.

# Day 2 extra credit: hints and expected results

SPOILERS for the "Beyond this lesson" challenges in [docs/day2-training.md](../../../docs/day2-training.md). Try each challenge first.

The expected results below come from MinGW-w64 GCC 13 builds. The kit's w64devkit GCC may be newer, so instruction choice, register names and counts can differ. Where they do, the pattern still holds: check what you see against the reasoning, not against the exact numbers.

Build commands, from the Devkit shell in the `lab` folder:

```bash
gcc -s -Wall -O1 day1/ex2_serial.c -o bin/day2/ex2o1.exe
gcc -s -Wall -O3 day1/ex2_serial.c -o bin/day2/ex2o3.exe
gcc -s -Wall -Os day1/ex2_serial.c -o bin/day2/ex2os.exe
gcc -s -Wall -O2 -S -masm=intel day2/ex4_chain.c -o bin/day2/ex4o2.s   # GCC's own assembly
```

## 1. The optimization ladder for ex2 (★)

**Hints.** Find `main` from "Invalid serial." in each build, as in Exercise 1.2. Look for `0x1337` (4919) and `0xC0FFEE` first; the multiply sits between them.

**Expected results.**

| Build | `make_serial` separate? | `h * 31` done with | Instructions in `main` (GCC 13) |
| --- | --- | --- | --- |
| `-O0` (`ex2.exe`) | Yes | `shl` by 5, then `sub` | about 66, plus `make_serial` |
| `-O1` | No, inlined | `shl` by 5, then `sub` | about 70 |
| `-O2` (`ex2o2.exe`) | No, inlined | `shl` by 5, then `sub` | about 63 |
| `-O3` | No, inlined | `shl` by 5, then `sub` | about 63; identical to `-O2` here |
| `-Os` | No, inlined | `imul eax, eax, 0x1f` | about 51 |

`make_serial` is `static` and called once, so GCC inlines it from `-O1` up. `-Os` optimizes for size, and one `imul` is shorter than a shift and a subtract. That is why 31 shows up as a number again only in the `-Os` build. In some builds `0x1337` appears twice, because the compiler copied the loop's start onto two paths.

The keygen works for every build: the algorithm never changes, only its encoding.

## 2. Which functions survive in ex4? (★★)

**Hints.** Follow the chain from `main`, as in Exercises 2.1 and 3.1. For the remainder, look at the end of `zone_key` for `imul` with `0x55e63b89`, or for a `div`.

**Expected results.**

| Build | `rotl` | `zone_key`, `check_door`, `check_zone`, `check_access` | Last instruction of `check_access` and `check_zone` | Remainder |
| --- | --- | --- | --- | --- |
| `-O0` | Separate function | All separate | `call` then `leave`/`ret` | Magic multiply, `shr rax, 0x20` then `shr eax, 0x19` |
| `-O1` | Inlined as `rol` | All separate | `call` then `ret`: no tail calls | Magic multiply, `shr rax, 0x39` |
| `-O2` | Inlined as `rol` | All separate | `jmp` | Magic multiply, `shr rax, 0x39` |
| `-O3` | Inlined as `rol` | All separate | `jmp` | Same as `-O2` |
| `-Os` | Inlined as `rol` | All separate | `jmp` | `div ecx` with ECX = 100000000 |

- The four larger functions survive at every level because the source marks them `noipa`, which forbids inlining. Without it, `-O2` would fold most of the chain into `main`.
- GCC turns tail calls into `jmp` from `-O2` up (`-foptimize-sibling-calls`). `-O1` keeps every `call`.
- `-Os` uses `div`, because one divide instruction is shorter than the multiply, shift, multiply-back and subtract. It is slower, but `-Os` trades speed for size.

## 3. Recover a division from its magic number (★★)

**Hints.**

- Unsigned: `mov` or `movzx` to widen, `imul` by the magic number, then `shr`. Signed: `movsx`, `imul`, `sar`, and a `sar ..., 0x1f` and `sub` pair that rounds toward zero.
- Add every shift that follows the multiply. A high-half multiply (`mul` or `imul` that leaves the result in EDX or the top of RAX) counts as a shift of 32.
- The divisor is about 2^(total shift) / magic. In Python: `round(2**37 / 0x88888889)` gives 60.
- If the result is not close to a whole number, you missed a shift, or the code adds the dividend back (see below).

**Expected results.** You should get a whole number every time, and the program's output should match `x / d` on your test inputs.

Some divisors need a 33-bit magic number, and unsigned division by 7 is the usual example. GCC takes the high half of x × magic as q, then computes `(((x - q) >> 1) + q) >> 2`. In that case add 2^32 to the magic number: divisor ≈ 2^(total shift) / (2^32 + magic).

For `x / 7`, GCC 13 emits `imul rax, rax, 0x24924925`, `shr rax, 0x20`, `sub`, `shr ecx`, `add` and `shr eax, 2`. The total shift is 32 + 1 + 2 = 35, and 2^35 / (2^32 + `0x24924925`) is 7.0.

For signed code, test a negative input. C rounds toward zero, so `-7 / 2` is `-3`, not `-4`. The `sub` of the sign mask is what makes that happen.

## 4. Break the tail call (★★★)

**Hints.** A `jmp` is only possible when the caller has nothing left to do and its frame is no longer needed. The callee must also fit its stack arguments into the space the caller itself received.

**Expected results** with GCC 13 at `-O2`. The unchanged `check_access` ends in `jmp`.

| Change to `check_access` | Ends in | Why |
| --- | --- | --- |
| `return check_zone(code, 7) + 1;` | `call`, then `add eax, 1` and `ret` | Work is left after the call: the add |
| `return !check_zone(code, 7);` | `call`, then `test`, `sete`, `movzx` and `ret` | Work is left: the result must be turned into 0 or 1 |
| Pass `&local` to a helper | `call` | The helper receives a pointer into `check_access`'s frame, so the frame must outlive the call. This is the same reason as `check_pass` in `ex5` |
| `return zone_key(code, 4, 12, 5, 0xC0DE, 0x2026);` | `call` | `zone_key` needs two stack arguments. `check_access` received only the 32-byte shadow space, so it has nowhere to put them once its own frame is gone |
| Return `long long` from `check_access` | `call`, then `cdqe` and `ret` | Work is left: the `int` result must be sign-extended to 64 bits |

The fourth case surprises most people, because nothing is done after the call. Look at where arguments 5 and 6 would have to go after a `jmp`: at `[rsp+0x28]` and `[rsp+0x30]` on entry to the callee. Those slots belong to the caller's caller, which never reserved them.

## 5. ex4's code from the -O2 Listing alone (★★★)

**Hints.**

- List the inputs first: ECX, EDX, R8D, R9D, and the two stack slots at `[rsp+0x28]` and `[rsp+0x30]`.
- `imul edx, edx, 0x1eef` is `floor * 7919`; `imul eax, ecx, 0xf4243` is `zone * 1000003`.
- `rol edx, cl` rotates left by CL, and CL was loaded from R9D.
- The tail end is a remainder, as in worked example 3: magic `0x55e63b89`, total shift 57, then `imul` by the divisor and `sub`.

**Expected pseudo-code:**

```
k = zone * 1000003 + floor * 7919 + door    // two imul, two add
k = rotl(k, shift)                          // mov ecx, r9d; rol edx, cl
k = k ^ salt                                // xor edx, [rsp+0x28]
k = k + pepper                              // add edx, [rsp+0x30]
q = (k * 0x55e63b89) >> 57                  // q = k / 100000000
return k - q * 100000000                    // k % 100000000
```

2^57 / `0x55e63b89` is 100000000.0…, which confirms the divisor. With `zone_key(7, 4, 12, 5, 0xC0DE, 0x2026)` the code is 25039268, the same as in the answer key and in [ex4\_code.py](ex4_code.py).

GCC may order the first three lines differently; any order that computes the same sum is right. All arithmetic is 32-bit, so mask with `& 0xFFFFFFFF` in Python after each step.

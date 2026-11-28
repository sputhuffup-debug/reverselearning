# Day 0 checkpoint: answer and model write-up

SPOILERS for the [Checkpoint](../../../docs/day0-training.md#checkpoint) in Day 0. Finish your own notes first, then compare.

**Answer:** type `10847`. The program prints "Unlocked. Checkpoint passed." and exits with code 0.

The offsets below come from a MinGW GCC 13 build at `-O0 -s`. The kit's GCC may place things differently; the shape stays the same.

## Hints, in order

Read one at a time, and go back to the program after each.

1. Run it with three different inputs and write down each output and exit code. There are four different outcomes.
2. One string looks like a password. Test it, and note what happens and which exit code you get.
3. The imports include a function that turns text into a number. What does that suggest about the real answer?
4. Find the code that prints "Unlocked. Checkpoint passed." and look just above it for a compare with a constant.
5. The constant is in hex. The program reads the number in decimal.

## Model write-up

### Target

| Field | Value |
| --- | --- |
| File | `bin/day0/checkpoint.exe` |
| Size and SHA-256 | Depend on your build; record your own |
| Goal | Find the input that unlocks the program |

### Triage

- **Kind:** PE32+ console `.exe` (`objdump -f`: `pei-x86-64`; Ghidra: `x86:LE:64`).
- **Sections:** the usual ten MinGW sections; nothing writable and executable; entry point in `.text`.
- **Packed?** No. Normal sections, a normal import list and readable strings.
- **Imports that matter:** `fgets` (reads a line), `strcspn` (strips the newline), `strcmp` (compares text), `strtol` (text to number), `puts`. The rest is MinGW runtime.
- **Strings that matter:** "Unlock code: ", "debug-override", "Maintenance mode is disabled in this build.", "Not a number.", "Unlocked. Checkpoint passed.", "Wrong code.".
- **First runs:**

| Input | Output | Exit code |
| --- | --- | --- |
| `abc` | Not a number. | 2 |
| `1234` | Wrong code. | 1 |
| `debug-override` | Maintenance mode is disabled in this build. | 3 |

### Functions

| Offset | Name | Purpose | Confidence | How you know |
| --- | --- | --- | --- | --- |
| `0x14d4` | `main` | Reads the code and checks it | known | Only xref to "Unlock code: " |
| `0x16c0` | `lib_main_init` | MinGW's `__main`, first call in `main` | known | Called before anything else; see Day 1 |

### Hypotheses

| # | Hypothesis | Evidence | Test | Result |
| --- | --- | --- | --- | --- |
| H1 | The code is `debug-override` | A password-like string | Run with it | Refuted: "Maintenance mode is disabled", exit 3 |
| H2 | The code is a number | `strtol` import; "Not a number." | Run with `abc` and `1234` | Confirmed: different messages |
| H3 | One compare against a constant decides it | Message order in `.rdata` | Ghidra: code above "Unlocked." | Confirmed: `CMP dword ptr [RBP + -0x4],0x2a5f`, then `JNZ` to "Wrong code." |
| H4 | The base is 10 | `strtol`'s third argument | `R8D` is `0xa` at the call; run with `0x2a5f` | Confirmed: `0x2a5f` prints "Not a number." |

### How the check works

`main` prints the prompt, reads a line with `fgets` and cuts the newline with `strcspn`. It first compares the line with `debug-override` and, on a match, prints the maintenance message and returns 3. It is a decoy: it never unlocks anything.

Next it calls `strtol(line, &end, 10)`. If no digits were read, or anything follows them, it prints "Not a number." and returns 2.

Then it compares the result with `0x2a5f`, which is 10847. Equal prints "Unlocked. Checkpoint passed." and returns 0; anything else prints "Wrong code." and returns 1.

In the decompiler, after renaming, the check reads something like:

```c
code = strtol(line, &end, 10);
if ((end == line) || (*end != '\0')) { puts("Not a number."); return 2; }
if (code == 0x2a5f) { puts("Unlocked. Checkpoint passed."); return 0; }
```

### Dynamic confirmation

In x64dbg, find "Unlocked. Checkpoint passed." with String references. Break on the `cmp` with `2A5F` just above it, run, and enter `1234`. The stack slot it reads holds `4D2`, which is 1234. Run again with `10847`: the slot holds `2A5F`, and the `jne` to "Wrong code." is not taken.

### Answer

`10847`. Shown by running `echo 10847 | ./checkpoint.exe; echo $?` in the Devkit shell, which prints the success line and `0`.

### Open questions

- None for the check. The `strcmp` decoy has no other effect.

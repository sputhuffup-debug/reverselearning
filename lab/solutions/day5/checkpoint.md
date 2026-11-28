# Day 5 checkpoint: answer and model write-up

SPOILERS for the [Checkpoint](../../../docs/day5-training.md#checkpoint). Finish your own notes and script before you read this.

The program's source is [checkpoint.c](checkpoint.c), and the complete script is [Day5Checkpoint.java](Day5Checkpoint.java). Addresses below come from one MinGW build; yours may differ by a few bytes.

## The answer

The passphrase is `north-relay-holds-at-dawn-42`. Entering it prints "Relay open. All stations report." and exits with 0.

`south-relay-folds-at-dusk-17` is the trap. It is what you get if you decode the decoy stations and ignore the flag test.

## Model write-up

This is a model of the half page the checkpoint asks for, in the shape of the [analysis notes template](../../../docs/templates/analysis-notes.md).

**Question.** What passphrase does `checkpoint.exe` accept? Defined Strings shows the prompt, "Relay open." and "Wrong passphrase.", but no passphrase.

**Where the check is.** "Relay open." is used once, in `main` (`FUN_140001656`). The last call before it is to `FUN_1400014d4`, whose return value `main` tests. I renamed it `check_phrase`; its argument is the line I typed.

**The table.** `check_phrase` reads bytes from `0x140008000`, the start of `.data`. Its loops multiply the index by 4 and run while `j <= 0x27`, so there are 40 records of 4 bytes. The prompt also says 40 stations.

**The record layout.**

| Offset | Field | How the check uses it |
| --- | --- | --- |
| 0x00 | flags | `AND EAX,0x10` then `JNE`: records with bit `0x10` set are skipped |
| 0x01 | seq | compared with the position `i` in the passphrase, and multiplied by 3 |
| 0x02 | sig | compared with the computed byte |
| 0x03 | key | XORed with the typed character |

**The encoding.** For position `i`, the check finds the live record with `seq == i`. It computes `(c ^ key) + 3 * seq` in 8 bits and compares it with `sig`. Undoing it gives `c = (sig - 3 * seq) ^ key`, masked to 8 bits after the subtraction.

**The first loop.** Before the main loop, `check_phrase` counts the live records and compares the count with `strlen` of the input. So the passphrase is exactly as long as the number of live stations: 28.

**By hand, records 1 to 3.**

| Record | flags | seq | sig | key | Live? | `sig - 3*seq` | Character |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 0x4F | 7 | 0xFD | 0x8D | yes | 0xE8 | 0xE8 ^ 0x8D = 0x65, `e` |
| 2 | 0xD5 | 26 | 0x4A | 0xCD | no, decoy | 0xFC | 0xFC ^ 0xCD = 0x31, `1` |
| 3 | 0x43 | 11 | 0x8B | 0x47 | yes | 0x6A | 0x6A ^ 0x47 = 0x2D, `-` |

Record 2 shows why the flag matters: it is a readable character that does not belong. Record 1 shows why the order matters: the first record holds position 7, not position 0.

**Plan in words.**

1. Find "Relay open." and follow its reference to `main`.
2. Walk `main` and keep the last call to a non-thunk function before the string is used. That is the check.
3. Walk the check and keep the lowest address it refers to in `.data`. That is the table.
4. For each of the 40 records, read the four fields and decode the character.
5. Skip records with bit `0x10` set. Store each other character at position `seq`.
6. Check that positions 0 to 27 are each filled once, then print them in order.

**How the script finds things without hardcoded addresses.** It starts from a string, not an address. At -O0 each field gets its own `LEA` (`table+0`, `+1`, `+2`, `+3`), so the script takes the lowest `.data` address, not the first one it sees. `printf` is MinGW's own code, not a thunk, but it is called before the check, so the check replaces it as "the last call".

**Checks along the way.** The script's lines for records 1 to 3 matched the table above. It printed 28 live records and 12 decoys, and every position from 0 to 27 appeared once. The passphrase it printed opened the relay.

**Result.** `north-relay-holds-at-dawn-42`. 12 decoys spell `south`, `f`, `dusk` and `17` at the positions they share with live stations.

**Why a script.** By hand this is 40 records, four fields each, a subtraction and an XOR, then a sort. That is about an hour of careful arithmetic, and one slip gives a wrong letter with no clue where. The script took 20 minutes once the layout was known, and it reruns in a second.

## Common mistakes

| Symptom | Cause |
| --- | --- |
| The phrase starts `e-4n-ty2` | Printed in table order. Sort by `seq` |
| Some positions have two characters, or the phrase reads `south` or `dusk` | The decoys are included. Skip records with bit `0x10` set |
| Every character is wrong, but the layout looks right | XOR before subtracting. The check XORs first, so you undo the addition first |
| Characters are wrong only for later positions | `3 * seq` was left out, or the subtraction was not masked with `& 0xff` |
| The table address is one byte too high | The script kept the first `.data` reference it saw, such as `table+1`, not the lowest |
| Record 2 onwards is garbage | The record size is wrong. It is 4 |

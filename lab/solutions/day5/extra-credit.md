# Day 5 extra credit: hints and expected output

SPOILERS for the challenges in [Beyond this lesson](../../../docs/day5-training.md#beyond-this-lesson). Write your own plan in words for a challenge before you read its hints.

There is no solution code here, only hints, the API calls to look up and the output to expect. The API is at [ghidra.re/ghidra_docs/api](https://ghidra.re/ghidra_docs/api/), or behind the Help button in the Script Manager.

Addresses and counts from MinGW's startup code depend on your compiler, so they are left out. Save your scripts in your own folder, with class names that don't clash with `lab/day5/scripts` or this folder.

## 1. Count the calls to every import (★)

**Hints**

- Every import stub is a thunk, so Exercise 5.1's loop and `isThunk()` find them all.
- For each thunk, count the references to its entry point that come from a call, as in Exercise 5.2's TODO 3.
- A name-to-count table is a `Map`. `java.util.HashMap` has `put`, `get` and `getOrDefault`. Two parallel `List`s work too, if you prefer what the primer covers.
- Sort last. Print the table unsorted first and check the counts, then sort the names by their count. `List.sort` with a comparator does it; so does picking the largest one by one.
- Leave out thunks with zero calls, or print them at the end. Many come from MinGW's startup code.

**API calls to look up:** `getFirstFunction()`, `getFunctionAfter(Function)`, `Function.isThunk()`, `Function.getEntryPoint()`, `getReferencesTo(Address)`, `getInstructionAt(Address)`, `Instruction.getFlowType()`, `FlowType.isCall()`.

**Expected output** on Day 1's `ex1`, among MinGW's own imports:

```text
puts      2
strcmp    1
fgets     1
strcspn   1
```

**The two questions.** `printf` has no stub because MinGW links its own `printf` into the program: it is ordinary code in `.text`, a `FUN_` function. `ex3` calls `IsDebuggerPresent` through its IAT slot: `MOV RAX,qword ptr [slot]` then `CALL RAX`. No stub exists, so there is nothing for this script to count. See primer 04, [Imports and the IAT](../../../docs/primers/04-memory-layout.md#imports-and-the-iat), and primer 05, [IsDebuggerPresent through the IAT](../../../docs/primers/05-stack-and-calls.md#isdebuggerpresent-through-the-iat).

**Stretch:** also count calls made through an IAT slot. Show References to on the slot's address lists the `MOV`s that read it. In a script, `getReferencesTo` on the slot gives the same list; check that a call follows each `MOV`.

## 2. Name functions after their strings (★★)

**Hints**

- Skip thunks, and skip any function whose name doesn't start with `FUN_`. That keeps your own renames and the import names.
- Walk each function's instructions in address order, and stop at the first reference that leads to a string.
- Reuse what Exercise 5.2 taught about strings. `getDataAt` misses strings Ghidra never defined, so also read the bytes up to the zero, and accept them only if they are all printable.
- Build a valid name from the string: keep letters and digits, turn everything else into `_`, and cut it to about 24 characters. Add a prefix such as `uses_`, since a name can't start with a digit.
- Two functions can use the same first string. If `setName` refuses the second name with an exception, catch it, print a message, and add the function's address to the name.
- Print each rename as "old name -> new name", so the console is a record of what changed.

**API calls to look up:** `Function.getName()`, `Function.getBody()`, `currentProgram.getListing().getInstructions(AddressSetView, boolean)`, `Instruction.getReferencesFrom()`, `getDataAt(Address)`, `getByte(Address)`, `Function.setName(String, SourceType)` with `SourceType.USER_DEFINED` (import `ghidra.program.model.symbol.SourceType`).

**Expected output.** On Day 1's `ex1`, `main` becomes `uses_Enter_password_`, because "Enter password: " is the first string it loads. On `ex3`, `main` becomes `uses_Debugger_detected_Bye_` if your script reads undefined strings. If it trusts only defined data, `main` gets the name of the second string, `uses_License_key_`, which shows why reading the bytes matters.

`decode` in `ex3` loads only the `secret` array, whose bytes aren't printable, so it keeps its `FUN_` name. A few MinGW startup functions get names from their own error messages.

**Undo.** A script run from the Script Manager makes its changes as one step, so Ghidra's undo reverts them together. Or practice on a copy: in the project window, copy the program and run the script on the copy.

## 3. Comment every XOR loop (★★)

**Hints**

- Keep instructions whose mnemonic is `XOR`. Skip the zeroing form, where both operands are the same register: compare the text of operand 0 with operand 1.
- An `-O0` loop ends with a conditional jump backward. The `XOR` is inside a loop when a later conditional jump in the same function targets an address at or before the `XOR`.
- Addresses compare with `compareTo`: negative means "lower than". A jump's target is `getFlows()[0]`.
- For the comment text, use the constant if `getScalar(1)` isn't `null`. Otherwise name operand 1, a register or a memory operand.
- Setting an end-of-line comment replaces the old one, so running the script twice is safe.

**API calls to look up:** `currentProgram.getListing().getInstructions(boolean)`, `Instruction.getMnemonicString()`, `Instruction.getDefaultOperandRepresentation(int)`, `Instruction.getScalar(int)`, `Instruction.getFlowType()`, `FlowType.isConditional()` and `isJump()`, `Instruction.getFlows()`, `Address.compareTo(Address)`, `getFunctionContaining(Address)`, `setEOLComment(Address, String)`.

**Expected output.** On Day 1's `ex3`, one comment, in `decode`, next to `XOR EAX,0x42`: for example "XOR in a loop, key 0x42". On Day 5's `ex1` at `-O0`, two of the program's own functions get comments:

- `decode`: the `XOR` of two registers, holding the text byte and the record's key. No constant, because each message has its own key.
- The unlock-word check: a loop that XORs each character of your input into a running value, then multiplies it by `0x01000193`. Starting at `0x811c9dc5`, that is the FNV-1a hash. The program compares the hash, never the word, which is why the word isn't in Defined Strings.

MinGW's runtime may add a few more. Check each one by its function name before you trust it.

## 4. Decode the messages in an -O2 build (★★)

**Build it.** In the `Devkit.cmd` shell, from the repo's `lab` folder:

```bash
gcc -O2 -s -Wall day5/ex1_messages.c -o bin/day5/ex1o2.exe
```

Import `bin/day5/ex1o2.exe` into your `day5` folder in the Ghidra project and analyze it. This doesn't change the Makefile; `make clean` won't delete this file.

**Hints**

- Run your unchanged capstone script on it first. In a test build with MinGW-w64 GCC 13, `main` still had exactly one `LEA` into `.data`, so the table search worked. Your w64devkit GCC may produce different code, so check.
- The record size: at `-O2`, look for an `IMUL` whose third operand is a number, such as `IMUL RDX,RDX,0x30`. At `-O0` there is no `IMUL`: the index is doubled with an `ADD`, added once more (times 3), then shifted left by 4. Handle each pattern separately, and print which one you found.
- The count: the range check differs between builds. At `-O0` the code compares your number with 20; at `-O2` it subtracts 1 first and compares with 19 (`0x13`). The prompt is safer: "Keeper's log: %d messages" gets the count in `EDX`, just before its `printf`, in both builds.
- `decode` is usually inlined at `-O2`: its loop sits inside `main`, and no separate function reads the key. Your script doesn't need `decode`, which is why it survives.
- Keep the field offsets as constants. Deriving them from the code is possible, but the memory operands differ too much between builds for a first attempt.

**API calls to look up:** `findBytes(Address, String)`, `getReferencesTo(Address)`, `currentProgram.getListing().getInstructions(AddressSetView, boolean)`, `Instruction.getMnemonicString()`, `Instruction.getNumOperands()`, `Instruction.getScalar(int)`, `Instruction.getRegister(int)`.

**Expected output** from both builds: 20 lines, something like this:

```text
 1 key 0x9c open   Keeper's log, week one. Lamp lit at dusk.
 2 key 0xb3 open   Fog all morning. Horn sounded twice.
 ...
15 key 0xc1 sealed Unlock word: brass-lantern-7
 ...
20 key 0x8b open   Last entry of the season. Lamp handed on.
```

Your script should also print the record size (0x30) and the count (20) it read, and which pattern it used.

## 5. Run a script headless (★★★)

**Hints**

- `analyzeHeadless.bat` is in the kit's `ghidra\support` folder. It runs Ghidra with no window: it imports a program into a project, analyzes it, and runs scripts on it.
- Use a separate, throwaway project folder. Create it first. `-deleteProject` removes the project when the run ends, so nothing is left behind.
- `-scriptPath` names the folder that holds your script; use your own folder or `lab\day5\scripts`. `-postScript` names the script, and the words after it are its arguments: what `getScriptArgs()` returns.
- Ghidra must find a JDK. If it complains, set `JAVA_HOME` to the kit's `jdk` folder in that window first.
- The output is long. Send it to a file and search it for `.java>`: every line your script prints starts with the script's name.
- To run a script on a program already in your own project, use `-process` with the program's name, plus `-noanalysis`, instead of `-import`. Close that project in the Ghidra window first, because a project can only be open once.

The command has this shape (one line in `cmd.exe`; put your own paths in):

```text
<kit>\ghidra\support\analyzeHeadless.bat <empty folder> day5test -import <repo>\lab\bin\day1\ex3.exe -scriptPath <repo>\lab\day5\scripts -postScript Day5FindCalls.java puts -deleteProject > headless.txt
```

Then `findstr ".java>" headless.txt` shows only the script's lines.

**Expected output.** The same lines the Script Manager printed, with Ghidra's log prefix in front. For `Day5FindCalls.java` with `puts` on `ex3`, the three calls, the strings "Debugger detected. Bye.", "License OK. Welcome!" and "Bad license key.", and your total of 3. For the capstone script on `bin\day5\ex1.exe`, the 20 messages.

If nothing from your script appears, search the file for `ERROR` and `Exception`. A compile error looks just like the one in the console. "Script not found" means `-scriptPath` or the script's name is wrong.

Day 10 builds on this: scripts that take arguments, run on many programs, and save their results.

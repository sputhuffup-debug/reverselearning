# Day 5: Ghidra Scripting I

Nov 27, 2026

## Overview

Day 5 closes the first block. For four days you have found things by hand: strings, references, calls, arrays and structs. Today you write Ghidra scripts in Java that do the same work for you. Every script automates a task you first solve by hand, so you always know what the right output looks like.

**Goals for the day**

1. Open the Script Manager, add the course's script folder, and run, edit and re-run a script.
2. Read a script's output in the console, and find an API call in Ghidra's API documentation.
3. Walk every function in a program and print its address and size.
4. Follow references in a script: from a string to the code that uses it, and from a call to its arguments.
5. Read bytes from the program and decode them: Day 1's `ex3` key, then a table of 20 encoded messages.
6. Explain every line of the scripts you write.

**What you need**

- The portable kit built by `Build-PortableRE.ps1`, as on Day 1. Ghidra compiles scripts with the kit's JDK, so nothing else needs installing.
- The course repo. Its `lab/day5` folder holds today's practice program, and `lab/day5/scripts` holds the four script skeletons.
- Day 1's `ex1` and `ex3`, built with `make day1`.
- Day 1's skills: strings, references and renaming. Day 4's struct layouts help with the capstone.
- No Java experience is needed. You need variables, `if`, loops and method calls; the guide explains anything beyond that.

**Lab rules**

The Day 1 rules still apply. Work in a VM with a snapshot, analyze only the practice programs, and keep notes. Today your notes also hold your finished scripts, with a comment on every line.

## How each exercise works

Every exercise today follows the same five steps. Don't skip the first two; they are what make the script yours.

1. **By hand first.** Solve the task in Ghidra without a script. Write down the result in your notes, as the exercise asks.
2. **Plan in words.** Write the steps a script would take, in plain language, one line per step. Compare them with the skeleton's `TODO` comments.
3. **Fill one TODO at a time.** Each skeleton in `lab/day5/scripts` has numbered `TODO` comments. Each one names the API calls to look up. Write the code for one `TODO` only.
4. **Check each step.** Run the script after each `TODO` and compare its output with your notes. The guide says what each step should print.
5. **Explain it.** Add a comment to every line you wrote, saying what it does and why. Copy the finished script into your notes.

The complete solutions are in [lab/solutions/day5](../lab/solutions/day5). Open them only to compare after you finish, as with the answer key.

## Schedule

The day runs about 7 hours with breaks, and roughly half of it is hands-on exercise time.

| Time | Block | What you do |
| --- | --- | --- |
| 0:00–0:20 | Module 0: Setup | Build today's program and Day 1's, run `ex1` once |
| 0:20–1:05 | Module 1A: Script Manager tour | Script directories, the editor, the console, the API documentation, how a script is built |
| 1:05–1:50 | Exercise 5.1 | List every function in Day 1's `ex1` |
| 1:50–2:05 | Break |  |
| 2:05–2:35 | Module 2A: Addresses and references | `Address`, `Reference` and `Instruction` in the API |
| 2:35–3:35 | Exercise 5.2 | Find every call to `strcmp` and its string arguments |
| 3:35–4:20 | Lunch |  |
| 4:20–5:20 | Module 3: Exercise 5.3 | Decode Day 1's `ex3` key with a script |
| 5:20–6:35 | Module 4: Capstone | Decode every message in `ex1`, sealed ones included |
| 6:35–6:55 | Review | Go over the answer key and compare your scripts with the solutions |
| 6:55–7:00 | Wrap-up | Reference updates and the plan for Day 6 |

## Module 0: Build the practice program (20 min)

Today has one new program, a lighthouse keeper's log. It holds 20 short messages, each encoded with its own one-byte key. It decodes a message only when you ask for it, and some messages are sealed and never shown. Its source is in the repo's `lab/day5` folder. As on Day 1, don't read it once it's compiled.

[**ex1\_messages.c**](../lab/day5/ex1_messages.c): 20 encoded messages in a table of structs, and an unlock word hidden among the sealed ones

**Compile** with `make`. Open `RE-Portable\Devkit.cmd`; its shell starts in the repo's `lab` folder. Then run:

```bash
make day5     # builds bin/day5/ex1.exe
make day1     # Exercises 5.1 to 5.3 use Day 1's ex1 and ex3
```

Run `bin/day5/ex1.exe` three times: once with `1`, once with `5`, and once with any word. Note what each run prints. You now know what an open message, a sealed message and a wrong unlock word look like.

Import `ex1.exe` from `bin/day5` into your Ghidra project and analyze it. Import Day 1's `ex1.exe` and `ex3.exe` too if they aren't in the project yet. Put today's programs in a folder named `day5` in the project window, so the two `ex1.exe` files don't get mixed up.

## Module 1: The Script Manager (1 h 30 min)

A Ghidra script is a Java class that Ghidra compiles and runs inside the CodeBrowser. It sees the program you have open, so it can read anything you can see in the Listing. Ghidra compiles the script each time you run it; there is no separate build step.

### 1A. Tour (45 min)

1. **Open the Script Manager.** Open Day 1's `ex1.exe` in the CodeBrowser, then Window → Script Manager. The left side shows categories; the right side lists the scripts in the selected category.
2. **Run a bundled script.** Type `HelloWorld` in the filter at the bottom. Select `HelloWorldScript.java` and click the Run Script button (the green arrow) in the Script Manager's toolbar.
3. **Find the console.** The script's output appears in the Console window at the bottom of the CodeBrowser. If it is hidden, use Window → Console. Each line starts with the script's name, like `HelloWorldScript.java> Hello World`.
4. **Add the course's script folder.** Click the Script Directories button in the Script Manager's toolbar; it opens the Bundle Manager. Click the green plus, pick the repo's `lab/day5/scripts` folder, and close the window. Never add `lab/solutions/day5` at the same time: its scripts have the same class names, and Ghidra can only load one of each.
5. **Find today's skeletons.** Each skeleton starts with a comment line `//@category Course.Day5`. That line puts it under Course → Day5 in the category tree. Select that category; you should see four scripts, from `Day5ListFunctions.java` to `Day5DecodeMessages.java`.
6. **Open the editor.** Select `Day5ListFunctions.java` and click the Edit Script button. Ghidra opens it in its own simple editor. Save with the editor's Save button, then run from the Script Manager.
7. **Run the empty skeleton.** Run `Day5ListFunctions.java` before you change anything. The console shows that it ran and finished, and nothing else. Every skeleton compiles and runs as it is, so any error you see later is in code you wrote.
8. **Make a mistake on purpose.** Type `x` on an empty line inside `run()`, save and run. The console shows a compile error with a line number. Delete the `x`, save, and run again.
9. **Find the API documentation.** Click the Help button in the Script Manager's toolbar to open the API documentation for scripts. Or use the online copy of [GhidraScript](https://ghidra.re/ghidra_docs/api/ghidra/app/script/GhidraScript.html) and [FlatProgramAPI](https://ghidra.re/ghidra_docs/api/ghidra/program/flatapi/FlatProgramAPI.html). Most calls you need today are in FlatProgramAPI, which every script can use directly.

**How a script is built.** Read the skeleton from top to bottom. It has four parts:

- **The header comment.** The first lines describe the script; the Script Manager shows them as the description. `//@category` sets where it appears.
- **The imports.** Each `import` line names a Ghidra class the script uses, such as `Function`. The skeletons already import everything their solution needs.
- **The class.** `public class Day5ListFunctions extends GhidraScript` makes it a Ghidra script. The class name must match the file name exactly.
- **The `run()` method.** Ghidra calls `run()` when you click Run Script. Your code goes inside it, below each `TODO`.

Two names are always there for you. `currentProgram` is the program open in the CodeBrowser. `println("text")` prints a line to the console.

### Exercise 5.1: List every function in Day 1's ex1 (45 min)

**Step 1, by hand.** Open Day 1's `ex1.exe`. In the Symbol Tree, open the Functions folder.

1. Find `main` (you renamed it on Day 1, or find it again from "Access granted!"). Note its address.
2. Work out `main`'s size: click its first instruction and its last `RET` in the Listing, and subtract the addresses. Add the length of the `RET` (1 byte).
3. Find `strcmp` in the Functions folder. Double-click it. It is a 6-byte stub that jumps to the real `strcmp` in a DLL. Ghidra calls this a **thunk**.
4. Note roughly how many functions there are. Most of them are MinGW's startup code, not the program's own.

**Write down:** `main`'s address and size, `strcmp`'s address and size, and three other thunk names.

**Step 2, plan in words.** Write the steps before you open the skeleton. For example: start at the first function; print its name, address and size; move to the next; stop after the last one; print the totals. Compare your plan with the four `TODO` comments in `Day5ListFunctions.java`.

**Step 3 and 4, fill and check one TODO at a time.**

- **TODO 1: the loop.** [`getFirstFunction()`](https://ghidra.re/ghidra_docs/api/ghidra/program/flatapi/FlatProgramAPI.html) returns the function at the lowest address. `getFunctionAfter(f)` returns the next one, or `null` after the last. A `while (f != null)` loop that ends with `f = getFunctionAfter(f);` visits them all. Add `!monitor.isCancelled()` to the condition, so the Cancel button can stop a long run.
  *Check:* the script prints nothing yet, and finishes within a second or two. If it never finishes, the loop is missing `getFunctionAfter`.
- **TODO 2: name and address.** A [`Function`](https://ghidra.re/ghidra_docs/api/ghidra/program/model/listing/Function.html) knows its name with `f.getName()` and its first address with `f.getEntryPoint()`. Print both on one line with `println`.
  *Check:* one line per function. Names are `FUN_` plus the address for stripped functions, and import names like `strcmp` for thunks. Find `main` by the address you wrote down.
- **TODO 3: size and thunks.** `f.getBody()` is the set of addresses the function covers. Its `getNumAddresses()` is the size in bytes. `f.isThunk()` is true for an import stub.
  *Check:* `main`'s size matches your notes, and `strcmp` shows 6 bytes and your thunk mark.
- **TODO 4: totals.** Count functions and thunks in two `int` variables as the loop runs, and print both after the loop.
  *Check:* the totals look like what you saw in the Symbol Tree. Most thunks sit together near the end.

**Step 5, explain it.** Add a comment to every line you wrote. Then compare with [Day5ListFunctions.java](../lab/solutions/day5/Day5ListFunctions.java) in the solutions.

**Stretch goal:** also print the largest function. Which one is it, and is it the program's own code?

## Module 2: References in a script (1 h 30 min)

### 2A. Addresses, references and instructions (30 min)

Scripts work with the same objects you click on in the CodeBrowser. Three of them matter today.

- An **Address** is a location in the program. `toAddr(0x140001450L)` makes one from a number, and `a.add(4)` moves 4 bytes on. Printing an address gives it in hex, like the Listing.
- A **Reference** is one arrow from Ghidra's references window. [`getReferencesTo(a)`](https://ghidra.re/ghidra_docs/api/ghidra/program/flatapi/FlatProgramAPI.html) returns the references pointing at `a`, the same list as Show References to. Each [`Reference`](https://ghidra.re/ghidra_docs/api/ghidra/program/model/symbol/Reference.html) has `getFromAddress()` and `getToAddress()`.
- An **Instruction** is one line of the Listing. `getInstructionAt(a)` returns it, and `getInstructionBefore(i)` returns the line above. An [`Instruction`](https://ghidra.re/ghidra_docs/api/ghidra/program/model/listing/Instruction.html) knows its mnemonic, its operands and its own references.

Try one call before the exercise. In a new line in `run()` of any skeleton, print `getFunctionContaining(currentAddress).getName()`. Click inside `main` in the Listing and run it; it prints `main`'s name. `currentAddress` is where your cursor is. It is handy for testing, but today's finished scripts don't rely on it. Delete the line afterwards.

### Exercise 5.2: Find every call to strcmp (1 h)

**Step 1, by hand.** In Day 1's `ex1.exe`, select the `strcmp` thunk in the Symbol Tree and press Ctrl+Shift+F.

1. Note each reference: its address, and whether it is a `CALL`.
2. Go to each call. Note the function it is in, and the instruction a few lines above that loads a string's address (`LEA` with a string).
3. Do the same in Day 1's `ex3.exe`. Look at where `strcmp`'s two arguments come from there.

**Write down:** for each program, the number of calls to `strcmp`, the calling function, and any string the call is given.

**Step 2, plan in words.** For example: find the function named `strcmp` and get the references to it. Keep the calls. For each call, print where it is, and look a few instructions back for strings.

**Step 3 and 4, fill and check one TODO at a time.**

- **TODO 1: the name to look for.** Start with `String target = "strcmp";`. [`getScriptArgs()`](https://ghidra.re/ghidra_docs/api/ghidra/app/script/GhidraScript.html) returns the arguments given to a headless run, and an empty array in the Script Manager. If it has any, use the first one instead.
  *Check:* nothing printed yet; the script runs and finishes.
- **TODO 2: find the function.** Reuse the loop from Exercise 5.1. Compare names with `f.getName().equals(target)`; in Java, `==` doesn't compare text. Keep matches in a `List<Function>`.
  *Check:* print the list's size for now. It should be 1 in both programs: the thunk.
- **TODO 3: references that are calls.** For each kept function, loop over `getReferencesTo(f.getEntryPoint())`. For each reference, `getInstructionAt(ref.getFromAddress())` gives the instruction it comes from. `ins.getFlowType().isCall()` tells you if it is a call.
  *Check:* temporarily print each call's address. `ex1` has one, at the address in your notes.
- **TODO 4: the caller.** [`getFunctionContaining(a)`](https://ghidra.re/ghidra_docs/api/ghidra/program/flatapi/FlatProgramAPI.html) returns the function an address is in. Print the call's address and the caller's name, and the number of calls at the end.
  *Check:* one line for `ex1`, naming `main` (or its `FUN_` name if you didn't rename it).
- **TODO 5: string arguments.** Start at `getInstructionBefore(call)` and step back up to 6 times, stopping at an earlier call. For each instruction, loop over `getReferencesFrom(ins.getAddress())`. `getDataAt(ref.getToAddress())` returns the data there, or `null`. If `d.getValue() instanceof String`, print it.
  *Check:* `ex1` prints the password string you found on Day 1. `ex3` prints the call but no string: both arguments are buffers on the stack.

**Try it on another function.** Change `"strcmp"` to `"puts"` in TODO 1 and run it on `ex3`. Compare the strings it prints with Defined Strings. Change it back afterwards. On Day 10 you will pass the name as an argument to a headless run instead.

**Step 5, explain it.** Comment every line, then compare with [Day5FindCalls.java](../lab/solutions/day5/Day5FindCalls.java).

## Module 3: Decoding ex3's key with a script (1 h)

On Day 1 you decoded `ex3`'s key by hand. Now a script does it, and it finds everything itself: `main`, `decode`, the array, the key and the length. It follows the same path you did, from a string to the code.

### Exercise 5.3: Decode ex3's key (1 h)

**Step 1, by hand.** Open Day 1's `ex3.exe`. Redo Part A of Day 1's capstone, and this time note every address.

1. Find "Bad license key." in Defined Strings, and follow its reference to `main`.
2. In `main`, find the call to `strcmp` and the call just before it: `decode`. Look at the instructions just before the `decode` call. One of them moves a small number into `EDX`, decode's second argument.
3. In `decode`, find the instruction that loads the array's address, and the `XOR` with a constant.
4. Double-click the array and note its first few bytes.

**Write down:** the string's address, `main`'s address, the `decode` call's address, the length in `EDX`, the array's address, the XOR key, and the decoded key.

**Step 2, plan in words.** For example: find the string and follow it to `main`. Walk `main` to the call before `strcmp`, and note the length. Walk `decode` for the array and the key. Read the bytes and XOR them.

**Step 3 and 4, fill and check one TODO at a time.**

- **TODO 1: find the string.** [`findBytes(start, "Bad license key")`](https://ghidra.re/ghidra_docs/api/ghidra/program/flatapi/FlatProgramAPI.html) searches memory from `start` and returns the first match, or `null`. Start at `currentProgram.getMinAddress()`.
  *Check:* it prints the string's address from your notes.
- **TODO 2: find main.** Take the first reference from `getReferencesTo` on that address, and pass its `getFromAddress()` to `getFunctionContaining`.
  *Check:* it prints `main`'s address.
- **TODO 3: find decode and the length.** `currentProgram.getListing().getInstructions(main.getBody(), true)` returns an iterator over `main`'s instructions, in order. Use `hasNext()` and `next()` to loop. For a call, `ins.getFlows()[0]` is the address it calls, and `getFunctionAt` on that address gives the function. Remember the last call that wasn't `strcmp`. For the length, look for a `MOV` into `EDX` whose `ins.getScalar(1)` isn't `null`. Ghidra's `ins.getRegister(0)` reports the full 64-bit register, so for `MOV EDX,0xe` its name is `RDX`, not `EDX`. Print it once to see this for yourself.
  *Check:* it prints `decode`'s address and the length from your notes.
- **TODO 4: the array and the key.** Walk `decode`'s instructions the same way. `ins.getReferencesFrom()` lists the instruction's references; `ref.getReferenceType().isData()` is true for a reference to data. At `-O0`, `decode` also saves its arguments on the stack, and those stores count as data references too. Keep only references whose `ref.getToAddress().isMemoryAddress()` is true: the array is in the program's memory, not on the stack. For the key, find the instruction whose `getMnemonicString()` is `XOR` and read `getScalar(1).getValue()`.
  *Check:* the array's address and the key match your notes.
- **TODO 5: decode.** `getBytes(array, length)` returns a `byte[]`. XOR each byte with the key and add it to a `StringBuilder` as a `char`. Java bytes are signed, so mask with `& 0xff`.
  *Check:* it prints the key you found on Day 1. Run `ex3.exe` and enter it.

**Step 5, explain it.** Comment every line, then compare with [Day5DecodeKey.java](../lab/solutions/day5/Day5DecodeKey.java). Note which of your Day 1 steps each `TODO` replaces.

## Module 4: Capstone, the keeper's log (1 h 15 min)

`ex1` in `bin/day5` refuses to show its sealed messages, and its unlock word isn't in Defined Strings. Decoding 20 messages by hand would take an hour; a script does it in a second. As always, work out the format by hand first, on one message.

### Part A: By hand (30 min)

1. Import and analyze `bin/day5/ex1.exe` (in your `day5` folder). Find `main` from the "is sealed" string.
2. In `main`, find where the number you type becomes an address in the table. Look for the multiplication: it may be an `ADD` and a `SHL` rather than an `IMUL`. Work out the record size.
3. Find the byte `main` tests to decide that a message is sealed. Note its offset in the record.
4. Rename the function `main` calls before printing an open message to `decode`. Find the offsets it reads the key, the length and the text from.
5. Double-click the table's address. Note which memory block it is in (Window → Memory Map shows the blocks). Find the number of records in the prompt or the range check.
6. Decode the first three characters of message 1 by hand, and check them against what `ex1.exe 1` printed.

**Write down:** the record size, the number of records, the offset of each field, the table's address and block, and your three decoded characters.

**Stretch goal:** build the record as a structure in the Data Type Manager, as on Day 4. Apply it to the table as an array.

### Part B: The script (35 min)

**Plan in words** first, then fill `Day5DecodeMessages.java` one `TODO` at a time.

- **TODO 1: the layout.** Replace the zeros with what you wrote down in Part A. Using named constants means the rest of the script reads like your notes.
  *Check:* nothing printed yet.
- **TODO 2: find main.** Search for "Message %d is sealed" and follow it to `main`, as in Exercise 5.3.
  *Check:* `main`'s address matches your notes.
- **TODO 3: find the table.** Walk `main`'s instructions. The table is the target of a `LEA` whose address is in `.data`. [`getMemoryBlock(a)`](https://ghidra.re/ghidra_docs/api/ghidra/program/flatapi/FlatProgramAPI.html) returns the block an address is in, and [`getName()`](https://ghidra.re/ghidra_docs/api/ghidra/program/model/mem/MemoryBlock.html) gives its name. Strings are in `.rdata`, so they don't match.
  *Check:* it prints the table address from your notes.
- **TODO 4: read each record.** Loop over the records. Record `i` starts at `table.add(i * RECORD_SIZE)`. `getByte(a)` reads one byte; mask it with `& 0xff`. Read the key, the length and the sealed flag, then `getBytes` the text and XOR it.
  *Check:* print just message 1 first. It must match what `ex1.exe 1` printed.
- **TODO 5: print every message.** One line each: its number from 1, its key in hex, open or sealed, and the text.
  *Check:* 20 lines of plain English. The open ones match what the program prints for those numbers.

### Part C: Use what you found (10 min)

1. Read the sealed messages carefully. One of them gives the unlock word; another one is out of date.
2. Run `ex1.exe` and enter the unlock word. It should print "Archive unlocked."
3. Comment every line of your script, then compare with [Day5DecodeMessages.java](../lab/solutions/day5/Day5DecodeMessages.java).

**Deliverable:** your four scripts with a comment on every line, and a half-page write-up. Include the record layout, how your script finds the table without a hardcoded address, the unlock word, and which sealed message is a trap.

## Answer key and hints

Try each exercise for at least 15 minutes before you look here. Addresses and function counts depend on your compiler, so they're left out. The complete scripts are in [lab/solutions/day5](../lab/solutions/day5); compare yours with them after you finish.

| Exercise | Hint | Answer |
| --- | --- | --- |
| 1A | The class name and the file name must match exactly | The skeleton prints nothing but compiles and finishes; the deliberate `x` gives a compile error with its line number |
| 5.1 | `getNumAddresses()` returns a `long` | One line per function, and around a hundred functions in all, most of them MinGW startup code. The thunks (`strcmp`, `puts`, `fgets`, `strcspn` and others) are 6 bytes each and come last. Compare with `lab/solutions/day5/Day5ListFunctions.java` |
| 5.2 ex1 | The string's `LEA` is two or three instructions before the call | One call to `strcmp`, in `main`; string argument `hunter2-ghidra`. Compare with `lab/solutions/day5/Day5FindCalls.java` |
| 5.2 ex3 | Both arguments are addresses of local buffers (`LEA` from `RBP`) | One call to `strcmp`, in `main`, with no string argument. With `puts`: three calls, with "Debugger detected. Bye.", "License OK. Welcome!" and "Bad license key." |
| 5.3 | `decode` is the last call before `strcmp`; the length is the `MOV EDX` just before `decode` | Length 14 (`0xe`), key `0x42`, key `R3v3rs1ng_D4y1`. Compare with `lab/solutions/day5/Day5DecodeKey.java` |
| 5A layout | The index is `n - 1`, times 3, shifted left by 4 | Record size `0x30` (48), 20 records. `key` at 0x00, `len` at 0x01, `sealed` at 0x02, `text` at 0x03 (45 bytes). The table is in `.data` |
| 5A check | Each record has its own key; message 1's is the first byte of the table | Message 1 is "Keeper's log, week one. Lamp lit at dusk." |
| 5B | Only one `LEA` in `main` points into `.data`; a `MOV` from `.data` loads an import pointer | Messages 5, 9, 12, 15 and 18 are sealed. Compare with `lab/solutions/day5/Day5DecodeMessages.java` |
| 5C | Message 5 names the old word; message 18 says the word ends in a number | Message 15: the unlock word is `brass-lantern-7`. Message 5's `tin-beacon-3` is retired and gives "Wrong unlock word." |

## Wrap-up and Day 6

Today's Ghidra features are in the running reference: [ghidra-reference.md](ghidra-reference.md) under Scripting. It lists the Script Manager tasks and every API call you used.

Keep your four scripts. Day 10 builds on them: scripts that rename, comment and create types, run headless with `analyzeHeadless`.

**Day 6 preview:** C++. You'll reverse a small class hierarchy with virtual functions, `std::string`, `std::vector` and an exception. You'll follow the hidden `this` pointer, rebuild vtables as structures, and read RTTI and mangled names.

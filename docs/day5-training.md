# Day 5: Ghidra Scripting I

Nov 27, 2026

## Overview

Day 5 closes the first block. For four days you have found things by hand: strings, references, calls, arrays and structs. Today you write Ghidra scripts in Java that do the same work for you. Every script automates a task you first solve by hand, so you always know what the right output looks like.

**Why scripting matters**

Real programs are big. Day 1's `ex1` has about a hundred functions, and a real application has thousands. Clicking through each one is slow, and you will miss some.

A script fixes three problems at once:

- **Scale.** A script checks every function, every call or every byte in a second. Decoding 20 messages by hand takes an hour; Module 4's script does it instantly.
- **Repeatability.** Analysis is rarely done once. When a new build of a program arrives, you run the same script again instead of redoing the clicks.
- **Sharing.** A script is a precise record of how you found something. A colleague can read it, run it and check your result, which a list of screenshots can't offer.

A script never replaces understanding. It only does what you tell it, so you must know the answer's shape first. That is why every exercise today starts by hand.

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

**Before you start**

If you haven't written Java before, read [Just enough Java for Ghidra scripts](primers/08-java-for-ghidra.md). It covers what today's scripts need and nothing more. The exercises also lean on [Reading assembly](primers/03-reading-assembly.md) and [The stack and the calling convention](primers/05-stack-and-calls.md).

You don't need to memorize the primers. Throughout the guide, a short "Primer:" note links to the exact section that explains the idea in front of you. Follow it when a step doesn't make sense, then come back.

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

**Why this order works.** Step 1 gives you the right answer before any code exists, so every run in step 4 has a target. Step 2 separates "what to do" from "how to say it in Java", which are two different problems. Step 5 is where you find the lines you copied without understanding.

**A good plan in words** has one action per line, names the thing it works on, and says when to stop. "Find the string, then its function" is two lines. "Look at main" is too vague: look for what, and stop when?

**Two extras.** After each exercise, a "Same idea, different program" note plans a different small script in words. It practices step 2 on a new problem and names the API calls it would use, without writing the Java. At the end, [Beyond this lesson](#beyond-this-lesson) offers extra-credit scripts for after the course day.

**When you are stuck,** read [When a script goes wrong](#when-a-script-goes-wrong) in Module 1. Most problems today are one of the five it describes.

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

The "Same idea" notes take about five minutes each, at the end of each exercise or during the review. [Beyond this lesson](#beyond-this-lesson) is outside the 7 hours.

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

The folder matters more than it looks. A script runs on whichever program is open in the CodeBrowser. Running Exercise 5.1's script on Day 5's `ex1` instead of Day 1's gives different, confusing output, and nothing tells you why.

## Module 1: The Script Manager (1 h 30 min)

A Ghidra script is a Java class that Ghidra compiles and runs inside the CodeBrowser. It sees the program you have open, so it can read anything you can see in the Listing. Ghidra compiles the script each time you run it; there is no separate build step.

A script reads the same database the windows show. When it asks for "the function containing this address", it gets the answer the Symbol Tree would give. So anything Ghidra's analysis got wrong, a script gets wrong too, and checking by hand still matters.

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

A note on step 6: any text editor works too. The skeletons are ordinary `.java` files in the repo, and Ghidra reads the saved file each time you click Run Script. Whichever editor you use, save before you run, or Ghidra runs the old version.

**How to read an API page.** Each class page lists its methods in a table: what each one returns on the left, its name and argument types on the right. For example, `getFunctionAfter(Function function)` returns a `Function`. Click a method's name to read what it does and when it returns `null`.

**How a script is built.** Read the skeleton from top to bottom. It has four parts:

- **The header comment.** The first lines describe the script; the Script Manager shows them as the description. `//@category` sets where it appears.
- **The imports.** Each `import` line names a Ghidra class the script uses, such as `Function`. The skeletons already import everything their solution needs.
- **The class.** `public class Day5ListFunctions extends GhidraScript` makes it a Ghidra script. The class name must match the file name exactly.
- **The `run()` method.** Ghidra calls `run()` when you click Run Script. Your code goes inside it, below each `TODO`.

Primer: [A script is a class with a run() method](primers/08-java-for-ghidra.md#a-script-is-a-class-with-a-run-method) explains `extends`, `@Override` and `throws Exception` line by line.

Two names are always there for you. `currentProgram` is the program open in the CodeBrowser. `println("text")` prints a line to the console.

Two more appear later today. `currentAddress` is where your cursor is in the Listing. `monitor` is the progress bar Ghidra shows while a script runs; asking it `monitor.isCancelled()` tells you whether the Cancel button was pressed.

`currentProgram` is a [`Program`](https://ghidra.re/ghidra_docs/api/ghidra/program/model/listing/Program.html) object, and you can ask it questions too. This one line, inside `run()`, gets the file name you imported:

```java
String fileName = currentProgram.getName();    // for example "ex1.exe"
```

Printing that name at the top of each script is a cheap guard against running it on the wrong `ex1.exe`.

### When a script goes wrong

Read this once now, and come back to it whenever a run surprises you. Almost every problem today is one of these five.

**1. A compile error.** The console shows lines like `Day5ListFunctions.java:24: error: ';' expected`, and nothing from your script runs. Fix the first error first; later ones are often side effects. The usual causes are a missing `;` or `)`, a misspelled name, or `=` where you meant `==`.

Primer: [Reading a compiler error](primers/08-java-for-ghidra.md#reading-a-compiler-error) lists the three messages you will see most.

**2. An exception while running.** The script compiles, prints a few lines, then stops with a name like `NullPointerException` and a stack trace. The first trace line that names your file, such as `Day5DecodeKey.java:31`, points at the line that failed. A `NullPointerException` means a lookup returned `null` and the next line called a method on it.

The fix is not to hide the error but to ask why the lookup found nothing. Check for `null` right after the call, print what you were looking for, and `return` with a clear message. Primer: [Objects, methods and null](primers/08-java-for-ghidra.md#objects-methods-and-null) and [Exceptions](primers/08-java-for-ghidra.md#exceptions).

**3. The script runs but finds nothing, or too little.** No error, but the lines you expect are missing. Check these causes in order:

- **The wrong program is open.** Look at the CodeBrowser's tab, or print `currentProgram.getName()`. Day 1's `ex1` and Day 5's `ex1` share a file name.
- **The register has a different name.** For `MOV EDX,0xe`, `getRegister(0)` reports the full 64-bit register, `RDX`. A comparison with `"EDX"` never matches. Exercise 5.3 shows this.
- **Stack slots look like data.** At `-O0` a function first saves its arguments on the stack, and those stores are data references too. `isMemoryAddress()` on the target address tells them apart. Exercise 5.3 shows this too.
- **The string isn't defined.** Ghidra doesn't always create a string at an address that a `LEA` loads. Then `getDataAt` returns `null` there, and a script that only trusts defined data misses the string. Exercise 5.2 shows a case and what to do.
- **The comparison is wrong.** `name == "strcmp"` compares objects, not text, and is usually false. Use `.equals`. Primer: [Strings](primers/08-java-for-ghidra.md#strings).

To narrow it down, print more. Print every function name, every mnemonic or every reference your loop sees, before any `if`. The missing line usually shows up a few lines from where you expected it.

**4. The opposite: the same line printed twice.** The same string can turn up twice when you walk back from a call. The `LEA` that loads it carries a DATA reference, and the next `MOV` can carry a PARAM reference to the same address. Remember the addresses you have printed and skip repeats.

**5. Your edits seem to have no effect, or the wrong script runs.** First, make sure you saved. Then check Script Directories: with `lab/solutions/day5` next to `lab/day5/scripts`, both folders hold a class named, say, `Day5FindCalls`. Ghidra loads only one, and it may run the solution instead of your file.

The sign is a script that prints complete output before you have written anything. Remove the solutions folder from the Bundle Manager, close it, and run again. To compare with a solution, open its `.java` file in a text editor instead of adding the folder.

**A script that never ends.** A loop without a step forward, such as a `while` that never calls `getFunctionAfter`, runs forever. Click Cancel on the progress bar. Your loops check `monitor.isCancelled()` so that Cancel can stop them.

### Exercise 5.1: List every function in Day 1's ex1 (45 min)

This exercise is the scripting version of the Symbol Tree's Functions folder. It teaches the most common pattern in Ghidra scripts: start at the first object, visit each one, stop at the end.

**Step 1, by hand.** Open Day 1's `ex1.exe`. In the Symbol Tree, open the Functions folder.

1. Find `main` (you renamed it on Day 1, or find it again from "Access granted!"). Note its address.
2. Work out `main`'s size: click its first instruction and its last `RET` in the Listing, and subtract the addresses. Add the length of the `RET` (1 byte).
3. Find `strcmp` in the Functions folder. Double-click it. It is a 6-byte stub that jumps to the real `strcmp` in a DLL. Ghidra calls this a **thunk**.
4. Note roughly how many functions there are. Most of them are MinGW's startup code, not the program's own.

Primer: a thunk is the "small stub" in [Imports and the IAT](primers/04-memory-layout.md#imports-and-the-iat). Its 6 bytes are one `JMP` through an IAT slot.

**Write down:** `main`'s address and size, `strcmp`'s address and size, and three other thunk names.

**Step 2, plan in words.** Write the steps before you open the skeleton. For example: start at the first function; print its name, address and size; move to the next; stop after the last one; print the totals. Compare your plan with the four `TODO` comments in `Day5ListFunctions.java`.

Your plan may be in a different order from the skeleton's, and that is fine. What matters is that each skeleton `TODO` matches one or two lines of your plan. If a `TODO` has no partner in your plan, find out what you missed.

**Step 3 and 4, fill and check one TODO at a time.**

- **TODO 1: the loop.** [`getFirstFunction()`](https://ghidra.re/ghidra_docs/api/ghidra/program/flatapi/FlatProgramAPI.html) returns the function at the lowest address. `getFunctionAfter(f)` returns the next one, or `null` after the last. A `while (f != null)` loop that ends with `f = getFunctionAfter(f);` visits them all. Add `!monitor.isCancelled()` to the condition, so the Cancel button can stop a long run.
  *Check:* the script prints nothing yet, and finishes within a second or two. If it never finishes, the loop is missing `getFunctionAfter`.

  Primer: [Control flow: if, for, while, for-each](primers/08-java-for-ghidra.md#control-flow-if-for-while-for-each) for `while`, and [Objects, methods and null](primers/08-java-for-ghidra.md#objects-methods-and-null) for what `null` means here.
- **TODO 2: name and address.** A [`Function`](https://ghidra.re/ghidra_docs/api/ghidra/program/model/listing/Function.html) knows its name with `f.getName()` and its first address with `f.getEntryPoint()`. Print both on one line with `println`.
  *Check:* one line per function. Names are `FUN_` plus the address for stripped functions, and import names like `strcmp` for thunks. Find `main` by the address you wrote down.

  The console should fill with lines that start with `Day5ListFunctions.java>`, then your text. `+` joins a name and an address into one string. Primer: [Strings](primers/08-java-for-ghidra.md#strings).
- **TODO 3: size and thunks.** `f.getBody()` is the set of addresses the function covers. Its `getNumAddresses()` is the size in bytes. `f.isThunk()` is true for an import stub.
  *Check:* `main`'s size matches your notes, and `strcmp` shows 6 bytes and your thunk mark.

  `getNumAddresses()` returns a `long`, not an `int`; store it in a `long`. If `main`'s size is off by one, recheck step 2 by hand: did you add the `RET`? Primer: [Variables and types](primers/08-java-for-ghidra.md#variables-and-types).
- **TODO 4: totals.** Count functions and thunks in two `int` variables as the loop runs, and print both after the loop.
  *Check:* the totals look like what you saw in the Symbol Tree. Most thunks sit together near the end.

  Declare both counters before the loop. A counter declared inside the loop starts again at 0 on every pass, and the line after the loop can't see it.

If the lines are hard to read, line them up in columns with `String.format`. Primer: [Hex formatting](primers/08-java-for-ghidra.md#hex-formatting) shows widths such as `%-28s`.

**Step 5, explain it.** Add a comment to every line you wrote. Then compare with [Day5ListFunctions.java](../lab/solutions/day5/Day5ListFunctions.java) in the solutions.

A useful comment says why, not just what. "Get the next function" repeats the code. "Next function by address, or null after the last one, which ends the loop" explains it.

**Stretch goal:** also print the largest function. Which one is it, and is it the program's own code?

**Same idea, different program: print a function's stack frame.** The Listing shows a function's local variables in a list at the top of the function. A script can print the same list, which helps when a function has twenty locals.

Plan in words:

1. Get the function the cursor is in. If there is none, print a message and stop.
2. Ask the function for its stack frame.
3. Ask the frame for its stack variables.
4. For each variable, print its name, its stack offset and its size in bytes.
5. Print how many variables there were.

The calls to look up are `getFunctionContaining(currentAddress)`, [`Function.getStackFrame()`](https://ghidra.re/ghidra_docs/api/ghidra/program/model/listing/Function.html), [`StackFrame.getStackVariables()`](https://ghidra.re/ghidra_docs/api/ghidra/program/model/listing/StackFrame.html), and `getName()`, `getStackOffset()` and `getLength()` on each [`Variable`](https://ghidra.re/ghidra_docs/api/ghidra/program/model/listing/Variable.html). Step 2 is a single call on a `Function` you already have:

```java
StackFrame frame = f.getStackFrame();    // the locals and stack parameters of function f
```

To check it, put the cursor in `ex3`'s `main` and compare with the variable list in the Listing. An offset of -0x48 (-72 in decimal) should print next to `local_48`.

Print offsets in decimal first: a negative `int` printed in hex comes out as `ffffffb8`. Primer: [Locals and how Ghidra names them](primers/05-stack-and-calls.md#locals-and-how-ghidra-names-them).

## Module 2: References in a script (1 h 30 min)

### 2A. Addresses, references and instructions (30 min)

Scripts work with the same objects you click on in the CodeBrowser. Three of them matter today.

- An **Address** is a location in the program. `toAddr(0x140001450L)` makes one from a number, and `a.add(4)` moves 4 bytes on. Printing an address gives it in hex, like the Listing.
- A **Reference** is one arrow from Ghidra's references window. [`getReferencesTo(a)`](https://ghidra.re/ghidra_docs/api/ghidra/program/flatapi/FlatProgramAPI.html) returns the references pointing at `a`, the same list as Show References to. Each [`Reference`](https://ghidra.re/ghidra_docs/api/ghidra/program/model/symbol/Reference.html) has `getFromAddress()` and `getToAddress()`.
- An **Instruction** is one line of the Listing. `getInstructionAt(a)` returns it, and `getInstructionBefore(i)` returns the line above. An [`Instruction`](https://ghidra.re/ghidra_docs/api/ghidra/program/model/listing/Instruction.html) knows its mnemonic, its operands and its own references.

Primer: [The Ghidra objects you will meet](primers/08-java-for-ghidra.md#the-ghidra-objects-you-will-meet) has a table of these objects and the Java facts that go with them.

**Addresses are objects.** You can't write `a + 4` or `a == b` on an `Address`. Use `a.add(4)` to move and `a.equals(b)` to compare. The `L` in `0x140001450L` makes the number a `long`, because it is too big for an `int`.

**References have a type.** Show References to lists a type next to each arrow, and a script can read the same thing. `ref.getReferenceType()` returns it, and you ask it questions:

| Question | True for | Example |
| --- | --- | --- |
| `isCall()` | a call to the address | `CALL strcmp` referring to the thunk |
| `isJump()` | a jump to the address | a `JNZ` referring to its target |
| `isData()` | a reference to data, read or written or just its address taken | `LEA RDX,[string]` referring to the string |

A reference goes from one instruction to one address. An instruction can have several, and an address can be the target of many. `getReferencesFrom(a)` gives the arrows leaving the instruction at `a`.

**Instructions have numbered operands.** Operand 0 is the first one after the mnemonic, the destination in Intel syntax. Operand 1 is the second, usually the source. So for `MOV EDX,0xe`, `getRegister(0)` asks about `EDX` and `getScalar(1)` about `0xe`.

Primer: [Intel syntax](primers/03-reading-assembly.md#intel-syntax) for the operand order, and [The core instructions](primers/03-reading-assembly.md#the-core-instructions) for what each mnemonic does.

`getScalar(n)` returns a [`Scalar`](https://ghidra.re/ghidra_docs/api/ghidra/program/model/scalar/Scalar.html) when operand `n` is a plain number, and `null` when it is a register or memory. That `null` is useful: it is how a script tells `XOR EAX,0x42` from `XOR EAX,EAX`.

Try one call before the exercise. In a new line in `run()` of any skeleton, print `getFunctionContaining(currentAddress).getName()`. Click inside `main` in the Listing and run it; it prints `main`'s name. `currentAddress` is where your cursor is. It is handy for testing, but today's finished scripts don't rely on it. Delete the line afterwards.

Before you delete it, click on an address outside any function, such as a string in `.rdata`, and run it again. The console shows a `NullPointerException`: `getFunctionContaining` found no function and returned `null`. This is mistake 2 in [When a script goes wrong](#when-a-script-goes-wrong), made on purpose.

Three more single calls are worth trying the same way, one at a time. Put the cursor somewhere, run, and compare with what the CodeBrowser shows:

```java
Reference[] refs = getReferencesTo(currentAddress);    // the arrows Show References to lists for the cursor
```

```java
Instruction ins = getInstructionAt(currentAddress);    // the Listing line at the cursor, or null on data
```

```java
MemoryBlock block = getMemoryBlock(currentAddress);    // the block the cursor is in, such as .text or .rdata
```

Print `refs.length`, `ins` or `block.getName()` to see the result. Each needs its class imported at the top of the file, as in the skeletons. A `cannot find symbol` error on `MemoryBlock` means the import is missing.

### Exercise 5.2: Find every call to strcmp (1 h)

On Day 1 you found the password by following `strcmp`'s references. This script does the same for any function name. It is the first script that works on any program, not just the one you wrote it for.

**Step 1, by hand.** In Day 1's `ex1.exe`, select the `strcmp` thunk in the Symbol Tree and press Ctrl+Shift+F.

1. Note each reference: its address, and whether it is a `CALL`.
2. Go to each call. Note the function it is in, and the instruction a few lines above that loads a string's address (`LEA` with a string).
3. Do the same in Day 1's `ex3.exe`. Look at where `strcmp`'s two arguments come from there.

Primer: arguments 1 and 2 go in RCX and RDX, set just before the call. See [The Windows x64 calling convention](primers/05-stack-and-calls.md#the-windows-x64-calling-convention). The shape `LEA` a string, `MOV RCX,RAX`, `CALL` is the "passing a string" item in [Patterns you'll see a lot](primers/03-reading-assembly.md#patterns-youll-see-a-lot).

**Write down:** for each program, the number of calls to `strcmp`, the calling function, and any string the call is given.

**Step 2, plan in words.** For example: find the function named `strcmp` and get the references to it. Keep the calls. For each call, print where it is, and look a few instructions back for strings.

Notice the stopping rules your plan needs: how far back to look, and what to do when an earlier call is in the way. The skeleton's answer is up to 6 instructions, stopping at an earlier call, because that call's arguments are not this one's.

**Step 3 and 4, fill and check one TODO at a time.**

- **TODO 1: the name to look for.** Start with `String target = "strcmp";`. [`getScriptArgs()`](https://ghidra.re/ghidra_docs/api/ghidra/app/script/GhidraScript.html) returns the arguments given to a headless run, and an empty array in the Script Manager. If it has any, use the first one instead.
  *Check:* nothing printed yet; the script runs and finishes.

  An empty array is not `null`: its `length` is 0. Primer: [Arrays](primers/08-java-for-ghidra.md#arrays).
- **TODO 2: find the function.** Reuse the loop from Exercise 5.1. Compare names with `f.getName().equals(target)`; in Java, `==` doesn't compare text. Keep matches in a `List<Function>`.
  *Check:* print the list's size for now. It should be 1 in both programs: the thunk.

  Primer: [Lists and sets](primers/08-java-for-ghidra.md#lists-and-sets) shows `new ArrayList<>()`, `add` and `size()`. If the size is 0, print every name the loop sees and look for `strcmp` among them.
- **TODO 3: references that are calls.** For each kept function, loop over `getReferencesTo(f.getEntryPoint())`. For each reference, `getInstructionAt(ref.getFromAddress())` gives the instruction it comes from. `ins.getFlowType().isCall()` tells you if it is a call.
  *Check:* temporarily print each call's address. `ex1` has one, at the address in your notes.

  `getInstructionAt` returns `null` if the reference comes from data rather than code. Skip those before asking for the flow type, or you meet a `NullPointerException`.
- **TODO 4: the caller.** [`getFunctionContaining(a)`](https://ghidra.re/ghidra_docs/api/ghidra/program/flatapi/FlatProgramAPI.html) returns the function an address is in. Print the call's address and the caller's name, and the number of calls at the end.
  *Check:* one line for `ex1`, naming `main` (or its `FUN_` name if you didn't rename it).

  Renames you make in the CodeBrowser show up in the script's output at once. Rename `main` and run again to see it.
- **TODO 5: string arguments.** Start at `getInstructionBefore(call)` and step back up to 6 times, stopping at an earlier call. For each instruction, loop over `getReferencesFrom(ins.getAddress())`. `getDataAt(ref.getToAddress())` returns the data there, or `null`. If `d.getValue() instanceof String`, print it.
  *Check:* `ex1` prints the password string you found on Day 1. `ex3` prints the call but no string: both arguments are buffers on the stack.

  Primer: [Objects, methods and null](primers/08-java-for-ghidra.md#objects-methods-and-null) explains `instanceof`. In `ex3`, the references before the call point at stack slots, not at `.rdata`, which is why there is nothing to print.

**Try it on another function.** Change `"strcmp"` to `"puts"` in TODO 1 and run it on `ex3`. Compare the strings it prints with Defined Strings. Change it back afterwards. On Day 10 you will pass the name as an argument to a headless run instead.

You should see three calls to `puts`. Two things can go wrong here, and both come from how Ghidra stores strings, not from your loop:

- **A string is missing.** Ghidra doesn't always define a string at an address a `LEA` loads. In `ex3`, "Debugger detected. Bye." may have no defined data, so `getDataAt` returns `null` there.

  Double-click the `LEA`'s target to see: the Listing shows raw bytes, not a string. Your script can still read those bytes itself with `getByte`, up to the zero byte that ends a C string.
- **A string is printed twice.** The `LEA` carries a DATA reference to the string. The `MOV` after it can carry a PARAM reference to the same address, and walking back sees both.

  Keep the addresses you have printed in a `Set`, and skip one you have seen. Primer: [Lists and sets](primers/08-java-for-ghidra.md#lists-and-sets).

If you read bytes yourself, decide when they are a string. A sensible rule: every byte is printable, between `0x20` and `0x7e`, and a zero comes before too long. Primer: [Text in a dump](primers/01-numbers-and-data.md#text-in-a-dump).

**Step 5, explain it.** Comment every line, then compare with [Day5FindCalls.java](../lab/solutions/day5/Day5FindCalls.java).

**Same idea, different program: list every reference into `.rdata`.** Defined Strings shows the strings Ghidra found, but not who uses them. A script can list each piece of read-only data that code points at, with the function that points at it. It also catches strings Ghidra never defined.

Plan in words:

1. Walk every instruction in the program, from the lowest address up.
2. For each instruction, get the references it makes.
3. Keep a reference only if its target is in the memory block named `.rdata`.
4. Print the instruction's address, the function it is in (or "no function"), and the target address.
5. At the end, print how many references and how many different targets there were.

The calls to look up are [`Listing.getInstructions(boolean)`](https://ghidra.re/ghidra_docs/api/ghidra/program/model/listing/Listing.html) on `currentProgram.getListing()`, `Instruction.getReferencesFrom()`, `getMemoryBlock(Address)`, [`MemoryBlock.getName()`](https://ghidra.re/ghidra_docs/api/ghidra/program/model/mem/MemoryBlock.html) and `getFunctionContaining(Address)`. Step 5's "different targets" is a `Set` of addresses.

To check it, run it on `ex3` and find "Bad license key." among the targets. Most other lines come from MinGW's startup code; filtering out lines with no function, or with names you don't recognize, is a good refinement. Primer: [Sections](primers/04-memory-layout.md#sections) explains what lives in `.rdata`.

## Module 3: Decoding ex3's key with a script (1 h)

On Day 1 you decoded `ex3`'s key by hand. Now a script does it, and it finds everything itself: `main`, `decode`, the array, the key and the length. It follows the same path you did, from a string to the code.

Nothing in the finished script is a fixed address. That is what makes it survive a rebuild: change the source, recompile, and the script still finds its way from the string. Scripts with hardcoded addresses break the first time the program changes.

### Exercise 5.3: Decode ex3's key (1 h)

**Step 1, by hand.** Open Day 1's `ex3.exe`. Redo Part A of Day 1's capstone, and this time note every address.

1. Find "Bad license key." in Defined Strings, and follow its reference to `main`.
2. In `main`, find the call to `strcmp` and the call just before it: `decode`. Look at the instructions just before the `decode` call. One of them moves a small number into `EDX`, decode's second argument.
3. In `decode`, find the instruction that loads the array's address, and the `XOR` with a constant.
4. Double-click the array and note its first few bytes.

Primer: [Worked example: ex3's main](primers/05-stack-and-calls.md#worked-example-ex3s-main) walks through this `main` line by line. Its section [decode(key, 14)](primers/05-stack-and-calls.md#decodekey-14) is step 2. It gives away the length, so try step 2 yourself first.

**Write down:** the string's address, `main`'s address, the `decode` call's address, the length in `EDX`, the array's address, the XOR key, and the decoded key.

**Step 2, plan in words.** For example: find the string and follow it to `main`. Walk `main` to the call before `strcmp`, and note the length. Walk `decode` for the array and the key. Read the bytes and XOR them.

Each sentence of that plan is a search with a stopping point. "Walk `main` to the call before `strcmp`" means: go through the instructions in order, remember the last call, and stop at `strcmp`. Write your plan at that level of detail before you open the skeleton.

**Step 3 and 4, fill and check one TODO at a time.**

- **TODO 1: find the string.** [`findBytes(start, "Bad license key")`](https://ghidra.re/ghidra_docs/api/ghidra/program/flatapi/FlatProgramAPI.html) searches memory from `start` and returns the first match, or `null`. Start at `currentProgram.getMinAddress()`.
  *Check:* it prints the string's address from your notes.

  `findBytes` searches the raw bytes, so it finds the text whether or not Ghidra defined a string there. If it prints `null`, check the spelling and the open program.
- **TODO 2: find main.** Take the first reference from `getReferencesTo` on that address, and pass its `getFromAddress()` to `getFunctionContaining`.
  *Check:* it prints `main`'s address.

  If `getReferencesTo` returns an empty array, the search found a copy of the text that no code uses. Print the array's length before you take element 0.
- **TODO 3: find decode and the length.** `currentProgram.getListing().getInstructions(main.getBody(), true)` returns an iterator over `main`'s instructions, in order. Use `hasNext()` and `next()` to loop. For a call, `ins.getFlows()[0]` is the address it calls, and `getFunctionAt` on that address gives the function. Remember the last call that wasn't `strcmp`. For the length, look for a `MOV` into `EDX` whose `ins.getScalar(1)` isn't `null`. Ghidra's `ins.getRegister(0)` reports the full 64-bit register, so for `MOV EDX,0xe` its name is `RDX`, not `EDX`. Print it once to see this for yourself.
  *Check:* it prints `decode`'s address and the length from your notes.

  The `true` in `getInstructions` means "forward", lowest address first. Primer: [Sub-registers](primers/02-registers-and-flags.md#sub-registers) explains why EDX is part of RDX. [Writing a piece: what happens to the rest](primers/02-registers-and-flags.md#writing-a-piece-what-happens-to-the-rest) explains why writing EDX sets all of RDX.

  If the length comes out as -1 or 0, your test for the register never matched. Print the mnemonic, `getRegister(0)` and `getScalar(1)` for every `MOV`, and look at what Ghidra actually reports.
- **TODO 4: the array and the key.** Walk `decode`'s instructions the same way. `ins.getReferencesFrom()` lists the instruction's references; `ref.getReferenceType().isData()` is true for a reference to data. At `-O0`, `decode` also saves its arguments on the stack, and those stores count as data references too. Keep only references whose `ref.getToAddress().isMemoryAddress()` is true: the array is in the program's memory, not on the stack. For the key, find the instruction whose `getMnemonicString()` is `XOR` and read `getScalar(1).getValue()`.
  *Check:* the array's address and the key match your notes.

  If the "array" prints as a stack address rather than a normal hex address, you kept a stack reference: add the `isMemoryAddress()` test. Primer: [Locals and how Ghidra names them](primers/05-stack-and-calls.md#locals-and-how-ghidra-names-them) shows these stack slots, and [Stack frames](primers/05-stack-and-calls.md#stack-frames) shows why `-O0` code stores its arguments there.
- **TODO 5: decode.** `getBytes(array, length)` returns a `byte[]`. XOR each byte with the key and add it to a `StringBuilder` as a `char`. Java bytes are signed, so mask with `& 0xff`.
  *Check:* it prints the key you found on Day 1. Run `ex3.exe` and enter it.

  `getBytes` wants an `int` length, and your length is a `long`: cast it. Primer: [Variables and types](primers/08-java-for-ghidra.md#variables-and-types) for signed bytes, [Casting](primers/08-java-for-ghidra.md#casting), and [Strings](primers/08-java-for-ghidra.md#strings) for `StringBuilder`. [XOR](primers/01-numbers-and-data.md#xor) and [Signed and unsigned numbers](primers/01-numbers-and-data.md#signed-and-unsigned-numbers) explain the bits.

If the key comes out as nonsense, check three things against your notes, in order: the array address, the key, and the length.

**Step 5, explain it.** Comment every line, then compare with [Day5DecodeKey.java](../lab/solutions/day5/Day5DecodeKey.java). Note which of your Day 1 steps each `TODO` replaces.

**Same idea, different program: list every XOR with a constant.** Simple encodings like `ex3`'s use `XOR` with a fixed number. Listing every such `XOR` in a program is a quick way to spot one, and a classic first script on a new target.

Plan in words:

1. Walk every instruction in the program.
2. Keep only instructions whose mnemonic is `XOR`.
3. Of those, keep only the ones whose second operand is a plain number. This drops `XOR EAX,EAX`, which just sets a register to zero.
4. Print the address, the function it is in, the full instruction, and the constant in hex.
5. At the end, print the count.

The calls to look up are `currentProgram.getListing().getInstructions(true)`, `getMnemonicString()`, `getScalar(1)`, `getFunctionContaining(Address)` and `Scalar.getValue()`. Printing the `Instruction` object itself gives the line as the Listing shows it.

To check it, run it on `ex3` and find `decode` in the output. Then run it on Day 5's `ex1`, and notice that none of the program's own functions show up.

Its messages carry their own keys, so its `XOR` takes the key from memory, not from a constant. Knowing what a script can't find is as useful as what it can.

## Module 4: Capstone, the keeper's log (1 h 15 min)

`ex1` in `bin/day5` refuses to show its sealed messages, and its unlock word isn't in Defined Strings. Decoding 20 messages by hand would take an hour; a script does it in a second. As always, work out the format by hand first, on one message.

This is the pattern behind most decoding scripts: find a table from the code that uses it, learn one record's layout, then loop. The hard part is the layout, and you work that out by hand.

### Part A: By hand (30 min)

1. Import and analyze `bin/day5/ex1.exe` (in your `day5` folder). Find `main` from the "is sealed" string.
2. In `main`, find where the number you type becomes an address in the table. Look for the multiplication: it may be an `ADD` and a `SHL` rather than an `IMUL`. Work out the record size.
3. Find the byte `main` tests to decide that a message is sealed. Note its offset in the record.
4. Rename the function `main` calls before printing an open message to `decode`. Find the offsets it reads the key, the length and the text from.
5. Double-click the table's address. Note which memory block it is in (Window → Memory Map shows the blocks). Find the number of records in the prompt or the range check.
6. Decode the first three characters of message 1 by hand, and check them against what `ex1.exe 1` printed.

Primer: [Arrays of structs](primers/07-data-in-memory.md#arrays-of-structs) shows how an index becomes an address. [Memory operands](primers/03-reading-assembly.md#memory-operands) shows how a field offset appears inside the brackets. For step 2, `SHL` by 4 multiplies by 16; see the bit operations in [The core instructions](primers/03-reading-assembly.md#the-core-instructions).

**Write down:** the record size, the number of records, the offset of each field, the table's address and block, and your three decoded characters.

**Stretch goal:** build the record as a structure in the Data Type Manager, as on Day 4. Apply it to the table as an array.

### Part B: The script (35 min)

**Plan in words** first, then fill `Day5DecodeMessages.java` one `TODO` at a time.

Your Part A notes are most of the plan already. Each fact you wrote down becomes either a constant (the layout) or a search (finding `main` and the table). Only the loop is new.

- **TODO 1: the layout.** Replace the zeros with what you wrote down in Part A. Using named constants means the rest of the script reads like your notes.
  *Check:* nothing printed yet.

  You can write the numbers in hex, such as `0x30`, or in decimal. Java accepts both.
- **TODO 2: find main.** Search for "Message %d is sealed" and follow it to `main`, as in Exercise 5.3.
  *Check:* `main`'s address matches your notes.

  If you get a `NullPointerException` here, you are probably looking at Day 1's `ex1`. Check the tab, or print `currentProgram.getName()` and the folder you opened it from.
- **TODO 3: find the table.** Walk `main`'s instructions. The table is the target of a `LEA` whose address is in `.data`. [`getMemoryBlock(a)`](https://ghidra.re/ghidra_docs/api/ghidra/program/flatapi/FlatProgramAPI.html) returns the block an address is in, and [`getName()`](https://ghidra.re/ghidra_docs/api/ghidra/program/model/mem/MemoryBlock.html) gives its name. Strings are in `.rdata`, so they don't match.
  *Check:* it prints the table address from your notes.

  `getMemoryBlock` returns `null` for an address outside every block, such as a stack slot, so check before calling `getName()`.

  Primer: [Sections](primers/04-memory-layout.md#sections) explains why the table, a writable `static` array, is in `.data`. [RIP-relative addressing](primers/03-reading-assembly.md#rip-relative-addressing) explains how the `LEA` reaches it.
- **TODO 4: read each record.** Loop over the records. Record `i` starts at `table.add(i * RECORD_SIZE)`. `getByte(a)` reads one byte; mask it with `& 0xff`. Read the key, the length and the sealed flag, then `getBytes` the text and XOR it.
  *Check:* print just message 1 first. It must match what `ex1.exe 1` printed.

  A counting `for` loop fits here, because you need the index `i`. Primer: [Control flow: if, for, while, for-each](primers/08-java-for-ghidra.md#control-flow-if-for-while-for-each). If message 1 is right but message 2 is garbage, the record size is wrong.
- **TODO 5: print every message.** One line each: its number from 1, its key in hex, open or sealed, and the text.
  *Check:* 20 lines of plain English. The open ones match what the program prints for those numbers.

  Primer: [Hex formatting](primers/08-java-for-ghidra.md#hex-formatting) shows `%02x` for a two-digit key. If every message comes out as odd symbols, a mask is missing. Every key here is above `0x7f`, so the encoded bytes are negative in Java.

### Part C: Use what you found (10 min)

1. Read the sealed messages carefully. One of them gives the unlock word; another one is out of date.
2. Run `ex1.exe` and enter the unlock word. It should print "Archive unlocked."
3. Comment every line of your script, then compare with [Day5DecodeMessages.java](../lab/solutions/day5/Day5DecodeMessages.java).

**Deliverable:** your four scripts with a comment on every line, and a half-page write-up. Include the record layout, how your script finds the table without a hardcoded address, the unlock word, and which sealed message is a trap.

**Same idea, different program: dump any table of records.** Today's table needed a script made for it. A general tool asks for the layout when it runs and prints each record's raw bytes in hex. It is useful on Day 4's arrays of structs and on any table you meet before you understand it.

Plan in words:

1. Take the table's start from the cursor.
2. Ask the user for the record size and the number of records.
3. For each record, read its bytes.
4. Print the record's number, its address, and its bytes in hex, separated by spaces.
5. Stop early if a record would run past the end of the memory block.

The calls to look up are `currentAddress`, [`askInt(String, String)`](https://ghidra.re/ghidra_docs/api/ghidra/app/script/GhidraScript.html), `Address.add(long)`, `getBytes(Address, int)`, `getMemoryBlock(Address)` and [`MemoryBlock.getEnd()`](https://ghidra.re/ghidra_docs/api/ghidra/program/model/mem/MemoryBlock.html). Step 2 is one call per question; `askInt` shows a dialog and waits:

```java
int size = askInt("Dump records", "Record size in bytes?");    // Cancel stops the script
```

To check it, run it on a table from Day 4 with the record size you found there. Each line should start where your structure did. Columns that change in a pattern are often an index or a length; columns that look random are often encoded text.

## Beyond this lesson

These challenges are extra credit, outside the 7 hours. Each one grows a script from today or applies the same method to a new question. Do them in any order.

Use the same five steps as in class. There is no skeleton, so your plan in words is your skeleton. Write its lines as `//` comments in a new file first, then fill them in.

Hints, the API calls to look up and the output to expect are in [lab/solutions/day5/extra-credit.md](../lab/solutions/day5/extra-credit.md). Read the hints for a challenge only after your own plan is written.

Save each new script in your own folder, with a new class name, and add that folder to Script Directories. Don't edit the solutions, and don't reuse a class name from `lab/day5/scripts`.

| Challenge | Difficulty |
| --- | --- |
| 1. Count the calls to every import | ★ |
| 2. Name functions after their strings | ★★ |
| 3. Comment every XOR loop | ★★ |
| 4. Decode the messages in an `-O2` build | ★★ |
| 5. Run a script headless | ★★★ |

### 1. Count the calls to every import

- *Difficulty:* ★
- *Goal:* grow Exercise 5.2's idea into a report of every import stub, with the number of calls to each one. Sort it by count.
- *By hand first:* in Day 1's `ex1`, count the calls to `puts` and `strcmp` with Show References to.
- *Check:* the counts for those two match yours. Explain why `printf` has no stub, and how `ex3` calls `IsDebuggerPresent` without one. Primer: [Imports and the IAT](primers/04-memory-layout.md#imports-and-the-iat).

### 2. Name functions after their strings

- *Difficulty:* ★★
- *Goal:* for each function still called `FUN_...`, find the first string it uses. Rename the function after it, such as `uses_Access_granted`.
- *By hand first:* in Day 1's `ex3`, list each of the program's own functions and the first string it uses. Note which functions use no string at all.
- *Check:* `main` gets a readable name, `decode` keeps its `FUN_` name, and the Symbol Tree shows the new names. Run it on a copy of the program, or be ready to undo.

### 3. Comment every XOR loop

- *Difficulty:* ★★
- *Goal:* find each `XOR` that sits inside a loop, and skip the ones that only zero a register. Add a comment next to each one that names the key or the register.
- *By hand first:* in `ex3`'s `decode` and Day 5's `decode`, find the `XOR` and the backward jump that closes its loop. Primer: [Loops: for and while](primers/06-control-flow.md#loops-for-and-while).
- *Check:* the comment shows in the Listing next to each `XOR`. On Day 5's `ex1`, explain the loop among the program's own functions that isn't `decode`.

### 4. Decode the messages in an -O2 build

- *Difficulty:* ★★
- *Goal:* build Day 5's program at `-O2` and run your capstone script on it. Then make the script read the record size and the count from the code instead of from constants.
- *By hand first:* find the table, the record size and the range check in the `-O2` `main`. Note that `decode` may no longer be a separate function. Primer: [What -O2 changes](primers/06-control-flow.md#what--o2-changes).
- *Check:* the same 20 lines as in the capstone, from both builds. No layout constant is left except the field offsets.

### 5. Run a script headless

- *Difficulty:* ★★★
- *Goal:* run Exercise 5.2's script on `ex3` from a command prompt with Ghidra's `analyzeHeadless`, passing `puts` as the script argument. Then run the capstone script the same way on Day 5's `ex1`.
- *By hand first:* write down the output both scripts gave in the Script Manager.
- *Check:* the command-line output contains the same lines, each starting with the script's name. Day 10 builds on this.

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

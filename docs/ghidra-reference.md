# Ghidra reference

Every Ghidra feature the course teaches, grouped by task, with the day that covers it. It grows with each day and replaces the [Day 1](day1-training.md) cheat sheet by Day 15.

Menu paths and shortcuts were written for Ghidra 12.x and are still to be checked against the version the kit installs.

## Projects and import

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Create a project | Start `Ghidra.cmd`, then File → New Project → Non-Shared. Put it in the kit's `projects` folder. | | Day 1 |
| Import a program | Drag the `.exe` into the project window and accept the detected format (Portable Executable, x86:LE:64). | | Day 1 |
| Analyze a program | Double-click the program to open the CodeBrowser and click Yes to analyze with the defaults. Wait for the progress bar at the bottom right. | | Day 1 |
| Change analyzers or re-run analysis | Analysis → Auto Analyze. Tick or untick analyzers in the list, then click Analyze. | | Day 2 |
| Run one analyzer once | Analysis → One Shot, then pick the analyzer. | | Day 2 |
| Let the decompiler work out parameters | Tick **Decompiler Parameter ID** in the analyzer list and analyze again. | | Day 2 |

## Navigating

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Read the disassembly | Listing (center): one instruction per line with its address. | | Day 1 |
| Read the pseudocode | Decompiler (right): C-like code for the function the cursor is in. Clicking in one window highlights the matching line in the other. | | Day 1 |
| Follow a name | Double-click it. | | Day 1 |
| Go back | | Alt+← | Day 1 |
| Go to an address | | `G` | Day 1 |
| See an array's bytes | Double-click the array in the decompiler. | | Day 1 |
| See a function as a graph | Window → Function Graph. Loops show up as boxes and arrows. | | Day 1 |
| Open a second program in the same CodeBrowser | File → Open. Each program gets its own tab above the Listing. | | Day 2 |
| Bookmark an address | Press Ctrl+D and type a short note. Window → Bookmarks lists them; double-click one to go back. | Ctrl+D | Day 3 |
| Read the Listing alone | Close the Decompiler window. Window → Decompiler opens it again. | | Day 3 |

## Finding code

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Browse functions, imports and exports | Symbol Tree (left). | | Day 1 |
| Spot what a program does from its imports | Symbol Tree → Imports. Names like `strcmp`, `IsDebuggerPresent` or `CreateFileW` are hints. | | Day 1 |
| List every string | Window → Defined Strings. Type in its filter to narrow the list. | | Day 1 |
| Find who uses a string or function | Right-click it → References → Show References to. | Ctrl+Shift+F | Day 1 |
| Find `main` in a stripped program | Follow a reference from one of its strings, such as "Access granted!". Don't trace the startup code. | | Day 1 |
| See what a function calls and who calls it | Window → Function Call Trees, with the cursor in the function. It shows Incoming Calls and Outgoing Calls. A recursive function shows up in its own outgoing calls. | | Day 3 |
| Find wide (UTF-16) strings | Window → Defined Strings. Their Data Type is `unicode`, and their value shows as `u"..."`. | | Day 3 |
| Tell A and W API functions apart | Symbol Tree → Imports. A name ending in `W`, such as `CreateFileW`, takes UTF-16 text; one ending in `A` takes 8-bit text. | | Day 3 |

## Annotating

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Rename a function or variable | Select it and press `L`. | `L` | Day 1 |
| Change a type | Select it and press Ctrl+L, for example to make a parameter `char *`. | Ctrl+L | Day 1 |
| Add a comment | | `;` | Day 1 |
| Show a number in hex or decimal | Right-click the number and pick the format. | | Day 1 |
| Set a function's prototype | Right-click the function name in the Decompiler → Edit Function Signature, and type the prototype as C. | | Day 2 |
| Set a function's calling convention | Edit Function Signature → Calling Convention. 64-bit Windows code uses `__fastcall`. | | Day 2 |
| Show a number as characters | Right-click the number in the Listing → Convert. | | Day 2 |
| Make data a pointer | Select the data in the Listing and press `P`. | `P` | Day 3 |
| Make an array | Select the first element in the Listing, press `[` and enter the number of elements. | `[` | Day 3 |
| Make bytes a wide string | Put the cursor on the first byte in the Listing, press `T` and enter `unicode`. | `T` | Day 3 |

## Patching and export

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Edit an instruction | Patch Instruction. | Ctrl+Shift+G | Day 1 |
| Save patches to a file | File → Export Program (Original File). | | Day 1 |

## Memory and addresses

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| See the memory layout | Window → Memory Map. | | Day 1 |
| Match x64dbg's addresses | Window → Memory Map, click the house icon (Set Image Base) and enter the base from x64dbg's Symbols tab. | | Day 1 |
| Convert an address without rebasing | Offset = Ghidra address − `0x140000000`. The x64dbg address = base + offset. | | Day 1 |

## Comparing programs

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Open Version Tracking | In the project window, Tools → Run Tool → Version Tracking. | | Day 2 |
| Compare two builds | In Version Tracking, File → New Session. Pick the source (for example the `-O0` build) and the destination (the `-O2` build). | | Day 2 |
| Match identical functions | Add the **Exact Function Bytes Match** correlator to the session. | | Day 2 |
| Match identical data, such as strings | Add the **Exact Data Match** correlator, then select its matches and accept them. | | Day 2 |
| Match functions that use the same data | Add the **Data Reference Match** correlator. It only uses matches you have accepted. | | Day 2 |
| Copy a name to the other build | Open the match and apply the function name from its markup items. | | Day 2 |

## Control flow

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Read a `switch` | Auto-analysis recovers jump tables. The indirect `jmp` is labeled `switchD` and each target `caseD_<n>`; the decompiler shows a `switch` statement. | | Day 3 |
| Find a jump table's data | Double-click the table address in the instruction that loads it. The table is labeled `switchdataD`. | | Day 3 |
| Spot a jump table that wasn't recovered | The decompiler shows a warning that it could not recover the jump table, and the cases are missing. Read the table from the Listing. | | Day 3 |
| Tell loops apart in the Listing | `for` and `while` jump forward to the condition first; `do`-`while` runs the body first. Each loop ends with a backward jump. | | Day 3 |

## Listing display

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Show or hide Listing fields | Click the Edit the Listing fields button at the top of the Listing. Right-click a field in the header to turn it off, such as Bytes. | | Day 3 |
| Change a field's settings | Edit → Tool Options → Listing Fields. For example, XREFs Field → Maximum Number of XREFs to Display. | | Day 3 |

## Data types

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| See a program's types | Window → Data Type Manager. Types you create go in the archive named after the program. | | Day 4 |
| Create a structure | Data Type Manager: right-click the program's archive → New → Structure. Set its name and size at the bottom of the Structure Editor. | | Day 4 |
| Edit a structure | Double-click it in the Data Type Manager. In the Structure Editor, double-click a row's Data Type cell and type a type, such as `short`, `char[10]` or `item *`. | | Day 4 |
| Show padding | Leave bytes no field uses as `undefined`, or turn on the editor's packing option to add padding the way the compiler does. | | Day 4 |
| Build a structure from code | Decompiler: right-click a pointer variable → Auto Create Structure. Rename the `field_0x..` names afterwards. | | Day 4 |
| Retype a variable as a struct pointer | Select it in the Decompiler and press Ctrl+L, then enter `item *` or `item **`. | Ctrl+L | Day 4 |
| Apply a type to data | In the Listing, put the cursor on the data and press `T`, then choose the type. | `T` | Day 4 |
| Make an array of a type | In the Listing, press `[` on the first element and enter the count. | `[` | Day 4 |
| Create a type archive | Data Type Manager: arrow menu at the top right → New File Archive. Save it as a `.gdt` file. | | Day 4 |
| Copy a type into an archive | Drag it from the program's archive onto the `.gdt` archive, then right-click the archive → Save Archive. | | Day 4 |
| Use an archive in another program | Data Type Manager: arrow menu → Open File Archive, pick the `.gdt`, then apply its types as usual. | | Day 4 |
| Send a changed type back to its archive | Right-click the type in the program's archive → Commit to Archive, then save the archive. | | Day 4 |

## Scripting

Scripts are Java classes that extend `GhidraScript`. Most calls below come from [FlatProgramAPI](https://ghidra.re/ghidra_docs/api/ghidra/program/flatapi/FlatProgramAPI.html), which every script can use directly.

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Open the Script Manager | Window → Script Manager in the CodeBrowser. Categories are on the left, scripts on the right. | | Day 5 |
| Find a script | Type in the filter at the bottom of the Script Manager, or pick a category. `//@category Course.Day5` in a script's header puts it under Course → Day5. | | Day 5 |
| Add a folder of scripts | Script Manager toolbar → Script Directories (the Bundle Manager), then the green plus. Pick the folder, such as `lab/day5/scripts`. Don't add two folders with scripts of the same name. | | Day 5 |
| Run a script | Select it and click Run Script (the green arrow) in the Script Manager's toolbar. | | Day 5 |
| Edit a script | Select it and click Edit Script. Save in the editor, then run it again; Ghidra compiles it on every run. | | Day 5 |
| Read a script's output | Window → Console. Each line starts with the script's name. Compile errors and exceptions appear here too. | | Day 5 |
| Look up an API call | Click the Help button in the Script Manager's toolbar, or use the online API documentation. | | Day 5 |
| Print a line | `println("text")` | | Day 5 |
| Use the open program, or the cursor's address | `currentProgram`, `currentAddress` | | Day 5 |
| Walk every function | `getFirstFunction()`, then `getFunctionAfter(f)` until it returns `null`. | | Day 5 |
| Read a function's name, start and size | `f.getName()`, `f.getEntryPoint()`, `f.getBody().getNumAddresses()`. `f.isThunk()` is true for an import stub. | | Day 5 |
| Find the function at or around an address | `getFunctionAt(a)` for its entry point, `getFunctionContaining(a)` for any address inside it. | | Day 5 |
| Find references | `getReferencesTo(a)` and `getReferencesFrom(a)`. Each `Reference` has `getFromAddress()`, `getToAddress()` and `getReferenceType()`. | | Day 5 |
| Read instructions | `getInstructionAt(a)`, `getInstructionBefore(i)`, or `currentProgram.getListing().getInstructions(f.getBody(), true)` for a whole function. | | Day 5 |
| Read an instruction's parts | `getMnemonicString()`, `getRegister(n)`, `getScalar(n)`, `getFlows()`, and `getFlowType().isCall()`. | | Day 5 |
| Read defined data, such as a string | `getDataAt(a)`, then `getValue()`. | | Day 5 |
| Search memory for text or bytes | `findBytes(currentProgram.getMinAddress(), "text")` returns the first match, or `null`. | | Day 5 |
| Read bytes | `getByte(a)` and `getBytes(a, n)`. Java bytes are signed, so mask with `& 0xff`. | | Day 5 |
| Move to another address | `a.add(n)`, or `toAddr(0x140001000L)` for a fixed one. | | Day 5 |
| Find which memory block an address is in | `getMemoryBlock(a).getName()`, such as `.data` or `.rdata`. | | Day 5 |
| Take arguments in a headless run | `getScriptArgs()`. It returns an empty array in the Script Manager. | | Day 5 |
| Let Cancel stop a long loop | Check `monitor.isCancelled()` in the loop condition. | | Day 5 |

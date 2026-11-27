# Ghidra reference

Every Ghidra feature the course teaches, grouped by task, with the day that covers it. It grows with each day and replaces the [Day 1](day1-training.md) cheat sheet by Day 15.

Menu paths and shortcuts were written for Ghidra 12.x and are still to be checked against the version the kit installs.

## Projects and import

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Create a project | Start `Ghidra.cmd`, then File → New Project → Non-Shared. Put it in the kit's `projects` folder. | | Day 1 |
| Import a program | Drag the `.exe` into the project window and accept the detected format (Portable Executable, x86:LE:64). | | Day 1 |
| Analyze a program | Double-click the program to open the CodeBrowser and click Yes to analyze with the defaults. Wait for the progress bar at the bottom right. | | Day 1 |

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

## Finding code

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Browse functions, imports and exports | Symbol Tree (left). | | Day 1 |
| Spot what a program does from its imports | Symbol Tree → Imports. Names like `strcmp`, `IsDebuggerPresent` or `CreateFileW` are hints. | | Day 1 |
| List every string | Window → Defined Strings. Type in its filter to narrow the list. | | Day 1 |
| Find who uses a string or function | Right-click it → References → Show References to. | Ctrl+Shift+F | Day 1 |
| Find `main` in a stripped program | Follow a reference from one of its strings, such as "Access granted!". Don't trace the startup code. | | Day 1 |

## Annotating

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Rename a function or variable | Select it and press `L`. | `L` | Day 1 |
| Change a type | Select it and press Ctrl+L, for example to make a parameter `char *`. | Ctrl+L | Day 1 |
| Add a comment | | `;` | Day 1 |
| Show a number in hex or decimal | Right-click the number and pick the format. | | Day 1 |

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

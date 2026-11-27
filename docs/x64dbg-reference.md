# x64dbg reference

Every x64dbg feature the course teaches, grouped by task, with the day that covers it. It grows with each day and replaces the [Day 1](day1-training.md) cheat sheet by Day 15.

Menu paths and shortcuts were written for x64dbg 2026.x and are still to be checked against the version the kit installs.

## Opening programs

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Open a program | Start `x64dbg.cmd` and use File → Open. | | Day 1 |
| Reach the program's entry point | It pauses first at a system breakpoint inside Windows. Press F9 once. | F9 | Day 1 |
| Restart the program | | Ctrl+F2 | Day 1 |

## Running and stepping

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Run until the next breakpoint | | F9 | Day 1 |
| Step over | Runs one instruction and doesn't follow calls inside it. | F8 | Day 1 |
| Step into | Follows calls. | F7 | Day 1 |
| Run until the function returns | | Ctrl+F9 | Day 1 |

## Breakpoints

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Set or clear a breakpoint | Select the instruction and press F2. | F2 | Day 1 |

## Reading state

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| See the current instruction | Disassembly (top left of the CPU tab). It is highlighted and RIP points at it. | | Day 1 |
| Read registers and flags | Registers (top right). Values that just changed turn red. | | Day 1 |
| See what a register points at | Right-click the register → Follow in Dump. | | Day 1 |
| Read local variables and return addresses | Stack (bottom right). | | Day 1 |
| Read a call's arguments | Pause on the `call`. The first four arguments are in RCX, RDX, R8 and R9. | | Day 1 |
| Read a return value | Step over the call and read RAX. | F8 | Day 1 |
| Find the image base | Open the Symbols tab and note the program's base address. | | Day 1 |

## Finding code

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Find code by its strings | Right-click in the disassembly → Search for → Current Module → String references. Double-click a result to jump to it. | | Day 1 |
| Go to an address | | Ctrl+G | Day 1 |
| Go back | | `-` (minus) | Day 1 |
| Find references to the selection | | `X` | Day 1 |

## Annotating

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Add a label | | `:` | Day 1 |
| Add a comment | | `;` | Day 1 |

## Changing and patching

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Edit a register | Double-click it, for example to set RAX to `0`. | | Day 1 |
| Flip a flag | Double-click the flag, such as ZF. | | Day 1 |
| Rewrite an instruction | Select it and press Space. To remove a jump, enter `nop` with "Fill with NOPs" ticked, or reverse the jump. | Space | Day 1 |
| Save a patched copy | File → Patch file → Patch File. Save under a new name and never overwrite the original. | Ctrl+P | Day 1 |
| Hide the debugger from `IsDebuggerPresent` | Debug → Advanced → Hide debugger (PEB). | | Day 1 |

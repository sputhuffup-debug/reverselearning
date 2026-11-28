# x64dbg reference

Every x64dbg feature the course teaches, grouped by task, with the day that covers it. It grows with each day and replaces the [Day 1](day1-training.md) cheat sheet by Day 15.

Menu paths and shortcuts were written for x64dbg 2026.x and are still to be checked against the version the kit installs.

## Opening programs

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Open a program | Start `x64dbg.cmd` and use File → Open. | | Day 1 |
| Reach the program's entry point | It pauses first at a system breakpoint inside Windows. Press F9 once. | F9 | Day 1 |
| Restart the program | | Ctrl+F2 | Day 1 |
| Run a program with command-line arguments | At the system breakpoint, File → Change Command Line. Keep the program's path first, type the arguments after it, then press F9. | | Day 3 |

## Running and stepping

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Run until the next breakpoint | | F9 | Day 1 |
| Step over | Runs one instruction and doesn't follow calls inside it. | F8 | Day 1 |
| Step into | Follows calls. | F7 | Day 1 |
| Run until the function returns | | Ctrl+F9 | Day 1 |
| Return to the program's own code | Run to user code. Use it after stopping inside a DLL. | Alt+F9 | Day 2 |

## Breakpoints

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Set or clear a breakpoint | Select the instruction and press F2. | F2 | Day 1 |
| Break on a DLL function | Symbols tab → select the DLL (for example `msvcrt.dll`) → find the function, such as `strcmp`, and press F2. | F2 | Day 2 |
| Stop only when a condition is true | Breakpoints tab, right-click the breakpoint → Edit, and fill in Break Condition, such as `eax == 7`. | | Day 3 |
| Count how often a breakpoint is hit | Read the hit count in the Breakpoints tab. A condition of `0` counts hits without stopping. | | Day 3 |

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
| Read arguments 5 and up | Pause on the `call`. Argument 5 is at `[rsp+0x20]` and argument 6 at `[rsp+0x28]`. Inside the callee they are 8 bytes higher. | | Day 2 |
| See how you got here | Call Stack tab. It lists the return addresses on the stack; a tail call (`jmp`) leaves no line. | | Day 2 |
| Go to a caller | Double-click a line in the Call Stack tab. | | Day 2 |
| See a function as a graph | Press `G` in the disassembly. Press it again to go back to the list. | `G` | Day 3 |
| Read `main`'s arguments | At `main`'s first instruction, ECX is `argc` and RDX is `argv`. `[rdx+8]` is `argv[1]`; follow it in the dump. | | Day 3 |
| Read wide (UTF-16) text in the dump | Right-click the dump and switch its text view from ASCII to Unicode. In ASCII view, wide text shows a dot between letters. | | Day 3 |
| See text sent with `OutputDebugString` | Log tab. | | Day 3 |
| Read memory in an expression | `[rax]` reads 8 bytes; `dword:[rax+0x14]`, `word:[rax+4]` and `byte:[rax+0x10]` read 4, 2 and 1. Brackets nest: `[[rcx+8]+8]`. | | Day 4 |
| Follow a struct in the dump | Click in the dump, press Ctrl+G and enter the struct's address or an expression such as `rax`. Read each field at its offset. | Ctrl+G | Day 4 |
| Follow a pointer field | In the dump, press Ctrl+G and enter the field as an expression, such as `[rcx+8]` for a list node's `next`. Repeat until it is 0. | Ctrl+G | Day 4 |
| Match the dump to a field's size | Right-click the dump and switch between hex bytes, 16-bit or 32-bit integers, and addresses. | | Day 4 |

## Watching values

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Watch a value | Open the Watch 1 tab next to the dump tabs, right-click → Add, and enter an expression. It updates every time the program pauses. | | Day 4 |
| Watch a struct field through a local | Add an expression that reads the local's stack slot, then the field: `word:[[rbp-0x10]+4]`. Use your own slot and offset. | | Day 4 |
| Watch one flag bit | Add an expression that masks the field, such as `byte:[[rbp-0x10]+0x10]&4`. It shows 0 while the bit is clear. | | Day 4 |

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
| Name functions in the call stack | Go to each function's start and press `:`. The Call Stack tab shows the labels. | `:` | Day 2 |

## Changing and patching

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Edit a register | Double-click it, for example to set RAX to `0`. | | Day 1 |
| Flip a flag | Double-click the flag, such as ZF. | | Day 1 |
| Rewrite an instruction | Select it and press Space. To remove a jump, enter `nop` with "Fill with NOPs" ticked, or reverse the jump. | Space | Day 1 |
| Save a patched copy | File → Patch file → Patch File. Save under a new name and never overwrite the original. | Ctrl+P | Day 1 |
| Hide the debugger from `IsDebuggerPresent` | Debug → Advanced → Hide debugger (PEB). | | Day 1 |

## Command line and expressions

| Task | How | Shortcut | Day |
| --- | --- | --- | --- |
| Run a command | Type it in the Command box at the bottom of the window and press Enter. Output goes to the Log tab. | | Day 3 |
| Work out an expression | Type it in the Command box, such as `rsp+0x20`. Numbers are hex. | | Day 3 |
| Read memory in an expression | `[address]` reads 8 bytes; `byte:[address]` reads one. | | Day 3 |
| Set a breakpoint from the command line | `bp address`. `bpcnd address, condition` gives it a condition. | | Day 3 |
| Show an address in the dump | `dump address`, such as `dump rbp-0x11`. | | Day 3 |
| Find the command line in memory | `peb()` is the PEB's address. `dump [[peb()+0x20]+0x78]` shows the command line, as UTF-16. | | Day 3 |

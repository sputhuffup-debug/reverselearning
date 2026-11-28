# Day 3 checkpoint: answer and model write-up

SPOILERS for the [Checkpoint](../../../docs/day3-training.md#checkpoint). Read this only after your 45 minutes are up.

## The answer

```bash
bin/day3/checkpoint.exe 631236932
```

It prints "You found the way out." and exits with 0. The argument is a path through a maze, one digit per move, with the digits laid out like a numeric keypad. Any other path of 12 moves or fewer that reaches the exit without touching a wall works too; 9 moves is the shortest.

## Model write-up

Addresses are from our build with MinGW-w64 GCC 13 at `-O0 -s -Wall`. Yours may differ, but the shapes should match.

### Summary

`checkpoint.exe` takes one command-line argument and treats each character as a move on a 6 by 6 grid. The grid is a global table of six wide strings in `.rdata`. Moving onto `#` or off the grid fails; ending on `X` after the last move succeeds.

### First look

- Running it with no argument prints "Usage: checkpoint <moves>" and exits with 2. So it wants an argument, not keyboard input.
- Defined Strings shows the plain messages: "Usage: checkpoint <moves>", "Too many moves.", "Unknown move.", "You walk into a wall.", "Still lost in the maze." and "You found the way out.".
- It also shows six wide strings of six characters each, such as `u"S..#.."`, made of `S`, `.`, `#` and `X`. If they are missing, follow the pointer table below and press `T` on each target to make it `unicode`.
- The imports include `strlen` and `puts`, and `__getmainargs`, so the program uses a narrow `main`.

### main (`0x1400014dc`)

1. `cmp dword ptr [rbp+0x10], 2` and `je`: `argc` must be 2, so exactly one argument. Otherwise it prints the usage line and returns 2.
2. `argv[1]` is read with `add rax, 8` and a load. `strlen` of it is compared with `0xc` (12) using `jbe`, so more than 12 characters prints "Too many moves.".
3. Two locals start at 0: the row at `[rbp-0x4]` and the column at `[rbp-0x8]`. The `S` in the grid's top-left corner matches this start.
4. A `while` loop walks a pointer along `argv[1]`: `jmp` to the test first, `movzx eax, byte ptr [rax]`, `test al, al`, `jne` back up.
5. In the body, two more locals are set to 0, then a `switch` on the character. It is a jump table: `sub eax, 0x31` (`'1'`), `cmp eax, 8`, `ja` to the default, and an indirect `jmp rax`. The table at `0x140004110` has 9 entries, for `'1'` to `'9'`.
6. The default case prints "Unknown move." and returns 1. The entry for `'5'` also points to the default, so `5` is not a move.
7. Each other case sets the two locals to -1, 0 or 1. They are the row change (`[rbp-0x14]`) and the column change (`[rbp-0x18]`).
8. Then `main` calls a helper with row + row change in ECX and column + column change in EDX. If it returns 0, the program prints "You walk into a wall." and returns 1. Otherwise both changes are added to the row and the column.
9. After the loop, it reads the grid cell at the final row and column and compares it with `0x58` (`'X'`). Equal prints "You found the way out." and returns 0; otherwise "Still lost in the maze." and 1.

### The cases

| Character | Row change | Column change | Direction |
| --- | --- | --- | --- |
| `1` | +1 | -1 | down and left |
| `2` | +1 | 0 | down |
| `3` | +1 | +1 | down and right |
| `4` | 0 | -1 | left |
| `6` | 0 | +1 | right |
| `7` | -1 | -1 | up and left |
| `8` | -1 | 0 | up |
| `9` | -1 | +1 | up and right |

Rows grow downwards, so `8` is up. That is the layout of a numeric keypad, with `5` in the middle doing nothing.

### The helper (`0x140001480`)

- Four signed compares reject a row or column below 0 or above 5, and return 0.
- It loads `maze[row]` from the pointer table at `0x140004060`, with a scale of 8. Then it reads the character at `col * 2` with `movzx eax, word ptr [rax]`: a wide string.
- `cmp ax, 0x23` (`'#'`) and `setne al`: it returns 1 for an open cell and 0 for a wall.

### The data

The pointer table at `0x140004060` is in `.rdata` and holds six pointers to the rows, which are also in `.rdata`:

```text
         col  012345
row 0         S..#..
row 1         ##.#.#
row 2         #..#..
row 3         #.##.#
row 4         #...#.
row 5         ###.#X
```

### The path

Positions are (row, column). From (0,0): `6` to (0,1), `3` to (1,2), `1` to (2,1), `2` to (3,1) and `3` to (4,2). Then `6` to (4,3), `9` to (3,4), `3` to (4,5) and `2` to (5,5), the `X`. That is 9 moves, within the limit of 12.

### How I confirmed it

- Ran `checkpoint.exe 631236932`: "You found the way out.", exit code 0.
- Ran `checkpoint.exe 63123693`, one move short: "Still lost in the maze.". So the program checks the end position, not whether the path passed the exit.
- In x64dbg, set the command line with File → Change Command Line. A breakpoint on the helper's first instruction, with the condition `ecx == 5`, stopped once: on the last move.

### Skills used

| Step | Where today's guide teaches it |
| --- | --- |
| Reading the jump table, and the `'5'` entry that points to the default | Module 1 |
| The `while` loop over the argument, ended by `test al, al` | Module 2 and Module 4's string loop |
| The pointer table and the rows in `.rdata` | Module 4 |
| `argc` and `argv[1]`, wide strings and `word ptr` reads | Module 5 |
| Conditional breakpoints and running with arguments in x64dbg | Exercises 1.3 and 5.2 |

## Common mistakes

- Taking the rows in Defined Strings as one long string, or in the wrong order. The pointer table gives the order.
- Reading the case order from the Listing instead of the table: the case bodies need not be in the order of their characters.
- Swapping row and column. The first argument of the helper indexes the pointer table, so it is the row.
- Trying `5` as a pause. It goes to the default and prints "Unknown move.".

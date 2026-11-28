# Primers

Short background reads for the course: what the day guides assume you already know. Each one explains a topic from the ground up, with examples from the course's own programs, and ends with questions to check yourself.

Read each primer before the first day that needs it. They are also worth rereading when an exercise doesn't make sense.

| Primer | What it covers | Read before | Time |
| --- | --- | --- | --- |
| [Numbers and data](01-numbers-and-data.md) | Hex and binary, bytes and sizes, little-endian, signed values, text, XOR | [Day 1](../day1-training.md) | 25 min |
| [Registers and flags](02-registers-and-flags.md) | The x86-64 registers and sub-registers, RIP, flags and conditional jumps | [Day 1](../day1-training.md) | 25 min |
| [Reading assembly](03-reading-assembly.md) | Intel syntax, memory operands, the core instructions, common patterns | [Day 1](../day1-training.md) | 35 min |
| [A program in memory](04-memory-layout.md) | Sections, heap, stack, DLLs, ASLR, where each kind of variable lives | [Day 1](../day1-training.md) | 20 min |
| [The stack and the calling convention](05-stack-and-calls.md) | Push and pop, frames, the Windows x64 calling convention, a real `main` walked through | [Day 1](../day1-training.md) (first half), [Day 2](../day2-training.md) | 40 min |
| [How C control flow compiles](06-control-flow.md) | If-else, loops, switch and jump tables, calls, recursion, what `-O2` changes | [Day 3](../day3-training.md) | 30 min |
| [Data in memory](07-data-in-memory.md) | Arrays, pointers, strings, structs, alignment, linked lists | [Day 4](../day4-training.md) | 30 min |
| [Just enough Java for Ghidra scripts](08-java-for-ghidra.md) | The Java that Day 5's scripts need, and the Ghidra objects they use | [Day 5](../day5-training.md) | 40 min |

Later days will add primers as they need them; see the [roadmap](../roadmap.md).

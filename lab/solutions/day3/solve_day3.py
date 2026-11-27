"""Solvers for Day 3's ex2 (door code) and ex3 (tower level). SPOILER: solution file.

    python solve_day3.py ex2    prints the 8-digit door code
    python solve_day3.py ex3    prints the tower level whose weave() value is 0xA4B5
"""
import sys


def door_code() -> str:
    x = 0x2A
    digits = []
    for _ in range(8):                 # the for loop: build the expected digits
        x = (x * 37 + 11) % 101
        digits.append(str(x % 10))
    return "".join(reversed(digits))   # the do-while loop reverses them in place


def weave(n: int) -> int:
    # Same recursion as the program, done bottom-up so it is fast.
    a, b = 2, 3                        # weave(0), weave(1)
    if n < 2:
        return n + 2
    for k in range(2, n + 1):
        a, b = b, a + b + k
    return b


def tower_level() -> int:
    for n in range(1, 31):
        if weave(n) == 0xA4B5:
            return n
    raise SystemExit("no level matches")


if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] not in ("ex2", "ex3"):
        sys.exit("usage: solve_day3.py ex2|ex3")
    print(door_code() if sys.argv[1] == "ex2" else tower_level())

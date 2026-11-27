"""Keygen for ex2_serial (Day 1, Exercise 1.2). SPOILER: solution file."""
import sys


def serial(name: str) -> int:
    h = 0x1337
    for c in name.encode():
        h = (h * 31 + c) & 0xFFFFFFFF
    return h ^ 0xC0FFEE


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: keygen_ex2.py NAME")
    print(format(serial(sys.argv[1]), "x"))

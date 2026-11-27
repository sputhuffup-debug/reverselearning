"""Access code for ex4_chain (Day 2, Exercise 2.3). SPOILER: solution file.

check_zone calls zone_key(7, 4, 12, 5, 0xC0DE, 0x2026); the last two arguments
are passed on the stack. check_door compares the code you typed with the result.
"""


def rotl(x: int, n: int) -> int:
    x &= 0xFFFFFFFF
    return ((x << n) | (x >> (32 - n))) & 0xFFFFFFFF


def zone_key(zone, floor, door, shift, salt, pepper):
    k = (zone * 1000003 + floor * 7919 + door) & 0xFFFFFFFF
    k = rotl(k, shift) ^ salt
    return ((k + pepper) & 0xFFFFFFFF) % 100000000


if __name__ == "__main__":
    print(zone_key(7, 4, 12, 5, 0xC0DE, 0x2026))

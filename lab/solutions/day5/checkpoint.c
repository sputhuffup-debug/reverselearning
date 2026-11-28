/* SPOILER: Day 5 checkpoint program. Built as bin/day5/checkpoint.exe; students see only the binary.
 *
 * A relay of 40 signal stations. Each live station holds one character of the passphrase, encoded
 * with its own key; decoy stations hold characters too, and the check skips them. The table is in
 * shuffled order, so the characters only make sense once every live record is decoded and sorted
 * by its sequence number. The passphrase itself is never stored: the check encodes what you type
 * and compares it with each station's signal byte.
 */
#include <stdio.h>
#include <string.h>

#define DECOY 0x10   /* a station with this flag bit set is a decoy */

struct station {
    unsigned char flags;   /* noise, except for the DECOY bit */
    unsigned char seq;     /* position of this station's character in the passphrase */
    unsigned char sig;     /* (character ^ key) + 3 * seq, in 8 bits */
    unsigned char key;
};

static struct station stations[] = {
    { 0x4F,  7, 0xFD, 0x8D },
    { 0xD5, 26, 0x4A, 0xCD },
    { 0x43, 11, 0x8B, 0x47 },
    { 0xCE, 26, 0x1E, 0xE4 },
    { 0xB1, 23, 0xD9, 0xE7 },
    { 0x04,  0, 0xE3, 0x8D },
    { 0xA2, 20, 0xDC, 0x8D },
    { 0xED,  3, 0x50, 0x33 },
    { 0xC1, 10, 0xE9, 0xB2 },
    { 0x04, 27, 0xFB, 0x98 },
    { 0xA5, 17, 0x38, 0x28 },
    { 0x6A, 23, 0x4C, 0x70 },
    { 0x6E,  8, 0xDC, 0xA8 },
    { 0x21, 12, 0x08, 0x8C },
    { 0x78,  2, 0xB7, 0xC4 },
    { 0xE0,  9, 0x02, 0x86 },
    { 0xF9, 21, 0xE2, 0xC7 },
    { 0xB9,  1, 0xF8, 0x9A },
    { 0xA1, 14, 0xCB, 0xCD },
    { 0x3C,  3, 0xAA, 0xD5 },
    { 0xB9,  4, 0xA1, 0xFD },
    { 0x27,  1, 0x62, 0x30 },
    { 0xEF, 22, 0x96, 0x35 },
    { 0x9A, 24, 0x00, 0xD3 },
    { 0x4A, 15, 0xF3, 0xA2 },
    { 0xEA,  6, 0x4A, 0x4A },
    { 0x5C, 22, 0xEC, 0xDF },
    { 0x96,  0, 0x2C, 0x5F },
    { 0x67, 18, 0xF5, 0xDE },
    { 0xA4, 25, 0x3A, 0xC2 },
    { 0x81,  2, 0x56, 0x22 },
    { 0x8C,  5, 0x8C, 0x50 },
    { 0xA3, 19, 0x3B, 0x76 },
    { 0x98, 27, 0x3F, 0xD9 },
    { 0x2F, 16, 0x30, 0x73 },
    { 0xCB, 13, 0x62, 0x54 },
    { 0x88,  4, 0xE8, 0xB4 },
    { 0xD3, 12, 0x12, 0x88 },
    { 0x88, 21, 0x5B, 0x78 },
    { 0x2D, 24, 0x09, 0xAF },
};

#define COUNT ((int)(sizeof stations / sizeof stations[0]))

/* Returns 1 if the passphrase matches every live station, 0 otherwise. */
static int check_phrase(const char *p) {
    int live = 0;
    for (int j = 0; j < COUNT; j++) {
        if (!(stations[j].flags & DECOY)) live++;
    }
    if ((int)strlen(p) != live) return 0;

    for (int i = 0; i < live; i++) {
        int found = 0;
        for (int j = 0; j < COUNT; j++) {
            if (stations[j].flags & DECOY) continue;
            if (stations[j].seq != i) continue;
            unsigned char sig = (unsigned char)(((unsigned char)p[i] ^ stations[j].key) + 3 * stations[j].seq);
            if (sig != stations[j].sig) return 0;
            found = 1;
        }
        if (!found) return 0;
    }
    return 1;
}

int main(void) {
    char line[64];

    printf("Relay check: %d stations on file. Enter the passphrase: ", COUNT);
    if (!fgets(line, sizeof line, stdin)) return 1;
    line[strcspn(line, "\r\n")] = 0;

    if (check_phrase(line)) {
        puts("Relay open. All stations report.");
        return 0;
    }
    puts("Wrong passphrase.");
    return 1;
}

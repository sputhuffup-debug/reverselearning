/* SPOILERS: the Day 4 structures as recovered, with Windows x64 offsets.
 *
 * Compare these with the structures you built in Ghidra. Field names are yours to choose;
 * the offsets, sizes and types are what matter. The offsets are the same on Linux x86-64,
 * because none of these fields is a long.
 *
 * In Ghidra's C parser (File > Parse C Source) this file also works as input, if you want
 * to check your archive against it.
 */

/* ex1 (catalog[], 8 entries) and ex3 (stockroom[], 7 entries): one part record. */
#define FLAG_TRACKED  0x01
#define FLAG_FRAGILE  0x02
#define FLAG_RESERVED 0x04

struct item {
    int   id;               /* 0x00 */
    short stock;            /* 0x04 */
    char  name[10];         /* 0x06 .. 0x0f */
    unsigned char flags;    /* 0x10  FLAG_* bits */
                            /* 0x11  1 byte of padding: reorder must start on an even address */
    short reorder;          /* 0x12 */
    int   price;            /* 0x14  in cents */
    struct item *alt;       /* 0x18  substitute part, or NULL */
    short bin;              /* 0x20  a letter, 'A' to 'K' */
                            /* 0x22  6 bytes of tail padding, so the next array entry is 8-aligned */
};                          /* sizeof = 0x28 (40): the array stride you see in find_item */

/* ex3: the shelf is an array of 6 pointers into stockroom[] (struct item *shelf[6]),
 * in the order stockroom[3], [0], [5], [2], [1], [4]. worst_shortfall takes it as
 * struct item ** and returns its result through a second struct item ** (an out parameter).
 */

/* ex2: one node of the pick list, allocated with calloc and kept sorted by key. */
struct node {
    unsigned short key;     /* 0x00 */
    char  letter;           /* 0x02  arrivals[i].enc ^ (key & 0x1f) */
                            /* 0x03  1 byte of padding */
    int   weight;           /* 0x04  key % 97 */
    struct node *next;      /* 0x08 */
    char  tag[5];           /* 0x10  "BOX" */
                            /* 0x15  3 bytes of tail padding */
};                          /* sizeof = 0x18 (24): the size passed to calloc */

/* ex2: the static table the list is built from (4 bytes per entry, 13 entries). */
struct arrival {
    unsigned short key;     /* 0x00 */
    unsigned char  enc;     /* 0x02 */
                            /* 0x03  1 byte of padding */
};

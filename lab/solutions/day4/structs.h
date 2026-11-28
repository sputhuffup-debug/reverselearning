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

/* ex4: the badge, unpacked from the access code by decode() into a local of main. */
enum level { LEVEL_VISITOR, LEVEL_STAFF, LEVEL_SUPERVISOR, LEVEL_MANAGER, LEVEL_AUDITOR };

#define PERM_DOCK    0x01
#define PERM_COLD    0x02
#define PERM_HAZMAT  0x04
#define PERM_NIGHT   0x08
#define PERM_VAULT   0x10
#define PERM_TEMP    0x80

struct badge {
    unsigned short site;    /* 0x00  code bits 16-31; must be 0x5744 ("WD") */
    unsigned char  perms;   /* 0x02  code bits 0-7, PERM_* bits */
    unsigned char  zone;    /* 0x03  code bits 12-15 */
    enum level     level;   /* 0x04  code bits 8-11; a 4-byte enum */
    char           role[12];/* 0x08  written by the switch on level */
};                          /* sizeof = 0x14 (20): the size main passes to memset */

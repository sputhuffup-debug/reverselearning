#include <stdio.h>
#include <string.h>

/* Same part record as ex1_inventory.c; only the data is different. */
#define FLAG_TRACKED  0x01
#define FLAG_FRAGILE  0x02
#define FLAG_RESERVED 0x04

struct item {
    int   id;
    short stock;
    char  name[10];
    unsigned char flags;
    short reorder;
    int   price;          /* in cents */
    struct item *alt;     /* a substitute part, or NULL */
    short bin;
};

static struct item stockroom[] = {
    { 7001,  4, "pump",    FLAG_TRACKED,                10, 4500, NULL,          'G' },
    { 7002,  2, "valve",   FLAG_TRACKED,                15,  820, &stockroom[4], 'G' },
    { 7003,  1, "filter",  0,                           20,  310, NULL,          'H' },
    { 7004, 30, "hose",    FLAG_TRACKED,                12,  640, NULL,          'H' },
    { 7005,  5, "clamp",   FLAG_TRACKED | FLAG_FRAGILE, 16,   95, NULL,          'J' },
    { 7006,  0, "seal",    FLAG_TRACKED,                 9,   60, &stockroom[6], 'J' },
    { 7007,  0, "o-ring",  FLAG_TRACKED,                40,   12, NULL,          'K' },
};

/* The shelf scan only covers the parts on this list, in this order. */
static struct item *shelf[] = {
    &stockroom[3], &stockroom[0], &stockroom[5], &stockroom[2], &stockroom[1], &stockroom[4],
};

static int read_int(const char *prompt, int *out) {
    char line[32];
    printf("%s", prompt);
    if (!fgets(line, sizeof line, stdin)) return 0;
    return sscanf(line, "%d", out) == 1;
}

/* Finds the tracked part on the shelf that is furthest below its reorder level. */
static int worst_shortfall(struct item **list, int n, struct item **out) {
    int best = 0;
    *out = NULL;
    for (int i = 0; i < n; i++) {
        struct item *it = list[i];
        int gap = it->reorder - it->stock;
        if ((it->flags & FLAG_TRACKED) && gap > best) {
            best = gap;
            *out = it;
        }
    }
    return best;
}

int main(void) {
    struct item *low;
    int id, qty;
    int gap = worst_shortfall(shelf, sizeof shelf / sizeof shelf[0], &low);

    printf("Shelf scan: %d parts checked.\n", (int)(sizeof shelf / sizeof shelf[0]));
    if (!read_int("Part number: ", &id)) return 1;
    if (!read_int("Quantity: ", &qty)) return 1;

    if (low && id == low->id && qty == gap) {
        printf("Restock approved: %d x %s for bin %c.\n", qty, low->name, low->bin);
        return 0;
    }
    puts("Restock rejected.");
    return 1;
}

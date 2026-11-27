#include <stdio.h>
#include <string.h>

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

static struct item catalog[] = {
    { 1001, 40, "bolt-m4",  FLAG_TRACKED,                 20,   15, &catalog[1], 'A' },
    { 1002, 25, "bolt-m5",  FLAG_TRACKED,                 20,   18, NULL,        'A' },
    { 2310,  7, "hinge",    FLAG_FRAGILE,                  5,  240, NULL,        'C' },
    { 3075, 12, "gasket",   FLAG_TRACKED | FLAG_FRAGILE,  10,  130, &catalog[6], 'B' },
    { 4417, 12, "keystone", FLAG_RESERVED | FLAG_FRAGILE,  3, 9900, NULL,        'F' },
    { 5120, 60, "washer",   FLAG_TRACKED,                 30,    4, NULL,        'A' },
    { 3076,  9, "gasket-x", FLAG_TRACKED,                 10,  155, NULL,        'B' },
    { 6001,  3, "spring",   0,                             2,   75, NULL,        'D' },
};

static int read_int(const char *prompt, int *out) {
    char line[32];
    printf("%s", prompt);
    if (!fgets(line, sizeof line, stdin)) return 0;
    return sscanf(line, "%d", out) == 1;
}

static struct item *find_item(struct item *list, int n, int id) {
    for (int i = 0; i < n; i++)
        if (list[i].id == id) return &list[i];
    return NULL;
}

int main(void) {
    int id, qty;
    struct item *it;

    if (!read_int("Part number: ", &id)) return 1;
    if (!read_int("Quantity: ", &qty)) return 1;

    it = find_item(catalog, sizeof catalog / sizeof catalog[0], id);
    if (!it) { puts("Unknown part."); return 1; }

    if (qty > it->stock && it->alt)
        printf("Only %d in stock; try part %d.\n", it->stock, it->alt->id);

    if ((it->flags & FLAG_RESERVED) && qty == it->stock) {
        printf("Order accepted: %s from bin %c.\n", it->name, it->bin);
        return 0;
    }
    puts("Order refused.");
    return 1;
}

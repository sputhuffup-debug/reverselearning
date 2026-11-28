/* SPOILERS: the Day 4 checkpoint. Solve checkpoint.exe without reading this file.
 * The answer and the recovered layout are in checkpoint.md. */
#include <stdio.h>

enum route { ROUTE_NORTH, ROUTE_SOUTH, ROUTE_EAST, ROUTE_WEST };

#define CRATE_URGENT   0x01
#define CRATE_FRAGILE  0x02
#define CRATE_HELD     0x04
#define CRATE_COLD     0x08
#define CRATE_CLEARED  0x40          /* inspected by hand: a hold no longer applies */

struct crate {
    unsigned short id;
    unsigned char  flags;
    char           bay;
    enum route     route;
    int            weight;           /* kg */
    struct crate  *next;             /* the truck's load list, built at runtime */
    char           label[8];
};

static struct crate yard[] = {
    { 1201, CRATE_URGENT,                                'A', ROUTE_EAST,  12, NULL, "tools"  },
    { 1202, CRATE_URGENT | CRATE_FRAGILE,                'B', ROUTE_EAST,  35, NULL, "glass"  },
    { 1203, CRATE_URGENT,                                'A', ROUTE_NORTH, 20, NULL, "paint"  },
    { 1204, CRATE_URGENT | CRATE_FRAGILE | CRATE_CLEARED,'C', ROUTE_EAST,  41, NULL, "mirror" },
    { 1205, CRATE_HELD,                                  'B', ROUTE_EAST,   8, NULL, "bolts"  },
    { 1206, CRATE_URGENT | CRATE_HELD,                   'D', ROUTE_EAST,  16, NULL, "cable"  },
    { 1207, CRATE_URGENT | CRATE_COLD,                   'C', ROUTE_EAST,  22, NULL, "fish"   },
    { 1208, 0,                                           'A', ROUTE_EAST,   5, NULL, "rope"   },
    { 1209, CRATE_URGENT | CRATE_HELD | CRATE_CLEARED,   'D', ROUTE_EAST,  27, NULL, "pumps"  },
    { 1210, CRATE_URGENT | CRATE_FRAGILE,                'B', ROUTE_WEST,  18, NULL, "lamps"  },
    { 1211, CRATE_URGENT | CRATE_FRAGILE,                'A', ROUTE_EAST,  30, NULL, "vases"  },
};

static int read_int(const char *prompt, int *out) {
    char line[32];
    printf("%s", prompt);
    if (!fgets(line, sizeof line, stdin)) return 0;
    return sscanf(line, "%d", out) == 1;
}

/* Heavy fragile crates are held; a crate cleared by hand loses its hold. */
static void inspect(struct crate *c, int n) {
    for (int i = 0; i < n; i++) {
        if ((c[i].flags & CRATE_FRAGILE) && c[i].weight > 30)
            c[i].flags |= CRATE_HELD;
        if (c[i].flags & CRATE_CLEARED)
            c[i].flags &= ~CRATE_HELD;
    }
}

/* Urgent crates that aren't held go on the truck for this route. Each one goes in at the front. */
static struct crate *load_truck(struct crate *c, int n, enum route r) {
    struct crate *head = NULL;
    for (int i = 0; i < n; i++) {
        if ((c[i].flags & (CRATE_URGENT | CRATE_HELD)) == CRATE_URGENT && c[i].route == r) {
            c[i].next = head;
            head = &c[i];
        }
    }
    return head;
}

int main(void) {
    int n = sizeof yard / sizeof yard[0];
    int count = 0, total = 0, lead, weight;
    struct crate *head;

    inspect(yard, n);
    head = load_truck(yard, n, ROUTE_EAST);
    for (struct crate *c = head; c; c = c->next) { count++; total += c->weight; }
    printf("Truck east: %d crates loaded.\n", count);

    if (!read_int("Lead crate: ", &lead)) return 1;
    if (!read_int("Load weight: ", &weight)) return 1;

    if (head && lead == head->id && weight == total) {
        printf("Truck sealed: %s first.\n", head->label);
        return 0;
    }
    puts("Seal rejected.");
    return 1;
}

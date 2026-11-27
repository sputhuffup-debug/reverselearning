#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct node {
    unsigned short key;
    char  letter;
    int   weight;
    struct node *next;
    char  tag[5];
};

/* Boxes arrive out of order; each letter is stored XORed with the low 5 bits of its key. */
static const struct { unsigned short key; unsigned char enc; } arrivals[] = {
    { 410, 0x29 }, { 590, 0x3f }, { 258, 0x2f }, { 396, 0x44 }, { 662, 0x45 },
    { 168, 0x3c }, { 192, 0x4c }, { 341, 0x41 }, { 511, 0x53 }, { 505, 0x34 },
    { 205, 0x46 }, { 120, 0x4f }, { 838, 0x52 },
};

/* Keep the list sorted by key. pp points at the link that will point at the new node. */
static void insert(struct node **head, struct node *n) {
    struct node **pp = head;
    while (*pp && (*pp)->key < n->key)
        pp = &(*pp)->next;
    n->next = *pp;
    *pp = n;
}

static int matches(const struct node *n, const char *s) {
    for (; n; n = n->next, s++)
        if (*s != n->letter) return 0;
    return *s == 0;
}

int main(void) {
    struct node *head = NULL;
    char input[64];
    int count = 0, total = 0;

    for (size_t i = 0; i < sizeof arrivals / sizeof arrivals[0]; i++) {
        struct node *n = calloc(1, sizeof *n);
        if (!n) return 3;
        n->key = arrivals[i].key;
        n->letter = (char)(arrivals[i].enc ^ (arrivals[i].key & 0x1f));
        n->weight = arrivals[i].key % 97;
        memcpy(n->tag, "BOX", 4);
        insert(&head, n);
    }
    for (struct node *n = head; n; n = n->next) { count++; total += n->weight; }
    printf("Packing %d boxes, total weight %d.\n", count, total);

    printf("Pick code: ");
    if (!fgets(input, sizeof input, stdin)) return 1;
    input[strcspn(input, "\r\n")] = 0;

    if (matches(head, input)) { puts("Pick list confirmed."); return 0; }
    puts("Wrong pick code.");
    return 1;
}

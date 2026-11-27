#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* noipa keeps a function a separate, real call even at -O2. */
#define KEEP __attribute__((noipa))

/* Small enough that -O2 inlines it. */
static unsigned rotl(unsigned x, int n) {
    return (x << n) | (x >> (32 - n));
}

/* Six arguments: four travel in registers, the last two on the stack. */
KEEP static unsigned zone_key(unsigned zone, unsigned floor, unsigned door,
                              unsigned shift, unsigned salt, unsigned pepper) {
    unsigned k = zone * 1000003u + floor * 7919u + door;
    k = rotl(k, shift) ^ salt;
    return (k + pepper) % 100000000u;
}

KEEP static int check_door(unsigned code, unsigned key) {
    return code == key;
}

KEEP static int check_zone(unsigned code, unsigned zone) {
    unsigned key = zone_key(zone, 4, 12, 5, 0xC0DE, 0x2026);
    return check_door(code, key);
}

KEEP static int check_access(unsigned code) {
    return check_zone(code, 7);
}

int main(void) {
    char line[64];
    char *end;
    unsigned long code;
    printf("Access code: ");
    if (!fgets(line, sizeof line, stdin)) return 1;
    line[strcspn(line, "\r\n")] = 0;
    code = strtoul(line, &end, 10);
    if (end != line && *end == 0 && check_access((unsigned)code)) {
        puts("Door open.");
        return 0;
    }
    puts("Access refused.");
    return 1;
}

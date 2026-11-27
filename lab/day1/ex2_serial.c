#include <stdio.h>
#include <string.h>

static unsigned int make_serial(const char *name) {
    unsigned int h = 0x1337;
    for (size_t i = 0; name[i]; i++)
        h = h * 31 + (unsigned char)name[i];
    return h ^ 0xC0FFEE;
}

int main(void) {
    char name[64];
    unsigned int serial;
    printf("Name: ");
    if (!fgets(name, sizeof name, stdin)) return 1;
    name[strcspn(name, "\r\n")] = 0;
    if (strlen(name) < 4) { puts("Name must be at least 4 characters."); return 1; }
    printf("Serial (hex): ");
    if (scanf("%x", &serial) != 1) return 1;
    if (serial == make_serial(name)) { puts("Valid serial. Thanks for registering!"); return 0; }
    puts("Invalid serial.");
    return 1;
}

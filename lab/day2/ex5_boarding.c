#include <stdio.h>
#include <string.h>

/* noipa keeps a function a separate, real call even at -O2. */
#define KEEP __attribute__((noipa))

static void put4(char *p, char a, char b, char c, char d) {
    p[0] = a; p[1] = b; p[2] = c; p[3] = d;
}

/* The pass is written into the caller's buffer; it is never stored as one string. */
static void build_pass(char *out) {
    put4(out, 'F', 'R', '4', 'M');
    put4(out + 4, 'E', '-', 'W', '4');
    put4(out + 8, 'L', 'K', '3', 'R');
    out[12] = 0;
}

KEEP static int same(const char *a, const char *b) {
    return strcmp(a, b) == 0;
}

KEEP static int check_pass(const char *input) {
    char expected[16];
    build_pass(expected);
    return same(input, expected);
}

int main(void) {
    char input[64];
    printf("Boarding pass: ");
    if (!fgets(input, sizeof input, stdin)) return 1;
    input[strcspn(input, "\r\n")] = 0;
    if (check_pass(input)) {
        puts("Boarding pass accepted. Have a good flight!");
        return 0;
    }
    puts("Boarding pass rejected.");
    return 1;
}

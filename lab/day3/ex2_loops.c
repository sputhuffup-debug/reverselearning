#include <stdio.h>
#include <string.h>

static int check(const char *code) {
    char expect[9];
    unsigned int x = 0x2A;
    int i, j;

    for (i = 0; i < 8; i++) {
        x = (x * 37 + 11) % 101;
        expect[i] = (char)('0' + x % 10);
    }
    expect[8] = 0;

    i = 0;
    j = 7;
    do {
        char t = expect[i];
        expect[i] = expect[j];
        expect[j] = t;
        i++;
        j--;
    } while (i < j);

    i = 0;
    while (i < 8 && code[i] == expect[i])
        i++;
    return i == 8;
}

int main(void) {
    char code[32];
    printf("Door code (8 digits): ");
    if (!fgets(code, sizeof code, stdin)) return 1;
    code[strcspn(code, "\r\n")] = 0;
    if (strlen(code) != 8) { puts("The code has 8 digits."); return 1; }
    if (check(code)) { puts("Door unlocked."); return 0; }
    puts("Wrong code.");
    return 1;
}

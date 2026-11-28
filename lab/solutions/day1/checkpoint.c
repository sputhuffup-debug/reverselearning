/* SPOILER: Day 1 checkpoint. Solve bin/day1/checkpoint.exe before you read this.
 * Two checks: the code must be 10 characters, then each character plus its index
 * must match a stored table. The answer is in checkpoint.md. */
#include <stdio.h>
#include <string.h>

static const unsigned char expected[10] = {
    0x42, 0x73, 0x35, 0x37, 0x6F, 0x75, 0x36, 0x38, 0x76, 0x7D
};

static int check_code(const char *s) {
    for (int i = 0; i < 10; i++) {
        if ((unsigned char)(s[i] + i) != expected[i])
            return 0;
    }
    return 1;
}

int main(void) {
    char input[64];
    printf("Unlock code: ");
    if (!fgets(input, sizeof input, stdin)) return 1;
    input[strcspn(input, "\r\n")] = 0;
    if (strlen(input) != 10) {
        puts("Wrong length.");
        return 1;
    }
    if (!check_code(input)) {
        puts("Wrong code.");
        return 1;
    }
    puts("Unlocked. Checkpoint passed.");
    return 0;
}

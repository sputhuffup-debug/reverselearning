#include <stdio.h>
#include <string.h>
#include <windows.h>

static const unsigned char secret[] = {
    0x10, 0x71, 0x34, 0x71, 0x30, 0x31, 0x73, 0x2C, 0x25, 0x1D, 0x06, 0x76, 0x3B, 0x73
};

static void decode(char *out, size_t n) {
    for (size_t i = 0; i < n; i++) out[i] = (char)(secret[i] ^ 0x42);
    out[n] = 0;
}

int main(void) {
    char input[64];
    char key[sizeof secret + 1];

    if (IsDebuggerPresent()) {
        puts("Debugger detected. Bye.");
        return 2;
    }
    printf("License key: ");
    if (!fgets(input, sizeof input, stdin)) return 1;
    input[strcspn(input, "\r\n")] = 0;

    decode(key, sizeof secret);
    if (strcmp(input, key) == 0) puts("License OK. Welcome!");
    else puts("Bad license key.");
    return 0;
}

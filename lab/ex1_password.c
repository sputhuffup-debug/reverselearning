#include <stdio.h>
#include <string.h>

int main(void) {
    char input[64];
    printf("Enter password: ");
    if (!fgets(input, sizeof input, stdin)) return 1;
    input[strcspn(input, "\r\n")] = 0;
    if (strcmp(input, "hunter2-ghidra") == 0) {
        puts("Access granted!");
        return 0;
    }
    puts("Access denied.");
    return 1;
}

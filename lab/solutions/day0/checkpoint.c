#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* SPOILER: Day 0 checkpoint. Students triage the built .exe without this source. */
int main(void) {
    char line[64];
    char *end;
    long code;

    printf("Unlock code: ");
    if (!fgets(line, sizeof line, stdin)) return 2;
    line[strcspn(line, "\r\n")] = 0;

    /* A decoy: it looks like a password in a strings search, but it is not the answer. */
    if (strcmp(line, "debug-override") == 0) {
        puts("Maintenance mode is disabled in this build.");
        return 3;
    }

    code = strtol(line, &end, 10);
    if (end == line || *end != 0) {
        puts("Not a number.");
        return 2;
    }
    if (code == 10847) {
        puts("Unlocked. Checkpoint passed.");
        return 0;
    }
    puts("Wrong code.");
    return 1;
}

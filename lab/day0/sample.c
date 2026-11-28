#include <stdio.h>
#include <string.h>

/* Day 0 worked example: reads one "key=value" line and checks it.
   The source is visible on purpose; the guide triages the built .exe step by step. */
int main(void) {
    char line[64];
    char *eq;

    printf("Config line: ");
    if (!fgets(line, sizeof line, stdin)) return 2;
    line[strcspn(line, "\r\n")] = 0;

    eq = strchr(line, '=');
    if (!eq) {
        puts("Bad format: expected key=value.");
        return 2;
    }
    *eq = 0;                                   /* split: line is the key, eq + 1 the value */

    if (strcmp(line, "channel") != 0) {
        puts("Unknown key.");
        return 1;
    }
    if (strcmp(eq + 1, "stable") == 0) {
        puts("Config OK: channel is stable.");
        return 0;
    }
    puts("Config rejected.");
    return 1;
}

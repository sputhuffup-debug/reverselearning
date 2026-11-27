#include <ctype.h>
#include <stdio.h>
#include <string.h>

static const char *words[] = {
    "amber", "copper", "falcon", "harbor", "lantern", "meadow", "orbit", "tundra"
};
static int order[] = { 5, 2, 7, 0 };
static int tries = 3;
static char phrase[64];

static void lower_in_place(char *s) {
    for (; *s; s++) *s = (char)tolower((unsigned char)*s);
}

static int match_word(const char *token, int pos) {
    return strcmp(token, words[order[pos]]) == 0;
}

static int check_phrase(void) {
    int pos = 0;
    char *token = strtok(phrase, "-");
    while (token) {
        if (pos >= 4 || !match_word(token, pos)) return 0;
        pos++;
        token = strtok(NULL, "-");
    }
    return pos == 4;
}

int main(void) {
    while (tries > 0) {
        printf("Passphrase (%d tries left): ", tries);
        if (!fgets(phrase, sizeof phrase, stdin)) break;
        phrase[strcspn(phrase, "\r\n")] = 0;
        lower_in_place(phrase);
        if (check_phrase()) { puts("Passphrase accepted."); return 0; }
        puts("Wrong passphrase.");
        tries--;
    }
    puts("Locked out.");
    return 1;
}

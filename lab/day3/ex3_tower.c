#include <stdio.h>

static unsigned long long weave(int n) {
    if (n < 2) return (unsigned long long)n + 2;
    return weave(n - 1) + weave(n - 2) + (unsigned long long)n;
}

int main(void) {
    int level;
    printf("Tower level (1-30): ");
    if (scanf("%d", &level) != 1) return 1;
    if (level < 1 || level > 30) { puts("Level out of range."); return 1; }
    if (weave(level) == 0xA4B5ULL) { puts("You reached the top of the tower."); return 0; }
    puts("Not this level.");
    return 1;
}

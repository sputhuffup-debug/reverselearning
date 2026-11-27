#include <stdio.h>

static int stage;

int main(void) {
    char line[32];
    int opt;

    puts("Vault console. Options 1-9, 0 to quit.");
    for (;;) {
        printf("> ");
        if (!fgets(line, sizeof line, stdin)) break;
        if (sscanf(line, "%d", &opt) != 1) opt = -1;
        switch (opt) {
        case 0:
            puts("The vault stays shut.");
            return 1;
        case 1:
            puts("You spin the dial left.");
            stage = (stage == 1) ? 2 : 0;
            break;
        case 2:
            puts("You spin the dial right.");
            stage = 0;
            break;
        case 3:
            puts("You press the brass button.");
            stage = (stage == 3) ? 4 : 0;
            break;
        case 4:
            puts("You pull the lever.");
            stage = (stage == 0) ? 1 : 0;
            break;
        case 5:
            puts("You turn the key.");
            stage = 0;
            break;
        case 6:
            puts("You knock twice.");
            stage = (stage == 2) ? 3 : 0;
            break;
        case 7:
            if (stage == 4) {
                puts("The vault opens. Code accepted.");
                return 0;
            }
            puts("The handle won't move.");
            stage = 0;
            break;
        case 8:
            puts("The plaque reads: order matters.");
            break;
        case 9:
            puts("Everything clicks back to the start.");
            stage = 0;
            break;
        default:
            puts("Unknown option.");
            break;
        }
    }
    puts("The vault stays shut.");
    return 1;
}

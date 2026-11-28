/* SPOILER: Day 3 checkpoint. Solve checkpoint.exe without reading this file; the answer is in checkpoint.md. */
#include <stdio.h>
#include <string.h>
#include <wchar.h>

static const wchar_t *const maze[] = {
    L"S..#..",
    L"##.#.#",
    L"#..#..",
    L"#.##.#",
    L"#...#.",
    L"###.#X",
};

static int open_cell(int row, int col) {
    if (row < 0 || row > 5 || col < 0 || col > 5) return 0;
    return maze[row][col] != L'#';
}

int main(int argc, char **argv) {
    int row = 0, col = 0;
    const char *p;

    if (argc != 2) {
        puts("Usage: checkpoint <moves>");
        return 2;
    }
    if (strlen(argv[1]) > 12) {
        puts("Too many moves.");
        return 1;
    }
    for (p = argv[1]; *p; p++) {
        int dr = 0, dc = 0;
        switch (*p) {
        case '1': dr = 1;  dc = -1; break;
        case '2': dr = 1;           break;
        case '3': dr = 1;  dc = 1;  break;
        case '4':          dc = -1; break;
        case '6':          dc = 1;  break;
        case '7': dr = -1; dc = -1; break;
        case '8': dr = -1;          break;
        case '9': dr = -1; dc = 1;  break;
        default:
            puts("Unknown move.");
            return 1;
        }
        if (!open_cell(row + dr, col + dc)) {
            puts("You walk into a wall.");
            return 1;
        }
        row += dr;
        col += dc;
    }
    if (maze[row][col] == L'X') {
        puts("You found the way out.");
        return 0;
    }
    puts("Still lost in the maze.");
    return 1;
}

/* Built with -municode (see the Makefile), so the program starts at wmain and argv holds wide strings. */
#include <stdio.h>
#include <wchar.h>
#include <windows.h>

static const wchar_t *const staff[] = { L"alonzo", L"grace", L"linus", L"barbara", L"edsger" };
static const int clearance[] = { 1, 3, 2, 3, 2 };

static int find_staff(const wchar_t *name) {
    for (int i = 0; i < 5; i++)
        if (wcscmp(name, staff[i]) == 0)
            return i;
    return -1;
}

static void make_code(const wchar_t *name, wchar_t *code) {
    size_t n = wcslen(name);
    for (size_t i = 0; i < n; i++)
        code[i] = (wchar_t)(L'A' + (name[i] - L'a' + 3) % 26);
    code[n] = 0;
}

int wmain(int argc, wchar_t **argv) {
    wchar_t code[16];
    int who;

    OutputDebugStringW(L"Badge reader started.");
    if (argc != 3) {
        puts("Usage: ex5 <name> <code>");
        return 2;
    }
    who = find_staff(argv[1]);
    if (who < 0) {
        puts("Unknown name.");
        return 1;
    }
    if (clearance[who] < 3) {
        puts("Clearance too low.");
        return 1;
    }
    make_code(staff[who], code);
    if (wcscmp(argv[2], code) != 0) {
        puts("Wrong code.");
        return 1;
    }
    puts("Badge accepted. The lab door opens.");
    return 0;
}

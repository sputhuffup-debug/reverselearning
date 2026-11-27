# Builds the practice programs from this folder into $(OUT) (default: bin/).
# The .c files stay where they are; only the .exe files land in $(OUT).
#
# From the w64devkit shell (Devkit.cmd opens it in this folder):
#   make                                   # -> bin/ex1.exe, bin/ex2.exe, bin/ex3.exe
#   make OUT=D:/RE-Portable/lab            # put them somewhere else
#   make clean
# From anywhere else: make -C path/to/repo/lab
#
# OUT must not contain spaces (a make limitation); use forward slashes.

CC      = gcc
# -O0 keeps the code close to the source; -s strips symbol names so you recover them yourself.
CFLAGS ?= -O0 -s -Wall
OUT    ?= bin

EXES := $(OUT)/ex1.exe $(OUT)/ex2.exe $(OUT)/ex3.exe

all: $(EXES)

$(OUT)/ex1.exe: ex1_password.c | $(OUT)
	$(CC) $(CFLAGS) $< -o $@

$(OUT)/ex2.exe: ex2_serial.c | $(OUT)
	$(CC) $(CFLAGS) $< -o $@

$(OUT)/ex3.exe: ex3_crackme.c | $(OUT)
	$(CC) $(CFLAGS) $< -o $@

$(OUT):
	mkdir -p $@

clean:
	rm -f $(EXES)

.PHONY: all clean

# Builds the practice programs from this folder into $(OUT) (default: bin/).
# The .c files stay where they are; only the .exe files land in $(OUT).
#
# From the w64devkit shell (Devkit.cmd):
#   make -C path/to/repo/lab                     # -> lab/bin/ex1_password.exe, ...
#   make -C path/to/repo/lab OUT=D:/RE-Portable/lab
#   make -C path/to/repo/lab clean
#
# OUT must not contain spaces (a make limitation); use forward slashes.

CC      = gcc
# -O0 keeps the code close to the source; -s strips symbol names so you recover them yourself.
CFLAGS ?= -O0 -s -Wall
OUT    ?= bin

SRCS := $(wildcard *.c)
EXES := $(SRCS:%.c=$(OUT)/%.exe)

all: $(EXES)

$(OUT)/%.exe: %.c | $(OUT)
	$(CC) $(CFLAGS) $< -o $@

$(OUT):
	mkdir -p $@

clean:
	rm -f $(EXES)

.PHONY: all clean

# Shared build rules for each day's Makefile (lab/dayN/Makefile).
#
# A day's Makefile sets DAY and PROGS, then includes this file:
#   DAY   = day1
#   PROGS = ex1:ex1_password.c ex2:ex2_serial.c      # <exe name>:<source>
#   include ../common.mk
#
# Optional per-program flags: CFLAGS_<exe name> = -O2   (added after CFLAGS)
# Keep symbol names in one program (no -s):  NOSTRIP_<exe name> = 1
# Sources ending in .cpp are built with g++.

CC       = gcc
CXX      = g++
# -O0 keeps the code close to the source; -s strips symbol names so you recover them yourself.
CFLAGS  ?= -O0 -s -Wall
OUT     ?= ../bin/$(DAY)

exe_name = $(word 1,$(subst :, ,$(1)))
exe_src  = $(word 2,$(subst :, ,$(1)))
EXES    := $(foreach p,$(PROGS),$(OUT)/$(call exe_name,$(p)).exe)

all: $(EXES)

define prog_rule
$(OUT)/$(call exe_name,$(1)).exe: $(call exe_src,$(1)) | $(OUT)
	$$(if $$(filter %.cpp,$$<),$$(CXX),$$(CC)) $$(if $$(NOSTRIP_$(call exe_name,$(1))),$$(filter-out -s,$$(CFLAGS)),$$(CFLAGS)) $$(CFLAGS_$(call exe_name,$(1))) $$< -o $$@
endef
$(foreach p,$(PROGS),$(eval $(call prog_rule,$(p))))

$(OUT):
	mkdir -p $@

clean:
	rm -f $(EXES)

.PHONY: all clean

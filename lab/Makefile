# Builds every day's practice programs into $(OUT)/<day>/ (default: bin/day1/ex1.exe, ...).
# The sources stay where they are.
#
# From the w64devkit shell (Devkit.cmd opens it in this folder):
#   make                          # every day
#   make day1                     # one day
#   make OUT=D:/RE-Portable/lab   # somewhere else (-> D:/RE-Portable/lab/day1/...)
#   make clean
#
# OUT must not contain spaces (a make limitation); use forward slashes.

OUT  ?= bin
DAYS := $(sort $(patsubst %/Makefile,%,$(wildcard day*/Makefile)))

# Each day runs in its own folder, so a relative OUT gets a "../" in front.
day_out = $(if $(findstring :,$(OUT))$(filter /%,$(OUT)),$(OUT),../$(OUT))/$(1)

all: $(DAYS)

$(DAYS):
	$(MAKE) -C $@ OUT=$(call day_out,$@)

clean:
	$(foreach d,$(DAYS),$(MAKE) -C $(d) clean OUT=$(call day_out,$(d)) &&) true

.PHONY: all clean $(DAYS)

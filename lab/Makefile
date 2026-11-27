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

# Recipes quote $(MAKE) with forward slashes: when make was started by its full Windows path,
# the shell would read the backslashes as escapes. ($(MAKE) must stay in the recipe line itself
# so make treats it as a recursive call.)

all: $(DAYS)

$(DAYS):
	"$(subst \,/,$(MAKE))" -C $@ OUT=$(call day_out,$@)

clean:
	$(foreach d,$(DAYS),"$(subst \,/,$(MAKE))" -C $(d) clean OUT=$(call day_out,$(d)) &&) true

.PHONY: all clean $(DAYS)

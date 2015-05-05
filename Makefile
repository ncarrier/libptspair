export CC       ?= gcc
export CFLAGS   ?= -O0 -g -Wall -Wextra
CFLAGS += -fpic
export CPPFLAGS ?= \
	-I.
export LDFLAGS  ?=

bin := pts_pair

libpts_pair_src := \
	example/main.c

libpts_pair_objects := $(libpts_pair_src:.c=.o)

libpts_pair_clean_files := \
	$(bin) \
	$(libpts_pair_objects)

all: $(bin)

$(bin): $(libpts_pair_objects)
	$(CC) $^ -o $@ $(CFLAGS) $(CPPFLAGS) $(LDFLAGS)

clean:
	$(Q) -rm -f $(libpts_pair_clean_files) &>/dev/null

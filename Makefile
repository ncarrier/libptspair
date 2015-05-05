VPATH := $(BASE_SRC_DIR)
export CC       ?= gcc
export CFLAGS   ?= -O0 -g -Wall -Wextra
CFLAGS += -fpic
export CPPFLAGS ?= \
	-I$(BASE_SRC_DIR)/include/
export LDFLAGS  ?=

bin := pts_pair
lib := libpts_pair.so

libpts_pair_src := \
	src/ptspair.c

libpts_pair_objects := $(libpts_pair_src:.c=.o)

libpts_pair_clean_files := \
	$(libpts_pair_objects) \
	$(lib) \
	main.o \
	$(bin)

all: $(bin)

$(bin): example/main.c $(lib)
	$(CC) $^ -o $@ $(CFLAGS) $(CPPFLAGS) $(LDFLAGS)

$(lib): $(libpts_pair_objects)
	$(CC) -shared $^ -o $@ $(LDFLAGS)

clean:
	$(Q) -rm -f $(libpts_pair_clean_files) &>/dev/null

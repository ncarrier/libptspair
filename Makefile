VPATH := $(BASE_SRC_DIR)
export CC       ?= gcc
export CFLAGS   ?= -O0 -g -Wall -Wextra
CFLAGS += -fpic
export CPPFLAGS ?= \
	-I$(BASE_SRC_DIR)/include/
export LDFLAGS  ?=

bin := ptspair
lib := libptspair.so

libptspair_src := \
	src/ptspair.c

libptspair_objects := $(libptspair_src:.c=.o)

libptspair_clean_files := \
	$(libptspair_objects) \
	$(lib) \
	main.o \
	$(bin)

all: $(bin)

$(bin): example/main.c $(lib)
	$(CC) $^ -o $@ $(CFLAGS) $(CPPFLAGS) $(LDFLAGS)

$(lib): $(libptspair_objects)
	$(CC) -shared $^ -o $@ $(LDFLAGS)

clean:
	$(Q) -rm -f $(libptspair_clean_files) &>/dev/null

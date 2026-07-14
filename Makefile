# commit-roast — cross-platform Makefile
#
# macOS : clang + native Foundation
# Linux : clang + GNUstep (gnustep-base)
#
# Memory management: manual reference counting (MRC) on BOTH platforms.
# ARC requires the libobjc2 runtime, which is not packaged on Ubuntu/Debian —
# their gnustep-base is built against the older GCC runtime. Compiling with ARC
# on macOS and MRC on Linux is not viable (ARC forbids explicit retain/release),
# so the project targets MRC everywhere.
#
# Linux packages: clang make gnustep-make libgnustep-base-dev libblocksruntime-dev

UNAME_S := $(shell uname -s)

BIN       := commit-roast
BUILD_DIR := build
SRC_DIR   := Sources
TEST_DIR  := Tests

PREFIX ?= /usr/local

SOURCES := $(wildcard $(SRC_DIR)/*.m)
OBJECTS := $(SOURCES:$(SRC_DIR)/%.m=$(BUILD_DIR)/%.o)

# Everything but main.m, so the test binary can link the code under test
# without pulling in a second main().
LIB_SOURCES := $(filter-out $(SRC_DIR)/main.m,$(SOURCES))
LIB_OBJECTS := $(LIB_SOURCES:$(SRC_DIR)/%.m=$(BUILD_DIR)/%.o)

TEST_SOURCES := $(wildcard $(TEST_DIR)/*.m)
TEST_OBJECTS := $(TEST_SOURCES:$(TEST_DIR)/%.m=$(BUILD_DIR)/tests/%.o)
TEST_BIN     := $(BUILD_DIR)/$(BIN)-tests

CC     := clang
CFLAGS := -fno-objc-arc -Wall -Wextra -O2 -MMD -MP -I$(SRC_DIR)
LDFLAGS :=

ifeq ($(UNAME_S),Darwin)
    LDFLAGS += -framework Foundation
else
    GNUSTEP_CONFIG := $(shell command -v gnustep-config 2>/dev/null)
    ifeq ($(GNUSTEP_CONFIG),)
        $(error gnustep-config not found. Install the GNUstep toolchain: \
                sudo apt-get install clang make gnustep-make libgnustep-base-dev)
    endif

    # Debian/Ubuntu build gnustep-base against the GCC Objective-C runtime, and
    # ship its headers and its libobjc.so symlink inside GCC's private
    # directories, which clang does not search. Ask gcc where they are rather
    # than hardcoding a version and an architecture.
    GCC_OBJC_INC := $(shell gcc -print-file-name=include 2>/dev/null)
    GCC_OBJC_LIB := $(shell dirname $$(gcc -print-file-name=libobjc.so 2>/dev/null))

    CFLAGS  += -fobjc-runtime=gcc -I$(GCC_OBJC_INC) $(shell gnustep-config --objc-flags)
    LDFLAGS += -L$(GCC_OBJC_LIB) $(shell gnustep-config --base-libs)
endif

DEPS := $(OBJECTS:.o=.d) $(TEST_OBJECTS:.o=.d)

.PHONY: all build clean test install uninstall run

all: build

build: $(BUILD_DIR)/$(BIN)

$(BUILD_DIR)/$(BIN): $(OBJECTS)
ifeq ($(strip $(SOURCES)),)
	$(error No sources in $(SRC_DIR)/. Are you at the root of the repository?)
endif
	@mkdir -p $(dir $@)
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.m
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/tests/%.o: $(TEST_DIR)/%.m
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# The test suite lands in M5. Until Tests/ holds something, `make test` must
# stay green rather than fail on an empty link, so CI can call it from day one.
ifeq ($(strip $(TEST_SOURCES)),)
test:
	@echo "No tests yet (see milestone M5) — nothing to run."
else
test: $(TEST_BIN)
	./$(TEST_BIN)
endif

$(TEST_BIN): $(LIB_OBJECTS) $(TEST_OBJECTS)
	@mkdir -p $(dir $@)
	$(CC) $(LIB_OBJECTS) $(TEST_OBJECTS) $(LDFLAGS) -o $@

run: build
	./$(BUILD_DIR)/$(BIN)

install: build
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 $(BUILD_DIR)/$(BIN) $(DESTDIR)$(PREFIX)/bin/$(BIN)

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/$(BIN)

clean:
	rm -rf $(BUILD_DIR)

-include $(DEPS)


BIN_DIR := bin

CHRS := $(wildcard *.chr)
BINS := $(CHRS:%.chr=$(BIN_DIR)/%.chr)

.PHONY: all
all: $(BINS)

.PHONY: clean
clean:
	-rm -rf $(BIN_DIR)

$(BIN_DIR)/%.chr: %.chr $(BIN_DIR)
	cp $< $@

$(BIN_DIR):
	-mkdir $(BIN_DIR)

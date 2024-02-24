
BIN_DIR := bin

CHRS := $(shell find ./ -name *.chr)

.PHONY: all
all: $(BIN_DIR)
	cp $(CHRS) $(BIN_DIR)

.PHONY: clean
clean:
	-rm -rf $(BIN_DIR)

$(BIN_DIR):
	-mkdir $(BIN_DIR)

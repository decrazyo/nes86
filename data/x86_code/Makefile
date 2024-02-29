
AS := nasm

BIN_DIR := bin
SRC_DIR := src

SRCS := $(wildcard $(SRC_DIR)/*.asm)
BINS := $(SRCS:$(SRC_DIR)/%.asm=$(BIN_DIR)/%.com)

AS_FLAGS := -f bin -Wx -Werror -O0

.PHONY: all
all: $(BINS)

.PHONY: clean
clean:
	-rm -rf $(BIN_DIR)

$(BIN_DIR)/%.com: $(SRC_DIR)/%.asm $(BIN_DIR)
	$(AS) $(AS_FLAGS) -o $@ $<

$(BIN_DIR):
	-mkdir $(BIN_DIR)

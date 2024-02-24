
AS := nasm

BIN_DIR := bin
SRC_DIR := src

SRCS := $(shell find $(SRC_DIR) -name *.asm)
OBJS := $(SRCS:$(SRC_DIR)/%.asm=$(BIN_DIR)/%.com)

AS_FLAGS := -f bin

.PHONY: all
all: $(BIN_DIR) $(OBJS)

.PHONY: clean
clean:
	-rm -rf $(BIN_DIR)

$(BIN_DIR)/%.com: $(SRC_DIR)/%.asm
	$(AS) $(AS_FLAGS) -o $@ $<

$(BIN_DIR):
	-mkdir $(BIN_DIR)

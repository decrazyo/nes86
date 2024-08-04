
AS := ia16-elf-as
LD := ia16-elf-ld

BIN_DIR := bin
SRC_DIR := src

SRCS := $(wildcard $(SRC_DIR)/*.asm)
BINS := $(SRCS:$(SRC_DIR)/%.asm=$(BIN_DIR)/%.com)
AS_FLAGS :=
LD_FLAGS := -T memmap.ldscript

.PHONY: all
all: $(BINS)

.PHONY: clean
clean:
	-rm -rf $(BIN_DIR)

$(BIN_DIR)/%.com: $(BIN_DIR)/%.o $(BIN_DIR)
	$(LD) $(LD_FLAGS) -o $@ $<

$(BIN_DIR)/%.o: $(SRC_DIR)/%.asm $(BIN_DIR)
	$(AS) $(AS_FLAGS) -o $@ $<

$(BIN_DIR):
	-mkdir $(BIN_DIR)

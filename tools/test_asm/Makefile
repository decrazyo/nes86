
NAME := test_asm

AS := nasm
LD := ld

BIN_DIR := bin
BUILD_DIR := build
SRC_DIR := src

SRCS := $(wildcard $(SRC_DIR)/*.asm)
OBJS := $(SRCS:$(SRC_DIR)/%.asm=$(BUILD_DIR)/%.o)

ELF := $(BIN_DIR)/$(NAME)

AS_FLAGS := -f elf32
LD_FLAGS := -m elf_i386

.PHONY: all
all: $(ELF)

.PHONY: clean
clean:
	-rm -rf $(BUILD_DIR)
	-rm -rf $(BIN_DIR)

$(ELF): $(OBJS) $(BIN_DIR)
	$(LD) $(LD_FLAGS) -o $(ELF) $(OBJS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm $(BUILD_DIR)
	$(AS) $(AS_FLAGS) -o $@ $<

$(BUILD_DIR):
	-mkdir $(BUILD_DIR)

$(BIN_DIR):
	-mkdir $(BIN_DIR)

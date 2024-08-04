
CC := ia16-elf-gcc
AS := ia16-elf-as
LD := ia16-elf-ld
OBJDUMP := ia16-elf-objdump

BIN_DIR := bin
BUILD_DIR := build
INC_DIR := include
SRC_DIR := src

SRCS := $(wildcard $(SRC_DIR)/*.S)
# OBJS := $(SRCS:$(SRC_DIR)/%.S=$(BUILD_DIR)/%.o)
OBJS := build/_start.o build/cpu.o build/test_mov.o build/test.o

BIN := $(BIN_DIR)/main

AS_FLAGS := -I$(INC_DIR)
LD_FLAGS := -T script.ld

.PHONY: all
all: $(BIN)
	$(OBJDUMP) -D -b binary -m i8086 -M intel $<

.PHONY: clean
clean:
	-rm -rf $(BIN_DIR)
	-rm -rf $(BUILD_DIR)

$(BIN): $(OBJS) $(BIN_DIR)
	$(LD) $(LD_FLAGS) -o $@ $(OBJS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.S $(BUILD_DIR)
	$(AS) $(AS_FLAGS) -c -o $@ $<

$(BIN_DIR):
	-mkdir $(BIN_DIR)

$(BUILD_DIR):
	-mkdir $(BUILD_DIR)

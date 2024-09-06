
AS := ia16-elf-as
LD := ia16-elf-ld

BIN_DIR := bin
SRC_DIR := src

SRCS := $(wildcard $(SRC_DIR)/*.asm)
BINS := $(SRCS:$(SRC_DIR)/%.asm=$(BIN_DIR)/%.bin)
DSTS := $(BINS:$(BIN_DIR)/%.bin=$(BINC_DIR)/%.bin)
AS_FLAGS :=
LD_FLAGS := -T memmap.ldscript

.PHONY: all
all: $(DSTS)

.PHONY: clean
clean:
	-rm -rf $(BIN_DIR)

$(BINC_DIR)/%.bin: $(BINS)
	cp $< $@

$(BIN_DIR)/%.bin: $(BIN_DIR)/%.o $(BIN_DIR)
	$(LD) $(LD_FLAGS) -o $@ $<

$(BIN_DIR)/%.o: $(SRC_DIR)/%.asm $(BIN_DIR)
	$(AS) $(AS_FLAGS) -o $@ $<

$(BIN_DIR):
	-mkdir $(BIN_DIR)

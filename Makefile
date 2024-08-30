
NAME := nes86

AS := ca65
LD := ld65
OBJDUMP := ia16-elf-objdump
MESEN := ./tools/Mesen2/bin/linux-x64/Release/Mesen

BIN_DIR := bin
BUILD_DIR := build
CONF_DIR := conf
DATA_DIR := data
INC_DIR := include
BINC_DIR := binclude
SRC_DIR := src
TOOLS_DIR := tools

SRC_SUB_DIRS := $(wildcard $(SRC_DIR)/*/)
BUILD_SUB_DIRS := $(SRC_SUB_DIRS:$(SRC_DIR)/%=$(BUILD_DIR)/%)

LD_CONF := $(CONF_DIR)/ld.cfg

SRCS := $(shell find $(SRC_DIR) -type f -name *.s)
OBJS := $(SRCS:$(SRC_DIR)/%.s=$(BUILD_DIR)/%.o)
INCS := $(wildcard $(INC_DIR)/*.inc)
BINCS := $(wildcard $(BINC_DIR)/*)

ROM := $(BIN_DIR)/$(NAME).nes
DBG := $(ROM:%.nes=%.dbg)

# TODO: use "--feature line_continuations" and remove ".linecont +" from source files.
#       at the moment, the cc65 package provided for my Linux distro doesn't support that.
AS_FLAGS := -I $(INC_DIR)
AS_FLAGS += --bin-include-dir $(BINC_DIR)
AS_FLAGS += --feature string_escapes
AS_FLAGS += --feature underline_in_numbers
AS_FLAGS += -D DEBUG
AS_FLAGS += --debug-info

LD_FLAGS := -C $(LD_CONF) --dbgfile $(DBG)

# TODO: lint lint65.py with pylint

.PHONY: all
all: $(TOOLS_DIR) $(DATA_DIR) $(ROM)
	# this is just here for development/debugging
	$(OBJDUMP) -D -b binary -m i8086 -M intel $(BINC_DIR)/bios.bin

.PHONY: $(NAME)
$(NAME):$(ROM)

.PHONY: clean
clean:
	$(MAKE) -C $(DATA_DIR) clean
	#$(MAKE) -C $(TOOLS_DIR) clean
	#-rm -rf $(BINC_DIR)
	-rm -rf $(BUILD_DIR)
	-rm -rf $(BIN_DIR)

.PHONY: $(TOOLS_DIR)
$(TOOLS_DIR):
	#$(MAKE) -C $(TOOLS_DIR)

.PHONY: $(DATA_DIR)
$(DATA_DIR): $(BINC_DIR)
	# TODO: refactor this so that "make all" doesn't rebuild everything every time
	$(MAKE) -C $(DATA_DIR)
	cp $(DATA_DIR)/*/$(BIN_DIR)/* $(BINC_DIR)

.PHONY: mesen
mesen: all
	$(MESEN) $(ROM) &

# link object and library files into a iNES file
$(ROM): $(OBJS) $(LD_CONF) $(BIN_DIR)
	$(LD) $(LD_FLAGS) -o $@ $(OBJS)

# assemble source files into objects
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s $(INCS) $(BINCS) $(BINC_DIR) $(BUILD_DIR)
	$(AS) $(AS_FLAGS) -o $@ $<
	-python $(TOOLS_DIR)/lint65.py $(LD_CONF) $<

$(BUILD_DIR):
	-mkdir $(BUILD_DIR)
	-mkdir -p $(BUILD_SUB_DIRS)

$(BIN_DIR):
	-mkdir $(BIN_DIR)

$(BINC_DIR):
	-mkdir $(BINC_DIR)

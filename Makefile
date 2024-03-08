
NAME := nes86

AS := ca65
LD := ld65

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

AS_FLAGS := -I $(INC_DIR) --bin-include-dir $(BINC_DIR) --feature org_per_seg --feature string_escapes -D DEBUG --debug-info
LD_FLAGS := -C $(LD_CONF) --dbgfile $(DBG)

.PHONY: all
all: $(TOOLS_DIR) $(DATA_DIR) $(ROM)
	objdump -D -b binary -m i8086 -M intel $(BINC_DIR)/x86_code.com

.PHONY: $(NAME)
$(NAME):$(ROM)

.PHONY: clean
clean:
	$(MAKE) -C $(DATA_DIR) clean
	$(MAKE) -C $(TOOLS_DIR) clean
	-rm -rf $(BINC_DIR)
	-rm -rf $(BUILD_DIR)
	-rm -rf $(BIN_DIR)

.PHONY: $(TOOLS_DIR)
$(TOOLS_DIR):
	$(MAKE) -C $(TOOLS_DIR)

.PHONY: $(DATA_DIR)
$(DATA_DIR): $(BINC_DIR)
	# TODO: refactor this so that "make all" doesn't rebuild everything every time
	$(MAKE) -C $(DATA_DIR)
	cp $(DATA_DIR)/*/$(BIN_DIR)/* $(BINC_DIR)

.PHONY: mesen
mesen: all
	mono ~/.local/bin/Mesen.exe $(ROM) &

# link object and library files into a iNES file
$(ROM): $(OBJS) $(LD_CONF) $(BIN_DIR)
	$(LD) $(LD_FLAGS) -o $@ $(OBJS)

# assemble source files into objects
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s $(INCS) $(BINCS) $(BINC_DIR) $(BUILD_DIR)
	$(AS) $(AS_FLAGS) -o $@ $<

$(BUILD_DIR):
	-mkdir $(BUILD_DIR)
	-mkdir -p $(BUILD_SUB_DIRS)

$(BIN_DIR):
	-mkdir $(BIN_DIR)

$(BINC_DIR):
	-mkdir $(BINC_DIR)

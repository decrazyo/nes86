
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

LD_CONF := $(CONF_DIR)/ld.cfg

SRCS := $(shell find $(SRC_DIR) -name *.s)
OBJS := $(SRCS:$(SRC_DIR)/%.s=$(BUILD_DIR)/%.o)
INCS := $(shell find $(INC_DIR) -name *.inc)
DATA := $(shell find $(DATA_DIR) -name *.chr -or -name *.pal)

ROM := $(BIN_DIR)/$(NAME).nes
DBG := $(ROM:%.nes=%.dbg)

AS_FLAGS := -I $(INC_DIR) --bin-include-dir $(BINC_DIR) --feature string_escapes --debug-info
LD_FLAGS := -C $(LD_CONF) --dbgfile $(DBG)

.PHONY: all
all: $(BIN_DIR) $(BUILD_DIR) $(BINC_DIR) $(TOOLS_DIR) $(DATA_DIR) $(ROM)

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
$(DATA_DIR):
	$(MAKE) -C $(DATA_DIR)
	cp $(DATA_DIR)/*/$(BIN_DIR)/* $(BINC_DIR)

.PHONY: mesen
mesen: all
	mono ~/.local/bin/Mesen.exe $(ROM) &

# link object and library files into a iNES file
$(ROM): $(OBJS)
	$(LD) $(LD_FLAGS) -o $(ROM) $(OBJS)

# assemble source files into objects
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s $(DATA) $(INCS)
	$(AS) $(AS_FLAGS) -o $@ $<

$(BUILD_DIR):
	-mkdir $(BUILD_DIR)

$(BIN_DIR):
	-mkdir $(BIN_DIR)

$(BINC_DIR):
	-mkdir $(BINC_DIR)

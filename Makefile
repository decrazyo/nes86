
NAME := nes86

AS := ca65
LD := ld65

BIN_DIR := bin
BUILD_DIR := build
CONF_DIR := conf
DATA_DIR := data
INC_DIR := include
SRC_DIR := src
TOOLS_DIR := tools

LD_CONF := $(CONF_DIR)/ld.cfg

SRCS := $(shell find $(SRC_DIR) -name *.s)
OBJS := $(SRCS:$(SRC_DIR)/%.s=$(BUILD_DIR)/%.o)
LIBS :=
INCS := $(shell find $(INC_DIR) -name *.inc)
DATA := $(shell find $(DATA_DIR) -name *.chr -or -name *.pal)

ROM := $(BIN_DIR)/$(NAME).nes
DBG := $(ROM:%.nes=%.dbg)

AS_FLAGS := -I $(INC_DIR) --bin-include-dir $(DATA_DIR) --debug-info
LD_FLAGS := -C $(LD_CONF) --dbgfile $(DBG)

.PHONY: all
all: tools $(BUILD_DIR) $(BIN_DIR) $(ROM)

.PHONY: clean
clean:
	-rm -rf $(BUILD_DIR)
	-rm -rf $(BIN_DIR)
	$(MAKE) -C tools clean

.PHONY: tools
tools:
	$(MAKE) -C tools

.PHONY: mesen
mesen: all
	mono ~/.local/bin/Mesen.exe $(ROM) &

# link object and library files into a iNES file
$(ROM): $(OBJS) $(LIBS)
	$(LD) $(LD_FLAGS) -o $(ROM) $(OBJS) $(LIBS)

# assemble source files into objects
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s $(DATA) $(INCS)
	$(AS) $(AS_FLAGS) -o $@ $<

$(BUILD_DIR):
	-mkdir $(BUILD_DIR)

$(BIN_DIR):
	-mkdir $(BIN_DIR)

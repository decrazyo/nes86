
# i don't feel like integrating my build system with ELKS.
# the user is responsible for building ELKS separately.
# this will just copy the files we need.

ELKS_DIR := elks

IMAGE := Image
ROMFS := romfs.bin

IMAGE_DIR := $(ELKS_DIR)/elks/arch/i86/boot
ROMFS_DIR := $(ELKS_DIR)/image

SRC_IMAGE := $(IMAGE_DIR)/$(IMAGE)
SRC_ROMFS := $(ROMFS_DIR)/$(ROMFS)

DST_IMAGE := $(BINC_DIR)/$(IMAGE)
DST_ROMFS := $(BINC_DIR)/$(ROMFS)

.PHONY: all
all: $(DST_IMAGE) $(DST_ROMFS)

.PHONY: clean
clean:

$(DST_IMAGE): $(SRC_IMAGE)
	cp $< $@

$(DST_ROMFS): $(SRC_ROMFS)
	cp $< $@

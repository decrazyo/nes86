
SRCS := $(wildcard *.chr)
DSTS := $(SRCS:%.chr=$(BINC_DIR)/%.chr)

.PHONY: all
all: $(DSTS)

.PHONY: clean
clean:

$(BINC_DIR)/%.chr: %.chr
	cp $< $@

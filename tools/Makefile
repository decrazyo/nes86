
SUB_DIRS := $(wildcard */.)

.PHONY: all
all: $(SUB_DIRS)

.PHONY: clean
clean: $(SUB_DIRS)

.PHONY: $(SUB_DIRS)
$(SUB_DIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

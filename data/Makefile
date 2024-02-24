
SUBDIRS := $(wildcard */.)

.PHONY: all
all: $(SUBDIRS)

.PHONY: clean
clean: $(SUBDIRS)

.PHONY: $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

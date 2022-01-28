# SPDX-License-Identifier: BSD-2-Clause
# Based on OpenSBI:
#   Copyright (c) 2019 Western Digital Corporation or its affiliates.
#   Authors:
#     Anup Patel <anup.patel@wdc.com>
# Modified for RISC-V Baremetal Playground:
#   Copyright (C) 2022 Tsukasa OI.


MAKEFLAGS += -r --no-print-directory

ifeq ($(shell uname -s),Darwin)
READLINK ?= greadlink
else
READLINK ?= readlink
endif

srcdir   = $(CURDIR)
objdir   = $(CURDIR)/obj
outdir   = $(CURDIR)/out

CMD_PREFIX_DEFAULT := @
ifeq ($(V), 1)
	CMD_PREFIX :=
else
	CMD_PREFIX := $(CMD_PREFIX_DEFAULT)
endif

GOALS_CLEAN := clean mrproper
GOALS_NODEP := $(GOALS_CLEAN) defconfig
GOALS_CLEAN_FILTERED := $(filter $(GOALS_CLEAN),$(MAKECMDGOALS))
GOALS_NODEP_FILTERED := $(filter $(GOALS_NODEP),$(MAKECMDGOALS))



MAKECONFIG_DEPS = .config Makefile SOURCES.mk CUSTOM.mk CUSTOM_DEPS.mk

src_targets :=
src_liball  := \
	crt/start.S \
	crt/stack.S
src_libcrt  := \
	crt/exit.S

ifeq ($(GOALS_CLEAN_FILTERED),)
-include SOURCES.mk
endif

obj_targets := $(src_targets:.c=.elf)
obj_targets := $(obj_targets:.cpp=.elf)
obj_targets := $(obj_targets:.S=.elf)
obj_liball  := $(src_liball:.c=.o)
obj_liball  := $(obj_liball:.cpp=.o)
obj_liball  := $(obj_liball:.S=.o)
obj_libcrt  := $(src_libcrt:.c=.o)
obj_libcrt  := $(obj_libcrt:.cpp=.o)
obj_libcrt  := $(obj_libcrt:.S=.o)
obj_path_targets := $(foreach elf,$(obj_targets),$(outdir)/$(elf))
obj_path_liball := $(foreach obj,$(obj_liball),$(objdir)/$(obj))
obj_path_libcrt := $(foreach obj,$(obj_libcrt),$(objdir)/$(obj))
obj_tmppath_targets := $(foreach elf,$(obj_targets),$(objdir)/$(elf))
dep_pathes  = $(obj_tmppath_targets:.elf=.dep)
dep_pathes += $(obj_path_liball:.o=.dep)
dep_pathes += $(obj_path_libcrt:.o=.dep)
obj_dumps  := $(foreach elf,$(obj_targets),$(outdir)/$(elf:.elf=.txt))

ifeq ($(shell test -f .config; echo $$?),0)
include .config
else ifeq ($(GOALS_NODEP_FILTERED),)
$(error .config not found. Make default one with `defconfig'.)
endif

.PHONY: all
all: $(obj_path_targets) $(obj_dumps)
.SECONDARY:

SOURCES.mk: data/templates/SOURCES.mk
	$(CMD_PREFIX)echo " TEMPLATE  SOURCES.mk"
	$(CMD_PREFIX)if test -f $@; then touch $@; else cp $< $@; fi
CUSTOM.mk: data/templates/CUSTOM.mk
	$(CMD_PREFIX)echo " TEMPLATE  CUSTOM.mk"
	$(CMD_PREFIX)if test -f $@; then touch $@; else cp $< $@; fi
CUSTOM_DEPS.mk: data/templates/CUSTOM_DEPS.mk
	$(CMD_PREFIX)echo " TEMPLATE  CUSTOM_DEPS.mk"
	$(CMD_PREFIX)if test -f $@; then touch $@; else cp $< $@; fi



CROSS_COMPILE ?= riscv64-unknown-elf-
CROSS_CC      ?= $(CROSS_COMPILE)gcc
CROSS_CXX     ?= $(CROSS_COMPILE)g++
CROSS_CPP     ?= $(CROSS_COMPILE)cpp
CROSS_AR      ?= $(CROSS_COMPILE)ar
CROSS_OBJDUMP ?= $(CROSS_COMPILE)objdump
CROSS_OBJCOPY ?= $(CROSS_COMPILE)objcopy

CFLAGS_DEFAULT := -O2 -g
CFLAGS_DEFAULT += -Wall -ffreestanding
CFLAGS_DEFAULT_DEFINES := -DADDR_START=$(CONFIG_ADDR_START)
ifneq ($(CONFIG_ADDR_STACK),auto)
CFLAGS_DEFAULT_DEFINES += -DADDR_STACK=$(CONFIG_ADDR_STACK)
else
CFLAGS_DEFAULT_DEFINES += -DSTACK_SIZE=$(CONFIG_STACK_SIZE)
endif

# Note: $(CXXFLAGS) is used **together with** $(CFLAGS)
CXXFLAGS_DEFAULT := -fno-rtti -fno-exceptions

CFLAGS   = $(CFLAGS_DEFAULT) $(CFLAGS_DEFAULT_DEFINES)
CXXFLAGS = $(CXXFLAGS_DEFAULT)

ARFLAGS = rcs
ARFLAGS_LIBALL = $(ARFLAGS)
ARFLAGS_LIBCRT = $(ARFLAGS)

LINKER_SCRIPT = data/ldscripts/riscv.ld
LDFLAGS := -Wl,-T,$(LINKER_SCRIPT)
LDFLAGS += -Wl,-Ttext-segment,$(CONFIG_ADDR_START)
ifneq ($(CONFIG_ADDR_DATA),auto)
LDFLAGS += -Wl,-Tdata,$(CONFIG_ADDR_DATA)
endif
LDFLAGS_BARE   = $(LDFLAGS) -nostdlib -nostartfiles
LDFLAGS_NEWLIB = $(LDFLAGS)

ARCH_CFLAGS = -march=$(CONFIG_TARGET_ISA) -mabi=$(CONFIG_TARGET_ABI) -mcmodel=medany
ALL_CFLAGS   = $(ARCH_CFLAGS) $(CFLAGS)
ALL_CXXFLAGS = $(ARCH_CFLAGS) $(CFLAGS) $(CXXFLAGS)

BASE_CFLAGS   := $(CFLAGS)
BASE_CXXFLAGS := $(CXXFLAGS)
ifeq ($(GOALS_NODEP_FILTERED),)
-include CUSTOM.mk
endif



compile_as_dep = $(CMD_PREFIX)mkdir -p $$(dirname $(1)); \
	echo " AS-DEP      $(subst $(objdir)/,,$(1))"; \
	printf %s $$(dirname $(1))/ > $(1) && \
	$(CROSS_CC) $(ALL_CFLAGS) -M $(2) >> $(1) || rm -f $(1)
compile_as = $(CMD_PREFIX)mkdir -p $$(dirname $(1)); \
	echo " AS          $(subst $(objdir)/,,$(1))"; \
	$(CROSS_CC) $(ALL_CFLAGS) -c $(2) -o $(1)
compile_cc_dep = $(CMD_PREFIX)mkdir -p $$(dirname $(1)); \
	echo " CC-DEP      $(subst $(objdir)/,,$(1))"; \
	printf %s $$(dirname $(1))/ > $(1) && \
	$(CROSS_CC) $(ALL_CFLAGS) -M $(2) >> $(1) || rm -f $(1)
compile_cc = $(CMD_PREFIX)mkdir -p $$(dirname $(1)); \
	echo " CC          $(subst $(objdir)/,,$(1))"; \
	$(CROSS_CC) $(ALL_CFLAGS) -c $(2) -o $(1)
compile_cxx_dep = $(CMD_PREFIX)mkdir -p $$(dirname $(1)); \
	echo " CXX-DEP     $(subst $(objdir)/,,$(1))"; \
	printf %s $$(dirname $(1))/ > $(1) && \
	$(CROSS_CXX) $(ALL_CXXFLAGS) -M $(2) >> $(1) || rm -f $(1)
compile_cxx = $(CMD_PREFIX)mkdir -p $$(dirname $(1)); \
	echo " CXX         $(subst $(objdir)/,,$(1))"; \
	$(CROSS_CXX) $(ALL_CXXFLAGS) -c $(2) -o $(1)
compile_ar = $(CMD_PREFIX)mkdir -p $$(dirname $(1)); \
	echo " AR          $(subst $(objdir)/,,$(1))"; \
	$(CROSS_AR) $(3) $(1) $(2)
compile_ld_bare = $(CMD_PREFIX)mkdir -p $$(dirname $(1)); \
	echo " LD (bare)   $(subst $(outdir)/,,$(1))"; \
	$(CROSS_CXX) $(ALL_CXXFLAGS) $(2) $(LDFLAGS_BARE) -o $(1)
compile_ld_newlib = $(CMD_PREFIX)mkdir -p $$(dirname $(1)); \
	echo " LD (newlib) $(subst $(outdir)/,,$(1))"; \
	$(CROSS_CXX) $(ALL_CXXFLAGS) $(2) \
		-Wl,--whole-archive $(objdir)/libcrt.a -Wl,--no-whole-archive \
		$(LDFLAGS_NEWLIB) -o $(1)

$(objdir)/%.dep: $(srcdir)/%.S $(MAKECONFIG_DEPS)
	$(call compile_as_dep,$@,$<)
$(objdir)/%.o: $(srcdir)/%.S $(MAKECONFIG_DEPS)
	$(call compile_as,$@,$<)
$(objdir)/%.dep: $(srcdir)/%.c $(MAKECONFIG_DEPS)
	$(call compile_cc_dep,$@,$<)
$(objdir)/%.o: $(srcdir)/%.c $(MAKECONFIG_DEPS)
	$(call compile_cc,$@,$<)
$(objdir)/%.dep: $(srcdir)/%.cpp $(MAKECONFIG_DEPS)
	$(call compile_cxx_dep,$@,$<)
$(objdir)/%.o: $(srcdir)/%.cpp $(MAKECONFIG_DEPS)
	$(call compile_cxx,$@,$<)

$(objdir)/liball.a: $(obj_path_liball) $(MAKECONFIG_DEPS)
	$(call compile_ar,$@,$(obj_path_liball),$(ARFLAGS_LIBALL))
$(objdir)/libcrt.a: $(obj_path_libcrt) $(MAKECONFIG_DEPS)
	$(call compile_ar,$@,$(obj_path_libcrt),$(ARFLAGS_LIBCRT))
$(outdir)/%.bare.elf: $(objdir)/%.bare.o $(objdir)/liball.a $(LINKER_SCRIPT) $(MAKECONFIG_DEPS)
	$(call compile_ld_bare,$@,$< $(objdir)/liball.a)
$(outdir)/%.newlib.elf: $(objdir)/%.newlib.o $(objdir)/liball.a $(objdir)/libcrt.a $(LINKER_SCRIPT) $(MAKECONFIG_DEPS)
	$(call compile_ld_newlib,$@,$< $(objdir)/liball.a)
$(outdir)/%.txt: $(outdir)/%.elf
	$(CMD_PREFIX) echo " OBJDUMP     $(subst $(outdir)/,,$@)"; \
	$(CROSS_OBJDUMP) -x -s -d -r $< >$@

ifeq ($(GOALS_NODEP_FILTERED),)
-include $(dep_pathes)
-include CUSTOM_DEPS.mk
endif



.PHONY: clean
clean:
	$(CMD_PREFIX)echo " RM        OBJDIR"
	$(CMD_PREFIX)test ! -d $(objdir) || rm -r -f $(objdir)
	$(CMD_PREFIX)echo " RM        OUTDIR"
	$(CMD_PREFIX)test ! -d $(outdir) || rm -r -f $(outdir)

.PHONY: mrproper
mrproper:
	$(CMD_PREFIX)echo " RM        SOURCES.mk"
	$(CMD_PREFIX)rm -f SOURCES.mk
	$(CMD_PREFIX)echo " RM        CUSTOM.mk"
	$(CMD_PREFIX)rm -f CUSTOM.mk
	$(CMD_PREFIX)echo " RM        CUSTOM_DEPS.mk"
	$(CMD_PREFIX)rm -f CUSTOM_DEPS.mk
	$(CMD_PREFIX)echo " RM        .config"
	$(CMD_PREFIX)rm -f .config

DEFAULT_CC_ISA := $(shell TMP=$$($(CROSS_CC) -v 2>&1 | sed -n 's/.*\(with\-arch=\([a-zA-Z0-9]*\)\).*/\2/p'); echo $${TMP})
DEFAULT_CC_ABI := $(shell TMP=$$($(CROSS_CC) -v 2>&1 | sed -n 's/.*\(with\-abi=\([a-zA-Z0-9]*\)\).*/\2/p'); echo $${TMP})
.PHONY: defconfig
defconfig:
	$(CMD_PREFIX)echo " MAKE_DEFCONFIG"
	$(CMD_PREFIX)$(srcdir)/scripts/defconfig.sh $(DEFAULT_CC_ISA) $(DEFAULT_CC_ABI)

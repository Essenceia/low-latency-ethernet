
###########
# Configs #
###########

ifndef debug
#debug :=
endif

# Enable waves by default
ifndef wave
wave:=1
endif

# Coverage, enabled by default
ifndef cov
cov:=1
endif

# Asserts, enabled by default
ifndef assert
assert:=1
endif

# Work in progress flag, used to bypass
# some lint sanity checks during early
# developpement
ifndef wip
wip:=
endif

############
# Sim type #
############

# Define simulator we are using, priority to iverilog
SIM ?= I
$(info Using simulator: $(SIM))

###########
# Globals #
###########

# Global configs.
TB_DIR := tb
REF_DIR := $(TB_DIR)/ref
CONF := conf
WAVE_DIR := wave
VIEW := gtkwave
GDB_CONF := .gdbinit
DEBUG_FLAG := $(if $(debug), debug=1)
DEFINES := $(if $(wave),wave=1)

########
# Lint #
########

# Lint variables.
LINT_FLAGS :=
ifeq ($(SIM),I)
LINT_FLAGS +=-Wall -g2012 $(if $(assert),-gassertions) -gstrict-expr-width
LINT_FLAGS +=$(if $(debug),-DDEBUG) 
else
LINT_FLAGS += -Wall -Wpedantic -Wno-GENUNNAMED -Wno-LATCH -Wno-IMPLICIT
LINT_FLAGS +=$(if $(wip),-Wno-UNUSEDSIGNAL)
endif

# Lint commands.
# TODO ONELINER
ifeq ($(SIM),I)
define LINT
	$(info 1 $(1))
	$(info 2 $(2))
	iverilog $(LINT_FLAGS) -s $2 -o $(BUILD_DIR)/$2 $1
endef
else
define LINT
	verilator --lint-only $(LINT_FLAGS) $1
endef
endif

#########
# Build #
#########

# Build variables.
ifeq ($(SIM),I)
BUILD_DIR := build
BUILD_FLAGS := 
else
BUILD_DIR := obj_dir
BUILD_FLAGS := 
BUILD_FLAGS += $(if $(assert),--assert)
BUILD_FLAGS += $(if $(wave), --trace --trace-underscore) 
BUILD_FLAGS += $(if $(cov), --coverage --coverage-underscore) 
BUILD_FLAGS += --timing
BUILD_FLAGS += --x-initial-edge
MAKE_THREADS = 4 
BUILD_FLAGS += -j $(MAKE_THREADS)
endif

# Build commands.
ifeq ($(SIM),I)
define BUILD
	iverilog $(LINT_FLAGS) -s $2 -o $(BUILD_DIR)/$2 $1
endef
else
define BUILD
	verilator --binary $(LINT_FLAGS) $(BUILD_FLAGS) -o $2 $1  
endef
endif

#######
# Run #
#######

# Run commands.
ifeq ($(SIM),I)
define RUN
	vvp $(BUILD_DIR)/$1
endef
else
define RUN
	./$(BUILD_DIR)/$1 $(if $(wave),+trace) 
endef
endif

config:
	@mkdir -p $(CONF)

build:
	@mkdir -p $(BUILD_DIR)

########
# Lint #
########

# Dependencies for linter.
crc_deps := crc32.v
mac_deps +=crc.v mac_rx.v

lint_mac :$(mac_deps)
	$(call LINT,$^,mac_rx)

lint_crc: $(crc_deps)
	$(call LINT,$^,crc_tb)

#############
# Testbench #
#############

# The list of testbenches.
tbs := crc mac

# Standard run recipe to build a given testbench
define build_recipe
$1_tb: $$($(1)_deps)
	$$(call BUILD,$$^,$$@)

endef

# Dependencies for each testbench
crc_deps :=crc32.v crc32_v2.v $(REF_DIR)/lfsr.v $(TB_DIR)/crc_tb.sv
mac_deps +=crc.v mac_rx.v $(TB_DIR)/mac_tb.sv

# Standard run recipe to run a given testbench
define run_recipe
run_$1: $1_tb
	$$(call RUN,$$^)

endef

# Generate run recipes for each testbench.
$(eval $(foreach x,$(tbs),$(call run_recipe,$x)))


# Generate build recipes for each testbench.
$(eval $(foreach x,$(tbs),$(call build_recipe,$x)))

####################
# Standard targets #
####################

# Cleanup
clean:
	rm -f vgcore.* vgd.log*
	rm -f callgrind.out.*
	rm -fr build/*
	rm -fr obj_dir/*
	rm -fr $(WAVE_DIR)/*



###########
# Configs #
###########

ifndef debug
debug :=
endif

ifndef wireshark
wireshark:=
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
VPI_DIR := $(TB_DIR)/vpi
REF_DIR := $(TB_DIR)/ref
CONF := conf
WAVE_DIR := wave
VIEW := gtkwave
GDB_CONF := .gdbinit
DEBUG_FLAG := $(if $(debug), debug=1)
DEFINES := $(if $(wave),wave=1)
DEFINES += $(DEBUG_FLAG)
DEFINES +=$(if $(wireshark), wireshark=1)

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
ifeq ($(SIM),I)
define LINT
	mkdir -p build
	iverilog $(LINT_FLAGS) -s $2 $(BUILD_FLAGS) -o $(BUILD_DIR)/$2 $1
endef
else
define LINT
	mkdir -p build
	verilator --lint-only $(LINT_FLAGS) $1
endef
endif

###############
# Build flags #
###############

# Build variables.
ifeq ($(SIM),I)
BUILD_DIR := build
BUILD_FLAGS := $(if $(wave),-DWAVE)  
BUILD_FLAGS += $(if $(assert),,-DINTERACTIVE)  
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

#############
# VPI build #
#############

# VPU Build variables
ifeq ($(SIM),I)
BUILD_VPI_DIR := build
else
BUILD_VPI_DIR := obj_vpi
endif

# VPI build commands.
ifeq ($(SIM),I)
define BUILD_VPI
	# Manually invoke vpi to not polute dependancy list
	@$(MAKE) -f makefile $3
	# Same as normal build
	iverilog $(LINT_FLAGS) -s $2 $(BUILD_FLAGS) -o $(BUILD_DIR)/$2 $1
endef
else
define BUILD_VPI
	@printf "\nVerilating vpi design and tb \n\n"
	verilator -cc --exe --vpi --public-flat-rw --threads 1 $(LINT_FLAGS) $(BUILD_FLAGS) --top-module $2 -LDFLAGS "$(CWD)/$(VPI_DIR)/$(BUILD_VPI_DIR)/$4_all.o V$2__ALL.a" -o $2 $1
	
	@printf "\nMaking vpi shared object \n\n"
	@$(MAKE) -f makefile $3
	
	@printf "\nInvoking generated makefile \n\n"
	$(MAKE) -C $(BUILD_DIR) -j $(MAKE_THREADS) -f V$2.mk
endef
endif

#########
# Build #
#########

# Build commands.
ifeq ($(SIM),I)
define BUILD
	mkdir -p build
	iverilog $(LINT_FLAGS) -s $2 $(BUILD_FLAGS) -o $(BUILD_DIR)/$2 $1
endef
else
define BUILD
	mkdir -p build
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
define RUN_VPI
	vvp -M $(VPI_DIR)/$(BUILD_VPI_DIR) -mtb $(BUILD_DIR)/$1
endef
else
define RUN
	./$(BUILD_DIR)/$1 $(if $(wave),+trace) 
endef
define RUN_VPI
	$(call RUN,$1)
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
MAC_DIR = mac
IP_DIR = ipv4
UDP_DIR = udp
TCP_DIR = tcp
UTILS_DIR = ../utils

crc_f := crc.v
mac_f :=crc.v mac_rx.v mac_head_tx.v $(crc_deps)
ip_f := ipv4_rx.v ipv4_head_tx.v ip_addr_match.v
udp_f := udp_head_tx.v udp_rx.v 
utils_f := thermo_to_len.v len_to_mask.v
tcp_f := tcp_entry.v
 
# add dir names
crc_deps := $(foreach x,$(crc_f),$(MAC_DIR)/$x) 
mac_deps := $(foreach x,$(mac_f),$(MAC_DIR)/$x) 
ip_deps := $(foreach x,$(ip_f),$(IP_DIR)/$x)
udp_deps := $(foreach x,$(udp_f),$(UDP_DIR)/$x) 
tcp_deps := $(foreach x,$(tcp_f),$(TCP_DIR)/$x) 
utils_deps := $(foreach x,$(utils_f),$(UTILS_DIR)/$x)

eth_deps := eth_rx.v eth_tx.v 
eth_deps += $(mac_deps) $(ip_deps) $(udp_deps) $(utils_deps)
eth_deps += $(TB_DIR)/eth_tb.sv 

lint_mac: $(mac_deps)
	$(call LINT,$^,mac_rx)

lint_crc: $(crc_deps)
	$(call LINT,$^,crc_tb)

lint_ip: $(ip_deps)
	$(call LINT,$^,ipv4_rx)

lint_udp: $(udp_deps)
	$(call LINT,$^,udp_rx)

lint_tcp: $(tcp_deps)
	$(call LINT,$^,tcp_entry)

lint_eth: $(eth_deps)
	$(call LINT,$^,eth_rx)
 
#############
# Testbench #
#############

# The list of testbenches.
tbs := crc mac

# Dependencies for each testbench
crc_deps += $(TB_DIR)/crc_tb.sv
mac_deps += $(TB_DIR)/mac_tb.sv

# Standard run recipe to build a given testbench
define build_recipe
$1_tb: $$($(1)_deps)
	$$(call BUILD,$$^,$$@)

endef

# Standard run recipe to run a given testbench
define run_recipe
run_$1: $1_tb
	$$(call RUN,$$^)

endef

# Generate run recipes for each testbench.
$(eval $(foreach x,$(tbs),$(call run_recipe,$x)))


# Generate build recipes for each testbench.
$(eval $(foreach x,$(tbs),$(call build_recipe,$x)))

#################
# VPI testbench #
#################


eth_tb : $(eth_deps) 
	$(call BUILD_VPI,$^,$@,vpi,tb)

# Run VPI
run_eth_cmd := vvp -M $(VPI_DIR)/$(BUILD_VPI_DIR) -mtb $(BUILD_DIR)/eth_tb
run_eth: eth_tb
	$(call RUN_VPI,$^)

vpi:
	cd $(VPI_DIR) && $(MAKE) $(BUILD_VPI_DIR)/tb.vpi SIM=$(SIM) $(DEFINES) $(40GBASE_ARGS)

#######################
# debug VPI testbench #
#######################

debug_run := $(call RUN_VPI,eth_tb)

valgrind:
	valgrind $(debug_run)	

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
	cd $(VPI_DIR) && $(MAKE) clean

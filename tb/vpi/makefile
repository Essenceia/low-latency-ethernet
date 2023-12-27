################
# Sanitization #
################

# Disable builtin implicit rules.
.SUFFIXES :
% :: %,v
% :: s.%
% :: RCS/%,v
% :: RCS/%
% :: SCCS/%
% :: SCCS/s.%

############
# Sim type #
############

# Define simulator we are using, priority to iverilog
SIM ?= I
$(info Using simulator: $(SIM))

###########
# Config #
###########

# enable wireshare network transaction dump
ifndef wireshark
wireshare:=
endif

###########
# Globals #
###########

# AUR Path.
AUR := $(HOME)/AUR

# Compilation flags.
CC_FLAGS := -Wall -Wextra -Wconversion -Wshadow -Wundef -fno-common -Wno-unused-parameter -Wno-type-limits 
CC_FLAGS += -Wno-format
CC_FLAGS += -fpic 
CC_FLAGS += $(if $(debug),-g) 

# Compilation defines.
CC_DEFS := $(if $(debug),-DDEBUG) 
CC_DEFS +=$(if $(40GBASE), -D_40GBASE)
CC_DEFS += $(if $(wireshark), -DWIRESHARK)

# Libraries 
INC_DIR := inc
INC := -I$(INC_DIR)
LIB :=-L $(INC_DIR) -leth -lfifo

# Link flags.
LD_FLAGS := $(if $(debug),-g) 

# Per-testbench parameters.
ifeq ($(SIM),I)
BUILD=build
CC_CMD=cc
LD_CMD=cc
CC_FLAGS += -std=gnu99

# set vpi lib path when using iverilog :
VPI_INC := -I$(AUR)/iverilog

VPI_DIR := vpi_i
PP :=
else
BUILD=obj_vpi
CC_CMD=g++
LD_CMD=g++
CC_FLAGS += -fpermissive
CC_DEFS += -DVERILATOR
CC_DEFS += $(if $(wave),-DVM_TRACE)

# set vpi lib path when using verilator :
VPI_INC := -I/usr/local/share/verilator/include 
VPI_INC += -I/usr/local/share/verilator/include/vltstd

VPI_INC += -I../../obj_dir
VPI_DIR := vpi_v
PP := pp
endif

# Log.
$(info Using SIM=$(SIM), building to $(BUILD) dir)

# Compilation utils.
CC := $(CC_CMD) $(CC_FLAGS) $(CC_DEFS)
LD := $(LD_CMD) $(LD_FLAGS)  

###########
# Headers #
###########

# All headers that are accessible to .c/cpp files.
# Any change in those will cause any required .o file to be rebuilt.
#HDRS := pcs_gearbox.h pcs_defs.h pcs_enc.h pcs_marker.h pcs_tx.h
HDRS += $(VPI_DIR)/tb_network.h$(PP) 
HDRS += tb_rand.h mac_intf.h defs.h trans_data.h 
HDRS += tv.h
HDRS += tb.h
HDRS += vpi_utils.h

#########
# Build #
#########

# General sources
SRCS := test tv tb tb_rand mac_intf trans_data
SRCS += vpi_utils

# VPI sources
VPI_SRCS := tb_network

# Standard object file build recipe.
define obj_recipe
$$(BUILD)/$1.o:$1.c $(HDRS)
	@mkdir -p $$(@D)
	$$(CC) $$(VPI_INC) $$(INC) -o $$@ -c $1.c

endef

# VPI object file build recipe.
define vpi_obj_recipe
$$(BUILD)/$1.o: $$(VPI_DIR)/$1.c$(PP) $$(HDRS)
	@mkdir -p $$(@D)
	$$(CC) $$(VPI_INC) -o $$@ -c $$(VPI_DIR)/$1.c$$(PP)

endef

# Generate run recipes for each testbench.
$(eval $(foreach x,$(SRCS),$(call obj_recipe,$x)))
$(eval $(foreach x,$(VPI_SRCS),$(call vpi_obj_recipe,$x)))

################
# Dependencies #
################

# Dependencies for all tests. '.o'-s ommitted.
deps_all :=tv tb_rand mac_intf trans_data

# Test dependencies names. '.o'-s ommitted.
test_deps_names := test $(deps_all) 
tb_deps_names := tb vpi_utils $(VPI_SRCS) $(deps_all)

# Dependencies generator.
gen_deps = $(foreach x,$($(1)_deps_names),$(BUILD)/$x.o)

# Dependencies.
test_deps := $(call gen_deps,test)
tb_deps := $(call gen_deps,tb)

###########
# Targets #
###########

test: $(test_deps)
	$(LD) -o test -g $^ $(LIB)

$(BUILD)/tb_all.o: $(tb_deps)
	@mkdir -p $(@D)
	$(LD) -r -o $(BUILD)/tb_all.o $^

$(BUILD)/tb.vpi: $(BUILD)/tb_all.o
	@mkdir -p $(@D)
	$(LD) -shared -o $(BUILD)/tb.vpi $^ -lvpi $(LIB)

#########
# Debug #
#########

valgrind:test
	valgrind ./test	

####################
# Standard targets #
####################

clean:
	rm -f network_dump.hex
	rm -f test
	rm -rf build/*	
	rm -rf obj_vpi/*	
	rm -f test	
	rm -f vgcore.*	


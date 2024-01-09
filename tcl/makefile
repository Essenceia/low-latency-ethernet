# Vivado tcl make wrapper

# Device
ifndef fpga
fpga :=xc7a100tfgg484-2
endif

# checkpoint
ifndef checkpoint
checkpoint :=1
endif

# project directory and name
PROJ := eth_rx
PROJ_DIR := ../vivado/$(fpga)_$(PROJ)
PROJ_PATH := $(PROJ_DIR)/$(PROJ).xpr

# Invoke vivado in tcl batch mode
VVD := vivado -mode batch -source

# tcl args
ARGS := -tclargs "$(PROJ_PATH)" "$(PROJ_DIR)" "$(checkpoint)"

# setup
setup: $(PROJ_PATH)
	mkdir -p $(PROJ_DIR)
	$(VVD) setup.tcl -tclargs "$(fpga)" "$(PROJ)" "$(checkpoint)"
	$(info Set up project with parameters :)
	$(info fpga: $(fpga))
	$(info project: $(PROJ))
	$(info checkpoints: $(checkpoints))
	$(info path to project: $(PROJ_PATH))


lint: lint.tcl
	$(VVD) $< $(ARGS)

# checkpoints

synth_cp:= $(PROJ_DIR)/synth_cp.dcp
impl_cp:= $(PROJ_DIR)/impl_cp.dcp

rtl_deps := $(shell find ../ -name "*\.[v|sv]" | grep -v phy | grep -v tb | tr '\n' ' ' )

$(synth_cp): $(rtl_deps) 
	$(VVD) synth.tcl $(ARGS)

$(impl_cp): $(synth_cp)
	$(VVD) impl.tcl $(ARGS)

synth:$(synth_cp)

impl: $(impl_cp)

clean:
	rm -f vivado*.jou
	rm -f vivado*.log
	rm -rf $(PROJ_DIR)/*

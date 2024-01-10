# Vivado tcl make wrapper

# Device
ifndef fpga
fpga :=xc7a100tfgg484-2
endif

# checkpoint
ifndef checkpoint
checkpoint :=1
endif

# nworst 
ifndef nworst
nworst := 50
endif

# project directory and name
PROJ := eth_rx
PROJ_DIR := ../vivado/$(fpga)_$(PROJ)
PROJ_PATH := $(PROJ_DIR)/$(PROJ).xpr

# Invoke vivado in tcl batch mode
VVD := vivado -mode batch -source

# tcl args
ARGS := -tclargs "$(PROJ_PATH)" "$(PROJ_DIR)"

# setup
setup:
	mkdir -p $(PROJ_DIR)
	$(VVD) setup.tcl -tclargs "$(PROJ)" "$(PROJ_DIR)" "1" "$(fpga)"
	$(info Set up project with parameters :)
	$(info fpga: $(fpga))
	$(info project: $(PROJ))
	$(info checkpoints: $(checkpoints))
	$(info path to project: $(PROJ_PATH))


lint: lint.tcl
	$(VVD) $< $(ARGS)

# checkpoints

synth_cp:= $(PROJ_DIR)/synth_op_cp.dcp
impl_cp:= $(PROJ_DIR)/impl_cp.dcp

rtl_deps := $(shell find ../ -name "*\.[v|sv]" | grep -v phy | grep -v tb | tr '\n' ' ' )

$(synth_cp): synth.tcl $(rtl_deps) 
	$(VVD) $< $(ARGS)

$(impl_cp): impl.tcl $(synth_cp)
	$(VVD) $< -tclargs "$(synth_cp)" "$(PROJ_DIR)"

synth:$(synth_cp)

impl: $(impl_cp)

# report timing, re-run on new nworst argument
timing_report_path:= $(PROJ_DIR)/timing_$(nworst)_nworst.rpt

$(timing_report_path): time.tcl $(impl_cp)
	$(VVD) $< -tclargs "$(impl_cp)" "$(PROJ_DIR)" "$(nworst)" "$(timing_report_path)"

time: $(timing_report_path)

rebuild:
	$(MAKE) setup
	$(MAKE) lint
	$(MAKE) synth
	$(MAKE) impl
	$(MAKE) time

clean:
	rm -f vivado*.jou
	rm -f vivado*.log
	rm -rf $(PROJ_DIR)/*

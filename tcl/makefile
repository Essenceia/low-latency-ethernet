# Vivado tcl make wrapper

# Device
ifndef fpga
fpga :=xc7a100tfgg484-3
endif

# checkpoint
ifndef checkpoint
checkpoint :=1
endif

# nworst 
ifndef nworst
nworst := 1
endif

# npath 
ifndef npath
npath := 20
endif

# run synth timing
ifndef run_synth_timing
run_synth_timing := 0
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
xdc_deps := $(fpga).xdc

$(synth_cp): synth.tcl $(rtl_deps) $(xdc_deps) 
	$(VVD) $< $(ARGS) "$(run_synth_timing)" "$(nworst)"

$(impl_cp): impl.tcl $(synth_cp)
	$(VVD) $< -tclargs "$(synth_cp)" "$(PROJ_DIR)"

synth:$(synth_cp)

# synthesis timing report
synth_timing_report_path:= $(PROJ_DIR)/post_synth_timing_nw_$(nworst)_np_$(npath).rpt
$(synth_timing_report_path): synth_time.tcl $(synth_cp) 
	$(VVD) $< -tclargs "$(synth_cp)" "$(PROJ_DIR)" "$(nworst)" "$(npath)" 

synth_time: $(synth_timing_report_path)

impl: $(impl_cp)

# implementation timing report, re-run on new nworst argument
timing_report_path:= $(PROJ_DIR)/timing_nw_$(nworst)_np_$(npath).rpt

$(timing_report_path): time.tcl $(impl_cp)
	$(VVD) $< -tclargs "$(impl_cp)" "$(PROJ_DIR)" "$(nworst)" "$(npath)"


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

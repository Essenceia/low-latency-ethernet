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
PROJ_DIR := ../vivado
PROJ := eth_rx
PROJ_PATH := $(PROJ_DIR)/$(fpga)_$(PROJ)/$(PROJ).xpr

# Invoke vivado in tcl batch mode
VVD := vivado -mode batch -source

# tcl args
ARGS := -tclargs "$(fpga)" "$(PROJ)" "$(checkpoint)"

$(PROJ_DIR):
	mkdir -p $(PROJ_DIR)

# setup
$(PROJ_PATH): setup.tcl $(PROJ_DIR)
	$(VVD) $< $(ARGS) 

setup: $(PROJ_PATH)
	$(info Set up project with parameters :)
	$(info fpga: $(fpga))
	$(info project: $(PROJ))
	$(info checkpoints: $(checkpoints))
	$(info path to project: $(PROJ_PATH))


lint: lint.tcl
	$(VVD) $< -tclargs "$(PROJ_PATH)" 

clean:
	rm -f vivado*.jou
	rm -f vivado*.log
	rm -rf $(PROJ_DIR)/*

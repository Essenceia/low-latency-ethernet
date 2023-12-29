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
PROJ_PATH := $(PROJ_DIR)/$(fpga)_$(PROJ)

# Invoke vivado in tcl batch mode
VVD := vivado -mode batch -source

# tcl args
ARGS := -tclargs "$(fpga)" "$(PROJ)" "$(checkpoint)"

$(PROJ_DIR):
	mkdir -p $(PROJ_DIR)

# setup
setup: setup.tcl $(PROJ_DIR)
	$(VVD) $< $(ARGS) 

$(PROJ_PATH): setup
	$(info Set up project with parameters :)
	$(info fpga: $(fpga))
	$(info project: $(PROJ))
	$(info checkpoints: $(checkpoints))
	$(info path to project: $(PROJ_PATH))

clean:
	rm -f vivado*.jou
	rm -f vivado*.log
	rm -rf $(PROJ_DIR)/*

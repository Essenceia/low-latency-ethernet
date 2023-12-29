# Vivado tcl make wrapper

# Device
ifndef fpga
fpga :=xc7a100tfgg484-2
endif

# checkpoint
ifndef checkpoint
checkpoint :=1
endif

# Invoke vivado in tcl batch mode
VVD := vivado -mode batch -source

# tcl args
ARGS := -tclargs "$(fpga) $(checkpoint)"

# setup
setup: setup.tcl
	$(VVD) $< $(ARGS) 

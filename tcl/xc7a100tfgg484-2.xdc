# set main clock property
# periode 1.551 -> 644
create_clock -name "TS_CLK" -period 1.551 [ get_ports clk ]
set_property HD.CLK_SRC BUFGCTRL_X0Y0 [ get_ports clk ]

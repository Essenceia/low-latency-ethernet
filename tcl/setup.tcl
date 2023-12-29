set device $[lindex $argv 0]
set checkpoints $[lindex $argv 1]

puts "device $device"

set rtl_path "../"
set xdc_path ""
set build_path "../build"
set project_name eth_rx_fpga
set path ${build_path}/${device}_${project_name}
set log_path $path
set design eth_rx
create_project $project_name $path -part $device -force 
set_property design_mode RTL [current_fileset -srcset]
set top_module $design
set_property top $top_module [get_property srcset [current_run]] 

# add verilg files
read_verilog -sv $rtl_path/eth_rx.v

# mac
read_verilog -sv ${rtl_mac_dir}/crc.v
read_verilog -sv ${rtl_mac_dir}/mac_rx.v 

#ip
read_verilog -sv ${rtl_ip_dir}/ipv4_rx.v
read_verilog -sv ${rtl_ip_dir}/ip_addr_match.v

#udp
read_verilog -sv ${rtl_udp_dir}/udp_rx.v

#add xdc constraints
read_xdc ${device}.xdc

# synthesis out of context ip
synth_design -mode out_of_context > ${log_path}/${project_name}_synth.rds

if { $checkpoints > 1 }{
	write_checkpoint ${project_name}_synth.dcp
}

# optimize
opt_design > ${log_path}/${project_name}_opt.rds

# place
place_design > ${log_path}/${project_name}_place.rds

# route
route_design > ${log_path}/${project_name}_route.rds

if { $checkpoints > 1 }{
	write_checkpoint ${project_name}_route.dcp
}

# report utilization
report_utilization -file ${log_path}/${project_name}_utilization.rpt

# timming reports
# short summary report
report_timing_summary -file ${log_path}/${project_name}_timing_summary.rpt
# mid sized report with list of 50 worst paths to work on
report_timing -nworst 50 -path_type full -input_pins -file ${log_path}/${project_name}_timing_50_worst.rpt

close_project




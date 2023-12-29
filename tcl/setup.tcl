set device [lindex $argv 0]
set design [lindex $argv 1] 
set checkpoints [lindex $argv 2]
puts "device $device"

set rtl_path "../"
set xdc_path ""
set build_path "../vivado"
set design eth_rx
set project_name $design
set path ${build_path}/${device}_${project_name}
set log_path $path
create_project $project_name $path -part $device -force 
set_property design_mode RTL [current_fileset -srcset]
set top_module $design
set_property top $top_module [get_property srcset [current_run]] 

# add verilg files
read_verilog -sv $rtl_path/eth_rx.v

# mac
set rtl_mac_dir ${rtl_path}/mac
read_verilog -sv ${rtl_mac_dir}/crc.v
read_verilog -sv ${rtl_mac_dir}/mac_rx.v 

#ip
set rtl_ip_dir ${rtl_path}/ipv4
read_verilog -sv ${rtl_ip_dir}/ipv4_rx.v
read_verilog -sv ${rtl_ip_dir}/ip_addr_match.v

#udp
set rtl_udp_dir ${rtl_path}/udp
read_verilog -sv ${rtl_udp_dir}/udp_rx.v

#add xdc constraints
read_xdc ${device}.xdc

# close
close_project




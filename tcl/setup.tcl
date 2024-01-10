set design [lindex $argv 0]
set path [lindex $argv 1]
set create [lindex $argv 2]
set device [lindex $argv 3]

puts "device $device"

set rtl_path "../"
set xdc_path ""
set log_path $path


if {$create == 1} {
	# create project
	puts "Create project\nname : $design\npath : $path\ndevice : $device"
	create_project $design $path -part $device -force
	
	set_property design_mode RTL [current_fileset -srcset]
	set top_module $design
	set_property top $top_module [get_property srcset [current_run]] 
}

# add verilg files
read_verilog -sv ${rtl_path}/eth_rx.v
 
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

if {$create == 1} {
	# close project
	close_project
}

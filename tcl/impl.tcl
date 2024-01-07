set path [lindex $argv 0]
set proj_dir [lindex $argv 1]

# open project
open_project $path

# read synth checkpoint
#read_checkpoint ${proj_dir}/synth_cp.dcp

# opt design
opt_design 

# place
place_design 

# route
route_design

# checkpoint
write_checkpoint ${proj_dir}/impl_cp.dcp

# close project
close_project

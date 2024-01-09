set path [lindex $argv 0]
set proj_dir [lindex $argv 1]

# open project
set res [open_project $path]
puts "res $res"

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

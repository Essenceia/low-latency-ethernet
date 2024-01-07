set path [lindex $argv 0]
set proj_dir [lindex $argv 1]

# open project
open_project $path

# run synth
synth_design -mode out_of_context -fsm_extraction one_hot -directive PerformanceOptimized

# checkpoint
write_checkpoint ${proj_dir}/synth_cp.dcp

# close project
close_project

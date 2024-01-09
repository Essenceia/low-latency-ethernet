set path [lindex $argv 0]
set proj_dir [lindex $argv 1]

# echo path
puts "Opening path $path" 

# open project
open_project $path

puts "\n\n== Synthesis =="

# run synth
synth_design -mode out_of_context -fsm_extraction one_hot -directive PerformanceOptimized

# checkpoint
write_checkpoint -force ${proj_dir}/synth_cp.dcp

# report timing and utilization
report_timing_summary -file $proj_dir/post_synth_timing_summary.rpt
report_utilization -file $proj_dir/post_synth_util.rpt

# opt design
puts "\n\n== Optimize =="
opt_design

puts "\n\n"
# close project
close_project

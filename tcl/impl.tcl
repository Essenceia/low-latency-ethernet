set path [lindex $argv 0]
set proj_dir [lindex $argv 1]

# open checkpoint
open_checkpoint $path

report_utilization -file $proj_dir/impl_util.rpt

# place
puts "\n\n=== Place ==="
place_design 

# route
puts "\n\n=== Route ==="
route_design > $proj_dir/route_log.txt

# reports
report_route_status -file ${proj_dir}/route_status.rpt
report_utilization -file ${proj_dir}/route_util.rpt
report_timing_summary -file ${proj_dir}/route_timing_summary.rpt


# write checkpoint
write_checkpoint -force ${proj_dir}/impl_cp.dcp

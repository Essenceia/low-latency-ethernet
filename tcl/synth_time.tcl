set path [lindex $argv 0]
set proj_dir [lindex $argv 1]
set nworst [lindex $argv 2]
set npath [lindex $argv 3]

# open synth checkpoint
open_checkpoint $path

# full synth timing
puts "\n\n=== Synth timing report ==="
report_timing -delay_type min_max -max_paths $npath -nworst $nworst -path_type full -input_pins \
-file ${proj_dir}/post_synth_timing_nw_${nworst}_np_${npath}.rpt

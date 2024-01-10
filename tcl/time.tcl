# timming reports
set path [lindex $argv 0]
set proj_dir [lindex $argv 1]
set nworst [lindex $argv 2]
set full_report_path [lindex $argv 3]

#open implementation checkpoint
open_checkpoint $path


# short summary report
puts "\n\n=== Timing Summary ==="
report_timing_summary -file ${proj_dir}/timing_summary.rpt

# mid sized report with list of 50 worst paths to work on
puts "\n\n=== Timing Details ==="
report_timing -nworst $nworst -path_type full -input_pins \
-file ${proj_dir}/timing_${nworst}_nworst.rpt



# timming reports
# short summary report
report_timing_summary -file ${log_path}/${project_name}_timing_summary.rpt
# mid sized report with list of 50 worst paths to work on
report_timing -nworst 50 -path_type full -input_pins -file ${log_path}/${project_name}_timing_50_worst.rpt



# Linter script
# Open project
set path [lindex $argv 0]
open_project $path

# lint ( do not have the -lint option like in vivado 2023 in 2020 )
synth_design -rtl -mode out_of_context 

close_project

# run_impl.tcl -- open the project and run synth + impl + bitstream in batch.
#
#   vivado -mode batch -source tcl/run_impl.tcl
#
# Requires tcl/create_project.tcl to have built vivado_proj/ first.

set JOBS 8
set HERE [file normalize [file dirname [info script]]]
set ROOT [file normalize $HERE/..]
set XPR  $ROOT/vivado_proj/kintex_003.xpr

if {![file exists $XPR]} {
  puts "ERROR: $XPR not found -- run tcl/create_project.tcl first."
  exit 1
}
open_project $XPR

reset_run synth_1
launch_runs synth_1 -jobs $JOBS
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
  puts "ERROR: synthesis failed"; exit 1
}

launch_runs impl_1 -to_step write_bitstream -jobs $JOBS
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {
  puts "ERROR: implementation failed"; exit 1
}

set bit [glob -nocomplain [get_property DIRECTORY [get_runs impl_1]]/*.bit]
puts "== DONE: $bit =="

# program.tcl -- program the bitstream onto the XC7K480T over JTAG.
#
#   vivado -mode batch -source tcl/program.tcl                       ;# default .bit
#   vivado -mode batch -source tcl/program.tcl -tclargs <path.bit>
#
# Needs the board powered + a JTAG cable connected (hw_server running, or
# connect_hw_server starts a local one).

set HERE [file normalize [file dirname [info script]]]
set ROOT [file normalize $HERE/..]
set BIT  $ROOT/vivado_proj/kintex_003.runs/impl_1/kintex_003.bit
if {$argc > 0} { set BIT [file normalize [lindex $argv 0]] }

if {![file exists $BIT]} { puts "ERROR: bitstream not found: $BIT"; exit 1 }

open_hw_manager
connect_hw_server
open_hw_target

set dev [lindex [get_hw_devices *xc7k480t*] 0]
if {$dev eq ""} { puts "ERROR: no xc7k480t device on the JTAG chain"; exit 1 }
current_hw_device $dev
refresh_hw_device -update_hw_probes false $dev

set_property PROGRAM.FILE $BIT $dev
set ltx [file rootname $BIT].ltx
if {[file exists $ltx]} { set_property PROBES.FILE $ltx $dev }

program_hw_devices $dev
refresh_hw_device $dev
puts "== programmed $BIT =="
close_hw_target
close_hw_manager

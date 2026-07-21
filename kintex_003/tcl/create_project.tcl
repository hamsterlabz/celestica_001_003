# create_project.tcl -- build the Vivado project (.xpr) in batch.
#
#   vivado -mode batch -source tcl/create_project.tcl
#
# Creates vivado_proj/kintex_003.xpr with the four IPs the top instantiates:
#   xdma_003    PCIe Gen2 x8 XDMA, configured like the board example project
#   mig_003     dual-controller DDR3 MIG from the board's mig_01.prj
#   axi_cc_003  AXI clock converter (XDMA 250 MHz -> MIG CH0 ui_clk)
#   axi_up_003  AXI data-width converter (128 -> 512 bit)
# Board data comes from the enclosing board repository (BOARD below).

set PART  xc7k480tffg1156-2
set NAME  kintex_003
set HERE  [file normalize [file dirname [info script]]]
set ROOT  [file normalize $HERE/..]
set BOARD [file normalize $ROOT/..]
set PROJ  $ROOT/vivado_proj

file delete -force $PROJ
create_project $NAME $PROJ -part $PART -force

# ---------- design sources ----------
add_files -norecurse [list $ROOT/src/kintex_003.v]
set_property top kintex_003 [current_fileset]

# ---------- IP: PCIe XDMA (config = examples/YPCB_00338_1P1_systest xdma_0) ----
create_ip -name xdma -vendor xilinx.com -library ip -module_name xdma_003
set_property -dict [list \
  CONFIG.functional_mode            {DMA} \
  CONFIG.mode_selection             {Basic} \
  CONFIG.pcie_blk_locn              {X0Y0} \
  CONFIG.pl_link_cap_max_link_width {X8} \
  CONFIG.pl_link_cap_max_link_speed {5.0_GT/s} \
  CONFIG.ref_clk_freq               {100_MHz} \
  CONFIG.axi_data_width             {128_bit} \
  CONFIG.axisten_freq               {250} \
  CONFIG.axi_addr_width             {64} \
  CONFIG.dedicate_perst             {true} \
  CONFIG.pf0_device_id              {7028} \
] [get_ips xdma_003]

# ---------- IP: DDR3 MIG (board dual-controller project file) ----------
# MIG requires the prj's ModuleName to match the IP instance name -> patch a copy.
set fh  [open $BOARD/ypcb003381p1/1.0/mig_01.prj r]
set prj [read $fh]
close $fh
regsub {<ModuleName>[^<]*</ModuleName>} $prj {<ModuleName>mig_003</ModuleName>} prj
set fh [open $PROJ/mig_003.prj w]
puts -nonewline $fh $prj
close $fh

create_ip -name mig_7series -vendor xilinx.com -library ip -module_name mig_003
set_property CONFIG.XML_INPUT_FILE $PROJ/mig_003.prj [get_ips mig_003]

# ---------- IP: AXI clock converter (250 MHz <-> CH0 ui_clk, async) ----------
create_ip -name axi_clock_converter -vendor xilinx.com -library ip \
  -module_name axi_cc_003
set_property -dict [list \
  CONFIG.PROTOCOL   {AXI4} \
  CONFIG.DATA_WIDTH {128} \
  CONFIG.ADDR_WIDTH {32} \
  CONFIG.ID_WIDTH   {4} \
  CONFIG.ACLK_ASYNC {1} \
] [get_ips axi_cc_003]

# ---------- IP: AXI data-width converter (128 -> 512) ----------
create_ip -name axi_dwidth_converter -vendor xilinx.com -library ip \
  -module_name axi_up_003
set_property -dict [list \
  CONFIG.PROTOCOL      {AXI4} \
  CONFIG.SI_DATA_WIDTH {128} \
  CONFIG.MI_DATA_WIDTH {512} \
  CONFIG.ADDR_WIDTH    {32} \
  CONFIG.SI_ID_WIDTH   {4} \
] [get_ips axi_up_003]

generate_target all [get_ips]

# ---------- constraints ----------
add_files -fileset constrs_1 -norecurse $ROOT/constraints/kintex_003.xdc

update_compile_order -fileset sources_1
puts "== project: $PROJ/$NAME.xpr =="

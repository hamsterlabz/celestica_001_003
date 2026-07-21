# kintex_003.xdc -- YPCB-00338-1P1 (Celestica) board pinout for kintex_003.v
#
# Derived from the board reverse-engineering data in this repository:
#   constraints/ypcb003381p1.xdc + ypcb003381p1/1.0/part0_pins.xml.
# Part: xc7k480tffg1156-2. All single-ended IO on this board is LVCMOS18.
#
# NOT in this file (owned by the generated IP):
#   * DDR3 pins + the two 200 MHz DDR3 system clocks (AH27/AH28, G25/G26) --
#     constrained by the MIG core generated from mig_003.prj (board mig_01.prj).
#   * PCIe block location (X0Y0) -- constrained by the XDMA core.

###################### Bitstream / config ######################
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

###################### Clock / reset ######################
set_property PACKAGE_PIN AA28 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS18 [get_ports sys_clk]
create_clock -period 20.000 -name sys_clk [get_ports sys_clk]

set_property PACKAGE_PIN R28 [get_ports sys_rstn]
set_property IOSTANDARD LVCMOS18 [get_ports sys_rstn]
set_false_path -from [get_ports sys_rstn]

###################### User LEDs ######################
set_property PACKAGE_PIN P30 [get_ports {led[0]}]
set_property PACKAGE_PIN M30 [get_ports {led[1]}]
set_property PACKAGE_PIN N30 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[*]}]

###################### PCI Express ######################
# 100 MHz reference clock (GTXE2 quad, dedicated refclk pair)
set_property PACKAGE_PIN J8 [get_ports pcie_refclk_p]
set_property PACKAGE_PIN J7 [get_ports pcie_refclk_n]
create_clock -period 10.000 -name pcie_refclk [get_ports pcie_refclk_p]

# PERST# from the edge connector
set_property PACKAGE_PIN Y26 [get_ports pcie_perstn]
set_property IOSTANDARD LVCMOS18 [get_ports pcie_perstn]
set_property PULLUP true [get_ports pcie_perstn]
set_false_path -from [get_ports pcie_perstn]

# x8 lanes
set_property PACKAGE_PIN F2 [get_ports {pci_exp_txp[0]}]
set_property PACKAGE_PIN F1 [get_ports {pci_exp_txn[0]}]
set_property PACKAGE_PIN H2 [get_ports {pci_exp_txp[1]}]
set_property PACKAGE_PIN H1 [get_ports {pci_exp_txn[1]}]
set_property PACKAGE_PIN K2 [get_ports {pci_exp_txp[2]}]
set_property PACKAGE_PIN K1 [get_ports {pci_exp_txn[2]}]
set_property PACKAGE_PIN M2 [get_ports {pci_exp_txp[3]}]
set_property PACKAGE_PIN M1 [get_ports {pci_exp_txn[3]}]
set_property PACKAGE_PIN N4 [get_ports {pci_exp_txp[4]}]
set_property PACKAGE_PIN N3 [get_ports {pci_exp_txn[4]}]
set_property PACKAGE_PIN P2 [get_ports {pci_exp_txp[5]}]
set_property PACKAGE_PIN P1 [get_ports {pci_exp_txn[5]}]
set_property PACKAGE_PIN T2 [get_ports {pci_exp_txp[6]}]
set_property PACKAGE_PIN T1 [get_ports {pci_exp_txn[6]}]
set_property PACKAGE_PIN U4 [get_ports {pci_exp_txp[7]}]
set_property PACKAGE_PIN U3 [get_ports {pci_exp_txn[7]}]
set_property PACKAGE_PIN H6 [get_ports {pci_exp_rxp[0]}]
set_property PACKAGE_PIN H5 [get_ports {pci_exp_rxn[0]}]
set_property PACKAGE_PIN J4 [get_ports {pci_exp_rxp[1]}]
set_property PACKAGE_PIN J3 [get_ports {pci_exp_rxn[1]}]
set_property PACKAGE_PIN K6 [get_ports {pci_exp_rxp[2]}]
set_property PACKAGE_PIN K5 [get_ports {pci_exp_rxn[2]}]
set_property PACKAGE_PIN L4 [get_ports {pci_exp_rxp[3]}]
set_property PACKAGE_PIN L3 [get_ports {pci_exp_rxn[3]}]
set_property PACKAGE_PIN M6 [get_ports {pci_exp_rxp[4]}]
set_property PACKAGE_PIN M5 [get_ports {pci_exp_rxn[4]}]
set_property PACKAGE_PIN P6 [get_ports {pci_exp_rxp[5]}]
set_property PACKAGE_PIN P5 [get_ports {pci_exp_rxn[5]}]
set_property PACKAGE_PIN R4 [get_ports {pci_exp_rxp[6]}]
set_property PACKAGE_PIN R3 [get_ports {pci_exp_rxn[6]}]
set_property PACKAGE_PIN T6 [get_ports {pci_exp_rxp[7]}]
set_property PACKAGE_PIN T5 [get_ports {pci_exp_rxn[7]}]

###################### LM73 temperature sensor ######################
set_property PACKAGE_PIN P25 [get_ports alert_lm73]
set_property PACKAGE_PIN N24 [get_ports iic_lm73_scl]
set_property PACKAGE_PIN N25 [get_ports iic_lm73_sda]
set_property IOSTANDARD LVCMOS18 [get_ports {alert_lm73 iic_lm73_scl iic_lm73_sda}]

###################### PCIe SMBus ######################
set_property PACKAGE_PIN R26 [get_ports iic_pcie_scl]
set_property PACKAGE_PIN R27 [get_ports iic_pcie_sda]
set_property IOSTANDARD LVCMOS18 [get_ports {iic_pcie_scl iic_pcie_sda}]

###################### BPI linear flash (MT28GU512AAA, held idle) ######################
set_property PACKAGE_PIN AD26 [get_ports {bpi_flash_addr[1]}]
set_property PACKAGE_PIN AC25 [get_ports {bpi_flash_addr[2]}]
set_property PACKAGE_PIN AC29 [get_ports {bpi_flash_addr[3]}]
set_property PACKAGE_PIN AC28 [get_ports {bpi_flash_addr[4]}]
set_property PACKAGE_PIN AD27 [get_ports {bpi_flash_addr[5]}]
set_property PACKAGE_PIN AC27 [get_ports {bpi_flash_addr[6]}]
set_property PACKAGE_PIN AB25 [get_ports {bpi_flash_addr[7]}]
set_property PACKAGE_PIN AB28 [get_ports {bpi_flash_addr[8]}]
set_property PACKAGE_PIN AB27 [get_ports {bpi_flash_addr[9]}]
set_property PACKAGE_PIN AB26 [get_ports {bpi_flash_addr[10]}]
set_property PACKAGE_PIN AA26 [get_ports {bpi_flash_addr[11]}]
set_property PACKAGE_PIN AA31 [get_ports {bpi_flash_addr[12]}]
set_property PACKAGE_PIN AA30 [get_ports {bpi_flash_addr[13]}]
set_property PACKAGE_PIN AB33 [get_ports {bpi_flash_addr[14]}]
set_property PACKAGE_PIN AB32 [get_ports {bpi_flash_addr[15]}]
set_property PACKAGE_PIN Y32 [get_ports {bpi_flash_addr[16]}]
set_property PACKAGE_PIN P32 [get_ports {bpi_flash_addr[17]}]
set_property PACKAGE_PIN R32 [get_ports {bpi_flash_addr[18]}]
set_property PACKAGE_PIN U33 [get_ports {bpi_flash_addr[19]}]
set_property PACKAGE_PIN T31 [get_ports {bpi_flash_addr[20]}]
set_property PACKAGE_PIN T30 [get_ports {bpi_flash_addr[21]}]
set_property PACKAGE_PIN U31 [get_ports {bpi_flash_addr[22]}]
set_property PACKAGE_PIN U30 [get_ports {bpi_flash_addr[23]}]
set_property PACKAGE_PIN N34 [get_ports {bpi_flash_addr[24]}]
set_property PACKAGE_PIN P34 [get_ports {bpi_flash_addr[25]}]
set_property PACKAGE_PIN AA33 [get_ports {bpi_flash_dq[0]}]
set_property PACKAGE_PIN AA34 [get_ports {bpi_flash_dq[1]}]
set_property PACKAGE_PIN Y33 [get_ports {bpi_flash_dq[2]}]
set_property PACKAGE_PIN Y34 [get_ports {bpi_flash_dq[3]}]
set_property PACKAGE_PIN V32 [get_ports {bpi_flash_dq[4]}]
set_property PACKAGE_PIN V33 [get_ports {bpi_flash_dq[5]}]
set_property PACKAGE_PIN W31 [get_ports {bpi_flash_dq[6]}]
set_property PACKAGE_PIN W32 [get_ports {bpi_flash_dq[7]}]
set_property PACKAGE_PIN W30 [get_ports {bpi_flash_dq[8]}]
set_property PACKAGE_PIN V25 [get_ports {bpi_flash_dq[9]}]
set_property PACKAGE_PIN W25 [get_ports {bpi_flash_dq[10]}]
set_property PACKAGE_PIN V29 [get_ports {bpi_flash_dq[11]}]
set_property PACKAGE_PIN W29 [get_ports {bpi_flash_dq[12]}]
set_property PACKAGE_PIN V28 [get_ports {bpi_flash_dq[13]}]
set_property PACKAGE_PIN W24 [get_ports {bpi_flash_dq[14]}]
set_property PACKAGE_PIN Y24 [get_ports {bpi_flash_dq[15]}]
set_property PACKAGE_PIN V30 [get_ports bpi_flash_ce_n]
set_property PACKAGE_PIN T33 [get_ports bpi_flash_oen]
set_property PACKAGE_PIN T34 [get_ports bpi_flash_wen]
set_property PACKAGE_PIN M31 [get_ports bpi_flash_adv_ldn]
set_property IOSTANDARD LVCMOS18 [get_ports {bpi_flash_addr[*] bpi_flash_dq[*] bpi_flash_ce_n bpi_flash_oen bpi_flash_wen bpi_flash_adv_ldn}]

// kintex_003 -- YPCB-00338-1P1 (Celestica) BOARD TOP.
//
// Board data: this repository (XC7K480T FFG1156-2 accelerator card).
// This is the only module allowed to hold Xilinx IP / primitives:
//   * xdma_003    -- PCIe Gen2 x8 XDMA (DMA/Basic, X0Y0, AXI4-MM 128 bit @ 250 MHz),
//                    configured exactly like the board example project
//                    (examples/YPCB_00338_1P1_systest, top_xdma_0_0)
//   * mig_003     -- dual-controller DDR3 MIG from the board's mig_01.prj:
//                    2 x 72-bit ECC @ 1066 MT/s, AXI 512 bit, per-channel 200 MHz
//                    differential system clocks (CH0 AH27/AH28, CH1 G25/G26)
//   * axi_cc_003  -- AXI clock converter, XDMA 250 MHz -> MIG CH0 ui_clk (133 MHz)
//   * axi_up_003  -- AXI data-width converter, 128 -> 512 bit
//   * IBUFDS_GTE2 -- PCIe 100 MHz reference clock buffer (J8/J7)
//
// Data path: host PCIe <-> XDMA <-> clock conv <-> upsizer <-> DDR3 CH0.
// DDR3 CH1 is brought up (calibrates, LED) but its AXI port is tied off -- that
// seam is where the SoC plugs in later.
//
// All board peripherals are declared as ports (constraints/kintex_003.xdc); the
// ones not used are tied off below (BPI flash idle, I2C released).

`default_nettype none

module kintex_003 (
  // ---- core / control ----
  input  wire        sys_clk,      // 50 MHz, AA28
  input  wire        sys_rstn,     // R28, active low
  // ---- user LEDs (P30 M30 N30) ----
  output wire [2:0]  led,
  // ---- PCIe Gen2 x8 ----
  input  wire        pcie_refclk_p,        // J8
  input  wire        pcie_refclk_n,        // J7
  input  wire        pcie_perstn,          // Y26
  output wire [7:0]  pci_exp_txp,
  output wire [7:0]  pci_exp_txn,
  input  wire [7:0]  pci_exp_rxp,
  input  wire [7:0]  pci_exp_rxn,
  // ---- DDR3 channel 0 (bank 12, sys clk AH27/AH28; pins owned by the MIG) ----
  input  wire        c0_sys_clk_p,
  input  wire        c0_sys_clk_n,
  output wire [14:0] c0_ddr3_addr,
  output wire [2:0]  c0_ddr3_ba,
  output wire        c0_ddr3_ras_n,
  output wire        c0_ddr3_cas_n,
  output wire        c0_ddr3_we_n,
  output wire        c0_ddr3_reset_n,
  output wire [0:0]  c0_ddr3_ck_p,
  output wire [0:0]  c0_ddr3_ck_n,
  output wire [0:0]  c0_ddr3_cke,
  output wire [0:0]  c0_ddr3_cs_n,
  output wire [0:0]  c0_ddr3_odt,
  inout  wire [71:0] c0_ddr3_dq,
  inout  wire [8:0]  c0_ddr3_dqs_p,
  inout  wire [8:0]  c0_ddr3_dqs_n,
  // ---- DDR3 channel 1 (bank 17, sys clk G25/G26; pins owned by the MIG) ----
  input  wire        c1_sys_clk_p,
  input  wire        c1_sys_clk_n,
  output wire [14:0] c1_ddr3_addr,
  output wire [2:0]  c1_ddr3_ba,
  output wire        c1_ddr3_ras_n,
  output wire        c1_ddr3_cas_n,
  output wire        c1_ddr3_we_n,
  output wire        c1_ddr3_reset_n,
  output wire [0:0]  c1_ddr3_ck_p,
  output wire [0:0]  c1_ddr3_ck_n,
  output wire [0:0]  c1_ddr3_cke,
  output wire [0:0]  c1_ddr3_cs_n,
  output wire [0:0]  c1_ddr3_odt,
  inout  wire [71:0] c1_ddr3_dq,
  inout  wire [8:0]  c1_ddr3_dqs_p,
  inout  wire [8:0]  c1_ddr3_dqs_n,
  // ---- LM73 temperature sensor I2C (unused) ----
  inout  wire        iic_lm73_scl,     // N24
  inout  wire        iic_lm73_sda,     // N25
  input  wire        alert_lm73,       // P25
  // ---- PCIe SMBus (unused) ----
  inout  wire        iic_pcie_scl,     // R26
  inout  wire        iic_pcie_sda,     // R27
  // ---- BPI linear flash, MT28GU512AAA (unused, held idle) ----
  output wire [25:1] bpi_flash_addr,
  inout  wire [15:0] bpi_flash_dq,
  output wire        bpi_flash_ce_n,   // V30
  output wire        bpi_flash_oen,    // T33
  output wire        bpi_flash_wen,    // T34
  output wire        bpi_flash_adv_ldn // M31
);

  // ===== Xilinx primitive: PCIe reference clock buffer ========================
  wire pcie_refclk;
  IBUFDS_GTE2 u_refclk (
    .I    (pcie_refclk_p),
    .IB   (pcie_refclk_n),
    .CEB  (1'b0),
    .O    (pcie_refclk),
    .ODIV2()
  );

  // ---- XDMA M_AXI, 128 bit @ axi_aclk (250 MHz) ------------------------------
  wire         axi_aclk, axi_aresetn, user_lnk_up;
  wire [3:0]   xm_awid,   xm_arid;
  wire [3:0]   xm_bid,    xm_rid;
  wire [63:0]  xm_awaddr, xm_araddr;
  wire [7:0]   xm_awlen,  xm_arlen;
  wire [2:0]   xm_awsize, xm_arsize;
  wire [1:0]   xm_awburst, xm_arburst;
  wire [2:0]   xm_awprot, xm_arprot;
  wire         xm_awlock, xm_arlock;
  wire [3:0]   xm_awcache, xm_arcache;
  wire         xm_awvalid, xm_awready, xm_arvalid, xm_arready;
  wire [127:0] xm_wdata,  xm_rdata;
  wire [15:0]  xm_wstrb;
  wire         xm_wlast, xm_wvalid, xm_wready;
  wire         xm_rlast, xm_rvalid, xm_rready;
  wire [1:0]   xm_bresp, xm_rresp;
  wire         xm_bvalid, xm_bready;

  // ===== Xilinx IP: PCIe XDMA (as in the board example project) ===============
  xdma_003 u_xdma (
    .sys_clk        (pcie_refclk),
    .sys_rst_n      (pcie_perstn),
    .pci_exp_txp    (pci_exp_txp),
    .pci_exp_txn    (pci_exp_txn),
    .pci_exp_rxp    (pci_exp_rxp),
    .pci_exp_rxn    (pci_exp_rxn),
    .user_lnk_up    (user_lnk_up),
    .axi_aclk       (axi_aclk),
    .axi_aresetn    (axi_aresetn),
    .usr_irq_req    (1'b0),
    .usr_irq_ack    (),
    .msi_enable     (),
    .msi_vector_width(),
    // PCIe configuration-management port, unused
    .cfg_mgmt_addr        (19'b0),
    .cfg_mgmt_write       (1'b0),
    .cfg_mgmt_write_data  (32'b0),
    .cfg_mgmt_byte_enable (4'b0),
    .cfg_mgmt_read        (1'b0),
    .cfg_mgmt_read_data   (),
    .cfg_mgmt_read_write_done(),
    .cfg_mgmt_type1_cfg_reg_access(1'b0),
    // M_AXI (host DMA master)
    .m_axi_awid     (xm_awid),
    .m_axi_awaddr   (xm_awaddr),
    .m_axi_awlen    (xm_awlen),
    .m_axi_awsize   (xm_awsize),
    .m_axi_awburst  (xm_awburst),
    .m_axi_awprot   (xm_awprot),
    .m_axi_awlock   (xm_awlock),
    .m_axi_awcache  (xm_awcache),
    .m_axi_awvalid  (xm_awvalid),
    .m_axi_awready  (xm_awready),
    .m_axi_wdata    (xm_wdata),
    .m_axi_wstrb    (xm_wstrb),
    .m_axi_wlast    (xm_wlast),
    .m_axi_wvalid   (xm_wvalid),
    .m_axi_wready   (xm_wready),
    .m_axi_bid      (xm_bid),
    .m_axi_bresp    (xm_bresp),
    .m_axi_bvalid   (xm_bvalid),
    .m_axi_bready   (xm_bready),
    .m_axi_arid     (xm_arid),
    .m_axi_araddr   (xm_araddr),
    .m_axi_arlen    (xm_arlen),
    .m_axi_arsize   (xm_arsize),
    .m_axi_arburst  (xm_arburst),
    .m_axi_arprot   (xm_arprot),
    .m_axi_arlock   (xm_arlock),
    .m_axi_arcache  (xm_arcache),
    .m_axi_arvalid  (xm_arvalid),
    .m_axi_arready  (xm_arready),
    .m_axi_rid      (xm_rid),
    .m_axi_rdata    (xm_rdata),
    .m_axi_rresp    (xm_rresp),
    .m_axi_rlast    (xm_rlast),
    .m_axi_rvalid   (xm_rvalid),
    .m_axi_rready   (xm_rready)
  );

  // ---- MIG user-side clocks / resets -----------------------------------------
  wire c0_ui_clk, c0_ui_clk_sync_rst, c0_mmcm_locked, c0_init_calib_complete;
  wire c1_ui_clk, c1_ui_clk_sync_rst, c1_mmcm_locked, c1_init_calib_complete;
  wire c0_axi_rstn = ~c0_ui_clk_sync_rst;
  wire c1_axi_rstn = ~c1_ui_clk_sync_rst;

  // ---- XDMA M_AXI moved to the CH0 ui_clk domain, still 128 bit --------------
  wire [3:0]   cm_awid,   cm_arid;
  wire [3:0]   cm_bid,    cm_rid;
  wire [63:0]  cm_awaddr, cm_araddr;
  wire [7:0]   cm_awlen,  cm_arlen;
  wire [2:0]   cm_awsize, cm_arsize;
  wire [1:0]   cm_awburst, cm_arburst;
  wire [2:0]   cm_awprot, cm_arprot;
  wire [0:0]   cm_awlock, cm_arlock;
  wire [3:0]   cm_awcache, cm_arcache;
  wire [3:0]   cm_awqos,  cm_arqos;
  wire [3:0]   cm_awregion, cm_arregion;
  wire         cm_awvalid, cm_awready, cm_arvalid, cm_arready;
  wire [127:0] cm_wdata,  cm_rdata;
  wire [15:0]  cm_wstrb;
  wire         cm_wlast, cm_wvalid, cm_wready;
  wire         cm_rlast, cm_rvalid, cm_rready;
  wire [1:0]   cm_bresp, cm_rresp;
  wire         cm_bvalid, cm_bready;

  // ===== Xilinx IP: AXI clock converter (250 MHz -> CH0 ui_clk) ===============
  axi_cc_003 u_axi_cc (
    .s_axi_aclk     (axi_aclk),
    .s_axi_aresetn  (axi_aresetn),
    .s_axi_awid     (xm_awid),
    .s_axi_awaddr   (xm_awaddr[31:0]),
    .s_axi_awlen    (xm_awlen),
    .s_axi_awsize   (xm_awsize),
    .s_axi_awburst  (xm_awburst),
    .s_axi_awlock   (xm_awlock),
    .s_axi_awcache  (xm_awcache),
    .s_axi_awprot   (xm_awprot),
    .s_axi_awqos    (4'b0),
    .s_axi_awregion (4'b0),
    .s_axi_awvalid  (xm_awvalid),
    .s_axi_awready  (xm_awready),
    .s_axi_wdata    (xm_wdata),
    .s_axi_wstrb    (xm_wstrb),
    .s_axi_wlast    (xm_wlast),
    .s_axi_wvalid   (xm_wvalid),
    .s_axi_wready   (xm_wready),
    .s_axi_bid      (xm_bid),
    .s_axi_bresp    (xm_bresp),
    .s_axi_bvalid   (xm_bvalid),
    .s_axi_bready   (xm_bready),
    .s_axi_arid     (xm_arid),
    .s_axi_araddr   (xm_araddr[31:0]),
    .s_axi_arlen    (xm_arlen),
    .s_axi_arsize   (xm_arsize),
    .s_axi_arburst  (xm_arburst),
    .s_axi_arlock   (xm_arlock),
    .s_axi_arcache  (xm_arcache),
    .s_axi_arprot   (xm_arprot),
    .s_axi_arqos    (4'b0),
    .s_axi_arregion (4'b0),
    .s_axi_arvalid  (xm_arvalid),
    .s_axi_arready  (xm_arready),
    .s_axi_rid      (xm_rid),
    .s_axi_rdata    (xm_rdata),
    .s_axi_rresp    (xm_rresp),
    .s_axi_rlast    (xm_rlast),
    .s_axi_rvalid   (xm_rvalid),
    .s_axi_rready   (xm_rready),
    .m_axi_aclk     (c0_ui_clk),
    .m_axi_aresetn  (c0_axi_rstn),
    .m_axi_awid     (cm_awid),
    .m_axi_awaddr   (cm_awaddr[31:0]),
    .m_axi_awlen    (cm_awlen),
    .m_axi_awsize   (cm_awsize),
    .m_axi_awburst  (cm_awburst),
    .m_axi_awlock   (cm_awlock),
    .m_axi_awcache  (cm_awcache),
    .m_axi_awprot   (cm_awprot),
    .m_axi_awqos    (cm_awqos),
    .m_axi_awregion (cm_awregion),
    .m_axi_awvalid  (cm_awvalid),
    .m_axi_awready  (cm_awready),
    .m_axi_wdata    (cm_wdata),
    .m_axi_wstrb    (cm_wstrb),
    .m_axi_wlast    (cm_wlast),
    .m_axi_wvalid   (cm_wvalid),
    .m_axi_wready   (cm_wready),
    .m_axi_bid      (cm_bid),
    .m_axi_bresp    (cm_bresp),
    .m_axi_bvalid   (cm_bvalid),
    .m_axi_bready   (cm_bready),
    .m_axi_arid     (cm_arid),
    .m_axi_araddr   (cm_araddr[31:0]),
    .m_axi_arlen    (cm_arlen),
    .m_axi_arsize   (cm_arsize),
    .m_axi_arburst  (cm_arburst),
    .m_axi_arlock   (cm_arlock),
    .m_axi_arcache  (cm_arcache),
    .m_axi_arprot   (cm_arprot),
    .m_axi_arqos    (cm_arqos),
    .m_axi_arregion (cm_arregion),
    .m_axi_arvalid  (cm_arvalid),
    .m_axi_arready  (cm_arready),
    .m_axi_rid      (cm_rid),
    .m_axi_rdata    (cm_rdata),
    .m_axi_rresp    (cm_rresp),
    .m_axi_rlast    (cm_rlast),
    .m_axi_rvalid   (cm_rvalid),
    .m_axi_rready   (cm_rready)
  );
  assign cm_awaddr[63:32] = 32'b0;
  assign cm_araddr[63:32] = 32'b0;

  // ---- upsized 512-bit AXI into MIG CH0 --------------------------------------
  wire [31:0]  um_awaddr, um_araddr;
  wire [7:0]   um_awlen,  um_arlen;
  wire [2:0]   um_awsize, um_arsize;
  wire [1:0]   um_awburst, um_arburst;
  wire [0:0]   um_awlock, um_arlock;
  wire [3:0]   um_awcache, um_arcache;
  wire [2:0]   um_awprot, um_arprot;
  wire [3:0]   um_awqos,  um_arqos;
  wire [3:0]   um_awregion, um_arregion;
  wire         um_awvalid, um_awready, um_arvalid, um_arready;
  wire [511:0] um_wdata,  um_rdata;
  wire [63:0]  um_wstrb;
  wire         um_wlast, um_wvalid, um_wready;
  wire         um_rlast, um_rvalid, um_rready;
  wire [1:0]   um_bresp, um_rresp;
  wire         um_bvalid, um_bready;

  // ===== Xilinx IP: AXI data-width converter (128 -> 512 bit) =================
  axi_up_003 u_axi_up (
    .s_axi_aclk     (c0_ui_clk),
    .s_axi_aresetn  (c0_axi_rstn),
    .s_axi_awid     (cm_awid),
    .s_axi_awaddr   (cm_awaddr[31:0]),
    .s_axi_awlen    (cm_awlen),
    .s_axi_awsize   (cm_awsize),
    .s_axi_awburst  (cm_awburst),
    .s_axi_awlock   (cm_awlock),
    .s_axi_awcache  (cm_awcache),
    .s_axi_awprot   (cm_awprot),
    .s_axi_awqos    (cm_awqos),
    .s_axi_awregion (cm_awregion),
    .s_axi_awvalid  (cm_awvalid),
    .s_axi_awready  (cm_awready),
    .s_axi_wdata    (cm_wdata),
    .s_axi_wstrb    (cm_wstrb),
    .s_axi_wlast    (cm_wlast),
    .s_axi_wvalid   (cm_wvalid),
    .s_axi_wready   (cm_wready),
    .s_axi_bid      (cm_bid),
    .s_axi_bresp    (cm_bresp),
    .s_axi_bvalid   (cm_bvalid),
    .s_axi_bready   (cm_bready),
    .s_axi_arid     (cm_arid),
    .s_axi_araddr   (cm_araddr[31:0]),
    .s_axi_arlen    (cm_arlen),
    .s_axi_arsize   (cm_arsize),
    .s_axi_arburst  (cm_arburst),
    .s_axi_arlock   (cm_arlock),
    .s_axi_arcache  (cm_arcache),
    .s_axi_arprot   (cm_arprot),
    .s_axi_arqos    (cm_arqos),
    .s_axi_arregion (cm_arregion),
    .s_axi_arvalid  (cm_arvalid),
    .s_axi_arready  (cm_arready),
    .s_axi_rid      (cm_rid),
    .s_axi_rdata    (cm_rdata),
    .s_axi_rresp    (cm_rresp),
    .s_axi_rlast    (cm_rlast),
    .s_axi_rvalid   (cm_rvalid),
    .s_axi_rready   (cm_rready),
    .m_axi_awaddr   (um_awaddr),
    .m_axi_awlen    (um_awlen),
    .m_axi_awsize   (um_awsize),
    .m_axi_awburst  (um_awburst),
    .m_axi_awlock   (um_awlock),
    .m_axi_awcache  (um_awcache),
    .m_axi_awprot   (um_awprot),
    .m_axi_awqos    (um_awqos),
    .m_axi_awregion (um_awregion),
    .m_axi_awvalid  (um_awvalid),
    .m_axi_awready  (um_awready),
    .m_axi_wdata    (um_wdata),
    .m_axi_wstrb    (um_wstrb),
    .m_axi_wlast    (um_wlast),
    .m_axi_wvalid   (um_wvalid),
    .m_axi_wready   (um_wready),
    .m_axi_bresp    (um_bresp),
    .m_axi_bvalid   (um_bvalid),
    .m_axi_bready   (um_bready),
    .m_axi_araddr   (um_araddr),
    .m_axi_arlen    (um_arlen),
    .m_axi_arsize   (um_arsize),
    .m_axi_arburst  (um_arburst),
    .m_axi_arlock   (um_arlock),
    .m_axi_arcache  (um_arcache),
    .m_axi_arprot   (um_arprot),
    .m_axi_arqos    (um_arqos),
    .m_axi_arregion (um_arregion),
    .m_axi_arvalid  (um_arvalid),
    .m_axi_arready  (um_arready),
    .m_axi_rdata    (um_rdata),
    .m_axi_rresp    (um_rresp),
    .m_axi_rlast    (um_rlast),
    .m_axi_rvalid   (um_rvalid),
    .m_axi_rready   (um_rready)
  );

  // ===== Xilinx IP: dual-controller DDR3 MIG (board mig_01.prj) ===============
  // CH0 serves the PCIe DMA path; CH1 calibrates but its AXI port is the seam
  // reserved for the SoC (tied off until then).
  mig_003 u_mig (
    // controller 0 -- DDR3 pins
    .c0_ddr3_addr           (c0_ddr3_addr),
    .c0_ddr3_ba             (c0_ddr3_ba),
    .c0_ddr3_ras_n          (c0_ddr3_ras_n),
    .c0_ddr3_cas_n          (c0_ddr3_cas_n),
    .c0_ddr3_we_n           (c0_ddr3_we_n),
    .c0_ddr3_reset_n        (c0_ddr3_reset_n),
    .c0_ddr3_ck_p           (c0_ddr3_ck_p),
    .c0_ddr3_ck_n           (c0_ddr3_ck_n),
    .c0_ddr3_cke            (c0_ddr3_cke),
    .c0_ddr3_cs_n           (c0_ddr3_cs_n),
    .c0_ddr3_odt            (c0_ddr3_odt),
    .c0_ddr3_dq             (c0_ddr3_dq),
    .c0_ddr3_dqs_p          (c0_ddr3_dqs_p),
    .c0_ddr3_dqs_n          (c0_ddr3_dqs_n),
    .c0_sys_clk_p           (c0_sys_clk_p),
    .c0_sys_clk_n           (c0_sys_clk_n),
    // controller 0 -- user side
    .c0_ui_clk              (c0_ui_clk),
    .c0_ui_clk_sync_rst     (c0_ui_clk_sync_rst),
    .c0_mmcm_locked         (c0_mmcm_locked),
    .c0_init_calib_complete (c0_init_calib_complete),
    .c0_aresetn             (c0_axi_rstn),
    .c0_app_sr_req          (1'b0),
    .c0_app_ref_req         (1'b0),
    .c0_app_zq_req          (1'b0),
    .c0_app_sr_active       (),
    .c0_app_ref_ack         (),
    .c0_app_zq_ack          (),
    // controller 0 -- AXI slave (512 bit)
    .c0_s_axi_awid          (4'b0),
    .c0_s_axi_awaddr        (um_awaddr[30:0]),
    .c0_s_axi_awlen         (um_awlen),
    .c0_s_axi_awsize        (um_awsize),
    .c0_s_axi_awburst       (um_awburst),
    .c0_s_axi_awlock        (um_awlock),
    .c0_s_axi_awcache       (um_awcache),
    .c0_s_axi_awprot        (um_awprot),
    .c0_s_axi_awqos         (um_awqos),
    .c0_s_axi_awvalid       (um_awvalid),
    .c0_s_axi_awready       (um_awready),
    .c0_s_axi_wdata         (um_wdata),
    .c0_s_axi_wstrb         (um_wstrb),
    .c0_s_axi_wlast         (um_wlast),
    .c0_s_axi_wvalid        (um_wvalid),
    .c0_s_axi_wready        (um_wready),
    .c0_s_axi_bid           (),
    .c0_s_axi_bresp         (um_bresp),
    .c0_s_axi_bvalid        (um_bvalid),
    .c0_s_axi_bready        (um_bready),
    .c0_s_axi_arid          (4'b0),
    .c0_s_axi_araddr        (um_araddr[30:0]),
    .c0_s_axi_arlen         (um_arlen),
    .c0_s_axi_arsize        (um_arsize),
    .c0_s_axi_arburst       (um_arburst),
    .c0_s_axi_arlock        (um_arlock),
    .c0_s_axi_arcache       (um_arcache),
    .c0_s_axi_arprot        (um_arprot),
    .c0_s_axi_arqos         (um_arqos),
    .c0_s_axi_arvalid       (um_arvalid),
    .c0_s_axi_arready       (um_arready),
    .c0_s_axi_rid           (),
    .c0_s_axi_rdata         (um_rdata),
    .c0_s_axi_rresp         (um_rresp),
    .c0_s_axi_rlast         (um_rlast),
    .c0_s_axi_rvalid        (um_rvalid),
    .c0_s_axi_rready        (um_rready),
    // controller 0 -- ECC control AXI-Lite, unused
    .c0_s_axi_ctrl_awvalid  (1'b0),
    .c0_s_axi_ctrl_awready  (),
    .c0_s_axi_ctrl_awaddr   (32'b0),
    .c0_s_axi_ctrl_wvalid   (1'b0),
    .c0_s_axi_ctrl_wready   (),
    .c0_s_axi_ctrl_wdata    (32'b0),
    .c0_s_axi_ctrl_bvalid   (),
    .c0_s_axi_ctrl_bready   (1'b1),
    .c0_s_axi_ctrl_bresp    (),
    .c0_s_axi_ctrl_arvalid  (1'b0),
    .c0_s_axi_ctrl_arready  (),
    .c0_s_axi_ctrl_araddr   (32'b0),
    .c0_s_axi_ctrl_rvalid   (),
    .c0_s_axi_ctrl_rready   (1'b1),
    .c0_s_axi_ctrl_rdata    (),
    .c0_s_axi_ctrl_rresp    (),
    .c0_interrupt           (),
    .c0_app_ecc_multiple_err(),
    // controller 1 -- DDR3 pins
    .c1_ddr3_addr           (c1_ddr3_addr),
    .c1_ddr3_ba             (c1_ddr3_ba),
    .c1_ddr3_ras_n          (c1_ddr3_ras_n),
    .c1_ddr3_cas_n          (c1_ddr3_cas_n),
    .c1_ddr3_we_n           (c1_ddr3_we_n),
    .c1_ddr3_reset_n        (c1_ddr3_reset_n),
    .c1_ddr3_ck_p           (c1_ddr3_ck_p),
    .c1_ddr3_ck_n           (c1_ddr3_ck_n),
    .c1_ddr3_cke            (c1_ddr3_cke),
    .c1_ddr3_cs_n           (c1_ddr3_cs_n),
    .c1_ddr3_odt            (c1_ddr3_odt),
    .c1_ddr3_dq             (c1_ddr3_dq),
    .c1_ddr3_dqs_p          (c1_ddr3_dqs_p),
    .c1_ddr3_dqs_n          (c1_ddr3_dqs_n),
    .c1_sys_clk_p           (c1_sys_clk_p),
    .c1_sys_clk_n           (c1_sys_clk_n),
    // controller 1 -- user side
    .c1_ui_clk              (c1_ui_clk),
    .c1_ui_clk_sync_rst     (c1_ui_clk_sync_rst),
    .c1_mmcm_locked         (c1_mmcm_locked),
    .c1_init_calib_complete (c1_init_calib_complete),
    .c1_aresetn             (c1_axi_rstn),
    .c1_app_sr_req          (1'b0),
    .c1_app_ref_req         (1'b0),
    .c1_app_zq_req          (1'b0),
    .c1_app_sr_active       (),
    .c1_app_ref_ack         (),
    .c1_app_zq_ack          (),
    // controller 1 -- AXI slave: SoC seam, tied off for now
    .c1_s_axi_awid          (4'b0),
    .c1_s_axi_awaddr        (31'b0),
    .c1_s_axi_awlen         (8'b0),
    .c1_s_axi_awsize        (3'b0),
    .c1_s_axi_awburst       (2'b0),
    .c1_s_axi_awlock        (1'b0),
    .c1_s_axi_awcache       (4'b0),
    .c1_s_axi_awprot        (3'b0),
    .c1_s_axi_awqos         (4'b0),
    .c1_s_axi_awvalid       (1'b0),
    .c1_s_axi_awready       (),
    .c1_s_axi_wdata         (512'b0),
    .c1_s_axi_wstrb         (64'b0),
    .c1_s_axi_wlast         (1'b0),
    .c1_s_axi_wvalid        (1'b0),
    .c1_s_axi_wready        (),
    .c1_s_axi_bid           (),
    .c1_s_axi_bresp         (),
    .c1_s_axi_bvalid        (),
    .c1_s_axi_bready        (1'b1),
    .c1_s_axi_arid          (4'b0),
    .c1_s_axi_araddr        (31'b0),
    .c1_s_axi_arlen         (8'b0),
    .c1_s_axi_arsize        (3'b0),
    .c1_s_axi_arburst       (2'b0),
    .c1_s_axi_arlock        (1'b0),
    .c1_s_axi_arcache       (4'b0),
    .c1_s_axi_arprot        (3'b0),
    .c1_s_axi_arqos         (4'b0),
    .c1_s_axi_arvalid       (1'b0),
    .c1_s_axi_arready       (),
    .c1_s_axi_rid           (),
    .c1_s_axi_rdata         (),
    .c1_s_axi_rresp         (),
    .c1_s_axi_rlast         (),
    .c1_s_axi_rvalid        (),
    .c1_s_axi_rready        (1'b1),
    // controller 1 -- ECC control AXI-Lite, unused
    .c1_s_axi_ctrl_awvalid  (1'b0),
    .c1_s_axi_ctrl_awready  (),
    .c1_s_axi_ctrl_awaddr   (32'b0),
    .c1_s_axi_ctrl_wvalid   (1'b0),
    .c1_s_axi_ctrl_wready   (),
    .c1_s_axi_ctrl_wdata    (32'b0),
    .c1_s_axi_ctrl_bvalid   (),
    .c1_s_axi_ctrl_bready   (1'b1),
    .c1_s_axi_ctrl_bresp    (),
    .c1_s_axi_ctrl_arvalid  (1'b0),
    .c1_s_axi_ctrl_arready  (),
    .c1_s_axi_ctrl_araddr   (32'b0),
    .c1_s_axi_ctrl_rvalid   (),
    .c1_s_axi_ctrl_rready   (1'b1),
    .c1_s_axi_ctrl_rdata    (),
    .c1_s_axi_ctrl_rresp    (),
    .c1_interrupt           (),
    .c1_app_ecc_multiple_err(),
    // common
    .sys_rst                (sys_rstn)          // ACTIVE LOW per mig_01.prj
  );

  // ---- onboard LEDs (P30 M30 N30; polarity not documented, assumed high) -----
  assign led[0] = user_lnk_up;             // PCIe link trained
  assign led[1] = c0_init_calib_complete;  // DDR3 CH0 calibrated
  assign led[2] = c1_init_calib_complete;  // DDR3 CH1 calibrated

  // ---- tie-offs for declared-but-unused board peripherals --------------------
  assign iic_lm73_scl = 1'bz;  assign iic_lm73_sda = 1'bz;
  assign iic_pcie_scl = 1'bz;  assign iic_pcie_sda = 1'bz;
  assign bpi_flash_addr    = 25'b0;
  assign bpi_flash_dq      = 16'hzzzz;
  assign bpi_flash_ce_n    = 1'b1;
  assign bpi_flash_oen     = 1'b1;
  assign bpi_flash_wen     = 1'b1;
  assign bpi_flash_adv_ldn = 1'b1;

endmodule

`default_nettype wire

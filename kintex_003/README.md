# kintex_003 — YPCB-00338-1P1 (Celestica) bring-up project

Vivado project for the **YPCB-00338-1P1 Accelerator Card**
(part **`xc7k480tffg1156-2`**). All board data — pinout, MIG project
files, PCIe example configuration — comes from this repository's
reverse-engineering data (original by TiferKing).

## What the top does

`src/kintex_003.v` is the board top and the only module holding Xilinx IP:

| Instance | IP | Role |
|---|---|---|
| `u_xdma` (`xdma_003`) | XDMA, PCIe **Gen2 x8**, AXI4-MM 128 bit @ 250 MHz | host interface, configured exactly like the board example project (`examples/YPCB_00338_1P1_systest`, `top_xdma_0_0`) |
| `u_mig` (`mig_003`) | MIG 7-series, **dual controller** from the board `mig_01.prj` | 2 × 72-bit ECC DDR3 @ 1066 MT/s, AXI 512 bit; one core so the XADC is instantiated once |
| `u_axi_cc` (`axi_cc_003`) | AXI clock converter | XDMA 250 MHz → MIG CH0 `ui_clk` (133 MHz) |
| `u_axi_up` (`axi_up_003`) | AXI data-width converter | 128 → 512 bit |
| `u_refclk` | `IBUFDS_GTE2` | PCIe 100 MHz reference clock (J8/J7) |

Data path: **host PCIe ⇄ XDMA ⇄ clock conv ⇄ upsizer ⇄ DDR3 CH0** — a host
can DMA into channel-0 DDR3 out of the box. DDR3 **CH1** powers up and
calibrates but its 512-bit AXI slave is tied off: that is the seam where a
user design plugs in later.

### Onboard LEDs (P30 / M30 / N30)

| LED | Signal |
|---|---|
| `led[0]` | `user_lnk_up` — PCIe link trained |
| `led[1]` | `c0_init_calib_complete` — DDR3 CH0 calibrated |
| `led[2]` | `c1_init_calib_complete` — DDR3 CH1 calibrated |

LED polarity is not documented in the board data; assumed active-high.

## Layout

| Path | What |
|---|---|
| `constraints/kintex_003.xdc` | full board pinout for the top's ports (clk/rst, LEDs, PCIe lanes + refclk + PERST#, I2C sensor/SMBus, BPI flash). DDR3 pins are **not** here — the MIG core owns them via its prj file |
| `src/kintex_003.v` | board top (see above) |
| `tcl/` | batch-mode Vivado scripts — `create_project.tcl` (project + all four IPs), `run_impl.tcl` (synth → impl → bitstream), `program.tcl` (JTAG). See [tcl/README.md](tcl/README.md) |
| `patches/` | `patch_xdma_2025_1.sh` — **required once per Vivado 2025.1 install** before `create_project.tcl`: the stock 2025.1 XDMA IP aborts customization on all 7-series parts (unguarded Zynq/Versal-only device queries in its xgui Tcl). The script catch-guards the three call sites; originals kept as `.orig` |

## Quick start

```bash
cd kintex_003
vivado -mode batch -source tcl/create_project.tcl   # -> vivado_proj/kintex_003.xpr
vivado -mode batch -source tcl/run_impl.tcl         # synth + impl + bitstream
vivado -mode batch -source tcl/program.tcl          # flash over JTAG
```

# openxc7_003 — YPCB-00338-1P1 with the open-source openXC7 toolchain

Fully open-source FPGA flow for the **YPCB-00338-1P1 Accelerator Card**
(part **`xc7k480tffg1156-2`**) — no Vivado license required. The included
`blinky` (50 MHz clock on AA28, the three onboard LEDs on P30/M30/N30) has
been taken through the complete flow to an 18.7 MB bitstream.

## Toolchain (build once, from source)

| Tool | Repo | Notes |
|---|---|---|
| yosys | github.com/YosysHQ/yosys | CMake build: `cmake -B build && cmake --build build` |
| nextpnr-xilinx | github.com/openXC7/nextpnr-xilinx | `cmake -B build -DARCH=xilinx`; its `xilinx/external/prjxray-db` submodule (the openXC7 fork) carries the kintex7 **420t/480t** databases that upstream f4pga lacks |
| prjxray | github.com/f4pga/prjxray | C++ tools (`xc7frames2bit`); with cmake ≥ 4 add `-DCMAKE_POLICY_VERSION_MINIMUM=3.5`, with gcc ≥ 15 add `#include <cstdint>` to `lib/include/prjxray/memory_mapped_file.h` and `-DCMAKE_CXX_FLAGS=-Wno-error=free-nonheap-object`. Python side: `python3 -m venv venv && venv/bin/pip install -e . fasm intervaltree` |

Generate the chip database once (about 3 minutes):

```bash
make chipdb        # pypy3 bbaexport + bbasm -> xc7k480tffg1156-2.bin (~700 MB)
```

## Build

```bash
make               # blinky.v + blinky.xdc -> blinky.bit
```

Flow: yosys `synth_xilinx` → JSON → `nextpnr-xilinx` (place & route, XDC pin
constraints) → FASM → `fasm2frames` → `xc7frames2bit` → `.bit`.

## PCIe without Vivado

[regymm/pcie_7x](https://github.com/regymm/pcie_7x) provides an open-source
PCIe Gen1/Gen2 x1 endpoint built directly on the PCIE_2_1 hard block + GTX
transceivers, openXC7-compatible, and ships a ready target for this exact
board (`Makefile.ypcb_k480t.openxc7`, `pcie_7x_ypcb_k480t.xdc`), verified to
build a full 18.7 MB endpoint bitstream with this toolchain. Two of
nextpnr-xilinx's submodules must point at the regymm forks first (then
`make chipdb` again):

* `xilinx/external/nextpnr-xilinx-meta` →
  [regymm/nextpnr-xilinx-meta](https://github.com/regymm/nextpnr-xilinx-meta)
  ("Added Kintex 7 PCIE_2_1") — without it the PCIE_2_1 bel is missing at
  placement;
* `xilinx/external/prjxray-db` →
  [regymm/prjxray-db](https://github.com/regymm/prjxray-db)
  ("Added Kintex 7 PCIe segbits/tilegrid and GTX bit fixes") — without it
  `fasm2frames` fails on the PCIE_BOT features.

One caution for hardware bring-up: that project's XDC puts PERST# on Y28
(LVCMOS33) while this repository's board files derive Y26 (LVCMOS18) —
reconcile on the bench before trusting reset behaviour.

## Scope

The open flow covers fabric logic, block RAM, DSP, and (via regymm) the
PCIe hard block. The DDR3 MIG and XDMA Vivado IPs of `../kintex_003` have
no open-source equivalent here; for full DDR3 + x8 DMA use the Vivado
project in `../kintex_003`.

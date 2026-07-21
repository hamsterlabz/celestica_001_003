# Vivado batch scripts

Headless build/program for the YPCB-00338-1P1 board (top = `kintex_003`,
part `xc7k480tffg1156-2`). Run from the `kintex_003/` directory.

| Script | What it does |
|---|---|
| [create_project.tcl](create_project.tcl) | Build the Vivado **project** (`vivado_proj/`) and create all four IPs: the XDMA (config copied from the board example project), the dual-controller DDR3 MIG (from the board `mig_01.prj`, `ModuleName` patched to `mig_003`), and the AXI clock/width converters. |
| [run_impl.tcl](run_impl.tcl) | Open that project and run synth+impl+bitstream via the run engine. |
| [program.tcl](program.tcl) | Program a `.bit` onto the board over JTAG. |

```bash
cd kintex_003
vivado -mode batch -source tcl/create_project.tcl   # -> vivado_proj/kintex_003.xpr
vivado -mode batch -source tcl/run_impl.tcl         # synth + impl + bitstream
vivado -mode batch -source tcl/program.tcl          # flash it to the board
```

There is no non-project `build.tcl` here (unlike `../kintex/tcl`): the MIG and
XDMA cores are generated from configuration (prj file / IP properties), which
is a project-flow operation — the project flow is the single source of truth.

## What the scripts read

- **Board RTL**: `src/kintex_003.v` (the only design source).
- **Board data**: `../ypcb003381p1/1.0/mig_01.prj`
  (DDR3 pinout + timing live inside it).
- **Constraints**: `constraints/kintex_003.xdc`.

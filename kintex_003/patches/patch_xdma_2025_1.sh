#!/bin/bash
# patch_xdma_2025_1.sh -- make the Vivado 2025.1 XDMA IP customizable on 7-series.
#
# Vivado 2025.1 bug: xdma v4.2 claims kintex7:ALL support, but three xgui
# parameter-update procs call xit::get_device_data with Zynq/Versal-only keys
# (DeviceData.PS_TYPE, DeviceData.SiteTypes) unguarded. On any pure-fabric
# 7-series part the query throws and the whole IP customization aborts:
#   ERROR: [Common 17-69] Command failed: Unrecognized device query'DeviceData.PS_TYPE'
# The queried values only matter on Versal/Zynq; on 7-series the else branch
# is the correct result, so a catch with a benign default fixes it.
#
# Idempotent: skips files whose calls are already guarded. Originals are kept
# as *.orig on first application.
#
#   ./patch_xdma_2025_1.sh [/tools/Xilinx/2025.1]

set -e
XIL="${1:-/tools/Xilinx/2025.1}"
XGUI="$XIL/Vivado/data/ip/xilinx/xdma_v4_2/xgui"
[ -d "$XGUI" ] || { echo "ERROR: $XGUI not found"; exit 1; }

patch_one() {  # file, old-line, new-line
  local f="$1" old="$2" new="$3"
  # the guarded line still contains the original call as a substring, so the
  # idempotence check must look for the guard itself, not for the old line
  if grep -qF "$new" "$f"; then echo "already patched: $f"; return; fi
  if ! grep -qF "$old" "$f"; then echo "WARNING: no match in $f (IP version changed?)"; return; fi
  cp --update=none "$f" "$f.orig"
  python3 - "$f" "$old" "$new" <<'EOF'
import sys
f, old, new = sys.argv[1:4]
s = open(f).read()
assert old in s
open(f, "w").write(s.replace(old, new))
EOF
  echo "patched: $f"
}

patch_one "$XGUI/xdma_v4_2.tcl" \
  '   set PS_TYPE [xit::get_device_data -data_key DeviceData.PS_TYPE -of [xit::current_scope]]' \
  '   if { [catch { set PS_TYPE [xit::get_device_data -data_key DeviceData.PS_TYPE -of [xit::current_scope]] }] } { set PS_TYPE "NONE" }'

for f in "$XGUI/xdma_v4_2.tcl" "$XGUI/gt_list.tcl" "$XGUI/utils.tcl"; do
  patch_one "$f" \
    'set pcie_type [xit::get_device_data -data_key DeviceData.SiteTypes -of [xit::current_scope]]' \
    'if { [catch { set pcie_type [xit::get_device_data -data_key DeviceData.SiteTypes -of [xit::current_scope]] }] } { set pcie_type [list] }'
done
echo "done"

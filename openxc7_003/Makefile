# openXC7 flow -- YPCB-00338-1P1 accelerator card (xc7k480tffg1156-2)
#
#   make            -> $(TOP).bit   (default TOP = blinky)
#   make chipdb     -> (re)generate the nextpnr chip database for $(PART)
#
# Requires the openXC7 toolchain built from source (see README.md):
#   yosys, nextpnr-xilinx (openXC7 fork), prjxray (fasm2frames + xc7frames2bit).
# Point GITS at the directory holding those clones.

TOP     ?= blinky
PART    ?= xc7k480tffg1156-2
FAMILY  ?= kintex7
GITS    ?= $(HOME)/gits
YOSYS   ?= $(GITS)/yosys/build/yosys
NEXTPNR ?= $(GITS)/nextpnr-xilinx/build/nextpnr-xilinx
BBAEXPORT = $(GITS)/nextpnr-xilinx/xilinx/python/bbaexport.py
BBASM     = $(GITS)/nextpnr-xilinx/build/bbasm
CHIPDB  ?= $(GITS)/nextpnr-xilinx/chipdb/$(PART).bin
DB      ?= $(GITS)/nextpnr-xilinx/xilinx/external/prjxray-db/$(FAMILY)
PYTHON  ?= $(GITS)/prjxray/venv/bin/python
FASM2FRAMES = $(GITS)/prjxray/utils/fasm2frames.py
FRAMES2BIT  = $(GITS)/prjxray/build/tools/xc7frames2bit

all: $(TOP).bit

# -nobram keeps the LED test LUT/FF-only; drop for real designs
$(TOP).json: $(TOP).v
	$(YOSYS) -p "synth_xilinx -flatten -abc9 -nobram -arch xc7 -top $(TOP); write_json $@" $<

$(TOP).fasm: $(TOP).json $(TOP).xdc
	$(NEXTPNR) --chipdb $(CHIPDB) --xdc $(TOP).xdc --json $(TOP).json --fasm $@

$(TOP).frames: $(TOP).fasm
	$(PYTHON) $(FASM2FRAMES) --db-root $(DB) --part $(PART) $< $@

$(TOP).bit: $(TOP).frames
	$(FRAMES2BIT) --part_file $(DB)/$(PART)/part.yaml --part_name $(PART) --frm_file $< --output_file $@

chipdb:
	pypy3 $(BBAEXPORT) --device $(PART) --bba $(dir $(CHIPDB))$(PART).bba
	$(BBASM) --l $(dir $(CHIPDB))$(PART).bba $(CHIPDB)
	rm -f $(dir $(CHIPDB))$(PART).bba

clean:
	rm -f $(TOP).json $(TOP).fasm $(TOP).frames $(TOP).bit

.PHONY: all chipdb clean

# ============================================================
# Makefile - Icarus Verilog + GTKWave flow
# Open-source alternative to the ModelSim .do script, so
# anyone can run this regression without a licensed simulator.
#
# Install (Ubuntu/Debian): sudo apt install iverilog gtkwave
# Install (macOS):         brew install icarus-verilog gtkwave
#
# Usage:
#   make sim     -> compile + run, prints PASS/FAIL to terminal
#   make wave    -> open the waveform in GTKWave
#   make clean   -> remove generated files
# ============================================================

RTL   = ../rtl/Sync_FIFO.v
TB    = ../tb/tb_Sync_FIFO.v
TOP   = tb_Sync_FIFO
OUT   = sim.vvp
VCD   = wave.vcd

.PHONY: sim wave clean

sim:
	iverilog -o $(OUT) -s $(TOP) $(RTL) $(TB)
	vvp $(OUT)

wave: sim
	gtkwave $(VCD) &

clean:
	rm -f $(OUT) $(VCD) report.txt

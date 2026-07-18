# ============================================================
# sim.do - ModelSim automation script for Sync FIFO
# Usage: from ModelSim's Transcript window, run:  do sim.do
# Requires: Sync_FIFO.v (DUT) and tb_Sync_FIFO.v (testbench)
#           in the same directory as this script.
# ============================================================

# 1) Create a fresh work library (safe to re-run any time)
if {[file exists work]} {
    vdel -all
}
vlib work
vmap work work

# 2) Compile DUT and testbench
vlog Sync_FIFO.v
vlog tb_Sync_FIFO.v

# 3) Load the design for simulation
vsim work.tb_Sync_FIFO

# 4) Open the Wave window and add signals of interest
view wave

# Top-level I/O and control signals
add wave -divider "Top-Level I/O"
add wave -radix binary   /tb_Sync_FIFO/clk
add wave -radix binary   /tb_Sync_FIFO/rst_n
add wave -radix binary   /tb_Sync_FIFO/wr_en
add wave -radix binary   /tb_Sync_FIFO/rd_en
add wave -radix hexadecimal /tb_Sync_FIFO/wr_data
add wave -radix hexadecimal /tb_Sync_FIFO/rd_data
add wave -radix binary   /tb_Sync_FIFO/full
add wave -radix binary   /tb_Sync_FIFO/empty

# Internal DUT pointers (extra-MSB wrap technique)
# NOTE: if you swap in your own Sync_FIFO.v and its internal
# pointer signal names differ, update these two lines to match.
add wave -divider "Internal Pointers (DUT)"
add wave -radix unsigned  /tb_Sync_FIFO/dut/wr_ptr
add wave -radix unsigned  /tb_Sync_FIFO/dut/rd_ptr
add wave -radix binary    /tb_Sync_FIFO/dut/wr_addr
add wave -radix binary    /tb_Sync_FIFO/dut/rd_addr

# Testbench scoreboard bookkeeping
add wave -divider "Testbench Scoreboard"
add wave -radix unsigned  /tb_Sync_FIFO/sb_wr_ptr
add wave -radix unsigned  /tb_Sync_FIFO/sb_rd_ptr
add wave -radix unsigned  /tb_Sync_FIFO/checks
add wave -radix unsigned  /tb_Sync_FIFO/errors

# 5) Cosmetic wave window formatting (optional but tidy)
configure wave -namecolwidth 180
configure wave -valuecolwidth 100
configure wave -justifyvalue left

# 6) Run the full test sequence to completion
run -all

# 7) Zoom the wave window to fit everything that ran
wave zoom full

# ============================================================
# Note on coverage: functional/code coverage is NOT enabled by
# this script. To add it, recompile with:
#   vlog +cover=bcesf Sync_FIFO.v
# then after run -all:
#   coverage report -file coverage_report.txt -byfile -assert -directive -cvg
# ============================================================

# Synchronous FIFO — RTL Design & Verification

A parameterizable synchronous FIFO in Verilog-2001, verified with a
self-checking, scoreboard-based testbench. Built as an independent RTL/DV
portfolio project — not from a guided course.

![CI](https://img.shields.io/badge/CI-move%20regression.yml%20to%20.github%2Fworkflows-orange)
![Language](https://img.shields.io/badge/RTL-Verilog--2001-blue)
![Sim](https://img.shields.io/badge/simulators-ModelSim%20%7C%20Icarus%20Verilog-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

## Result at a glance
```
TOTAL CHECKS : 107
TOTAL ERRORS : 0
RESULT: PASS
```

## Why this project
Full/empty detection in a synchronous FIFO looks trivial until you hit the
pointer-wraparound boundary — the extra-MSB (wrap-bit) technique used here
is the standard industry approach for disambiguating "wrapped all the way
around" from "caught back up," and it's the part that's easy to get subtly
wrong. This project's verification plan specifically targets that boundary,
not just basic read/write.

## Repository Structure
Currently flat at repo root (a folder reorganization is planned — see note below):
```
sync-fifo/
├── Sync_FIFO.v                  # DUT - parameterizable sync FIFO
├── tb_Sync_FIFO.v                # self-checking scoreboard testbench
├── sim.do                        # ModelSim automation script
├── Makefile                      # Icarus Verilog + GTKWave flow (open-source alt.)
├── fifo_block_diagram.svg
├── pointer_wraparound.svg
├── testbench_architecture.svg
├── design_spec.md                # what was built and why
├── verification_plan.md          # test plan matrix, written before/during coding
├── verification_report.md        # results write-up
└── regression.yml                # CI workflow (needs to move into .github/workflows/ to activate)
```
> **Note:** this repo is planned to move to an organized `rtl/`, `tb/`, `scripts/`,
> `docs/`, `diagrams/` folder layout. Until then, all paths above are relative
> to repo root.

## Design Overview
See [`design_spec.md`](design_spec.md) for the full interface and
functional spec. In short:

![FIFO block diagram]("C:\Users\Chauhan Jayrajsinh N\OneDrive\Documents\GitHub\sync-fifo\diagrams\fifo_block_diagram.png")

Full/empty uses the **extra-MSB pointer technique**:

![Pointer wraparound](file:///C:/Users/Chauhan%20Jayrajsinh%20N/OneDrive/Documents/GitHub/sync-fifo/diagrams/pointer_wraparound.svg)

## Verification Approach
See [`verification_plan.md`](verification_plan.md) for the full
test matrix (10 scenarios, corner cases explicitly called out) and
[`verification_report.md`](verification_report.md) for results.

![Testbench architecture](file:///C:/Users/Chauhan%20Jayrajsinh%20N/OneDrive/Documents/GitHub/sync-fifo/diagrams/testbench_architecture.svg)

The testbench is self-checking: a behavioral array acts as a golden
reference model, so pass/fail is computed automatically rather than
eyeballed from waveforms.

## How to Run — Any Platform

### Option A: ModelSim (any edition, including free ALTERA/Intel edition)
```tcl
vsim -c -do sim.do
```
Or interactively: open ModelSim in this folder, then `do sim.do`.
This compiles, elaborates, sets up the wave window with top-level I/O,
internal pointers, and scoreboard signals, and runs to completion.

### Option B: Open-source (Icarus Verilog + GTKWave) — no license required
```bash
# Install once:
#   Ubuntu/Debian: sudo apt install iverilog gtkwave
#   macOS:         brew install icarus-verilog gtkwave

make sim      # compile + run, prints PASS/FAIL to terminal
make wave     # opens the waveform in GTKWave
make clean    # remove generated files
```

### Option C: Automatic (CI)
Currently inactive — `regression.yml` needs to be moved into `.github/workflows/`
for GitHub Actions to detect and run it (see note below).

## Sample Regression Log
```
--- TEST 1: Fill to full ---
[40000] WRITE  data=00  (full=0)
...
[340000] WRITE  data=0f  (full=1)
[350000] WRITE SKIPPED - FIFO FULL

--- TEST 2: Drain to empty ---
[380000] READ   data=00  MATCH
...
[690000] READ SKIPPED - FIFO EMPTY

--- TEST 3: Alternating write/read at wraparound ---
...all reads MATCH across multiple pointer wraps...

--- TEST 4: Randomized write/read ---
...100 pseudo-random transactions, zero mismatches...

============================================
 TOTAL CHECKS : 107
 TOTAL ERRORS : 0
 RESULT: PASS
============================================
```

## Waveforms

1. **Reset and Read/Write Waveforms**
   - **i. Reset and First Write**
     <img width="967" height="350" alt="Screenshot 2026-07-19 002354" src="https://github.com/user-attachments/assets/5b024c09-a65e-4e0f-9caa-527fbc86c5e6" />
   - **ii. First Read**
     <img width="757" height="353" alt="Screenshot 2026-07-19 002915" src="https://github.com/user-attachments/assets/341a45ab-062f-4c66-82a9-168981a597e8" />
2. **Fill to FULL**
   <img width="1806" height="352" alt="Screenshot 2026-07-19 003034" src="https://github.com/user-attachments/assets/bcdb9b6e-8a5c-486e-abe8-5bc2b5be5a6a" />
3. **Drain to EMPTY**
   <img width="1891" height="348" alt="Screenshot 2026-07-19 003325" src="https://github.com/user-attachments/assets/3fdb71d1-bd01-4ba6-b225-8869d75b9ecd" />
4. **Wraparound Stress**
   <img width="1280" height="355" alt="Screenshot 2026-07-19 003607" src="https://github.com/user-attachments/assets/d3464a03-d6e6-4cc0-b2a1-4f68d39c4e51" />
5. **Final PASS Summary** — scoreboard tally at `$finish`
   <img width="722" height="183" alt="Screenshot 2026-07-19 003743" src="https://github.com/user-attachments/assets/3365628e-b977-4ab4-94d5-15299d907e95" />

## Known Limitations / Future Work
- Single clock domain only — see the companion **Async FIFO** project
  (in progress) for the CDC-safe version using gray-coded pointers.
- No functional coverage or SVA assertions yet (would require SystemVerilog;
  this project intentionally stayed in Verilog-2001 for portability).
- A parallel **cocotb/Python** verification of this same FIFO is planned as
  a separate repo, to demonstrate the same DUT verified from a different
  methodology.

## License
MIT — see [LICENSE](LICENSE).

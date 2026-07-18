# Verification Plan — Synchronous FIFO

## 1. Verification Objective
Prove that `Sync_FIFO` meets [`design_spec.md`](design_spec.md) under normal operation,
boundary conditions, and randomized stimulus — with zero silent data 
corruption or flag mis-assertion.

## 2. Methodology
- **Testbench style:** self-checking, scoreboard-based (no manual eyeballing
  of output — pass/fail is a computed result).
- **Reference model:** a behavioral queue/array in the testbench mirrors
  expected FIFO order. Every write pushes into it; every read pops and
  compares against DUT output. This removes the need for a separate golden
  RTL model.
- **Language / tooling:** Verilog-2001 (no SystemVerilog dependency, for
  portability across simulators), ModelSim primary + Icarus Verilog
  alternative flow.

## 3. Features to Verify (Test Plan Matrix)

| # | Feature / Scenario                          | Stimulus Approach          | Pass Criteria                              | Status |
|---|----------------------------------------------|-----------------------------|---------------------------------------------|--------|
| 1 | Reset behavior                               | Assert `rst_n`, sample flags | `empty=1`, `full=0` post-reset             | ✅ Pass |
| 2 | Basic write-then-read                        | Single write, single read   | Data returned unchanged                     | ✅ Pass |
| 3 | Fill to full (exact depth)                   | `DEPTH` consecutive writes  | `full` asserts on the Nth write, not before/after | ✅ Pass |
| 4 | Overflow protection                          | Write while full            | Write ignored, no state corruption          | ✅ Pass |
| 5 | Drain to empty (exact depth)                 | `DEPTH` consecutive reads   | `empty` asserts on the Nth read, not before/after | ✅ Pass |
| 6 | Underflow protection                         | Read while empty            | Read ignored, no stale/garbage capture      | ✅ Pass |
| 7 | Pointer wraparound under sustained load      | Alternating write/read near-full for 2×DEPTH cycles | FIFO order preserved through multiple wraps | ✅ Pass |
| 8 | Randomized mixed traffic                     | 100 pseudo-random write/read decisions | Zero mismatches vs. scoreboard    | ✅ Pass |
| 9 | Data integrity end-to-end                    | All of the above            | Every read matches its corresponding write  | ✅ Pass |
| 10| CDC safety (out of scope for this design)    | N/A — single clock domain   | N/A — see design_spec.md §6                 | N/A    |

## 4. Corner Cases Specifically Targeted
- Write on the exact cycle `full` asserts (boundary, not one before/after)
- Read on the exact cycle `empty` asserts
- Pointer address bits wrapping from `DEPTH-1` back to `0` while occupancy
  stays high (this is where an incorrectly-implemented extra-MSB scheme
  would show stale data or a false empty/full)
- Back-to-back write immediately followed by read, and vice versa

## 5. Pass/Fail Criteria (Overall)
The regression is considered **PASS** only if `errors == 0` reported by the
scoreboard at `$finish`, across all four test phases (fill, drain,
wraparound-stress, randomized).

## 6. What This Plan Does NOT Cover (Future Work)
- Formal verification / assertion-based checking (SVA) — plain Verilog-2001
  was used for simulator portability; a SystemVerilog assertion layer is a
  natural extension.
- Functional coverage collection (`covergroup`/`coverpoint`) — not available
  in Verilog-2001; would require SV or a coverage-capable simulator flow.
- Gate-level / timing-annotated simulation.
- CDC-specific verification (belongs to the separate Async FIFO project).

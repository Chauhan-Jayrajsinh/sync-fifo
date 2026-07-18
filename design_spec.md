# Design Specification — Synchronous FIFO

## 1. Overview
A parameterizable synchronous FIFO (First-In-First-Out) buffer for data transfer
between two logical interfaces operating on a single, common clock domain.

## 2. Parameters
| Parameter    | Description                     | Default |
|--------------|----------------------------------|---------|
| `DATA_WIDTH` | Width of each data word (bits)   | 8       |
| `FIFO_DEPTH` | Number of storage locations      | 16 (must be a power of 2) |

## 3. Interface

| Signal      | Direction | Width          | Description                          |
|-------------|-----------|----------------|---------------------------------------|
| `clk`       | input     | 1              | System clock                          |
| `rst_n`     | input     | 1              | Active-low asynchronous reset         |
| `wr_en`     | input     | 1              | Write enable                          |
| `wr_data`   | input     | `DATA_WIDTH`   | Write data                            |
| `rd_en`     | input     | 1              | Read enable                           |
| `rd_data`   | output    | `DATA_WIDTH`   | Read data (registered)                |
| `full`      | output    | 1              | FIFO full flag                        |
| `empty`     | output    | 1              | FIFO empty flag                       |

## 4. Functional Behavior

- **Reset:** `rst_n = 0` asynchronously clears both pointers. `empty` asserts,
  `full` deasserts.
- **Write:** on the rising edge of `clk`, if `wr_en = 1` and `full = 0`, `wr_data`
  is stored at the current write address and the write pointer advances.
  A write attempted while `full = 1` is **ignored** (no overflow corruption).
- **Read:** on the rising edge of `clk`, if `rd_en = 1` and `empty = 0`, the data
  at the current read address is registered onto `rd_data` and the read pointer
  advances. A read attempted while `empty = 1` is **ignored** (no underflow /
  stale-data hazard).
- **Simultaneous read + write:** legal in the same cycle as long as neither
  `full` (for the write) nor `empty` (for the read) blocks it. Both pointers
  advance independently.

## 5. Full / Empty Detection — Design Decision

Two common approaches exist for full/empty disambiguation in a synchronous FIFO:

1. **Occupancy counter** — an explicit up/down counter tracking entries in use.
2. **Extra-MSB (wrap-bit) pointer comparison** — pointers are `log2(DEPTH)+1`
   bits wide. The address bits index memory; the extra MSB records how many
   times each pointer has wrapped. `empty` = pointers fully equal (including
   MSB). `full` = address bits equal but MSBs differ (write pointer has
   lapped the read pointer exactly once).

**This design uses the extra-MSB technique** — it avoids a separate counter
register and keeps full/empty as pure combinational pointer comparisons,
which is the more common technique in industry FIFO IP.
See [`diagrams/pointer_wraparound.svg`](../diagrams/pointer_wraparound.svg) for a worked example.

## 6. Known Limitations / Non-Goals
- Single clock domain only — **not** safe for CDC (clock-domain-crossing) use.
  An asynchronous FIFO with gray-coded pointers is a separate, planned piece
  of this portfolio.
- No almost-full / almost-empty (programmable threshold) flags in this version.
- No built-in ECC / parity protection on stored data.

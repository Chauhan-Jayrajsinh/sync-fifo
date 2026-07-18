`timescale 1ns/1ps
// ============================================================
// Self-checking testbench for Sync_FIFO - plain Verilog-2001
// (no SystemVerilog constructs - compatible with vlog on .v files)
// Scoreboard = fixed-size circular buffer array instead of $queue
// ============================================================

module tb_Sync_FIFO;

  parameter DATA_WIDTH = 8;
  parameter FIFO_DEPTH = 16;

  reg                    clk, rst_n;
  reg                    wr_en, rd_en;
  reg  [DATA_WIDTH-1:0]  wr_data;
  wire [DATA_WIDTH-1:0]  rd_data;
  wire                   full, empty;

  Sync_FIFO #(
    .DATA_WIDTH(DATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
  ) dut (
    .clk(clk), .rst_n(rst_n),
    .wr_en(wr_en), .wr_data(wr_data),
    .rd_en(rd_en), .rd_data(rd_data),
    .full(full), .empty(empty)
  );

  always #5 clk = ~clk;

  // -------------------- Scoreboard (manual circular buffer) --------------------
  // Big enough to never wrap during this test run
  reg [DATA_WIDTH-1:0] sb_mem [0:255];
  integer sb_wr_ptr;
  integer sb_rd_ptr;
  integer errors;
  integer checks;

  // -------------------- Stimulus tasks --------------------
  task do_write;
    input [DATA_WIDTH-1:0] data;
    begin
      @(negedge clk);
      if (!full) begin
        wr_en   = 1;
        wr_data = data;
        @(negedge clk);
        wr_en   = 0;
        sb_mem[sb_wr_ptr] = data;
        sb_wr_ptr = sb_wr_ptr + 1;
        $display("[%0t] WRITE  data=%h  (full=%b)", $time, data, full);
      end else begin
        $display("[%0t] WRITE SKIPPED - FIFO FULL", $time);
      end
    end
  endtask

  task do_read;
    reg [DATA_WIDTH-1:0] expected;
    begin
      @(negedge clk);
      if (!empty) begin
        rd_en = 1;
        @(negedge clk);
        rd_en = 0;
        expected = sb_mem[sb_rd_ptr];
        sb_rd_ptr = sb_rd_ptr + 1;
        checks = checks + 1;
        if (rd_data !== expected) begin
          errors = errors + 1;
          $display("[%0t] *** MISMATCH *** got=%h expected=%h", $time, rd_data, expected);
        end else begin
          $display("[%0t] READ   data=%h  MATCH", $time, rd_data);
        end
      end else begin
        $display("[%0t] READ SKIPPED - FIFO EMPTY", $time);
      end
    end
  endtask

  // -------------------- Test sequence --------------------
  integer i;

  // VCD dump - used by the Icarus Verilog / GTKWave flow (scripts/Makefile).
  // ModelSim ignores these when run via sim.do, so this testbench works
  // unmodified in both flows.
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_Sync_FIFO);
  end

  initial begin
    clk       = 0;
    rst_n     = 0;
    wr_en     = 0;
    rd_en     = 0;
    wr_data   = 0;
    sb_wr_ptr = 0;
    sb_rd_ptr = 0;
    errors    = 0;
    checks    = 0;

    #20;
    rst_n = 1;
    @(negedge clk);

    // --- TEST 1: fill to full (overshoot on purpose) ---
    $display("\n--- TEST 1: Fill to full ---");
    for (i = 0; i < FIFO_DEPTH + 2; i = i + 1)
      do_write(i);
    if (!full) begin
      errors = errors + 1;
      $display("*** ERROR: full not asserted when FIFO should be full ***");
    end

    // --- TEST 2: drain to empty (overshoot on purpose) ---
    $display("\n--- TEST 2: Drain to empty ---");
    for (i = 0; i < FIFO_DEPTH + 2; i = i + 1)
      do_read;
    if (!empty) begin
      errors = errors + 1;
      $display("*** ERROR: empty not asserted when FIFO should be empty ***");
    end

    // --- TEST 3: refill, then alternate write/read to stress wraparound ---
    $display("\n--- TEST 3: Alternating write/read at wraparound ---");
    for (i = 0; i < FIFO_DEPTH; i = i + 1)
      do_write(100 + i);
    for (i = 0; i < 2*FIFO_DEPTH; i = i + 1) begin
      do_write(200 + i);
      do_read;
    end

    // --- TEST 4: pseudo-random write/read mix ---
    $display("\n--- TEST 4: Randomized write/read ---");
    for (i = 0; i < 100; i = i + 1) begin
      if ($random % 2 == 0)
        do_write($random & {DATA_WIDTH{1'b1}});
      else
        do_read;
    end

    // drain anything left in the scoreboard so counts line up
    while (sb_rd_ptr < sb_wr_ptr)
      do_read;

    // -------------------- Final report --------------------
    $display("\n============================================");
    $display(" TOTAL CHECKS : %0d", checks);
    $display(" TOTAL ERRORS : %0d", errors);
    if (errors == 0)
      $display(" RESULT: PASS");
    else
      $display(" RESULT: FAIL");
    $display("============================================\n");

    $finish;
  end

endmodule

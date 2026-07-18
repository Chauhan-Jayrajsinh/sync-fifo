// ============================================================
// Sync_FIFO.v
// Parameterizable synchronous FIFO
// Technique: extra-MSB (wrap-bit) pointer comparison for
//            unambiguous full/empty detection
//
// NOTE: This is a reference implementation matching the port
// interface exercised by tb_Sync_FIFO.v. If your original RTL
// differs internally, replace this file with yours - the
// testbench and scripts in this repo will still apply as long
// as the port list matches.
// ============================================================

module Sync_FIFO #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16          // must be a power of 2
) (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    wr_en,
    input  wire [DATA_WIDTH-1:0]   wr_data,
    input  wire                    rd_en,
    output reg  [DATA_WIDTH-1:0]   rd_data,
    output wire                    full,
    output wire                    empty
);

    localparam PTR_WIDTH = $clog2(FIFO_DEPTH);

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    // Pointers: one extra MSB beyond the address width.
    // The extra bit is what distinguishes "wrapped all the way
    // around" (full) from "caught back up" (empty) when the
    // lower bits of wr_ptr and rd_ptr are equal.
    reg [PTR_WIDTH:0] wr_ptr;
    reg [PTR_WIDTH:0] rd_ptr;

    wire [PTR_WIDTH-1:0] wr_addr = wr_ptr[PTR_WIDTH-1:0];
    wire [PTR_WIDTH-1:0] rd_addr = rd_ptr[PTR_WIDTH-1:0];

    // full: lower bits match but MSBs differ (wrote all the way around)
    assign full  = (wr_ptr[PTR_WIDTH]     != rd_ptr[PTR_WIDTH]) &&
                   (wr_ptr[PTR_WIDTH-1:0] == rd_ptr[PTR_WIDTH-1:0]);

    // empty: pointers fully identical (including MSB)
    assign empty = (wr_ptr == rd_ptr);

    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_addr] <= wr_data;
            wr_ptr       <= wr_ptr + 1'b1;
        end
    end

    // Read logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr  <= 0;
            rd_data <= {DATA_WIDTH{1'b0}};
        end else if (rd_en && !empty) begin
            rd_data <= mem[rd_addr];
            rd_ptr  <= rd_ptr + 1'b1;
        end
    end

endmodule

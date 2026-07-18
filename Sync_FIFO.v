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
parameter
  DATA_WIDTH = 8,
  FIFO_DEPTH = 16,
  ADDR_WIDTH = $clog2(FIFO_DEPTH))
 (
  // Ports
  input clk,rst_n, // Active LOW Reset
  input wire wr_en,rd_en,
  input wire [DATA_WIDTH-1:0] wr_data,
  output reg [DATA_WIDTH-1:0] rd_data,
  output wire full,empty // Status Flags
);

// Pointers: one extra MSB beyond the address width.
// The extra bit is what distinguishes "wrapped all the way
// around" (full) from "caught back up" (empty) when the
// lower bits of wr_ptr and rd_ptr are equal.
reg [ADDR_WIDTH : 0]wptr , rptr;
reg [DATA_WIDTH-1:0] mem [0 : FIFO_DEPTH - 1];
always@(posedge clk or negedge rst_n) begin 
  if(!rst_n) begin 
    wptr <= 0;
    rd_data <= 0;
    rptr <= 0;   
  end
  
  else begin // Pointer increment 
     if(wr_en && !full) begin
       wptr <= wptr + 1;
       
       // Memory Write
       mem[wptr[ADDR_WIDTH - 1 : 0]] <= wr_data;
     end
     if(rd_en && !empty) begin
       rptr <= rptr + 1;
       
       // Memory Read
       rd_data <= mem[rptr[ADDR_WIDTH - 1 : 0]];
    end
  end
end
  
// combinational flag logic — OUTSIDE the clocked block
  // Full Condition
  assign full = (wptr[ADDR_WIDTH] != rptr[ADDR_WIDTH]) && 
                (wptr[ADDR_WIDTH - 1 : 0] == rptr[ADDR_WIDTH - 1 : 0]);
    // Empty Condition
       assign empty = (wptr == rptr);
endmodule

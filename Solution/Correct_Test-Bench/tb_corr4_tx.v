//======================================================================
// tb_corr7_tx: Verify long frames work (DATA_WIDTH=16)
//----------------------------------------------------------------------
// Rationale:
//   Old design used a 4-bit counter; with 16 data bits the frame
//   truncated. We ensure the line remains active for the full duration.
//======================================================================
`timescale 1ns/1ps
module tb_corr4_tx;
  reg clk=0; always #5 clk=~clk;
  reg rst=1;

  reg  [15:0] s_tdata = 16'hBEEF;
  reg         s_tvalid=0;
  wire        s_tready;
  wire        txd, busy;

  localparam integer PRESCALE=6;

  uart_tx_corr_4 #(.DATA_WIDTH(16)) dut (
    .clk(clk), .rst(rst),
    .s_axis_tdata(s_tdata), .s_axis_tvalid(s_tvalid), .s_axis_tready(s_tready),
    .txd(txd), .busy(busy), .prescale(PRESCALE[15:0])
  );

  integer edge_count=0; reg last;
  initial begin
    repeat(5) @(posedge clk); rst<=0;

    @(posedge clk);
    s_tvalid<=1; wait(s_tready); @(posedge clk); s_tvalid<=0;

    last=1; repeat(2500) begin
      @(posedge clk);
      if (txd!=last) edge_count=edge_count+1;
      last=txd;
    end
    // crude heuristic: with 1 start + 16 data + 1 stop, expect several edges
    if (edge_count >= 18) $display("PASS: long frame serialized (edges=%0d).", edge_count);
    else                  $display("FAIL: not enough transitions (counter too short).");
    $finish;
  end
endmodule

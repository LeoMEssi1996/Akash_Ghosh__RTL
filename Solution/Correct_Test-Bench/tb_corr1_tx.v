//======================================================================
// tb_corr1_tx: Verify bit-time = (prescale<<3) for START/DATA/STOP
//----------------------------------------------------------------------
// Rationale:
//   Former bug was prescaler off-by-one. We measure the period between
//   consecutive edges (start→d0) and compare to expected cycles.
//======================================================================
`timescale 1ns/1ps
module tb_corr1_tx;
  reg clk=0; always #5 clk=~clk;  // 100 MHz
  reg rst=1;

  reg  [7:0] s_tdata = 8'h55;
  reg        s_tvalid= 0;
  wire       s_tready;
  wire       txd, busy;

  localparam integer PRESCALE = 6;
  localparam integer BITCYC   = PRESCALE*8;

  uart_tx_corr_1 #(.DATA_WIDTH(8)) dut (
    .clk(clk), .rst(rst),
    .s_axis_tdata(s_tdata), .s_axis_tvalid(s_tvalid), .s_axis_tready(s_tready),
    .txd(txd), .busy(busy), .prescale(PRESCALE[15:0])
  );

  integer cyc=0, first_edge=0, second_edge=0; reg last;
  initial begin
    repeat(5) @(posedge clk);
    rst <= 0;

    // enqueue one byte
    @(posedge clk);
    s_tvalid <= 1;
    wait (s_tready);
    @(posedge clk) s_tvalid <= 0;

    // watch edges and measure bit time
    last = 1'b1;
    forever begin
      @(posedge clk);
      cyc = cyc + 1;
      if (txd != last) begin
        if (first_edge==0) first_edge = cyc;        // idle→start
        else begin
          second_edge = cyc;                         // start→d0
          $display("Measured bit cycles = %0d (expected %0d)", second_edge-first_edge, BITCYC);
          if (second_edge-first_edge == BITCYC)
            $display("PASS: Exact bit period from prescale.");
          else
            $display("FAIL: Bit period mismatch.");
          $finish;
        end
      end
      last = txd;
    end
  end
endmodule

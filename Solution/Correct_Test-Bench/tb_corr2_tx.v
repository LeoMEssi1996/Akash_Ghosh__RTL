//======================================================================
// tb_corr2_tx: Verify LSB-first serialization (and BIG_ENDIAN option)
//----------------------------------------------------------------------
// Rationale:
//   Former bug was MSB-first. We sample at mid-bit and reconstruct the
//   byte; must match input (or bit-reversed if BIG_ENDIAN=1).
//======================================================================
`timescale 1ns/1ps
module tb_corr2_tx;
  reg clk=0; always #5 clk=~clk;
  reg rst=1;

  reg  [7:0] s_tdata;
  reg        s_tvalid=0;
  wire       s_tready;
  wire       txd, busy;

  localparam integer PRESCALE=6;
  localparam integer BITCYC = PRESCALE*8;

  // Try both modes by flipping parameter if you want.
  uart_tx_corr_2 #(.DATA_WIDTH(8), .BIG_ENDIAN(0)) dut (
    .clk(clk), .rst(rst),
    .s_axis_tdata(s_tdata), .s_axis_tvalid(s_tvalid), .s_axis_tready(s_tready),
    .txd(txd), .busy(busy), .prescale(PRESCALE[15:0])
  );

  task automatic capture_byte(output [7:0] val);
    integer i;
    begin
      // wait START (1->0)
      @(posedge clk); while (txd==1) @(posedge clk);
      // to d0 center: 1.5 bits
      repeat (BITCYC + (BITCYC/2)) @(posedge clk);
      val = 0;
      for (i=0;i<8;i=i+1) begin
        val = {txd, val[7:1]};     // LSB-first sampling
        repeat (BITCYC) @(posedge clk);
      end
    end
  endtask

  initial begin
    repeat(5) @(posedge clk); rst<=0;

    s_tdata  <= 8'h2D;            // 0010_1101 (d0=1)
    s_tvalid <= 1;
    wait (s_tready);
    @(posedge clk) s_tvalid<=0;

    reg [7:0] got;
    capture_byte(got);
    $display("TX put=0x%02h got=0x%02h", 8'h2D, got);
    if (got==8'h2D) $display("PASS: LSB-first as expected.");
    else            $display("FAIL: wrong bit order.");
    $finish;
  end
endmodule

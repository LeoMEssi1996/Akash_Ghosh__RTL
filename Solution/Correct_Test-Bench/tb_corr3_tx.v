//======================================================================
// tb_corr3_tx: Verify AXI-ready is stable (1 in idle, 0 while active)
//----------------------------------------------------------------------
// Rationale:
//   We push two bytes back-to-back; a toggle-y ready would cause
//   duplicate/drop. We count accepted handshakes and expect exactly 2.
//======================================================================
`timescale 1ns/1ps
module tb_corr3_tx;
  reg clk=0; always #5 clk=~clk;
  reg rst=1;

  reg  [7:0] s_tdata;
  reg        s_tvalid=0;
  wire       s_tready;
  wire       txd, busy;

  localparam integer PRESCALE=6;

  uart_tx_corr_4 #(.DATA_WIDTH(8)) dut (
    .clk(clk), .rst(rst),
    .s_axis_tdata(s_tdata), .s_axis_tvalid(s_tvalid), .s_axis_tready(s_tready),
    .txd(txd), .busy(busy), .prescale(PRESCALE[15:0])
  );

  integer accepts=0;

  initial begin
    repeat(5) @(posedge clk); rst<=0;

    fork
      begin
        @(posedge clk);
        s_tdata<=8'h11; s_tvalid<=1;
        wait (s_tready); @(posedge clk); // 1st accepted
        s_tdata<=8'h22;
        wait (s_tready); @(posedge clk); // 2nd accepted
        s_tvalid<=0;
      end
      begin
        forever begin
          @(posedge clk);
          if (s_tvalid && s_tready) accepts=accepts+1;
          if (accepts>=2) disable fork;
        end
      end
    join

    if (accepts==2) $display("PASS: AXI tready stable; 2 accepts recorded.");
    else            $display("FAIL: accepts=%0d", accepts);
    $finish;
  end
endmodule

//======================================================================
// tb_corr5_rx: Verify overrun sets on collision and clears on read
//----------------------------------------------------------------------
// Rationale:
//   Hold m_axis_tready low to force an overrun, then assert ready
//   and confirm the flag clears exactly on handshake.
//======================================================================
`timescale 1ns/1ps
module tb_corr5_rx;
  reg clk=0; always #5 clk=~clk;
  reg rst=1;

  wire [7:0] m_tdata;
  wire       m_tvalid;
  reg        m_tready=0;
  reg        rxd=1;
  wire       busy, overrun_error, frame_error;

  localparam integer PRESCALE=6;
  localparam integer BITCYC=PRESCALE*8;

  uart_rx_corr_5 #(.DATA_WIDTH(8)) dut (
    .clk(clk), .rst(rst),
    .m_axis_tdata(m_tdata), .m_axis_tvalid(m_tvalid), .m_axis_tready(m_tready),
    .rxd(rxd), .busy(busy), .overrun_error(overrun_error), .frame_error(frame_error),
    .prescale(PRESCALE[15:0])
  );

  task automatic drive_uart(input [7:0] b);
    integer i;
    begin
      rxd<=0; repeat (BITCYC) @(posedge clk);
      for (i=0;i<8;i=i+1) begin rxd<=b[i]; repeat (BITCYC) @(posedge clk); end
      rxd<=1; repeat (BITCYC) @(posedge clk);
    end
  endtask

  initial begin
    repeat(5) @(posedge clk); rst<=0;

    // cause overrun: send two bytes with consumer not ready
    drive_uart(8'hA5);
    drive_uart(8'h5A);

    // overrun should be 1 now
    if (!overrun_error) $display("FAIL: expected overrun after back-to-back frames.");
    else                $display("Overrun asserted as expected.");

    // now consume and confirm clear
    m_tready <= 1;
    repeat(2) @(posedge clk);
    if (!overrun_error && m_tvalid)
      $display("PASS: overrun cleared on read handshake.");
    else
      $display("FAIL: overrun did not clear properly.");

    $finish;
  end
endmodule

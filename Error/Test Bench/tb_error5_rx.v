//TB for Error-5 (RX overrun flag never clears)

`timescale 1ns/1ps

module tb_error5_rx;

  reg clk=0; always #5 clk=~clk;
  reg rst=1;

  wire [7:0] m_axis_tdata;
  wire       m_axis_tvalid;
  reg        m_axis_tready=0; // hold off to force overrun
  reg        rxd=1;
  wire       busy, overrun_error, frame_error;

  localparam integer PRESCALE=6;
  localparam integer BITCYC=PRESCALE*8;

  Error_05 #(.DATA_WIDTH(8)) dut (
    .clk(clk), .rst(rst),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .rxd(rxd),
    .busy(busy),
    .overrun_error(overrun_error),
    .frame_error(frame_error),
    .prescale(PRESCALE[15:0])
  );

  task automatic drive_uart_byte(input [7:0] b);
    integer i;
    begin
      rxd <= 0; repeat (BITCYC) @(posedge clk); // start
      for (i=0;i<8;i=i+1) begin rxd<=b[i]; repeat (BITCYC) @(posedge clk); end
      rxd <= 1; repeat (BITCYC) @(posedge clk);
    end
  endtask

  initial begin
    repeat(4) @(posedge clk);
    rst <= 0;

    // send two bytes while consumer is not ready -> overrun must set
    drive_uart_byte(8'hA5);
    drive_uart_byte(8'h5A);

    // now accept one
    m_axis_tready <= 1;
    repeat(4) @(posedge clk);

    // in broken RTL, overrun_error stays stuck high
    if (overrun_error) $display("FAIL (BUG TRIGGERED): overrun flag is sticky and did not clear.");
    else               $display("PASS (unexpected for broken RTL).");
    $finish;
  end
endmodule

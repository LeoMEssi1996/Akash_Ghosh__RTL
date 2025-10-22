//TB for Error-4 (TX counter too small for DATA_WIDTH=16)

`timescale 1ns/1ps

module tb_error4_tx;
  reg clk=0; always #5 clk=~clk;
  reg rst=1;

  reg  [15:0] s_axis_tdata = 16'hBEEF;
  reg         s_axis_tvalid=0;
  wire        s_axis_tready;
  wire        txd, busy;

  localparam integer PRESCALE=6;
  localparam integer BITCYC=PRESCALE*8;

  Error_04 #(.DATA_WIDTH(16)) dut (
    .clk(clk), .rst(rst),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .txd(txd), .busy(busy),
    .prescale(PRESCALE[15:0])
  );

  integer edges;
  reg prev;

  initial begin
    repeat(4) @(posedge clk);
    rst <= 0;

    @(posedge clk);
    s_axis_tvalid <= 1;
    wait(s_axis_tready);
    @(posedge clk);
    s_axis_tvalid <= 0;

    // count falling edges after start; should see many (data toggles)
    prev = 1; edges=0;
    repeat (BITCYC*30) begin
      @(posedge clk);
      if (txd!=prev) edges=edges+1;
      prev = txd;
    end
    // if counter wraps early, frame length is too short -> fewer transitions
    if (edges < 10)
      $display("FAIL (BUG TRIGGERED): truncated frame (bit counter too small), edges=%0d", edges);
    else
      $display("PASS (unexpected for broken RTL) edges=%0d", edges);

    $finish;
  end
endmodule

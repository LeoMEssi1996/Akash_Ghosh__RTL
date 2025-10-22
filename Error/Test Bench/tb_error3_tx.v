// TB for Error-3 (TX toggles tready, violating AXI handshake)
`timescale 1ns/1ps

module tb_error3_tx;

  reg clk=0; always #5 clk=~clk;
  reg rst=1;

  reg  [7:0] s_axis_tdata;
  reg        s_axis_tvalid=0;
  wire       s_axis_tready;
  wire       txd, busy;

  localparam integer PRESCALE=6;

  Error_03 #(.DATA_WIDTH(8)) dut (
    .clk(clk), .rst(rst),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .txd(txd), .busy(busy),
    .prescale(PRESCALE[15:0])
  );

  integer accepted;
  initial begin
    repeat(4) @(posedge clk);
    rst <= 0;

    // stream two bytes back-to-back; a ready toggle may cause double-accept or drop
    accepted = 0;
    fork
      begin
        s_axis_tdata  <= 8'h11;
        s_axis_tvalid <= 1;
        repeat(2) @(posedge clk);
        s_axis_tdata  <= 8'h22;
        repeat(2) @(posedge clk);
        s_axis_tvalid <= 0;
      end
      begin
        forever begin
          @(posedge clk);
          if (s_axis_tvalid && s_axis_tready) begin
            accepted = accepted + 1;
            $display("ACCEPT @%0t data=0x%02h", $time, s_axis_tdata);
          end
          if (accepted>=2) disable fork;
        end
      end
    join

    if (accepted != 2) begin
      $display("FAIL (BUG TRIGGERED): AXI acceptance count=%0d (expected 2).", accepted);
    end else begin
      $display("Check wave: duplicated/dropped frames can still occur due to toggle; review in sim.");
    end
    $finish;
  end
endmodule

//TB for Error-2 (TX sends MSB-first)

`timescale 1ns/1ps

module tb_error2_tx;

  reg clk=0; always #5 clk=~clk;
  reg rst=1;

  reg  [7:0] s_axis_tdata;
  reg        s_axis_tvalid=0;
  wire       s_axis_tready;
  wire       txd;
  wire       busy;

  localparam integer PRESCALE=6;
  localparam integer BITCYC = PRESCALE*8;

  Error_02 #(.DATA_WIDTH(8)) dut (
    .clk(clk), .rst(rst),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .txd(txd), .busy(busy),
    .prescale(PRESCALE[15:0])
  );

  // simple sampler: sample mid-bit and rebuild the byte from wire
  task automatic capture_uart_byte(output [7:0] val);
    integer i, c;
    begin
      // wait start bit (1->0)
      @(posedge clk);
      while (txd==1) @(posedge clk);

      // wait 1.5 bit to center of d0
      for (c=0; c<(BITCYC + BITCYC/2); c=c+1) @(posedge clk);

      val = 8'h00;
      for (i=0;i<8;i=i+1) begin
        val = {txd, val[7:1]}; // LSB-first capture
        // wait 1 bit
        repeat (BITCYC) @(posedge clk);
      end
      // stop bit not checked here
    end
  endtask

  initial begin
    repeat(4) @(posedge clk);
    rst <= 0;

    s_axis_tdata  <= 8'h2D; // 0010_1101  (LSB-first should send d0=1)
    @(posedge clk);
    s_axis_tvalid <= 1;
    wait(s_axis_tready);
    @(posedge clk);
    s_axis_tvalid <= 0;

    // capture
    reg [7:0] got;
    capture_uart_byte(got);
    $display("TX put=0x%02h, captured=0x%02h", 8'h2D, got);
    if (got == 8'hB4) begin
      $display("FAIL (BUG TRIGGERED): MSB-first caused bit reversal (0x2D -> 0xB4)");
    end else begin
      $display("PASS (unexpected for broken RTL) got=0x%02h", got);
    end
    $finish;
  end
endmodule

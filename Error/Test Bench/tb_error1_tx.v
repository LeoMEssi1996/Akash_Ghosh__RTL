//TB for Error 1 (TX prescaler off-by-one ---> bit time too short)
`timescale 1ns/1ps

module tb_error1_tx;

  // clock/reset
  reg clk = 0; always #5 clk = ~clk; // 100 MHz
  reg rst = 1;

  // AXI in
  reg  [7:0]  s_axis_tdata  = 8'h55;
  reg         s_axis_tvalid = 0;
  wire        s_axis_tready;

  // uart
  wire txd;
  wire busy;

  // prescale (tiny for sim). expected bit period = (prescale*8) clocks
  localparam integer PRESCALE = 6; // expect 48 clk/cycle
  localparam integer EXP_BIT  = PRESCALE*8;

  // DUT (broken)
  Error_01 #(.DATA_WIDTH(8)) dut (
    .clk(clk), .rst(rst),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .txd(txd), .busy(busy),
    .prescale(PRESCALE[15:0])
  );

  // measure start→first data-bit edge to estimate bit time
  integer last_edge_cycle, bit_cycles, cycles;
  reg     prev_txd;

  initial begin
    repeat(4) @(posedge clk);
    rst <= 0;

    // push one byte
    @(posedge clk);
    s_axis_tvalid <= 1;
    wait(s_axis_tready);
    @(posedge clk);
    s_axis_tvalid <= 0;

    // wait for start bit
    prev_txd = 1'b1;
    last_edge_cycle = 0;
    cycles = 0;

    forever begin
      @(posedge clk);
      cycles = cycles + 1;
      if (txd !== prev_txd) begin
        // first edge will be idle---->start (1--->0), second is start->d0
        if (last_edge_cycle==0) begin
          last_edge_cycle = cycles; // mark start
        end else begin
          bit_cycles = cycles - last_edge_cycle;
          $display("Measured bit period (clk cycles) = %0d, expected = %0d", bit_cycles, EXP_BIT);
          if (bit_cycles < EXP_BIT) begin
            $display("FAIL (BUG TRIGGERED): bit time too SHORT due to off-by-one prescale");
          end else begin
            $display("PASS (unexpected for broken RTL)");
          end
          $finish;
        end
      end
      prev_txd = txd;
    end
  end

endmodule

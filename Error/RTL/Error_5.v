//Error_5 — RX overrun flag never clears
//============================================================
// BUG #5: overrun_error never cleared; set even on successful accept
// Effect: latched high permanently after first overrun
//============================================================
`timescale 1ns/1ps
module Error_05 #(parameter DATA_WIDTH=8)(
    input  wire                   clk,
    input  wire                   rst,
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    input  wire                   rxd,
    output wire                   busy,
    output wire                   overrun_error,
    output wire                   frame_error,
    input  wire [15:0]            prescale
);
    reg [DATA_WIDTH-1:0] data_q        = 0;
    reg                  valid_q       = 1'b0;
    reg                  busy_q        = 1'b0;
    reg                  overrun_q     = 1'b0;  // <— BUG sticky
    reg                  frame_err_q   = 1'b0;
    reg [3:0]            bit_cnt_q     = 0;
    reg [18:0]           prescale_cnt_q= 0;
    reg                  rxd_q         = 1'b1;

    assign m_axis_tdata  = data_q;
    assign m_axis_tvalid = valid_q;
    assign busy          = busy_q;
    assign overrun_error = overrun_q;
    assign frame_error   = frame_err_q;

    always @(posedge clk) begin
        if (rst) begin
            data_q<=0; valid_q<=0; busy_q<=0; overrun_q<=0; frame_err_q<=0;
            bit_cnt_q<=0; prescale_cnt_q<=0; rxd_q<=1;
        end else begin
            rxd_q <= rxd;

            if (valid_q && m_axis_tready) begin
                valid_q <= 1'b0;
                // BUG: should clear overrun here when consumer drains; not done
            end

            if (prescale_cnt_q != 0) begin
                prescale_cnt_q <= prescale_cnt_q - 1'b1;
            end else if (bit_cnt_q == 0) begin
                if (!rxd_q) begin
                    busy_q        <= 1'b1;
                    bit_cnt_q     <= DATA_WIDTH + 2;
                    prescale_cnt_q<= (prescale<<2) - 2; // 1.5 bits to d0
                    data_q        <= 0;
                end
            end else begin
                if (bit_cnt_q > 1) begin
                    bit_cnt_q     <= bit_cnt_q - 1'b1;
                    prescale_cnt_q<= (prescale<<3) - 1;
                    data_q        <= {rxd_q, data_q[DATA_WIDTH-1:1]};
                end else begin
                    bit_cnt_q     <= 0;
                    busy_q        <= 0;
                    if (rxd_q) begin
                        // BUG: sets overrun regardless and never clears
                        overrun_q <= valid_q; 
                        valid_q   <= 1'b1;
                    end else begin
                        frame_err_q <= 1'b1;
                    end
                end
            end
        end
    end
endmodule

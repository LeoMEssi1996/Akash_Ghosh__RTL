//============================================================
// UART_RX_CORR_5 — clean overrun lifecycle + diagnostics
//------------------------------------------------------------
// Fix:
//   overrun_error is set only when a fresh byte arrives while
//   previous valid byte is still pending; it is cleared when the
//   consumer handshakes (valid && ready).
//
// Creativity
//   A small 8-bit counter tracks cumulative overruns for field debug.
//============================================================
`timescale 1ns/1ps
module uart_rx_corr_5 #(
    parameter DATA_WIDTH = 8
)(
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
    reg rx1_q=1'b1, rx2_q=1'b1; always @(posedge clk) begin rx1_q<=rxd; rx2_q<=rx1_q; end
    wire rx = rx2_q;

    reg [DATA_WIDTH-1:0] data_q=0;
    reg                  valid_q=0, busy_q=0, ovr_q=0, frm_q=0;
    reg [7:0]            ovr_count_q=0;           // innovation: sticky stats
    reg [5:0]            bit_cnt_q=0;
    reg [18:0]           prescale_cnt_q=0;

    assign m_axis_tdata  = data_q;
    assign m_axis_tvalid = valid_q;
    assign busy          = busy_q;
    assign overrun_error = ovr_q;
    assign frame_error   = frm_q;

    always @(posedge clk) begin
        if (rst) begin
            data_q<=0; valid_q<=0; busy_q<=0; ovr_q<=0; frm_q<=0; bit_cnt_q<=0; prescale_cnt_q<=0; ovr_count_q<=0;
        end else begin
            // clear on consumption
            if (valid_q && m_axis_tready) begin
                valid_q <= 1'b0;
                ovr_q   <= 1'b0;    //  cleared here
            end

            if (prescale_cnt_q!=0) prescale_cnt_q<=prescale_cnt_q-1'b1;
            else if (bit_cnt_q==0) begin
                if (!rx) begin
                    busy_q<=1'b1; bit_cnt_q<=DATA_WIDTH+2; prescale_cnt_q<=(prescale<<2)-2; data_q<=0; frm_q<=0;
                end
            end else begin
                if (bit_cnt_q>1) begin
                    bit_cnt_q<=bit_cnt_q-1'b1; prescale_cnt_q<=(prescale<<3)-1; data_q<={rx, data_q[DATA_WIDTH-1:1]};
                end else begin
                    bit_cnt_q<=0; busy_q<=0;
                    if (rx) begin
                        if (valid_q) begin ovr_q<=1'b1; ovr_count_q<=ovr_count_q+1'b1; end
                        valid_q<=1'b1;
                    end else frm_q<=1'b1;
                end
            end
        end
    end
endmodule

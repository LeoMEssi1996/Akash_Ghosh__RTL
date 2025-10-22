//============================================================
// UART_TX_CORR_4 — parameter-robust counter sizing
//------------------------------------------------------------
// Fix:
//   Counter now sized via $clog2(DATA_WIDTH+3) so any width works.
//
// Creativity
//   Same module synthesizes for 5..64+ bit frames without edits.
//============================================================
`timescale 1ns/1ps
module uart_tx_corr_4 #(
    parameter DATA_WIDTH = 16
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    output wire                   txd,
    output wire                   busy,
    input  wire [15:0]            prescale
);
    localparam CNT_W = (DATA_WIDTH+3 <= 2) ? 1 : $clog2(DATA_WIDTH+3);

    reg [DATA_WIDTH:0] shreg_q=0;
    reg [CNT_W-1:0]    bit_cnt_q=0;
    reg [18:0]         prescale_cnt_q=0;
    reg tx_q=1'b1, ready_q=1'b1, busy_q=1'b0;

    assign s_axis_tready=ready_q; assign txd=tx_q; assign busy=busy_q;

    always @(posedge clk) begin
        if (rst) begin shreg_q<=0; bit_cnt_q<=0; prescale_cnt_q<=0; tx_q<=1; ready_q<=1; busy_q<=0; end
        else begin
            if (prescale_cnt_q!=0) prescale_cnt_q<=prescale_cnt_q-1'b1;
            else if (bit_cnt_q==0) begin
                ready_q<=1;
                if (s_axis_tvalid && ready_q) begin
                    shreg_q<={1'b1,s_axis_tdata}; tx_q<=0; ready_q<=0; busy_q<=1;
                    bit_cnt_q<=DATA_WIDTH+1; prescale_cnt_q<=(prescale<<3)-1;
                end else busy_q<=0;
            end else begin
                if (bit_cnt_q>1) begin bit_cnt_q<=bit_cnt_q-1'b1; prescale_cnt_q<=(prescale<<3)-1; {shreg_q,tx_q}<={1'b0,shreg_q}; end
                else begin bit_cnt_q<=0; tx_q<=1; prescale_cnt_q<=(prescale<<3)-1; ready_q<=1; busy_q<=0; end
            end
        end
    end
endmodule

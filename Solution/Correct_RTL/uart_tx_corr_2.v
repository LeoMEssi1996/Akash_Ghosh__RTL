//============================================================
// UART_TX_CORR_2 — Correct LSB-first shift; optional BIG_ENDIAN load
//------------------------------------------------------------
// Fix:
//   Buggy TX shifted left (MSB-first). We right-shift the payload
//   so d0 goes first on the wire.
//
//   Creativity
//   BIG_ENDIAN parameter bit-reverses the payload on load via a
//   small function, giving easy interoperability with MSB-first buses.
//============================================================
`timescale 1ns/1ps
module uart_tx_corr_2 #(
    parameter DATA_WIDTH = 8,
    parameter BIG_ENDIAN = 0  // 0=LSB order as provided; 1=reverse bits on load
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
    // simple bit-reversal for Verilog-2001
    function [DATA_WIDTH-1:0] f_rev;
        integer k;
        input [DATA_WIDTH-1:0] x;
        begin
            for (k=0;k<DATA_WIDTH;k=k+1) f_rev[k] = x[DATA_WIDTH-1-k];
        end
    endfunction

    wire [DATA_WIDTH-1:0] load_data = BIG_ENDIAN ? f_rev(s_axis_tdata) : s_axis_tdata;

    reg [DATA_WIDTH:0] shreg_q        = 0;
    reg [5:0]          bit_cnt_q      = 0;
    reg [18:0]         prescale_cnt_q = 0;
    reg                tx_q           = 1'b1;
    reg                ready_q        = 1'b1;
    reg                busy_q         = 1'b0;

    assign s_axis_tready = ready_q;
    assign txd           = tx_q;
    assign busy          = busy_q;

    always @(posedge clk) begin
        if (rst) begin
            shreg_q<=0; bit_cnt_q<=0; prescale_cnt_q<=0;
            tx_q<=1; ready_q<=1; busy_q<=0;
        end else begin
            if (prescale_cnt_q!=0) prescale_cnt_q <= prescale_cnt_q - 1'b1;
            else if (bit_cnt_q==0) begin
                ready_q <= 1'b1;
                if (s_axis_tvalid && ready_q) begin
                    shreg_q        <= {1'b1, load_data};
                    tx_q           <= 1'b0;                       // start
                    prescale_cnt_q <= (prescale<<3) - 1;
                    bit_cnt_q      <= DATA_WIDTH + 1;
                    ready_q        <= 1'b0; busy_q <= 1'b1;
                end else busy_q <= 1'b0;
            end else begin
                if (bit_cnt_q>1) begin
                    bit_cnt_q      <= bit_cnt_q - 1'b1;
                    prescale_cnt_q <= (prescale<<3) - 1;
                    {shreg_q, tx_q} <= {1'b0, shreg_q};           //  LSB-first
                end else begin
                    bit_cnt_q<=0; tx_q<=1; prescale_cnt_q<=(prescale<<3)-1; ready_q<=1; busy_q<=0;
                end
            end
        end
    end
endmodule

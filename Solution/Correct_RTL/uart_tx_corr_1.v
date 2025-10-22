//============================================================
// UART_TX_CORR_1 — Correct bit-time using (prescale<<3)-1
//------------------------------------------------------------
// Fix:
//   The buggy version loaded (prescale<<3) without -1, making the
//   bit period one tick short. We reload (prescale<<3)-1 at START,
//   each DATA bit, and STOP, so every cell is exactly 8*prescale clk.
//
//   Creativity
//   Keeps interface stable (tready=1 only in idle), making backpressure
//   behavior explicit and timing-friendly.
//============================================================
`timescale 1ns/1ps
module uart_tx_corr_1 #(
    parameter DATA_WIDTH = 8
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

    reg [DATA_WIDTH:0] shreg_q        = 0; // {stop, data[7:0]} for right-shift
    reg [5:0]          bit_cnt_q      = 0; // enough for data+stop
    reg [18:0]         prescale_cnt_q = 0;
    reg                tx_q           = 1'b1;
    reg                ready_q        = 1'b1;
    reg                busy_q         = 1'b0;

    assign s_axis_tready = ready_q;
    assign txd           = tx_q;
    assign busy          = busy_q;

    always @(posedge clk) begin
        if (rst) begin
            shreg_q        <= 0;
            bit_cnt_q      <= 0;
            prescale_cnt_q <= 0;
            tx_q           <= 1'b1;
            ready_q        <= 1'b1;
            busy_q         <= 1'b0;
        end else begin
            if (prescale_cnt_q != 0) begin
                prescale_cnt_q <= prescale_cnt_q - 1'b1;
            end else if (bit_cnt_q == 0) begin
                // idle
                ready_q <= 1'b1;
                busy_q  <= 1'b0;
                if (s_axis_tvalid && ready_q) begin
                    // start bit
                    shreg_q        <= {1'b1, s_axis_tdata};
                    tx_q           <= 1'b0;
                    prescale_cnt_q <= (prescale<<3) - 1;  //  exact bit time
                    bit_cnt_q      <= DATA_WIDTH + 1;     // data + stop scheduling tick
                    ready_q        <= 1'b0;
                    busy_q         <= 1'b1;
                end
            end else begin
                // active frame
                if (bit_cnt_q > 1) begin
                    bit_cnt_q      <= bit_cnt_q - 1'b1;
                    prescale_cnt_q <= (prescale<<3) - 1;
                    {shreg_q, tx_q} <= {1'b0, shreg_q};   // LSB first
                end else begin
                    // stop bit
                    bit_cnt_q      <= 0;
                    tx_q           <= 1'b1;
                    prescale_cnt_q <= (prescale<<3) - 1;  // hold full stop cell
                    ready_q        <= 1'b1;
                    busy_q         <= 1'b0;
                end
            end
        end
    end
endmodule

//BUG-1 — off-by-one prescaler (baud too fast)

//==========================================================================================
// BUG 1: Prescaler loaded as (prescale<<3) instead of ((prescale<<3)-1)
// Effect: bit period is one cycle short across start/data/stop -> ~12.5% fast
//=========================================================================================
`timescale 1ns/1ps

module Error_01 
(
    input                    clk,
    input                    rst,
    input  [7:0]  s_axis_tdata,
    input                    s_axis_tvalid,
    output  reg                 s_axis_tready,
    output   reg                 txd,
    output   reg                 busy,
    input   [15:0]            prescale
);

    
    reg [7:0] shreg_q;
    reg [3:0]          bit_cnt_q;
    reg [18:0]         prescale_cnt_q; 
    

    

    always @(posedge clk) begin
        if (rst) begin
            shreg_q           = 8'b0;
            bit_cnt_q         = 4'd0;
            prescale_cnt_q    = 19'd0;
            txd               = 1;
            s_axis_tready     = 1;
            busy              = 0;
        end else begin
            if (prescale_cnt_q != 0) begin
                prescale_cnt_q = prescale_cnt_q - 1'b1;
            end else if (bit_cnt_q == 0) begin
                if (s_axis_tvalid && tready_q) begin
                    // BUG: missing -1 makes the bit time short
                    prescale_cnt_q = (prescale << 3);  
                    bit_cnt_q      = 8 + 1'b1;
                    shreg_q        = {1'b1, s_axis_tdata};
                    tx             = 0;             
                 s_axis_tready     = 1;
                 busy              = 1;
                end
            end else begin
                if (bit_cnt_q > 1) begin
                    bit_cnt_q      = bit_cnt_q - 1'b1;
                    prescale_cnt_q = (prescale << 3);   
                    {shreg_q, tx_q} = {1'b0, shreg_q};
                end else begin
                    bit_cnt_q      = 4'd0;
                    prescale_cnt_q = (prescale << 3);
                    tx              = 1;
                    s_axis_tready       = 1;
                    busy        = 0;
                end
            end
        end
    end
endmodule
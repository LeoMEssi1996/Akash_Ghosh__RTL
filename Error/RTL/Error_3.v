Error 3 — AXI handshake toggles tready


//==========================================================================
// BUG 3: tready toggled each idle cycle; violates AXI ready rule
// Effect: occasional duplicate/drop on TX enqueue
//==========================================================================


module Error_03 (
    input  wire                   clk,
    input  wire                   rst,
    input  wire [7:0]  s_axis_tdata,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    output wire                   txd,
    output wire                   busy,
    input  wire [15:0]            prescale
);
    reg                tready_q; // BUG toggled below
    reg                tx_q;
    reg [3:0]          bit_cnt_q;
    reg [18:0]         prescale_cnt_q;
    reg [8:0]          shreg_q;

  assign s_axis_tready = tready_q;  

    always @(posedge clk) begin
        if (rst) begin
            tready_q<=1; 
			txd<=1; 
			busy<=0; 
			bit_cnt_q<=0; 
			prescale_cnt_q<=0; 
			shreg_q<=0;
        end else begin
            if (prescale_cnt_q != 0) begin
                prescale_cnt_q <= prescale_cnt_q - 1'b1;
            end else if (bit_cnt_q == 0) begin
                // Wrong: gratuitous toggle
                tready_q <= ~tready_q;  //  Wrong
                if (s_axis_tvalid && tready_q) begin
                    prescale_cnt_q <= (prescale<<3) - 1;
                    bit_cnt_q      <= 4'd9;
                    shreg_q        <= {1'b1, s_axis_tdata};
                    txd          <= 1'b0;
                    busy         <= 1'b1;
                end
            end else begin
                if (bit_cnt_q > 1) begin
                    bit_cnt_q      <= bit_cnt_q - 1'b1;
                    prescale_cnt_q <= (prescale<<3) - 1;
                    {shreg_q, tx_q}<= {1'b0, shreg_q};
                end else begin
                    bit_cnt_q      <= 0;
                    prescale_cnt_q <= (prescale<<3) - 1;
                    txd          <= 1'b1;
                    tready_q       <= 1'b1;
                    busy        <= 1'b0;
                end
            end
        end
    end
endmodule

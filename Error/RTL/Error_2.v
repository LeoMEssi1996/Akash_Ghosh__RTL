//Error 2 — MSB-first on TX (should be LSB-first)

//======================================================================================
// BUG 2: Transmits MSB first by shifting left
// Effect: bytes are bit-reversed on the wire (0x55 -> 0xAA in loopback)
//=========================================================================================
module Error_02(clk,rst,s_axi_tdata,s_axi_tvalid,s_axi_tready,txd,busy,pre_scale);

    input                        clk;
    input                        rst;
    input         [7:0]   s_axi_tdata;
    input                     s_axi_tvalid;
	input   [15:0]            pre_scale;
    output reg                   s_axi_tready;
    output reg                   txd;
    output reg                   busy;
    

    reg [DATA_WIDTH:0] shreg_q;
    reg [3:0]          bit_cnt_q;
    reg [18:0]         prescale_cnt_q;
  

   
    always @(posedge clk) begin
        if (rst) begin
            {shreg_q, bit_cnt_q, prescale_cnt_q, txd, s_axis_tready, busy} <= {0, 0, 0, 1'b1, 1'b1, 1'b0};

        end 
		else begin
            if (prescale_cnt_q != 0) begin
                prescale_cnt_q <= prescale_cnt_q - 1'b1;
            end else if (bit_cnt_q == 0) begin
                if (s_axis_tvalid && tready_q) begin
                    prescale_cnt_q <= (prescale<<3) - 1;
                    bit_cnt_q      <= DATA_WIDTH + 1;
                    busy         <= 1'b1;
                    s_axis_tready      <= 1'b0;
                    tx        <= 1'b0;                  // start
                    shreg_q        <= {1'b1, s_axis_tdata};  // preload
                end
            end else begin
                if (bit_cnt_q > 1) begin
                    bit_cnt_q      <= bit_cnt_q - 1'b1;
                    prescale_cnt_q <= (prescale<<3) - 1;
                    // BUG: shift left (MSB-first)
                    shreg_q        <= {shreg_q[DATA_WIDTH-1:0], 1'b0}; // BUG
                    tx_q           <= shreg_q[DATA_WIDTH];             //  BUG
                end else begin
                    bit_cnt_q      <= 0;
                    prescale_cnt_q <= (prescale<<3) - 1;
                    txd         <= 1'b1;
                    s_axis_tready      <= 1'b1;
                    busy        <= 1'b0;
                end
            end
        end
    end
endmodule
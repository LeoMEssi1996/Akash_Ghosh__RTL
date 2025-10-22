//Error 4 — bit counter too narrow for wider words



//============================================================
// BUG 4: bit counter is 4 bits while DATA_WIDTH=16
// Effect: counter wraps -> frame truncated/garbled
//============================================================

module Error_04 #(parameter DATA_WIDTH=16)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    output wire                   txd,
    output wire                   busy,
    input  wire [15:0]            prescale
);
    reg [DATA_WIDTH:0] shreg_q;
    reg [3:0]          bit_cnt_q; // <— BUG width
    reg [18:0]         prescale_cnt_q;
    
	

    always @(posedge clk) begin
        if (rst) begin
		shreg_q<=0;
		bit_cnt_q<=0; 
		prescale_cnt_q<=0;
		txd<=1;
		s_axis_tready<=1; 
		busy<=0; 
		end
        else begin
            if (prescale_cnt_q != 0) begin 
			
			prescale_cnt_q <= prescale_cnt_q - 1'b1;
			end
			
            else if (bit_cnt_q == 0) begin
                if (s_axis_tvalid && tready_q) begin
                    prescale_cnt_q <= (prescale<<3)-1;
                    bit_cnt_q      <= DATA_WIDTH + 1; // wraps in 4 bits -> BUG
                    shreg_q        <= {1'b1, s_axis_tdata};
                    txd           <= 1'b0;
                    s_axis_tready       <= 1'b0;
                    busy         <= 1'b1;
                end
            end else begin
                if (bit_cnt_q > 1) begin 
				bit_cnt_q <= bit_cnt_q - 1'b1;
				prescale_cnt_q <= (prescale<<3)-1;
				{shreg_q, tx_q} <= {1'b0, shreg_q};

				end
                else begin 
				bit_cnt_q <= 0; 
				prescale_cnt_q <= (prescale<<3)-1; 
				txd <= 1'b1; 
				s_axis_tready <= 1'b1;
				busy <= 1'b0; 
				end
            end
        end
    end
endmodule
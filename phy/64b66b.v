/* 64b/66b encoder and scrable, used for transmission path */
module scrambler_64b66b_tx #(
	parameter BLOCKS = 8, // number of blocks
	parameter LEN    = 8 // size of each block in bits
)
(
	input clk,
	input nreset,

	input                   valid_i,
	input  [BLOCKS*LEN-1:0] data_i,
	output [BLOCKS*LEN-1:0] scram_o
);
localparam S_W = 58*8; // 464
// S_58 to S_0, previously scrambled data
reg   [S_W-1:0] s_q;
logic [S_W-1:0] s_next;

// scramble
genvar i;
generate
	for (  i = 0; i < BLOCKS; i++ ) begin
		assign scram_o[i*LEN+LEN-1:i*LEN] = {{LEN-1{1'b0}}, 1'b1} 
										  ^ s_q[(39-i)*LEN+LEN-1:(39-i)*LEN] 
										  ^ s_q[(57-i)*LEN+LEN-1:(57-i)*LEN]; 
	end
endgenerate

// flop prviously scrambled data
assign s_next = { s_q[S_W-BLOCKS*LEN-1:0], scram_o };
always @(posedge clk) begin
	if ( ~nreset ) begin
		s_q <= {BLOCKS*LEN{1'b0}};
	end else if ( valid_i  == 1'b1 ) begin
		s_q <= s_next;
	end
end

endmodule


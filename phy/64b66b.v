/* 64b/66b encoder and scrable, used for transmission path */
module scrambler_64b66b_tx #(
	parameter LEN    = 32 // size of each block in bits
)
(
	input clk,
	input nreset,

	input                   valid_i,
	input  [LEN-1:0] data_i,
	output [LEN-1:0] scram_o
);
localparam S_W = 58;
// S_58 to S_0, previously scrambled data
reg   [S_W-1:0] s_q;
logic [S_W-1:0] s_next;

// scramble
genvar i;
generate
	for (  i = 0; i < LEN; i++ ) begin : xor_loop
		assign scram_o[i] = data_i[i]^ ( s_q[38-i] ^ s_q[57-i] ); 
	end
endgenerate

// flop prviously scrambled data
assign s_next[S_W-1:LEN] = s_q[LEN-1:0];
generate
	for ( i = 0; i < LEN; i++) begin
		assign s_next[LEN-i-1] = scram_o[i];
	end
endgenerate
always @(posedge clk) begin
	if ( ~nreset ) begin
		// scrambler's initial start is set to all 1's
		s_q <= {S_W{1'b1}};
	end else if ( valid_i  == 1'b1 ) begin
		s_q <= s_next;
	end
end
endmodule


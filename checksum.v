/* Generic Checksum module, breaks adder path into tree */
module checksum #(
	parameter SUM_W  = 16,
	parameter DATA_W = 32 
)(
	input [DATA_W-1:0] data_i,

	output [SUM_W-1:0] data_o
);
localparam N = DATA_W/SUM_W;
localparam N_LOG2 = $clog2(N);

logic [SUM_W-1:0]  sum;
logic [SUM_W-1:0]  sum_wrap;
logic              sum_wrap_overflow;
logic [N_LOG2-1:0] carry;

checksum_inner #( .DATA_N(N) , .C_W(N_LOG2), .SUM_W(SUM_W))
m_checksum_recursive(
	.data_i(data_i),
	.data_o( { carry, sum })
); 
//wrap sum
assign { sum_wrap_overflow, sum_wrap } = sum + carry; 
// ones complement
assign data_o = ~sum_wrap;
endmodule

module checksum_inner #(
	parameter DATA_N = 4,
	parameter C_W    = 2,
	parameter SUM_W  = 16 
)(
	input  [DATA_N*SUM_W-1:0]       data_i,
	output [C_W+SUM_W-1:0] data_o,
);
localparam W = C_W+SUM_W;
	if ( DATA_N == 2 ) begin
		assign data_o = data_i[2*W+W-1:W] + data_i[W-1:0];
	end else begin
		logic [C_W-1+SUM_W-1:0] msb_sum;	
		logic [C_W-1+SUM_W-1:0] lsb_sum;	
		checksum_inner #(.DATA_N(DATA_N/2), .C_W(C_W-1) , .SUM_W(SUM_W)) 
		m_checksum_msb( 
			.data_i(data_i[DATA_N*(C_W+SUM_W)-1:(DATA_N/2)*(C_W+SUM_W)] ),
			.data_o(msb_sum)		
	 	);
		checksum_inner #(.DATA_N(DATA_N/2), .C_W(C_W-1) , .SUM_W(SUM_W)) 
		m_checksum_lsb( 
			.data_i(data_i[DATA_N*(C_W+SUM_W)-1:(DATA_N/2)*(C_W+SUM_W)] ),
			.data_o(msb_sum)		
	 	);
		assign data_o = msb_sum + lsb_sum;	
	end
endmodule

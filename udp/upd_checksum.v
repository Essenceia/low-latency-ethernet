module udp_rx_checksum #(
	parameter SUM_W  = 16
	parameter DATA_W = 32,
	parameter KEEP_W = $clog2(DATA_W)
)(
	input clk, 
	input nreset,

	input              data_v_i,
	input [DATA_W-1:0] data_i,
	input [KEEP_W-1:0] keep_i,
	input              last_i,

	input              checksum_v_i,
	input [SUM_W-1:0]  checksum_i,

	output              err_v_o
);
// expected checksum
reg   [SUM_W-1:0] exp_checksum_q;
logic [SUM_W-1:0] exp_checksum_next;
// computed checksum
reg   [SUM_W-1:0] sum_q;
logic [SUM_W-1:0] sum_next;
logic [SUM_W-1:0] sum;
logic             match;

assign exp_checksum_next = checksum_i;
// reset sum on last block
assign sum_next = {SUM_W{~(valid_i & last_i)}} & sum; 
always @(posedge clk) begin
	if ( checksum_v_i ) begin
		exp_checksum_q <= exp_checksum_next;
	end
	if ( valid_i ) begin
		sum_q <= sum_next;
	end
end
assign match = sum == exp_checksum_q;

// mask out input data we should not keep
logic [DATA_W-1:0] data_masked;
genvar i;
generate
	for( i = 0; i < KEEP_W; i++ ) begin
		assign data_masked[i*8+7:i*8] = {8{keep_i[i]}} & data_i[i*8+7:i*8];
	end
endgenerate

// calculate 
checksum #(.SUM_W(SUM_W) , .DATA_W(DATA_W) ) 
m_checksum
(
	.data_i(data_masked),
	.data_o(sum)
);
// output
assign err_v_o = ( valid_i & last_i ) & ~match;

endmodule

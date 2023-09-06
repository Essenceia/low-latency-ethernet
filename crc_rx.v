/* CRC computation for ethernet MAC frame check sequence
 * G(x) = x32 + x26 + x23 + x22 + x16 + x12 + x11 + x10 
 *      + x8 + x7 + x5 + x4 + x2 + x + 1
 * */
module crc32_rx #(
	parameter SUM_W  = 32
)(
	input clk,

	input             start_i,
	input             valid_i,
	input [SUM_W-1:0] data_i,

	output [SUM_W-1:0] crc_o
);

reg   [SUM_W-1:0]  sum;
reg   [SUM_W-1:0]  sum_q;
logic [SUM_W-1:0]  sum_lite_next;
logic [SUM_W-1:0]  sum_next;

logic [SUM_W-1:0] res;

assign sum = start_i ? {SUM_W{1'b1}}: sum_q;
genvar i;
generate
	for( i=SUM_W-1; i > -1; i--) begin
		localparam j = (SUM_W-1)-i;
		logic [SUM_W-1:0] buff;
		if( j == 0 ) begin
			/* s31, ..., s0 */ 
			assign buff = sum;
		end else begin
			/* .. , s2, s1, s0, d31, d30, d29 */
			assign buff = { sum[SUM_W-j-1:0], res[j:0]} ;
		end
		
		logic [SUM_W:0] poly;	
		assign poly = 33'b0 
				   | 33'b1
				   |(33'b1 <<  1)
				   |(33'b1 <<  2)
				   |(33'b1 <<  4)
				   |(33'b1 <<  5)
				   |(33'b1 <<  7)
				   |(33'b1 <<  8)
				   |(33'b1 <<  10)
				   |(33'b1 <<  11)
				   |(33'b1 <<  12)
				   |(33'b1 <<  16)
				   |(33'b1 <<  22)
				   |(33'b1 <<  23)
				   |(33'b1 <<  26)
				   |(33'b1 <<  32); 
		assign res[j] = data_i[i] 
				   ^ buff[0]
				   ^ buff[1]
				   ^ buff[3]
				   ^ buff[4]
				   ^ buff[6]
				   ^ buff[7]
				   ^ buff[9]
				   ^ buff[10]
				   ^ buff[11]
				   ^ buff[15]
				   ^ buff[21]
				   ^ buff[22]
				   ^ buff[25]
				   ^ buff[31];
	end
endgenerate;

if ( DATA_W >= SUM_W ) begin
	assign sum_lite_next = res[DATA_W-1-:SUM_W];
end else if ( DATA_W < SUM_W ) begin
	assign sum_lite_next = { sum_q[SUM_W-1-:DATA_W], res};
end
assign sum_next = valid_i ? ~sum_lite_next : sum_q;

always @(posedge clk) begin
	sum_q <= sum_next;
end
 
assign crc_o = sum_q;
endmodule


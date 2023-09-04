/* CRC computation for ethernet MAC frame check sequence
 * G(x) = x32 + x26 + x23 + x22 + x16 + x12 + x11 + x10 
 *      + x8 + x7 + x5 + x4 + x2 + x + 1
 * */
module crc_rx #(
	parameter DATA_W = 32, 
	parameter SUM_W  = 32
)(
	input clk,

	input              start_i,
	input              valid_i,
	input [DATA_W-1:0] data_i,

	output [SUM_W-1:0] crc_o
);

reg   [SUM_W-1:0]  sum;
reg   [SUM_W-1:0]  sum_q;
logic [SUM_W-1:0]  sum_lite_next;
logic [SUM_W-1:0]  sum_next;

logic [DATA_W-1:0] res;

assign sum = start_i ? {SUM_W{1'b0}}: sum_q;
genvar i;
genvar j;
generate
	for( i=0 ; i < DATA_W; i++) begin
		logic [SUM_W-1:0] buff;
		
		if( i == 0) begin
			assign buff = sum;
		end else if ( i < SUM_W ) begin
			assign buff = {sum[SUM_W-1-:i], res[i-1:0]};
		end else begin
			assign buff = res[i-1:SUM_W-i];
		end
		
		assign res[i] = data_i[i] 
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
assign sum_next = valid_i ? sum_lite_next : sum_q;

always @(posedge clk) begin
	sum_q <= sum_next;
end
 
assign crc_o = sum_q;
endmodule


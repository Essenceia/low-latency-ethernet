/* CRC computation for ethernet MAC frame check sequence */
module crc #(
	parameter DATA_W = 32, 
	parameter SUM_W  = 32
)(
	input [DATA_W-1:0] data_i,

	output [SUM_W-1:0] data_o
);


reg   [SUM_W-1:0]  sum_q;
logic [SUM_W-1:0]  sum_next;

// TODO
assign data_o = sum_q;
endmodule


/* udp header tx module
 * generate udp header based on module
 * parameters */
module udp_head_tx #(
	parameter PORT_W = 16,
	parameter [PORT_W-1:0] DST_PORT = 16'd18170,
	parameter [PORT_W-1:0] SRC_PORT = 16'd18170,
	parameter LEN_W = 16,
	parameter CRC_W = 16,
	parameter HAS_CRC = 0,
	parameter HEAD_W = 2*PORT_W+LEN_W+CRC_W
)(
	/* data length */
	input [LEN_W-1:0] len_i,
	/* verilator lint_off UNUSEDSIGNAL*/
	input [CRC_W-1:0] crc_i,
	/* verilator lint_on UNUSEDSIGNAL*/
	
	output [HEAD_W-1:0] head_o
);
localparam [LEN_W-1:0] HEAD_N = HEAD_W/8;
logic [CRC_W-1:0] crc;
if (HAS_CRC) begin
assign crc = crc_i;
end else begin
/* in IPv4 CRC is optional, when crc is not used we
 * can set all values to 0 */
assign crc = {CRC_W{1'b0}};
end

/* calculate full length : data + head length */
logic             unused_len_of;
logic [LEN_W-1:0] len;
assign { unused_len_of, len} = len_i + HEAD_N;
 
assign head_o = {crc, len, DST_PORT, SRC_PORT};
endmodule

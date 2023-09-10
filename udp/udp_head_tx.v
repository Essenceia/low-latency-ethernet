/* udp header tx module
 * generate udp header based on module
 * parameters */
module udp_head_tx #(
	parameter PORT_W = 16,
	parameter DST_PORT = 16'd18170,
	parameter SRC_PORT = 16'd18170,
	parameter LEN_W = 16,
	parameter CRC_W = 16,
	parameter HAS_CRC = 0,
	parameter HEAD_W = 2*PORT_W+LEN_W+CRC_W
)(
	input [LEN_W-1:0] len_i,
	input [CRC_W-1:0] crc_i,

	output [HEAD_W-1:0] head_o
);
logic [CRC_W-1:0] crc;
if (HAS_CRC) begin
assign crc = crc_i;
end else begin
/* in IPv4 CRC is optional, when crc is not used we
 * can set all values to 0 */
assign crc = {CRC_W{1'b0}};
end

assign head_o = {crc, len_i, DST_PORT, SRC_PORT};
endmodule

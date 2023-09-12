/* udp header tx module
 * generate udp header based on module
 * parameters */
module udp_head_tx #(
	parameter PORT_W = 16,
	parameter [PORT_W-1:0] DST_PORT = 16'd18170,
	parameter [PORT_W-1:0] SRC_PORT = 16'd18170,
	parameter LEN_W = 16,
	parameter CS_W = 16,
	parameter HAS_CS = 0,
	parameter HEAD_W = 2*PORT_W+LEN_W+CS_W
)(
	/* data length */
	input [LEN_W-1:0] len_i,
	/* verilator lint_off UNUSEDSIGNAL*/
	input [CS_W-1:0] cs_i,
	/* verilator lint_on UNUSEDSIGNAL*/
	
	output [HEAD_W-1:0] head_o
);
localparam [LEN_W-1:0] HEAD_N = HEAD_W/8;
logic [CS_W-1:0] cs;
if (HAS_CS) begin
assign cs = cs_i;
end else begin
/* in IPv4 CS is optional, when cs is not used we
 * can set all values to 0 */
assign cs = {CS_W{1'b0}};
end

/* calculate full length : data + head length */
logic             unused_len_of;
logic [LEN_W-1:0] len;
assign { unused_len_of, len} = len_i + HEAD_N;
 
assign head_o = {cs, len, DST_PORT, SRC_PORT};
endmodule

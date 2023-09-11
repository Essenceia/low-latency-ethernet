/* ipv4 header tx module
 * generate static header based on
 * module parameters
 *
 * Assumptions:
 * 	- no support for options on tx is needed
 * 	- no support for fragmentation is needed
 *
 * Currently only support DATA_W == 16 */
module ipv4_head_tx #(
	parameter LEN_W = 16,
	parameter ADDR_W = 32,
	parameter [ADDR_W-1:0] SRC_ADDR = {8'd206, 8'd200, 8'd127, 8'd128},
	parameter [ADDR_W-1:0] DST_ADDR = {8'd206, 8'd200, 8'd127, 8'd128},
	/* Expedited Forwarding PHB 101110 */
	parameter [5:0] DSCP = 6'h2e,
	parameter [1:0] ENC = 2'b00, /* not enc-capable */ 
	
	parameter [7:0] TTL = 8'd64,
	parameter [7:0] PROTOCOL = 8'd17, /* UDP decimale 17 */
 
	parameter HEAD_N = 20, 
	parameter HEAD_W = HEAD_N*8 
)(
	input [LEN_W-1:0] data_len_i,
	
	output [HEAD_W-1:0] head_o
);
localparam [3:0] VERSION = 4'b0100; /* v4 */
localparam [3:0] IHL = 4'd5;/* header length */
/* fragmentation */
localparam [15:0] FRAG_ID = 16'b0;
localparam [2:0]  FRAG_FLAG = 3'h3; 
localparam [12:0] FRAG_OFF = 13'b0;
localparam [LEN_W-1:0] HEAD_LEN = HEAD_N;
/* Checksum */
localparam CS_W = 16;
/* Pre-caclculated static cs value based on the static parameters
 * of the ip header */
localparam [CS_W-1:0] CS_BASE_VAL =	 { VERSION, IHL, DSCP, ENC } 
	+ HEAD_LEN 
    + FRAG_ID 
	+ { FRAG_FLAG, FRAG_OFF} 
	+ { TTL, PROTOCOL } 
	+ SRC_ADDR[31:16] + SRC_ADDR[15:0]
	+ DST_ADDR[31:16] + DST_ADDR[15:0];
 
/* total length */
logic             unused_tot_len_of;
logic [LEN_W-1:0] tot_len;
assign { unused_tot_len_of, tot_len } = data_len_i + HEAD_LEN;

/* checksum */
logic            unused_cs_of;
logic [CS_W-1:0] cs;
assign { unused_cs_of, cs } = CS_BASE_VAL + data_len_i;

/* output */
assign head_o = { DST_ADDR, SRC_ADDR, 
	cs, PROTOCOL, TTL, 
	FRAG_OFF, FRAG_FLAG, FRAG_ID, 
	tot_len, ENC, DSCP, IHL, VERSION};

endmodule

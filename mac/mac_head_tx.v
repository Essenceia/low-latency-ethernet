/* MAC HEADER TX
 * Generates a mac header depending on configured parameters.
 * Doesn't support dynamic parameters are our system will
 * only be sending 1 packet type to 1 client.
 *
 * assumptions : 
 * 	- packets are allways of type IPv4 */

module mac_head_tx #(

	/* include vlan tagging */
	parameter VLAN_TAG = 1,
	parameter PCP = 3'b0,
	parameter VID = 12'b1,
 
	/* head field length */
	parameter PRE_N  = 8,
	parameter PRE_W  = PRE_N*8,
	parameter ADDR_N = 6,
	parameter ADDR_W = ADDR_N*8,
	parameter TYPE_N = 2,
	parameter TYPE_W = TYPE_N*8,
	parameter VLAN_N = ( VLAN_TAG )? 4 : 0,
	parameter VLAN_W = VLAN_N*8,
	parameter HEAD_LITE_N = PRE_N + 2*ADDR_N,
	parameter HEAD_N = HEAD_LITE_N + VLAN_N +TYPE_N,
	parameter HEAD_W = HEAD_N*8,

	/* configuration of header values */
	parameter [ADDR_W-1:0] SRC_ADDR = {24'h0 ,24'hF82F08},
	parameter [ADDR_W-1:0] DST_ADDR = {24'h0 ,24'hFCD4F2} 
)(
	output [HEAD_W-1:0] head_o
);
localparam LSB_W = HEAD_LITE_N*8;
localparam MSB_W = (VLAN_N)*8 + TYPE_W;

localparam [PRE_W-1:0] PRE = {56'hAAAAAAAAAAAAAA, 8'hAB}; 
/* type : IPv4 */
localparam IPV4 = 16'h0800; 
/* vtag
 * vlan tag protocol identifier */
localparam TPIC = 16'h8100;
/* drop eligibility indicator */
localparam DEI = 1'b0;

/* without vtag :
 * [ premable 8B | dst @ 6B | src @ 6B | type 2B ]
 *
 * with vtag :
 * [ premable 8B | dst @ 6B | src @ 6B | vtag 4B | type 2B ] 
 */

logic [LSB_W-1:0]  lsb_head;

assign lsb_head = { SRC_ADDR , DST_ADDR , PRE};

logic [MSB_W-1:0]  msb_head;
logic [TYPE_W-1:0] h_type;
assign h_type = IPV4;
if ( VLAN_TAG ) begin
	logic [VLAN_W-1:0] vtag;
	assign vtag = { VID ,DEI ,PCP , TPIC}; 
	assign msb_head = { h_type, vtag };
end else begin
	assign msb_head = h_type;
end

assign head_o = { msb_head, lsb_head };

endmodule

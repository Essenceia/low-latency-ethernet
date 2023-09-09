/* MAC TX
 * mac tx module, none 802.3 compliant
 * accept data weight : 64 */
module mac_tx #(
	parameter IS_10G = 1,
	/* include vlan tagging */
	parameter VLAN_TAG = 1,
	parameter DATA_W = 64,
	parameter KEEP_W = DATA_W/8,
	parameter BLOCK_W = 64,
	parameter LEN_W  = $clog2(BLOCK_W),

	/* synchronization, used when data_w < 64 */
	parameter SEQ_N = DATA_W/BLOCK_W,
	parameter SEQ_W = $clog2(SEQ_N) 
)(
	input clk,
	input nreset,
	
	/* PCS */ 
	input               pcs_valid_i,
	output              ctrl_v_o,
	output              idle_o,
	output              start_o,
	output              term_o,
	output [KEEP_W-1:0] term_keep_o,

	/* IPv4 */
	output             ready_o,
	output             data_v_next_o, /* accept data next cycle */
	input              head_v_i, /* start sending packet head */
	input              data_v_i,
	input [DATA_W-1:0] data_i,
	input              last_i,
	input [LEN_W-1:0]  len_i
)
localparam ADDR_N = 6;
localparam ADDR_W = ADR_N*8;
localparam TYPE_N = 2;
localparam TYPE_W = TYPE_N*8;
localparam VLAN_N = ( VLAN_TAG )? 4 : 0; 
localparam HEAD_N = PRE_N + 2*ADDR_N + TYPE_N;

localparam HEAD_CNT_N = 
/* fsm */
reg   fsm_idle_q;
logic fsm_idle_next;
reg   fsm_head_q;
logic fsm_head_next;
reg   fsm_data_q;
logic fsm_data_next;

/* head
 * [pre 8B] [dst addr 6B| src addr 2B] [src addr 4B|vlan 4B] [type 2B| ... ] 
 *
 * head cnt */ 
reg cnt_q;

endmodule

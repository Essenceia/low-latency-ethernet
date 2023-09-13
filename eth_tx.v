/* Tx eth pipe */
module eth_tx #(
	/* configuration */
	parameter UDP_CS = 0,
	parameter VLAN_TAG = 1,
	parameter UDP = 1,
	parameter IS_10G = 1,

	parameter DATA_W = 16,
	parameter KEEP_W = DATA_W/8,
	parameter LEN_W = $clog2(KEEP_W+1),

	parameter PKT_LEN_W = 16,
	
	/* UDP */
	parameter PORT_W = 16,
	parameter [PORT_W-1:0] DST_PORT = 16'd18170,
	parameter [PORT_W-1:0] SRC_PORT = 16'd18170,
	parameter UDP_CS_W = 16,

	/* IPv4 */
	parameter IP_ADDR_W = 32,
	parameter [IP_ADDR_W-1:0] IP_SRC_ADDR = {8'd206, 8'd200, 8'd127, 8'd128},
	parameter [IP_ADDR_W-1:0] IP_DST_ADDR = {8'd206, 8'd200, 8'd127, 8'd128},
	/* Transport protocol */
	parameter PROT_W = 8,
	parameter [PROT_W-1:0] PROT_UDP = 8'd17,
	parameter [PROT_W-1:0] PROT_TCP = 8'd6,
	parameter [PROT_W-1:0] PROTOCOL = UDP ? PROT_UDP : PROT_TCP,

	parameter IP_HEAD_N = 20, 
	parameter IP_HEAD_W = IP_HEAD_N*8,
 
	/* MAC */
	parameter MAC_PRE_N  = 8,
	parameter MAC_ADDR_N = 6,
	parameter MAC_ADDR_W = MAC_ADDR_N*8,
	parameter MAC_TYPE_N = 2,
	parameter MAC_VLAN_N = (VLAN_TAG)? 4 : 0,
	parameter MAC_HEAD_LITE_N = MAC_PRE_N + 2*MAC_ADDR_N,
	parameter MAC_HEAD_N = MAC_HEAD_LITE_N + MAC_VLAN_N + MAC_TYPE_N,
	parameter MAC_HEAD_W = MAC_HEAD_N*8,
	
	parameter [MAC_ADDR_W-1:0] MAC_SRC_ADDR = {24'h0 ,24'hF82F08},
	parameter [MAC_ADDR_W-1:0] MAC_DST_ADDR = {24'h0 ,24'hFCD4F2},

	parameter LANE0_CNT_N = IS_10G & ( DATA_W == 64 )? 2 : 1,
	
	parameter TCP_HEAD_N = 20,
	parameter TCP_HEAD_W = TCP_HEAD_N*8,
	parameter UDP_HEAD_N = 8, 
	parameter UDP_HEAD_W = UDP_HEAD_N*8
)(
	input clk,
	input nreset,

	/* from application */
	input                  app_cancel_i,
	input                  app_early_v_i,
	/* full packet udp data len */
	input [PKT_LEN_W-1:0]  app_pkt_len_i,
	output                 app_ready_v_o,

	/* data steaming */
	input                  app_valid_i,
	input [DATA_W-1:0]     app_data_i,
	/* verilator lint_off UNUSEDSIGNAL*/
	input [LEN_W-1:0]      app_len_i,
	/* packet data checksum used only if USP_CS = 1 */
	input [UDP_CS_W-1:0]   app_cs_i,
	/* verilator lint_on UNUSEDSIGNAL*/
	
	/* pma */ 
	output                   mac_ready_i,

	output                   mac_ctrl_v_o,
	output [DATA_W-1:0]      mac_data_o,	
	output [LANE0_CNT_N-1:0] mac_start_v_o,
	output                   mac_idle_v_o,
	output                   mac_term_v_o,
	output [KEEP_W-1:0]      mac_term_keep_o
);
/* transport layer header */
localparam T_HEAD_N = UDP ? UDP_HEAD_N : TCP_HEAD_N;
localparam T_HEAD_W = T_HEAD_N*8; 
/* full eth head */
localparam HEAD_N = T_HEAD_N + IP_HEAD_N + MAC_HEAD_N; 
localparam HEAD_W = HEAD_N*8;

/* head counter */
localparam HEAD_CNT_W = $clog2(HEAD_N+1); 

/* upd lenght for calculating IP data length */
localparam [PKT_LEN_W-1:0] IP_LEN_ADD = UDP_HEAD_N;

/* fsm */
reg   fsm_idle_q;
logic fsm_idle_next;
reg   fsm_head_q;
logic fsm_head_next;
reg   fsm_data_q;
logic fsm_data_next;
reg   fsm_foot_q;
logic fsm_foot_next;


/* Generate Header */

/* Transport layer UDP/TCP */
logic [T_HEAD_W-1:0] t_head;
if ( UDP ) begin
/* UDP */
udp_head_tx #(
	.PORT_W(PORT_W),
	.DST_PORT(DST_PORT),
	.SRC_PORT(SRC_PORT),
	.LEN_W(PKT_LEN_W),
	.HAS_CS(UDP_CS)
)m_udp_head_tx(
	.len_i(app_pkt_len_i),
	.cs_i(app_cs_i),
	.head_o(t_head)
);
end else begin
/* TCP */
end

/* IPv4 */
logic [IP_HEAD_W-1:0] ip_head;
logic [PKT_LEN_W-1:0] ip_data_len;
logic                 unused_ip_data_len_of;

assign { unused_ip_data_len_of, ip_data_len } = app_pkt_len_i + IP_LEN_ADD;

ipv4_head_tx #(
	.LEN_W(PKT_LEN_W),
	.ADDR_W(IP_ADDR_W),
	.SRC_ADDR(IP_SRC_ADDR),
	.DST_ADDR(IP_DST_ADDR),
	.PROTOCOL(PROTOCOL),
	.HEAD_N(IP_HEAD_N),
	.HEAD_W(IP_HEAD_W)
)m_ipv4_head_tx(
	.data_len_i(ip_data_len),
	.head_o(ip_head)
);

/* MAC */
logic [MAC_HEAD_W-1:0] mac_head;

mac_head_tx #(
	.VLAN_TAG(VLAN_TAG),
	.SRC_ADDR(MAC_SRC_ADDR),
	.DST_ADDR(MAC_DST_ADDR) 
)m_mac_head_tx(
	.head_o(mac_head)
);

/* total head */
logic [HEAD_W-1:0] head_init; 
logic [HEAD_W-1:0] head_next; 
reg   [HEAD_W-1:0] head_q; 
logic              head_rst;
 
assign head_init = {mac_head, ip_head, t_head};
/* shift right */
assign head_rst = fsm_idle_q & app_early_v_i;
assign head_next = head_rst ? head_init : {{KEEP_W*8{1'bx}}, head_q[HEAD_W-1:DATA_W]};
always @(posedge clk) begin
		head_q <= head_next;
end

/* stream head */
reg   [HEAD_CNT_W-1:0] head_cnt_q;
logic [HEAD_CNT_W-1:0] head_cnt_next;
logic [HEAD_CNT_W-1:0] head_cnt_add;
logic                  head_cnt_zero;
logic                  head_cnt_en;
logic                  unused_head_cnt_add;
logic                  head_cnt_rst;

assign {unused_head_cnt_add, head_cnt_add} = head_cnt_q + KEEP_W;

assign head_cnt_en = fsm_head_q | fsm_idle_q;
assign head_cnt_rst = (fsm_idle_q & ~app_early_v_i) | ~mac_ready_i;
assign head_cnt_next = head_cnt_rst ? {HEAD_CNT_W{1'b0}}: head_cnt_add;
assign head_cnt_zero = ~|head_cnt_q;

always @(posedge clk) begin
	if (head_cnt_en) begin
		head_cnt_q <= head_cnt_next;
	end
end

/* Sections end */
logic end_head_v;
logic end_data_v;
logic end_foot_v;

assign end_head_v = head_cnt_q >= HEAD_N;
assign end_data_v = 1'b0; // TODO
assign end_foot_v = 1'b0; // TODO

/* data */
logic data_v;
logic data_ctrl;
logic data_term;
logic [KEEP_W-1:0] data_term_keep; 
logic [LANE0_CNT_N-1:0] data_start;
logic [DATA_W-1:0] data;
logic [DATA_W-1:0] data_foot;

assign data_v = fsm_head_q | fsm_data_q | fsm_foot_q;
assign data_ctrl = head_cnt_zero; //TODO include term
assign data_start = {{LANE0_CNT_N-1{1'b0}}, head_cnt_zero & fsm_head_q};
assign data_term  = 1'bx; //TODO
assign data_term_keep = {KEEP_W{1'bx}}; //TODO

assign data = {DATA_W{fsm_head_q}} & head_q[DATA_W-1:0]
			| {DATA_W{fsm_data_q}} & app_data_i 
			| {DATA_W{fsm_foot_q}} & data_foot; 
 
/* FSM */

assign fsm_idle_next = app_cancel_i
				     | fsm_idle_q & ~app_early_v_i
					 | fsm_foot_q & end_foot_v;
assign fsm_head_next = ~app_cancel_i 
					 &(fsm_idle_q & app_early_v_i
					 | fsm_head_q & ~end_head_v );
assign fsm_data_next = ~app_cancel_i
					 &(fsm_head_q & end_head_v
					 | fsm_data_q & ~end_data_v);
assign fsm_foot_next = ~app_cancel_i
					 &( fsm_data_q & end_data_v
					 |  fsm_foot_q & ~end_foot_v);
always @(posedge clk) begin
	if( ~nreset) begin
		fsm_idle_q <= 1'b1;
		fsm_head_q <= 1'b0;
		fsm_data_q <= 1'b0;
		fsm_foot_q <= 1'b0;
	end else begin
		fsm_idle_q <= fsm_idle_next;
		fsm_head_q <= fsm_head_next;
		fsm_data_q <= fsm_data_next;
		fsm_foot_q <= fsm_foot_next;
	end
end 

/* output */
/* app */
if ( HEAD_W % DATA_W == 0 ) begin
assign app_ready_v_o = fsm_data_q;
end
/* mac */
assign mac_ctrl_v_o = data_ctrl; 
assign mac_idle_v_o = ~data_v;
assign mac_start_v_o = data_start;
assign mac_term_v_o = data_term;
assign mac_term_keep_o = data_term_keep;
assign mac_data_o = data; 
endmodule

/* Tx eth pipe */
module eth_tx #(
	/* set minimum interpacket gap to zero, will break
     * 802.3 compatilibility and cause packet loss
     * if other testing equipement doesn't also support
     * a min IPG of 0 */
	parameter IS_IPG_ZERO = 1,
	/* configuration */
	parameter UDP_CS = 0,
	parameter VLAN_TAG = 1,
	parameter UDP = 1,
	parameter IS_10G = 1,

	parameter DATA_W = 16,
	parameter KEEP_W = DATA_W/8,
	parameter LEN_W = $clog2(KEEP_W+1),

	/* PHY */
	parameter BLOCK_N = 8,
	parameter BLOCK_LEN_W = $clog2(BLOCK_N+1),
	
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
	parameter MAC_CRC_N  = 4,
	parameter MAC_CRC_W  = MAC_CRC_N*8,
	
	parameter [MAC_ADDR_W-1:0] MAC_SRC_ADDR = {24'h0 ,24'hF82F08},
	parameter [MAC_ADDR_W-1:0] MAC_DST_ADDR = {24'h0 ,24'hFCD4F2},

	parameter LANE0_CNT_N = IS_10G & ( DATA_W == 64 )? 2 : 1,

	/* Head */	
	parameter TCP_HEAD_N = 20,
	parameter UDP_HEAD_N = 8, 

	/* APP */
	parameter PKT_LEN_W = 16,
	parameter APP_LAST_LEN_N = BLOCK_N+KEEP_W,
	parameter APP_LAST_LEN_W = $clog2(APP_LAST_LEN_N+1)
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
//	input                  app_valid_i,
	input [DATA_W-1:0]     app_data_i,
	input [LEN_W-1:0]      app_len_i,
	/* term, last block */
	input                      app_last_i,/* last valid data len!=0 */
	input                      app_last_block_next_i,/* next start of last block */
	input [APP_LAST_LEN_W-1:0] app_last_block_next_len_i,
	/* verilator lint_off UNUSEDSIGNAL*/
	/* packet data checksum used only if USP_CS = 1 */
	input [UDP_CS_W-1:0]   app_cs_i,
	/* verilator lint_on UNUSEDSIGNAL*/
	
	/* physical layer */ 
	input                    phy_ready_i,

	output                   phy_ctrl_v_o,
	output [DATA_W-1:0]      phy_data_o,	
	output [LANE0_CNT_N-1:0] phy_start_o,
	output                   phy_idle_o,
	output                   phy_term_o,
	output [BLOCK_LEN_W-1:0] phy_term_len_o
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

/* footer, contains only mac crc */
localparam FOOT_CNT_MAX = MAC_CRC_N + APP_LAST_LEN_N ;
localparam FOOT_CNT_W = $clog2(FOOT_CNT_MAX+1);

/* fsm */
reg   fsm_idle_q;
logic fsm_idle_next;
reg   fsm_head_q;
logic fsm_head_next;
reg   fsm_data_q;
logic fsm_data_next;
reg   fsm_foot_q;
logic fsm_foot_next;

logic end_head_v;
logic end_foot_v;

/* Generate Header */

/* Transport layer UDP/TCP */
logic [T_HEAD_W-1:0] t_head;
if ( UDP ) begin : transport_layer
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
assign head_cnt_rst = (fsm_idle_q & ~app_early_v_i) | ~phy_ready_i;
assign head_cnt_next = head_cnt_rst ? {HEAD_CNT_W{1'b0}}: head_cnt_add;
assign head_cnt_zero = ~|head_cnt_q;

always @(posedge clk) begin
	if (head_cnt_en) begin
		head_cnt_q <= head_cnt_next;
	end
end

assign end_head_v = head_cnt_q >= HEAD_N;

/* footer 
 * footer only contains MAC crc
 * calculate MAC crc to be added as footer
 * crc includes all information appart from itself
 * and the preamble bytes of the mac header */

logic                 crc_data_v; /* data to be accounted for in crc calculation */
logic                 crc_start_v;
logic [MAC_CRC_W-1:0] crc_raw;
logic [KEEP_W-1:0]    app_data_keep;
logic [LEN_W-1:0]     crc_data_len;
logic [DATA_W-1:0]    crc_data;

/* exclude mac pre */
assign crc_start_v = head_cnt_q == MAC_PRE_N;

assign crc_data_v = fsm_head_q & (head_cnt_q >= MAC_PRE_N)
			      | fsm_data_q;

assign crc_data = {DATA_W{fsm_head_q}} & head_q[DATA_W-1:0]
		        | {DATA_W{fsm_data_q}} & app_data_i;  
/* convert app data len to keep */
len_to_mask #(.LEN_W(LEN_W), .LEN_MAX(KEEP_W)
)m_data_len_to_keep(
	.len_i(app_len_i),
	.mask_o(app_data_keep)
);

/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off WIDTHEXPAND */
assign crc_data_len = app_last_i? app_len_i : KEEP_W;
/* verilator lint_on WIDTHEXPAND */
/* verilator lint_on WIDTHTRUNC */

crc #(.DATA_W(DATA_W))
)m_crc_tx(
	.clk(clk),
	.valid_i(crc_data_v),
	.start_i(crc_start_v),
	.len_i(crc_data_len),
	.data_i(crc_data),
	.crc_o(crc_raw)
);
/* foot cnt */
logic                  unused_foot_cnt_init;
logic [FOOT_CNT_W-1:0] foot_cnt_init;
logic [FOOT_CNT_W-1:0] foot_cnt_next;
logic [FOOT_CNT_W-1:0] foot_cnt_dec;
reg   [FOOT_CNT_W-1:0] foot_cnt_q;
logic                  foot_cnt_rst;

/* calculate crc init value: data might be shifter by a few bytes depending
 * on the length of valid app data bytes :
 * we cram the first crc bytes alongside the last app data 
 * bytes if there is space. */
assign foot_cnt_rst = fsm_data_q & app_last_block_next_i;

/* verilator lint_off WIDTHTRUNC */
assign {unused_foot_cnt_init,foot_cnt_init} = app_last_block_next_len_i + MAC_CRC_N;
assign foot_cnt_dec  = foot_cnt_q - KEEP_W;
/* verilator lint_on WIDTHTRUNC */
/* verilator lint_off WIDTHEXPAND */
assign end_foot_v = ~(foot_cnt_q > KEEP_W);
/* verilator lint_on WIDTHEXPAND */

assign foot_cnt_next = foot_cnt_rst ? foot_cnt_init : foot_cnt_dec;

always @(posedge clk) begin
	foot_cnt_q <= foot_cnt_next;
end

reg                   last_block_v_q;
logic                 last_block_v_next;

assign last_block_v_next = fsm_data_q & app_last_block_next_i  
						 | last_block_v_q & ~fsm_idle_q;
always @(posedge clk) begin
	if (~nreset) begin
		last_block_v_q <= 1'b0;
	end else begin
		last_block_v_q <= last_block_v_next;
 	end
end

logic [MAC_CRC_W-1:0] crc_raw_shifted;
logic [MAC_CRC_W-1:0] crc_raw_shifted_arr[KEEP_W:1];
logic [MAC_CRC_W-1:0] crc_next;
reg   [MAC_CRC_W-1:0] crc_q;
logic                 crc_rst;

logic [DATA_W-1:0]    data_foot;
logic [DATA_W-1:0]    data_last;
logic [DATA_W-1:0]    data_last_crc_shifted;
logic [DATA_W-1:0]    data_last_crc_shifted_arr[KEEP_W-1:1];

/* shift crc based on number of data bytes in last packet */
genvar i;
generate 
	/* starts at 1 : no valid data in last packet, violates the rules for app last */
	for(i=1; i<=KEEP_W; i++) begin: crc_shift_data_gen
		if ( i == KEEP_W ) begin
			/* all bytes on last are valid, no crc shift needed */
			assign crc_raw_shifted_arr[KEEP_W] = crc_raw;
		end else begin
			/* partial data bytes valid on last */
			assign crc_raw_shifted_arr[i] = {{8*i{1'bx}},crc_raw[MAC_CRC_W-1:8*i]};
			assign data_last_crc_shifted_arr[i] = {crc_raw[8*i-1:0], {8*i{1'bx}}};
		end
	end	
endgenerate

always_comb begin: crc_shift_sel_mux
	
	for(int s=1; s<=KEEP_W; s++) begin 
		/* verilator lint_off WIDTHEXPAND */
		if ( s == app_len_i ) crc_raw_shifted = crc_raw_shifted_arr[s];
		if ( s == app_len_i ) data_last_crc_shifted = data_last_crc_shifted_arr[s];
		/* verilator lint_on WIDTHEXPAND */
	end
end

/* data last : append first crc byte(s) after last app data */
generate
	for(i=0; i<KEEP_W; i++) begin : data_last_gen
		assign data_last[i*8+:8] = {8{app_data_keep[i]}}  & app_data_i[i*8+:8]
						         | {8{~app_data_keep[i]}} & data_last_crc_shifted[i*8+:8];
	end
endgenerate

/* flop crc data */
assign crc_rst = fsm_data_q & app_last_i;
assign crc_next = crc_rst? crc_raw_shifted : {{DATA_W{1'bx}},crc_q[MAC_CRC_W-1:DATA_W]};
always @(posedge clk) begin
	crc_q <= crc_next;
end

assign data_foot = crc_q[DATA_W-1:0];

/* data */
logic data_v;
logic data_ctrl;
logic data_term;
logic [BLOCK_LEN_W-1:0] data_term_len; 
logic [LANE0_CNT_N-1:0] data_start;
logic [DATA_W-1:0] data;

assign data_v     = fsm_head_q | fsm_data_q | fsm_foot_q;
assign data_ctrl  = head_cnt_zero | data_term;
assign data_start = {{LANE0_CNT_N-1{1'b0}}, head_cnt_zero & fsm_head_q};

/* last block : in last block we can only send 7 bytes of data */
assign data_term  = fsm_data_q & app_last_block_next_i
				  | last_block_v_q 
			      | (fsm_foot_q & (foot_cnt_q < BLOCK_N)); 

/* no holes in data until term, only evaluated when data_term == 1 */
assign data_term_len = {BLOCK_LEN_W{~data_term}} | foot_cnt_q[BLOCK_LEN_W-1:0];  

/* lite : doesn't include foot, used to feed crc calculation */
assign data = {DATA_W{fsm_head_q}} & head_q[DATA_W-1:0]
		    | {DATA_W{fsm_data_q & ~app_last_i}} & app_data_i 
		    | {DATA_W{fsm_data_q &  app_last_i}} & data_last
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
					 | fsm_data_q & ~app_last_i);
assign fsm_foot_next = ~app_cancel_i
					 &( fsm_data_q & app_last_i
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
assign phy_ctrl_v_o = data_ctrl; 
assign phy_idle_o = ~data_v;
assign phy_start_o = data_start;
assign phy_term_o = data_term;
assign phy_term_len_o = data_term_len;
assign phy_data_o = data;

`ifdef FORMAL

`endif
endmodule

/* Tx eth pipe */
module eth_tx #(
	/* configuration */
	parameter UDP_CS = 0,
	parameter VLAN_TAG = 1,
	parameter UDP = 1,

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
	
	parameter TCP_HEAD_N = 20,
	parameter TCP_HEAD_W = TCP_HEAD_N*8,
	parameter UDP_HEAD_N = 8, 
	parameter UDP_HEAD_W = UDP_HEAD_N*8
)(
	/* verilator lint_off UNUSEDSIGNAL*/
	input clk,
	input nreset,

	/* from application */
	input                  app_valid_i,
	input [DATA_W-1:0]     app_data_i,
	input [LEN_W-1:0]      app_len_i,
	/* full packet udp data len */
	input [PKT_LEN_W-1:0]  app_pkt_len_i,
	/* packet data checksum */
	input [UDP_CS_W-1:0]   app_cs_i
	
	/* pma */ 
	/* verilator lint_on UNUSEDSIGNAL*/
	
);
/* transport layer header */
localparam T_HEAD_W = UDP ? UDP_HEAD_W : TCP_HEAD_W;
/* full eth head */
localparam HEAD_W = T_HEAD_W + IP_HEAD_W + MAC_HEAD_W; 

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
/* verilator lint_off WIDTHEXPAND */
assign { unused_ip_data_len_of, ip_data_len } = app_len_i + UDP_HEAD_N;
/* verilator lint_on WIDTHEXPAND */

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
/* verilator lint_off UNUSEDSIGNAL*/
logic [HEAD_W-1:0] head; 
/* verilator lint_on UNUSEDSIGNAL*/
assign head = {mac_head, ip_head, t_head};


endmodule

/* IPv4 RX module
 * Has support for IP option field by default 
 *
 * Filtering, discards any packet that doesn't match : 
 * Checks :
 * - version ( only supports ipv4 )
 * - fragmentation indication : we do no support
 *   	fragmented packets
 * - protocol
 * - header hecksum
 * Note :
 * We do not check src or dst addresses, we assume the routing
 * is point-to-point and correctly delivering packets.
 */

module ipv4_rx #(
	parameter DATA_W = 16,
	parameter LEN_W = $clog2(DATA_W/8),
	/* supports fragmentation */
	parameter FRAG = 0,

	parameter ADDR_W = 32,
	parameter PROT_W = 8,/* Protocol */

	/* filtering, accepted protocol */
	parameter [PROT_W-1:0] PROTOCOL = 8'd17 /* UDP */
)(
	input clk,
	input nreset,

	input cancel_i,
	/* MAC */
	input valid_i,
	input [DATA_W-1:0] data_i,
	input [LEN_W-1:0]  len_i,

	/* Transport */
	output valid_o,
	output [DATA_W-1:0] data_o,
	output [LEN_W-1:0]  len_o,

	/* error detection 
 	 * checksum error */
	output cs_err_o
);
localparam [3:0] VERSION = 4'b0100; /* v4 */
localparam TOT_LEN_W = 16;
localparam IHL_W = 4; /* Ip Header Lenght */ 

/* fsm */
reg   fsm_idle_q;
logic fsm_idle_next;
reg   fsm_head_q;
logic fsm_head_next;
reg   fsm_data_q;
logic fsm_data_next;

/* get head, check if packet matches filter
 *  0                   1                   2                   3
 *  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * |Version|  IHL  |   DSCP  | ENC |          Total Length         |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * |         Identification        |Flags|      Fragment Offset    |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * |  Time to Live |    Protocol   |         Header Checksum       |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * |                       Source Address                          |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * |                    Destination Address                        |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * |                    Options                    |    Padding    |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ 
 *
 * cnt the number of received header bytes */
reg   [IHL_W-1:0] cnt_q;
logic [IHL_W-1:0] cnt_next;
logic [IHL_W-1:0] cnt_add;
logic             unused_cnt_add_of;
logic             cnt_rst;

assign cnt_rst  = fsm_idle_q & ~valid_i;
assign {unused_cnt_add_of, cnt_add} = cnt_q + ( DATA_W/8 );
assign cnt_next = cnt_rst ? {IHL_W{1'b0}} : cnt_add;

always @(posedge clk) begin
	cnt_q <= cnt_next;
end

/* save ip header length value to track end of header, */ 
reg   [IHL_W-1:0] ihl_q;
logic [IHL_W-1:0] ihl_next;
logic             ihl_en;

assign ihl_en   = fsm_idle_q;
assign ihl_next = data_i[7:4];
always @(posedge clk) begin
	ihl_q <= ihl_next;
end

/* track end of header */
logic end_head_v;
assign end_head_v = cnt_next >= ihl_q;


/* discard valid signals: don't match accepted */
logic dcd_v;
logic version_dcd_v;
logic frag_dcd_v;
logic prot_dcd_v;
logic hs_dcd_v;

assign version_dcd_v = 1'b0; 

/* data bypass, packet filtering */
reg   bypass_v_q;
logic bypass_v_next;
logic bypass_v_rst;

assign bypass_v_rst = cnt_rst;
assign bypass_v_next = bypass_v_rst ? 1'b0 ; bypass_v_q | dcd_v ; 

/* fsm */
logic end_data_v;

assign fsm_idle_next = cancel_i 
					 | fsm_data_q & end_data_v;
assign fsm_head_next = fsm_idle_q & valid_i
					 | fsm_head_q & ~end_head_v;
assign fsm_data_next = fsm_head_q & end_head_v
					 | fsm_data_q & ~end_data_v;
always @(posedge clk) begin
	if (~nreset) begin
		fsm_idle_q <= 1'b1;
		fsm_head_q <= 1'b0;
		fsm_data_q <= 1'b0;
	end else begin
		fsm_idle_q <= fsm_idle_next;
		fsm_head_q <= fsm_head_next;
		fsm_data_q <= fsm_data_next;
	end
end

endmodule

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
 * - src/dst addr
 *
 * Currently only support DATA_W = 16 */
module ipv4_rx #(
	parameter DATA_W = 16,
	localparam LEN_W = $clog2((DATA_W/8)+1),

	localparam ADDR_W = 32,
	parameter MATCH_SRC_ADDR = 1, 
	parameter MATCH_DST_ADDR = 1, 
	parameter [ADDR_W-1:0] SRC_ADDR = {8'd206, 8'd200, 8'd127, 8'd128},
	parameter [ADDR_W-1:0] DST_ADDR = {8'd206, 8'd200, 8'd127, 8'd128},
	
	localparam PROT_W = 8,/* Protocol */
	/* filtering, accepted protocol */
	parameter [PROT_W-1:0] PROTOCOL = 8'd17 /* UDP */
)(
	input clk,
	input nreset,

	input              cancel_i,
	/* MAC */
	input              valid_i,
	input              start_i,
	input [DATA_W-1:0] data_i,
	input [LEN_W-1:0]  len_i,
	/* error detection 
 	 * checksum error */
	output              cs_err_o,

	/* Transport */
	output              valid_o,
	output              start_o,
	output              cancel_o,
	output [DATA_W-1:0] data_o,
	output [LEN_W-1:0]  len_o
);
/* Ip Header Lenght : must be multiplied by 4 to get
 * real value : we assume there are 2 implicit hidden
 * bits set to 0  */ 
localparam IHL_W        = 4;
localparam IHL_HIDDEN_W = 2;
localparam IHL_FULL_W   = IHL_W + IHL_HIDDEN_W;
 
localparam V_W       = 4;
localparam TOT_LEN_W = 16;
localparam FF_W      = 3; 
localparam CS_W      = 16;
localparam [V_W-1:0] VERSION    = 4'b0100; /* v4 */
localparam [FF_W-1:0] FRAG_FLAG = 3'h3; /* no fragmentation */

localparam MAX_HEAD_N = 60;/* supporting options by default */
localparam HEAD_W     = $clog2(MAX_HEAD_N);


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
reg   [TOT_LEN_W-1:0] cnt_q;
logic [TOT_LEN_W-1:0] cnt_next;
logic [TOT_LEN_W-1:0] cnt_lite_next;
logic [TOT_LEN_W-1:0] cnt_add;
logic                  unused_cnt_lite_next_of;
logic                  cnt_rst;

assign cnt_add = {{TOT_LEN_W-LEN_W{1'b0}}, {LEN_W{valid_i}} & len_i}; 
assign {unused_cnt_lite_next_of, cnt_lite_next} = cnt_q + cnt_add;

assign cnt_rst  = fsm_idle_q & ~start_i;
assign cnt_next = cnt_rst ? {TOT_LEN_W{1'b0}} : cnt_lite_next;

always @(posedge clk) begin
	if(valid_i)begin
		cnt_q <= cnt_next;
	end
end

/* save ip header length value to track end of header, */ 
reg   [IHL_W-1:0] ihl_q;
logic [IHL_W-1:0] ihl_next;
logic             ihl_en;

assign ihl_en   = fsm_idle_q;
assign ihl_next = data_i[7:4];

always @(posedge clk) begin
	if (ihl_en) begin
		ihl_q <= ihl_next;
	end
end


/* track end of header */
logic end_head_v;
assign end_head_v = cnt_lite_next[IHL_FULL_W-1:IHL_HIDDEN_W] >= ihl_q | |cnt_q[TOT_LEN_W-1:IHL_FULL_W];

/* head field values and data valid signals */
logic [V_W-1:0] version;
logic           version_lite_v;
assign version        = data_i[V_W-1:0];
assign version_lite_v = fsm_idle_q; 

logic [FF_W-1:0] frag_flag;
logic            frag_flag_lite_v;
assign frag_flag        = data_i[FF_W-1:0];
assign frag_flag_lite_v = cnt_q[HEAD_W-1:0] == 'd3;

logic [PROT_W-1:0] protocol;
logic              protocol_lite_v;
assign protocol        = data_i[DATA_W-1-:PROT_W];
assign protocol_lite_v = cnt_q[HEAD_W-1:0] == 'd4;

/* scr and dst addr match */
logic src_addr_dcd_v;
logic dst_addr_dcd_v;

if ( DATA_W == 16 ) begin
	/* addr is split over 2 cycles */
	if (MATCH_SRC_ADDR) begin
		ip_addr_match #(
			.DATA_W(DATA_W),
			.ADDR_W(ADDR_W),
			.ADDR(SRC_ADDR),
			.IDX_W(HEAD_W),
			.MSB_IDX(6)
		)m_src_addr_match(
			.clk(clk),
			.valid_i(valid_i),
			.data_i(data_i),
			.idx_i(cnt_q[HEAD_W-1:0]),
			.fsm_idle_v_i(fsm_idle_q),
			.fsm_head_v_i(fsm_head_q),
			.match_fail_v_o(src_addr_dcd_v)
		);
	end else begin
		assign src_addr_dcd_v = 1'b0;
	end
	if (MATCH_DST_ADDR) begin
		ip_addr_match #(
			.DATA_W(DATA_W),
			.ADDR_W(ADDR_W),
			.ADDR(DST_ADDR),
			.IDX_W(HEAD_W),
			.MSB_IDX(8)
		)m_dst_addr_match(
			.clk(clk),
			.valid_i(valid_i),
			.data_i(data_i),
			.idx_i(cnt_q[HEAD_W-1:0]),
			.fsm_idle_v_i(fsm_idle_q),
			.fsm_head_v_i(fsm_head_q),
			.match_fail_v_o(dst_addr_dcd_v)
		);
	end else begin
		assign dst_addr_dcd_v = 1'b0;
	end
end

/* save the header checksum to be compared once the full checksum calculation
 * has been completed */
reg   [CS_W-1:0] head_checksum_q;
logic [CS_W-1:0] head_checksum_next;
logic            head_checksum_lite_v;

assign head_checksum_next   = data_i;
assign head_checksum_lite_v = cnt_q[HEAD_W-1:0] == 'd5;

always @(posedge clk) begin
	if (head_checksum_lite_v) begin
		head_checksum_q <= head_checksum_next;
	end
end

/* Checksum calculation */
reg   [CS_W-1:0] cs_q;
logic            unused_cs_add_of;
logic [CS_W-1:0] cs_add;
logic [CS_W-1:0] cs_next;
logic            cs_en;
logic            cs_rst;

assign cs_rst = cnt_rst;
/* don't include head checksum in the checksum calculation */
assign cs_en  = valid_i & ~fsm_data_q & ~head_checksum_lite_v;

assign { unused_cs_add_of, cs_add} = cs_q + data_i;
assign cs_next = cs_rst ? {CS_W{1'b0}} : cs_add;

always @(posedge clk) begin
	if ( cs_en ) begin
		cs_q <= cs_next;
	end
end

/* discard valid signals: don't match accepted */
logic dcd_v;
logic version_dcd_lite_v;
logic frag_dcd_lite_v;
logic prot_dcd_lite_v;
logic cs_err_v;


assign version_dcd_lite_v = version_lite_v & (version != VERSION);
 
assign frag_dcd_lite_v = frag_flag_lite_v & (frag_flag != FRAG_FLAG);
assign prot_dcd_lite_v = protocol_lite_v & (protocol != PROTOCOL);

assign cs_err_v = fsm_data_q & ( cs_q != head_checksum_q );

assign dcd_v = version_dcd_lite_v 
			 | ( valid_i & fsm_head_q ) & ( frag_dcd_lite_v | prot_dcd_lite_v )
			 | src_addr_dcd_v
			 | dst_addr_dcd_v 
			 | cs_err_v; 
/* data bypass, packet filtering */
reg   bypass_v_q;
logic bypass_v_next;
logic bypass_v_rst;

assign bypass_v_rst = cnt_rst;
assign bypass_v_next = bypass_v_rst ? 1'b0 : bypass_v_q | dcd_v ; 

always @(posedge clk) begin
	bypass_v_q <= bypass_v_next;
end

/* total length */
reg   [TOT_LEN_W-1:0] tot_len_q;
logic [TOT_LEN_W-1:0] tot_len_next;
logic                 tot_len_en;

assign tot_len_en   = (cnt_q == 'd2) & valid_i;
assign tot_len_next = data_i; 
always @(posedge clk) begin
	if(tot_len_en)begin
		tot_len_q <= tot_len_next;
	end
end

/* data end
 * ip needs to keep track itself of the end of the
 * data there is no term signal expected from pcs
 * because of the additional mac footer for the crc. */
logic end_data_v;
assign end_data_v = cnt_add >= tot_len_q;
 
/* fsm */

assign fsm_idle_next = cancel_i 
					 | fsm_idle_q & ~start_i
					 | fsm_data_q & end_data_v;
assign fsm_head_next = fsm_idle_q & start_i
					 | fsm_head_q & ~end_head_v;
assign fsm_data_next = fsm_head_q & end_head_v
					 | fsm_data_q & ~end_data_v;
always @(posedge clk) begin
	if (~nreset) begin
		fsm_idle_q <= 1'b1;
		fsm_head_q <= 1'b0;
		fsm_data_q <= 1'b0;
	end else begin
		if(valid_i)begin
			fsm_idle_q <= fsm_idle_next;
			fsm_head_q <= fsm_head_next;
			fsm_data_q <= fsm_data_next;
		end
	end
end

/* start, flop head  */
reg fsm_head_2q;
always @(posedge clk) begin
	if (valid_i) begin
		fsm_head_2q <= fsm_head_q;
	end
end

/* output */
/* for DATA_W = 16 data is never partial: 
 * input data = output data, input len = output len */
assign valid_o = valid_i & fsm_data_q &  ~bypass_v_q;
assign data_o  = data_i;
assign len_o   = len_i;
assign start_o = fsm_head_2q & fsm_data_q;
/* cs error will be transmitied in the first cycle of valid data
 * for transport layer */
assign cs_err_o = cs_err_v; 
endmodule

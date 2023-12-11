/* MAC RX module */
module mac_rx #(
	parameter IS_10G = 1,
	/* mac supports vlan tagging */
	parameter VLAN_TAG = 1,
	parameter DATA_W = 16,
	localparam LEN_W = $clog2((DATA_W/8)+1),
	localparam LANE0_CNT_N = IS_10G & ( DATA_W == 64 )? 2 : 1
)(
	input clk,
	input nreset,

	input                   cancel_i,
	// from physical layer
	input                   valid_i,
	input [DATA_W-1:0]      data_i,
	input                   idle_i,
	input [LANE0_CNT_N-1:0] start_i,
	input                   term_i,
	input [LEN_W-1:0]       len_i,

	// to IP layer
	output              valid_o,
	output              start_o,
	// data
	output [DATA_W-1:0] data_o,
	output [LEN_W-1:0]  len_o,

	output crc_err_o /* contains crc error */
);
localparam DATA_BYTES_N = DATA_W/8;
localparam PRE_N  = 8;
//localparam PRE_W  = PRE_N*8;;
localparam ADDR_N = 6;
//localparam ADDR_W = ADDR_N*8;
localparam TYPE_N = 2;
localparam TYPE_W = TYPE_N*8;
localparam VLAN_N = ( VLAN_TAG )? 4 : 0; 
localparam HEAD_N = PRE_N + 2*ADDR_N + TYPE_N;
localparam HEAD_VTAG_N = HEAD_N + VLAN_N;
localparam CNT_W = $clog2(HEAD_VTAG_N); 

/* header index */
localparam TYPE_IDX_TMP = PRE_N + 2*ADDR_N - DATA_BYTES_N;
localparam TYPE_IDX_W   = $clog2(TYPE_IDX_TMP);
/* verilator lint_off WIDTHTRUNC */
localparam [TYPE_IDX_W-1:0] TYPE_IDX = TYPE_IDX_TMP;
/* verilator lint_on WIDTHTRUNC */

/* type : IPv4 */
localparam [TYPE_W-1:0] IPV4 = 16'h0800; 
/* vlan tag protocol identifier */
localparam [TYPE_W-1:0] TPIC = 16'h8100;
/* CRC */
localparam CRC_W = 32;

/* fsm */
reg   fsm_invalid_q;
logic fsm_invalid_next;
reg   fsm_head_q;
logic fsm_head_next;
reg   fsm_data_q;
logic fsm_data_next;

/* input data is valid */
logic data_v;
assign data_v = valid_i & ~idle_i; 

/* start of a new packet */
logic start_v;
logic start_lite;
assign start_lite = |start_i;
assign start_v = valid_i & start_lite;

/* handle header : ignore all information
 * without vtag :
 * [ premable 8B | dst @ 6B | src @ 6B | type 2B ]

 * [ premable 8B | dst @ 6B | src @ 6B | vtag 4B | type 2B ] 
 *
 * count the number of bytes received since the start of the
 * packet.
 * If we are vlan aware check if we have a vlan tag.*/
reg   [CNT_W-1:0] cnt_q;
logic [CNT_W-1:0] cnt_next; 
logic [CNT_W-1:0] cnt_add;
logic             unused_cnt_add_of;
logic             cnt_rst; 
logic [CNT_W-1:0] data_lite_cnt;
logic [CNT_W-1:0] data_cnt;


/* cnt the number of bytes received from the PCS */
if ((DATA_W == 64) && (IS_10G == 1)) begin
	/* first packet can have 4 or 8 bytes of data */
	assign data_lite_cnt = start_lite ? (start_i[1] ? 'd4 : 'd8): 'd8;
end else begin
	/*verilator lint_off WIDTHTRUNC */
	assign data_lite_cnt = DATA_BYTES_N;
	/*verilator lint_on WIDTHTRUNC */
end
assign data_cnt = {CNT_W{data_v}} & data_lite_cnt;

assign cnt_rst = fsm_invalid_q & ~start_v; 
assign {unused_cnt_add_of, cnt_add} = cnt_q + data_cnt;
assign cnt_next = cnt_rst ? {CNT_W{1'b0}} : cnt_add;

always @(posedge clk) begin
	cnt_q <= cnt_next;
end

/* type and vlan */
logic [TYPE_W-1:0] type_id;
logic              type_v;// type index valid
logic              type_err_v;// type content matches accepted packet expectations, eg : IPv4

if ((DATA_W == 64) & (IS_10G))begin
	/* vlan tag and type index or type starts at 20 bytes, so the type field may
	 * not fall on the first indexes of the data depending on if
	 * start was received on the first or second lane0.
	 * If start was received on the second lane0, vlan_id will be
	 * received on the lsb bytes of data bus, else it will start at
	 * the 4th byte.
	 * type/vlan will be valid after 16 ( middle ) or 20 bytes */
	logic [TYPE_W-1:0] lite_type_id[1:0];

	assign lite_type_id[0] = data_i[TYPE_W-1:0];
	assign lite_type_id[1] = data_i[4*8+TYPE_W-1:4*8];

	if ( VLAN_TAG ) begin
		logic [TYPE_W-1:0] vlan_id;
		logic              vlan_idx_v;
		logic              vlan_v;
		logic              tpic_v;
		
		assign tpic_v = vlan_id == TPIC;
		assign vlan_v = vlan_idx_v & tpic_v;
		/* vlan and type may be received in the same packet
 		 * or in 2 consecutive packets */ 
		assign vlan_idx_v = cnt_q[4] & ~cnt_q[3] & &(~cnt_q[1:0]); 

		/* verilator lint_off UNUSEDSIGNAL */
		assign vlan_id = cnt_q[2] ? lite_type_id[0] : lite_type_id[1];	
		/* verilator lint_on UNUSEDSIGNAL */
	
		/* get type */
		reg   type_lsb_v_q;	
		logic type_lsb_v_next;

		/* verilator lint_off UNDRIVEN */
		/* verilator lint_off UNUSEDSIGNAL */
		assign type_lsb_v_next = vlan_v & ~cnt_q[2];
		/* verilator lint_on UNUSEDSIGNAL */
		/* verilator lint_on UNDRIVEN */

		always @(posedge clk) begin
			type_lsb_v_q <= type_lsb_v_next;
		end	
		assign type_v  = vlan_idx_v & ( cnt_q[2] | ~cnt_q[2] &(~vlan_v | type_lsb_v_q));
		assign type_id = {TYPE_W{ cnt_q[2] & ~vlan_v}} &  lite_type_id[0]
					   | {TYPE_W{ cnt_q[2] &  vlan_v}} &  lite_type_id[1]
					   | {TYPE_W{~cnt_q[2] & ~type_lsb_v_q}} &  lite_type_id[1]  
					   | {TYPE_W{~cnt_q[2] &  type_lsb_v_q}} &  lite_type_id[0];  
	end else begin

		assign type_v  = cnt_q[4] & ~cnt_q[3] & &(~cnt_q[1:0]); 
		assign type_id = cnt_q[2] ? lite_type_id[0] : lite_type_id[1];	

	end // vlan tag
end else begin
	// DATA_W {16, 32}
	/* verilator lint_off WIDTHTRUNC */
	assign type_id = data_i[TYPE_W-1:0];
	/* verilator lint_on WIDTHTRUNC */

	if ( VLAN_TAG) begin
		logic [TYPE_W-1:0] vlan_id;
		logic              vlan_idx_v;
		logic              vlan_v;
		logic              tpic_v;
		
		assign tpic_v = vlan_id == TPIC;
		assign vlan_v = vlan_idx_v & tpic_v;
		assign vlan_idx_v = cnt_q[TYPE_IDX_W-1:0] == TYPE_IDX;
		/* verilator lint_off WIDTHTRUNC */
		assign vlan_id = data_i[TYPE_W-1:0];
		/* verilator lint_on WIDTHTRUNC */
	
		/* get type, delay for 1 or 2 cycles depending on
 		 * data size, vlan tag is 4 bytes long */
		localparam TYPE_CNT_W = DATA_W == 32 ? 1 : 2;
		reg   [TYPE_CNT_W-1:0] type_lsb_v_q;	
		logic [TYPE_CNT_W-1:0] type_lsb_v_next;

		/* TODO : 40G : stall progress of shift on invalid blocks
		 * to support alignement marker removal */
		assign type_lsb_v_next[TYPE_CNT_W-1] = fsm_head_q & vlan_v & ~cnt_q[2];

		if ( DATA_W == 16 ) begin
			assign type_lsb_v_next[0] = vlan_v ? 1'b0 : type_lsb_v_q[1];
		end

		always @(posedge clk) begin
			type_lsb_v_q <= type_lsb_v_next;
		end	

		assign type_v = ( vlan_idx_v & ~vlan_v ) | type_lsb_v_q[0];

	end else begin
		/* !VLAN_TAG */
		assign type_v = cnt_q == TYPE_IDX;
	end // vlan_tag
end
assign type_err_v = fsm_head_q & type_v & (type_id != IPV4);
 
/* data bypass valid
 * controls if data will be sent to the upper layers.
 * We can invalidate data if packet is of the wrong type of there are
 * errors */
reg   bypass_v_q;
logic bypass_v_next;	
logic bypass_v_rst;

/* reasons to invalidate data */
assign bypass_v_rst  = fsm_invalid_q;
assign bypass_v_next = bypass_v_rst ? 1'b0 : bypass_v_q | type_err_v; 

always @(posedge clk) begin
	bypass_v_q <= bypass_v_next;
end

/* data and len */
logic              data_lite_v;

assign data_lite_v = data_v & ~bypass_v_q;

if ( DATA_W == 16 ) begin
	assign len_o  = term_i ? len_i : DATA_BYTES_N;
	assign data_o  = data_i;
	assign valid_o = data_lite_v & fsm_data_q;
	
	/* flop fsm_head_q to detect first data cycle */
	reg fsm_head_2q;
	always @(posedge clk)begin
		if(valid_i)begin
			fsm_head_2q <= fsm_head_q;
		end
	end
	assign start_o =  fsm_head_2q & fsm_data_q;
end else begin 
	/* if DATA_W > 16 need to shift data because of header */
	logic [LEN_W-1:0]  head_data_len;
	logic [DATA_W-1:0] head_data_shifted;
	logic              head_data_lite_v;

	assign head_data_lite_v = type_v;
	assign len_o   = {LEN_W{head_data_lite_v}} & head_data_len
				   | {LEN_W{term_i}} & len_i
				   | {LEN_W{~head_data_len & ~term_i}} & DATA_BYTES_N; // '1
	assign data_o  = head_data_lite_v ? head_data_shifted : data_i;
	assign valid_o = data_lite_v & 
					( fsm_data_q 
					| fsm_head_q & head_data_lite_v ); 
	assign start_o = head_data_lite_v;
	if ( DATA_W == 32 ) begin
		/* with or whitout vtag data will be on the 2 msb bytes after the type */
		assign head_data_len =  'd2;
		assign head_data_shifted = { {TYPE_W{1'bx}}, data_i[DATA_W-:TYPE_W]};
	end else if ( DATA_W == 64 ) begin
		/* cnt_q[2] = 20, start 2nd lane0 
 		 * no vtag :
 		 * [X | pre 4B] [pre 4B | @dst 4B] [@dst 2B | @src 6B] [type 2B| data 6B]
 		 * vtag : 
		 * [X | pre 4B] [pre 4B | @dst 4B] [@dst 2B | @src 6B] [vtag 4B| type 2B | data 2B]
 		 * 
 		 * ~cnt_q[2] = 16, start 1st lane0 
 		 * no vtag:
		 * [pre 8B] [@dst 6B | @scr 2B] [@src 4B | type 2B | data 2B]
		 * vtag:
		 * [pre 8B] [@dst 6B | @scr 2B] [@src 4B | vtag 4B] [type 2B | data 6B]
		 */
		logic head_data_shift2;
		if (IS_10G) begin
			if ( VLAN_TAG ) begin
				/* verilator lint_off UNUSEDSIGNAL */
				assign head_data_shift2 = cnt_q[2] ^ vlan_v;
				/* verilator lint_on UNUSEDSIGNAL */
			end else begin
				assign head_data_shift2 = ~cnt_q[2];	
			end
		end else // !10G
			if ( VLAN_TAG ) begin
				/* verilator lint_off UNUSEDSIGNAL */
				assign head_data_shift2 = ~vlan_v;
				/* verilator lint_on UNUSEDSIGNAL */
				assign head_data_len = {2'b0, {4{~head_data_shift2}}, 2'b11};  
			end else begin // !VTAG
				assign head_data_shift2 = 1'b1;
				assign head_data_len = 'd2;  
			end
		end
		/* verilator lint_off UNUSEDSIGNAL */
		assign head_data_shifted = head_data_shift2
		/* verilator lint_on UNUSEDSIGNAL */
								 ? {data_i[DATA_W-:TYPE_W], {DATA_W-TYPE_W{1'bx}}}
								 : {data_i[DATA_W-:DATA_W-TYPE_W],{TYPE_W{1'bx}}};
end

/* crc */
// TODO 
logic             crc_start_v;
logic             crc_zero;
logic             crc_err_v;
logic [CRC_W-1:0]  crc;
/* crc starts after preamble */
assign crc_start_v = cnt_q == 8;
/* crc test at the end of the packet 
 * TODO: handle when data does not end
 * on payload boundary */
assign crc_zero = ~|crc;
assign crc_err_v = ~crc_zero & term_i & valid_i; 

crc #(.DATA_W(DATA_W), .CRC_W(CRC_W))
m_crc(
	.clk(clk),
	.start_i(crc_start_v),
	.valid_i(data_v),
	.len_i(len_i),
	.data_i(data_i),
	.crc_o(crc)
);
/* fsm */

assign fsm_invalid_next = cancel_i
						| term_i & fsm_data_q
						| fsm_invalid_q & ~start_lite;
assign fsm_head_next = (start_lite
					 | fsm_head_q & ~type_v) & ~cancel_i;
assign fsm_data_next = (fsm_head_q & type_v
					 | fsm_data_q & ~term_i) & ~cancel_i; 
always @(posedge clk) begin
	if ( ~nreset ) begin
		fsm_invalid_q <= 1'b1;
		fsm_head_q <= 1'b0;
		fsm_data_q <= 1'b0;
	end else begin
		if(valid_i)begin
			fsm_invalid_q <= fsm_invalid_next;
			fsm_head_q <= fsm_head_next;
			fsm_data_q <= fsm_data_next;
		end
	end
end

/* output */
assign crc_err_o = crc_err_v;

`ifdef FORMAL
logic [2:0] f_fsm;
assign f_fsm = { fsm_invalid_q, fsm_head_q, fsm_data_q };

always @(posedge clk) begin
	if(nreset)begin
		sva_fsm_onehot: assert($onehot(f_fsm));	
	end
end
`endif
endmodule

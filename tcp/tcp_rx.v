/* TCP RX module
 * TCP state will be maintained by entry,
 * this module is only for parsing 
 *
 * Only support DATA_W == 16b */
module tcp_rx#(
	parameter IS_10G = 1,
	parameter DATA_W = 16,
	localparam PORT_W = 16,
	parameter [PORT_W-1:0] SRC_PORT = {16'd9000},
	parameter [PORT_W-1:0] DST_PORT = {16'd9000},
	localparam LEN_W = $clog2(DATA_W/8),
	localparam SEQ_W = 32,
	localparam FLAG_W = 8
)(
	input clk,
	input nreset,

	/* from IP */
	input              valid_i,
	input              start_i,
	input [DATA_W-1:0] data_i,
	input [LEN_W-1:0]  len_i,

	/* to tcp entries logic */
	output              head_v_o,
	output [SEQ_W-1:0]  seq_o,
	output [FLAG_W-1:0] flag_o,

	/* to transport layer */
	output              valid_o,
	output              start_o,
	output [LEN_W-1:0]  len_o,
	output [DATA_W-1:0] data_o	
);
/* max head width in btyes */
localparam MAX_HEAD_N = 57;
localparam HEAD_CNT_W = $clog2(MAX_HEAD_W);
 
/* FSM */
logic start_v;
logic data_end_v;
logic head_end_v;

logic fsm_idle_next;
reg   fsm_idle_q;
logic fsm_head_next;
reg   fsm_head_q;
logic fsm_data_next;
reg   fsm_data_q;

/* TCP header :
 *  0                   1                   2                   3
 *  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * |          Source Port          |       Destination Port        |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * |                        Sequence Number                        |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * |                    Acknowledgment Number                      |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * |  Data |       |C|E|U|A|P|R|S|F|                               |
 * | Offset| Rsrvd |W|C|R|C|S|S|Y|I|            Window             |
 * |       |       |R|E|G|K|H|T|N|N|                               |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * |           Checksum            |         Urgent Pointer        |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * |                           [Options]                           |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 * |                                                               :
 * :                             Data                              :
 * :                                                               |
 * +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *
 * header cnt */
logic                  unused_cnt_add;
logic [HEAD_CNT_W-1:0] head_cnt_add;
logic [HEAD_CNT_W-1:0] head_cnt_next;
reg   [HEAD_CNT_W-1:0] head_cnt_q;

assign { unused_cnt_add, head_cnt_add} = head_cnt_q + {{HEAD_CNT_W-LEN_W{1'b0}},len_i};
assign head_cnt_next = start_i ? {{HEAD_CNT_W-LEN_W{1'b0}},len_i}: head_cnt_add;
always @(posedge clk) begin
	if ( valid_i ) begin
		head_cnt_q <= head_cnt_next;
	end
end
 
/* store ports */
logic              src_port_en;
reg   [PORT_W-1:0] src_port_q;
logic              dst_port_en;
reg   [PORT_W-1:0] dst_port_q;

assign src_port_en = start_v;
assign dst_port_en = head_cnt_q == 'd2; 
always @(posedge clk) begin
	if ( src_port_en ) begin
		src_port_q <= data_i;
	end
	if ( dst_port_en ) begin
		dst_port_q <= data_i;
	end
end
/* seq and ack number */
localparam SEQ_EN_W = SEQ_W/DATA_W;

logic [SEQ_EN_W-1:0] seq_en;
logic [SEQ_EN_W-1:0] ack_en;
reg   [SEQ_W-1:0]    seq_q;
reg   [SEQ_W-1:0]    ack_q;

genvar i;
generate
for(i=0; i<SEQ_EN_W; i++) begin: gen_seq_en_loop
	assign seq_en[i] = (4 + (i*8/DATA_W)) == head_cnt_q; 
	assign ack_en[i] = (8 + (i*8/DATA_W)) == head_cnt_q;

	always @(posedge clk) begin
		if (seq_en[i]) begin
			seq_q[i*DATA_W+:DATA_W] <= data_i; 
		end
		if (ack_en[i]) begin
			ack_q[i*DATA_W+:DATA_W] <= data_i; 
		end
	end
end
endgenerate
/* data offset */
localparam DOFF_W = 4;
logic              doff_v;
reg   [DOFF_W-1:0] doff_q;
logic [DOFF_W-1:0] doff_next;

assign doff_v = fsm_head_q & ( head_cnt_q > 'd12); 
always @(posedge clk) begin
	if ( ~doff_v ) begin
		doff_q <= data_i[DOFF_W-1:0];
	end
end		
/* flags */

/* FSM logic */
assign start_v = valid_i & start_i;
assign head_end_v = valid_i & doff_v & ( doff_q <= head_cnt_next );

assign fsm_idle_next = fsm_idle_q & ~start_v
					 | fsm_data_q & end_v;
assign fsm_head_next = fsm_idle_q & start_v
					 | fsm_head_q & ~head_end_v;
assign fsm_data_next = fsm_head_q & head_end_v
					 | fsm_data_q & ~data_end_v; 
always @(posedge clk) begin
	if ( ~nreset ) begin
		fsm_idle_q <= 1'b0;
		fsm_head_q <= 1'b0;
		fsm_data_q <= 1'b0;
	end else begin
		fsm_idle_q <= fsm_idle_next;	
		fsm_head_q <= fsm_head_next;
		fsm_data_q <= fsm_data_next;	
	end
end

`ifdef FORMAL

always @(posedge clk) begin
	if ( ~nreset ) begin
		if ( DATA_W == 16 ) begin
		/* given valid data, the lenght should contain 2 valid bytes with 
		 * the exeption of the last packet */
		sva_len_2 : assert( ~valid_i | valid_i & ( len_i == 2'd2 | fsm_idle_next )));
		end
	end
end
`endif
endmodule

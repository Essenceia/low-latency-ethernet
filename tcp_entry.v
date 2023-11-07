/* TCP entry : manages 1 socket, 
 * contains socket lifetime fsm */
module tcp_entry#(
	parameter IP_W = 32, // IP address
	parameter PORT_W = 16,
	parameter SEQ_W = 32, // seq and ack number are the same size
 	parameter FLAG_W = 8,
	/* flag index */
	localparam CWR_IDX = 0,
	localparam ECE_IDX = 1,
	localparam URG_IDX = 2,
	localparam ACK_IDX = 3,
	localparam PSH_IDX = 4,
	localparam PST_IDX = 5,
	localparam SYN_IDX = 6,
	localparam FIN_IDX = 7
)
(
	input clk,
	input nreset,

	/* init new entry */
	input init_v_i,
	input [IP_W-1:0]   init_ip_dst_i,
	input [PORT_W-1:0] init_port_src_i,
	input [PORT_W-1:0] init_port_dst_i,
	input [SEQ_W-1:0]  init_seq_i,

	/* cancel signal */
	input cancel_v_i;

	/* entry is allocated */
	output              valid_o,
	output [IP_W-1:0]   ip_dst_o,
	output [PORT_W-1:0] port_dst_o,
	output [SEQ_W-1:0]  seq_next_o,

	/* received valid tcp header */
	input              rec_v_i,
	input [SEQ_W-1:0]  rec_seq_i,
	input [SEQ_W-1:0]  rec_ack_i,
	input [FLAG_W-1:0] rec_flag_i,

	/* sent packet, increment seq */
	input              sent_v_i,

	/* request send of tcp packet */
	output              send_v_o,
	/* header content for next tcp packet */
	output [FLAG_W-1:0] send_flag_o
);
/* FSM */
logic init_v;
logic cancel_v;
logic invalid_next;
reg   invalid_q;
logic syn_wait_next;
reg   syn_wait_q;
logic syn_sent_next;
reg   syn_sent_q;
logic est_wait_next;
reg   est_wait_q;
logic est_next;
reg   est_q;


/* establish connection : wait for valid SYN+ACK */
logic rec_syn_ack_v;
assign rec_syn_ack_v = rec_v_i & rec_flag_i[SYN_IDX] & rec_flag_i[ACK_IDX]; 

/* FSM 
 * cancel, TODO: add timeout */
assign cancel_v = cancel_v_i; 

/* invalid */
assign init_v = init_v_i & invalid_q & ~cancel_v;
assign syn_wait_next = init_v;
assign syn_sent_next = sent_v_i  & syn_sending_q;
assign est_wait_next = rec_syn_ack_v & syn_sent_q;
assign est_next      = sent_v_i & est_wait_q;
 
always @(posedge clk) begin
	if ( ~nreset ) begin
		invalid_q  <= 1'b0;
		syn_wait_q <= 1'b0;
		syn_sent_q <= 1'b0;
		est_wait_q <= 1'b0;
		est_q      <= 1'b0;
	end else begin
		invalid_q  <= invalid_next;
		syn_wait_q <= syn_wait_next;
		syn_sent_q <= syn_sent_next;
		est_wait_q <= est_wait_next;
		est_q      <= est_next;
	end
end

`ifdef FORMAL
logic [4:0] f_fsm;
assign f_fsm = { invalid_q, syn_wait_q, syn_sent_q, est_wait_q, est_q };

always begin
	sva_fsm_onehot : assert( $onehot(f_fsm));
end

`endif
endmodule

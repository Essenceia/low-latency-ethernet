/* UDP rx module
*
* Features :
* - src/dst port check 
* - no UDP checksum : legal for IPv4 
*
* Note: only supports DATA_W = 16 */
module udp_rx #(
	parameter DATA_W  = 16,
	parameter LEN_W   = $clog2(DATA_W/8),
	/* port number */
	parameter PORT_W   = 16,
	parameter [PORT_W-1:0] SRC_PORT = 16'd18070,
	parameter [PORT_W-1:0] DST_PORT = 16'd18070
)
(
	input clk,
	input nreset,
	
	input              cancel_i,
	// ip payload
	input              valid_i,
	input              start_i,
	input [DATA_W-1:0] data_i,
	input [LEN_W-1:0]  len_i,
	input              ip_cs_err_i,
	
	// to application layer
	output              valid_o,
	output              start_o,
	//output              last_o,TODO: check if we can do without
	output [DATA_W-1:0] data_o, 
	output [LEN_W-1:0]  len_o
);
localparam CNT_W = 16;
localparam HEAD_N = 8;
localparam CNT_HEAD_W = $clog2(HEAD_N+1);
/* fsm */
reg   fsm_head_q;
logic fsm_head_next;
reg   fsm_data_q;
logic fsm_data_next;
reg   fsm_idle_q;
logic fsm_idle_next;

/* cnt bytes receieved */
reg   [CNT_W-1:0] cnt_q;
logic [CNT_W-1:0] cnt_next;
logic [CNT_W-1:0] cnt_add;
logic             unused_cnt_add_of;
logic             cnt_rst;

assign cnt_rst = fsm_idle_q & ~valid_i;
assign {unused_cnt_add_of, cnt_add} = cnt_q + {{CNT_W-LEN_W{1'b0}}, {LEN_W{valid_i}}&len_i}; 
assign cnt_next = cnt_rst ? {CNT_W{1'b0}} : cnt_add;

always @(posedge clk) begin
	cnt_q <= cnt_next;
end
/* 0      7 8     15 16    23 24    31
* +--------+--------+--------+--------+
* |     Source      |   Destination   |
* |      Port       |      Port       |
* +--------+--------+--------+--------+
* |                 |                 |
* |     Length      |    Checksum     |
* +--------+--------+--------+--------+
* |
* |          data octets ...
* +---------------- ...
*/
/* udp length */
logic             udp_len_v;
reg   [CNT_W-1:0] udp_len_q;
logic [CNT_W-1:0] udp_len_next;

assign udp_len_v = valid_i & fsm_head_q & ( cnt_q[CNT_HEAD_W-1:0] == 'd3 );
assign udp_len_next = udp_len_v ? data_i : udp_len_q;

always @(posedge clk) begin
	udp_len_q <= udp_len_next;
end
/* head and data end 
 * head end : got all 8 udp head bytes
 * data end : receieved bytes >= udp length */
logic end_head_v;
logic end_data_v;
assign end_head_v = cnt_add[CNT_HEAD_W-1:0] == 'd8;
assign end_data_v = cnt_add >= udp_len_q;
  
/* port */
logic              src_port_cnt_v;
logic [PORT_W-1:0] src_port;
logic              dst_port_cnt_v;
logic [PORT_W-1:0] dst_port;
assign src_port_cnt_v = ( cnt_q[CNT_HEAD_W-1:0] == 'd0 ) & fsm_idle_q;
assign src_port       = data_i;
assign dst_port_cnt_v = ( cnt_q[CNT_HEAD_W-1:0] == 'd2 ) & fsm_head_q;
assign dst_port       = data_i;

/* discard signals */ 
logic dcd_v;
logic src_dcd_v;
logic dst_dcd_v;

assign src_dcd_v = src_port_cnt_v & ( src_port != SRC_PORT); 
assign dst_dcd_v = dst_port_cnt_v & ( dst_port != DST_PORT); 
assign dcd_v = valid_i & ( src_dcd_v | dst_dcd_v | ip_cs_err_i );

/* data bypass */
reg   bypass_v_q;
logic bypass_v_next;
logic bypass_rst;

assign bypass_rst  = cnt_rst;
assign bypass_v_next = bypass_rst ? 1'b0 : bypass_v_q | dcd_v;
always @(posedge clk) begin
	bypass_v_q <= bypass_v_next;
end


// FSM
assign fsm_idle_next  = cancel_i
					  | fsm_idle_q & ~valid_i
					  | fsm_data_q & end_data_v; 
assign fsm_head_next  = ~cancel_i & 
					  ( fsm_idle_q & valid_i
					  | fsm_head_q & ~end_head_v);
assign fsm_data_next = ~cancel_i & 
					 ( fsm_head_q & end_head_v 
					 | fsm_data_q & ~end_data_v );
always @(posedge clk) begin
	if ( ~nreset ) begin
		fsm_idle_q <= 1'b1;
		fsm_head_q <= 1'b0;
		fsm_data_q <= 1'b0;
	end else begin
		fsm_idle_q <= fsm_idle_next;  
		fsm_head_q <= fsm_head_next;
		fsm_data_q <= fsm_data_next;
	end
end

// output
assign valid_o  = fsm_data_q & valid_i & ~bypass_v_q;
assign data_o   = data_i;
assign len_o    = len_i;
`ifdef FORMAL
initial begin
	a_reset : assume ( ~nreset );
end 
always @(posedge clk) begin
	sva_fsm_onehot : assert ( $onehot( { fsm_head_q, fsm_data_q, fsm_idle_q } );	
	// xcheck
	sva_xcheck_valid_o : assert ( ~$isunknown( valid_o ));
	//sva_xcheck_last_o  : assert ( ~valid_o | ( valid_o & ~$isunknown( last_o )));
	sva_xcheck_len_o  : assert ( ~valid_o | ( valid_o & ~$isunknown( len_o )));
	genvar i;
	generate
		for( i = 0; i < KEEP_W; i ++) begin
			assert ( ~( valid_o & ( len_o < i )) | ( valid_o & (len_o >= i) & ~$isunknown( data_o[i*8+7:i*8] )));
		end
	endgenerate
end
`endif
endmodule

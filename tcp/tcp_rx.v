/* TCP RX module
 * TCP state will be maintained by entry,
 * this module is only for parsing */
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
 */

/* store ports */
logic [PORT_W-1:0] src_port_next;
reg   [PORT_W-1:0] src_port_q;
logic [PORT_W-1:0] dst_port_next;
reg   [PORT_W-1:0] dst_port_q;

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

assign start_v = valid_i & start_i;
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

endmodule

/* PCS encode block
*
* Add control additional control blocks
*/
module pcs_enc #(
	parameter XGMII_DATA_W = 32,
	parameter XGMII_KEEP_W = $clog2(XGMII_DATA_W),
	parameter BLOCK_W = 64,
	parameter CNT_N = BLOCK_W/XGMII_DATA_W,
	parameter CNT_W = $clog2( CNT_N ),

	parameter BLOCK_TYPE_W = 8
)(
	// data clk
	input clk,
	input nreset,

	input idle_v_i,

	input [CNT_W-1:0]        part_i,
	input [XGMII_DATA_W-1:0] data_i, // tx data
	input [XGMII_KEEP_W-1:0] keep_i,
	
	input start_i,
	input last_i,

	output                    sync_header_v_o,
	output [1;0]              sync_header_o, 
	output [XGMII_DATA_W-1:0] data_o		
);
logic [BLOCK_TYPE_W-1:0] block_type;
// fsm
reg   fsm_idle_q;
reg   fsm_data_q;
logic start_v;
logic last_v;
logic ctrl_v;
logic fsm_idle_next;
logic fsm_data_next;
logic part_zero;

// block type field
assign block_type_v = ctrl_v;
assign block_type   = {BLOCK_TYPE_W{start_v}} & 0x78;

// output data
assign data_o = { data_i[XGMII_DATA_W-1:BLOCK_TYPE_W] , block_type_v ? block_type : data_i[BLOCK_TYPE_W-1:0] };
// sync header data or control
// data 2'b01
// cntr 2'b10
assign sync_header_v_o = part_zero;
assign sync_header_o   = { ctrl_v , ~ctrl_v };

// FSM
assign part_zero = part_i == 'd0; 

assign start_v = ~idle_v_i & part_zero & start_i;
assign last_v  = ~idle_v_i & part_zero & last_i;
assign ctrl_v  = ( start_i | last_i | idle_v_i ) & part_zero;

assign fsm_idle_next = last_v | fsm_idle_q & ~start_v;
assign fsm_data_next = start_v | fsm_data_q & ~last_v; 

always @(posedge clk) begin
	if ( ~nreset ) begin
		fsm_idle_q  <= 1'b1;
		fsm_data_q  <= 1'b0;
	end else begin
		fsm_idle_q  <= fsm_idle_next;
		fsm_data_q  <= fsm_data_next;
	end
end
endmodule

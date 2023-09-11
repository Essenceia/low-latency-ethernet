/* IP address match when full addr data
 * is spread over multiple cycles */
module ip_addr_match #(
	parameter DATA_W = 16,
	parameter ADDR_W = 32,
	parameter [ADDR_W-1:0] ADDR = {8'd206, 8'd200, 8'd127, 8'd128},
	parameter IDX_W = 5,
	parameter [IDX_W-1:0] MSB_IDX = 6,
	parameter [IDX_W-1:0] LSB_IDX = MSB_IDX + 1
)(
	input clk,

	input              valid_i,
	input [DATA_W-1:0] data_i,
	input [IDX_W-1:0]  idx_i,
	input              fsm_idle_v_i,
	input              fsm_head_v_i,

	output             match_fail_v_o
);
logic addr_dcd_lsb_v;
logic addr_msb_idx_v;
logic addr_dcd_msb_v_next;
reg   addr_dcd_msb_v_q;
logic addr_msb_en;
logic addr_dcd_msb_rst;

/* msb src addr */
assign addr_dcd_msb_rst = fsm_idle_v_i;
assign addr_msb_idx_v = idx_i[IDX_W-1:0] == MSB_IDX;
assign addr_msb_en    = (addr_msb_idx_v & valid_i) | fsm_idle_v_i;	
assign addr_dcd_msb_v_next = addr_dcd_msb_rst ? 1'b0 : ADDR[31:16] != data_i;
always @(posedge clk) begin
	if (addr_msb_en) begin
		addr_dcd_msb_v_q <= addr_dcd_msb_v_next;
	end
end

/* lsb src addr */
assign addr_dcd_lsb_v = valid_i & (idx_i[IDX_W-1:0] == LSB_IDX) 
						  & (ADDR[15:0] != data_i);
assign match_fail_v_o = fsm_head_v_i & (addr_dcd_msb_v_q | addr_dcd_lsb_v); 
	
endmodule


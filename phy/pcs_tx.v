/* PCS on the transmission path */
module pcs_tx#(
	parameter XGMII_DATA_W = 32,
	parameter XGMII_KEEP_W = $clog2(XGMII_DATA_W),
	parameter BLOCK_W = 64,
	parameter CNT_N = BLOCK_W/XGMII_DATA_W,
	parameter CNT_W = $clog2( CNT_N ),
	parameter BLOCK_TYPE_W = 8,
	
	parameter PMA_DATA_W = 16 
)(
	input mii_clk,
	input pma_clk,
	input nreset,

	// MAC
	input idle_v_i,

	input [CNT_W-1:0]              part_i,
	input [XGMII_DATA_W-1:0]       data_i, // tx data
	input [XGMII_KEEP_W-1:0]           keep_i,
	input [(CNT_N-1)*XGMII_KEEP_W-1:0] keep_next_i,
	
	input start_i,
	input last_i,

	// PMA
	output [PMA_DATA_W-1:0] data_o
);
// data
logic [XGMII_DATA_W-1:0] data_enc; // encoded
logic [XGMII_DATA_W-1:0] data_scram_part; // scrambled
logic [BLOCK_W-1:0}      data_scram_part_shifted;
logic [BLOCK_W-1:0]      data_scram;// full data
// sync header
logic       sync_header_v;
logic [1:0] sync_header;
// encode
pcs_enc #()
m_pcs_enc(
	.clk(mii_clk),
	.nreset(nreset),

	.idle_v_i(idle_v_i),
	.part_i(part_i),
	.data_i(data_i), // tx data
	.keep_i(keep_i),
	.keep_next_i(keep_next_i),
	.start_i(start_i),
	.last_i(last_i),
	.block_header_v_o(sync_header_v),
	.sync_header_o(sync_header), 
	.data_o(data_enc)	
);
// scramble

// add sync header

// gearbox
endmodule

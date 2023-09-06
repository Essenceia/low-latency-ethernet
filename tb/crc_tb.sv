module crc_tb;
localparam DATA_W = 32;
localparam CRC_W = 32;

reg clk = 1'b0;
logic start_i;
logic valid_i;
logic [DATA_W-1:0] data_i;
logic [CRC_W-1:0]  crc_o;
logic [CRC_W-1:0]  crc_2_o;

always clk = #5 ~clk;

reg   [CRC_W-1:0] crc_state_q;
logic [CRC_W-1:0] crc_state_next;
logic [CRC_W-1:0] crc_state;
logic [CRC_W-1:0] tb_exp_crc;
logic [CRC_W-1:0] crc_state_neg;

//logic [63:0] tb_data = 64'h987654321;
logic [63:0] tb_data = '0;
logic [DATA_W-1:0] tb_res = 32'h55404551;
logic [DATA_W-1:0] tb_data_diff;
assign tb_data_diff = tb_res ^ crc_o;
initial begin
	$dumpfile("wave/crc_tb.vcd");
	$dumpvars(0, crc_tb);
	#10
	start_i = 1'b1;
	valid_i = 1'b1;
    data_i = tb_data[DATA_W-1:0];
	#10
	start_i = 1'b0;
	data_i = tb_data[2*DATA_W-1:DATA_W];
	#1
	assert(tb_res == crc_o);
	#9
	$display("Test finished");
	$finish;
end

/* uut */
crc32 #(
	.DATA_W(DATA_W),
	.SUM_W(CRC_W)
)m_crc_rx(
	.clk(clk),
	.start_i(start_i),
	.valid_i(valid_i),
	.data_i(data_i),
	.crc_o(crc_o)
);
/* uut */
crc #(
	.DATA_W(DATA_W),
	.SUM_W(CRC_W)
)m_crc_v2_rx(
	.clk(clk),
	.start_i(start_i),
	.valid_i(valid_i),
	.data_i(data_i),
	.crc_o(crc_2_o)
);

/* behavioral reference */
always @(posedge clk) begin
	crc_state_q <= crc_state_next;
end
assign crc_state = start_i ? '1 : crc_state_q;
assign crc_state_neg = ~crc_state_q;
lfsr #(
    .LFSR_WIDTH(32),
    .LFSR_POLY(32'h4c11db7),
    .LFSR_CONFIG("GALOIS"),
    .LFSR_FEED_FORWARD(0),
    .REVERSE(1),
    .DATA_WIDTH(32),
    .STYLE("AUTO")
)
eth_crc_32 (
    .data_in(data_i),
    .state_in(crc_state),
    .data_out(tb_exp_crc),
    .state_out(crc_state_next)
);
endmodule

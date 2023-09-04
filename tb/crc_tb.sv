module crc_tb;
localparam DATA_W = 32;
localparam CRC_W = 32;

reg clk = 1'b0;
logic start_i;
logic valid_i;
logic [DATA_W-1:0] data_i;
logic [CRC_W-1:0]  crc_o;

always clk = #5 ~clk;

logic [63:0] tb_data = 64'h987654321;
logic [DATA_W-1:0] tb_res = 32'hcbf43926;
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
	#10
	$display("Test finished");
	$finish;
end

/* uut */
crc_rx #(
	.DATA_W(DATA_W),
	.SUM_W(CRC_W)
)m_crc_rx(
	.clk(clk),
	.start_i(start_i),
	.valid_i(valid_i),
	.data_i(data_i),
	.crc_o(crc_o)
);
endmodule

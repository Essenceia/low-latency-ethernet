module crc_tb;
localparam DATA_W = 16;
localparam CRC_W = 32;
localparam LEN_W = $clog2((DATA_W/8)+1);
localparam [LEN_W-1:0] DATA_BYTE_N = (DATA_W/8);

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
reg   [CRC_W-1:0] crc_q;
logic [CRC_W-1:0] tb_res = 32'hC704DD7B;
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
	#10
	assert(tb_res == crc_o);
	#100
	$display("Test finished");
	$finish;
end

/* uut */
crc #(
	.DATA_W(DATA_W)
)m_crc_rx(
	.clk(clk),
	.start_i(start_i),
	.valid_i(valid_i),
	.len_i(DATA_BYTE_N),
	.data_i(data_i),
	.crc_o(crc_o)
);

always @(posedge clk)begin
	crc_q <= {crc_q[CRC_W-1:DATA_W], crc_o}; 
end

endmodule

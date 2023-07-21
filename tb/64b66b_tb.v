module lite_64b66b_tb;
localparam BLOCKS = 8;
localparam LEN = 8;


reg clk = 1'b0;
reg nreset;
logic                  valid_i;
logic [BLOCKS*LEN-1:0] data_i;
logic [BLOCKS*LEN-1:0] scram_o;

always #5 clk = ~clk;
initial begin
	$dumpfile("build/wave.vcd");
	$dumpvars(0, lite_64b66b_tb);
	nreset = 1'b0;
	#10
	nreset = 1'b1;
	// begin testing
	for( int i = 0; i < 8; i ++) begin
		valid_i = 1'b1;
		data_i = {64{1'b0}};
		#10
		$display("running scramble cycle %d",i);
	end
	$finish;
end

scrambler_64b66b_tx #( .BLOCKS(BLOCKS), .LEN(LEN))
m_64b66b_tx(
	.clk(clk),
	.nreset(nreset),
	.valid_i(valid_i),
	.data_i(data_i),
	.scram_o(scram_o)
);



endmodule

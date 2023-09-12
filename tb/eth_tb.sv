`define TB_LOOP_CNT 10

/* Top level tb for ethernet modules */
module eth_tb;

localparam DATA_W = 16;
localparam KEEP_W = DATA_W/8;
localparam LEN_W = $clog2(KEEP_W+1);
localparam PKT_LEN_W = 16;
localparam UDP_CS_W = 16;

/* tx */
reg   clk = 1'b0;
logic nreset;
logic                  app_valid_i;
logic [DATA_W-1:0]     app_data_i;
logic [LEN_W-1:0]      app_len_i;
logic [PKT_LEN_W-1:0]  app_pkt_len_i;
logic [UDP_CS_W-1:0]   app_cs_i;

always clk = #5 ~clk;

initial begin
	$dumpfile("wave/eth_tb.vcd");
	$dumpvars(0, eth_tb);
	nreset = 1'b0;
	#10
	nreset = 1'b1;
	/* Test 1 */
	/* generated tx header */
	app_pkt_len_i = 50;
	#100
	
	$display("Test finised");
	$finish;		
end

/* UUT TX */
eth_tx #(
	.DATA_W(DATA_W)
)m_eth_tx(
	.clk(clk),
	.nreset(nreset),
	.app_valid_i(app_valid_i),
	.app_data_i(app_data_i),
	.app_len_i(app_len_i),
	.app_pkt_len_i(app_pkt_len_i),
	.app_cs_i(app_cs_i)	
);
endmodule

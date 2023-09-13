`define TB_LOOP_CNT 10

/* Top level tb for ethernet modules */
module eth_tb;

localparam IS_10G = 1;

localparam DATA_W = 16;
localparam KEEP_W = DATA_W/8;
localparam LEN_W = $clog2(KEEP_W+1);
localparam PKT_LEN_W = 16;
localparam UDP_CS_W = 16;

localparam LANE0_CNT_N = IS_10G & ( DATA_W == 64 )? 2 : 1;

reg   clk = 1'b0;
logic nreset;

/* rx */
/* from physical layer */
logic                   mac_cancel_i;
logic                   mac_valid_i;
logic [DATA_W-1:0]      mac_data_i;
logic                   mac_ctrl_v_i;
logic                   mac_idle_i;
logic [LANE0_CNT_N-1:0] mac_start_i;
logic                   mac_term_i;
logic [KEEP_W-1:0]      mac_term_keep_i;

/* to application */
logic                  app_valid_o;
logic                  app_cancel_o;
logic [DATA_W-1:0]     app_data_o;
logic [LEN_W-1:0]      app_len_o;
/* tx */
logic                  app_valid_i;
logic [DATA_W-1:0]     app_data_i;
logic [LEN_W-1:0]      app_len_i;
logic [PKT_LEN_W-1:0]  app_pkt_len_i;
logic [UDP_CS_W-1:0]   app_cs_i;

always clk = #5 ~clk;

task set_rx_idle();
	mac_valid_i = 1'b1;
	mac_cancel_i = 1'b0;
	mac_data_i = {DATA_W{1'bx}};
	mac_ctrl_v_i = 1'b0;
	mac_idle_i = 1'b1;	
	mac_start_i = {LANE0_CNT_N{1'b0}};
	mac_term_i = 1'b0;
	mac_term_keep_i = {KEEP_W{1'b0}};	
endtask

task send_simple_tx_data(int l);
	app_valid_i = 1'b0;	
	app_pkt_len_i = l;
	for(int i=0; i<l/KEEP_W; i++)begin
		#10
		app_valid_i = 1'b1;
		app_data_i = $random;
		app_len_i = {KEEP_W{1'b1}};	
	end
	#10
	app_valid_i = 1'b0;
	app_len_i = {KEEP_W{1'b0}};	
	app_data_i = {DATA_W{1'bx}};
	
	for(int i=0; i < l%KEEP_W; i++)begin
		$display("i %d l %d",i,l);
		app_valid_i = 1'b1;
		app_len_i[i] = 1'b1;
		app_data_i[i*8+:8] = $random;
	end
	#10
	app_valid_i = 1'b0;
endtask

initial begin
	$dumpfile("wave/eth_tb.vcd");
	$dumpvars(0, eth_tb);
	nreset = 1'b0;
	#10
	nreset = 1'b1;
	mac_cancel_i = 1'b0;
	mac_valid_i = 1'b0;
	/* generated tx header */
	app_pkt_len_i = 50;
	#10
	set_rx_idle();
	send_simple_tx_data(19);
	#100
	
	$display("Test finised");
	$finish;		
end

/* UUT RX */
eth_rx #(
	.DATA_W(DATA_W)
)m_eth_rx(
	.clk(clk),
	.nreset(nreset),
	.mac_cancel_i(mac_cancel_i),
	.mac_valid_i(mac_valid_i),
	.mac_data_i(mac_data_i),
	.mac_ctrl_v_i(mac_ctrl_v_i),
	.mac_idle_i(mac_idle_i),
	.mac_start_i(mac_start_i),
	.mac_term_i(mac_term_i),
	.mac_term_keep_i(mac_term_keep_i),
	.app_valid_o(app_valid_o),
	.app_cancel_o(app_cancel_o),
	.app_data_o(app_data_o),
	.app_len_o(app_len_o)
);
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

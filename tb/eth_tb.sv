`define TB_LOOP_CNT 1000

/* Top level tb for ethernet modules */
module eth_tb;

localparam IS_10G = 1;

localparam DATA_W = 16;
localparam KEEP_W = DATA_W/8;
localparam LEN_W = $clog2(KEEP_W+1);
localparam PKT_LEN_W = 16;
localparam UDP_CS_W = 16;

localparam BLOCK_N = 8;
localparam BLOCK_LEN_W = $clog2(BLOCK_N+1);
localparam APP_LAST_LEN_N = BLOCK_N+KEEP_W;
localparam APP_LAST_LEN_W = $clog2(APP_LAST_LEN_N+1);

localparam LANE0_CNT_N = IS_10G & ( DATA_W == 64 )? 2 : 1;

reg   clk = 1'b0;
logic nreset;

/* rx */
/* from physical layer */
logic                   phy_cancel_i;
logic                   mac_valid_i;
logic [DATA_W-1:0]      mac_data_i;
logic [LANE0_CNT_N-1:0] mac_start_i;
logic                   mac_term_i;
logic [LEN_W-1:0]       mac_len_i;

/* to application */
logic                  app_valid_o;
logic                  app_cancel_o;
logic [DATA_W-1:0]     app_data_o;
logic [LEN_W-1:0]      app_len_o;
/* tx */
logic                  app_early_v_i;
logic                  app_ready_v_o;
logic                  app_cancel_i;
//logic                  app_valid_i;
logic [DATA_W-1:0]     app_data_i;
logic [LEN_W-1:0]      app_len_i;
logic [PKT_LEN_W-1:0]  app_pkt_len_i;
logic [UDP_CS_W-1:0]   app_cs_i;

logic                      app_last_i;
logic                      app_last_block_next_i;
logic [APP_LAST_LEN_W-1:0] app_last_block_next_len_i;

logic                  phy_ready_i;

logic                   phy_ctrl_v_o;
logic [DATA_W-1:0]      phy_data_o;	
logic [LANE0_CNT_N-1:0] phy_start_o;
logic                   phy_idle_o;
logic                   phy_term_o;
logic [BLOCK_LEN_W-1:0] phy_term_len_o;

/* verilator lint_off BLKSEQ */
always clk = #5 ~clk;
/* verilator lint_on BLKSEQ */

task set_rx_idle();
	mac_valid_i = 1'b0;
	phy_cancel_i = 1'b0;
	mac_data_i = {DATA_W{1'bx}};
	mac_start_i = {LANE0_CNT_N{1'b0}};
	mac_term_i = 1'b0;
	mac_len_i = {LEN_W{1'b0}};	
endtask

task set_tx_default();
	app_cancel_i = 1'b0;
	app_early_v_i = 1'b0;
	app_last_i = 1'b0;
	phy_ready_i = 1'b1;
	/* verilator lint_off WIDTHTRUNC */
	app_len_i = KEEP_W;
	/* verilator lint_on WIDTHTRUNC */
	app_cs_i = {UDP_CS_W{1'bx}};
endtask

task set_last_tx(int x, int l);
	$display("x %d %d %d %d",x,x%BLOCK_N,x/BLOCK_N,l/BLOCK_N);
	if( (x%BLOCK_N==0) & ((x/BLOCK_N) == (l/BLOCK_N)))begin
		app_last_block_next_i = 1'b1;
		/* verilator lint_off WIDTHTRUNC */
		app_last_block_next_len_i = l%BLOCK_N;
		/* verilator lint_on WIDTHTRUNC */
	end else begin
		app_last_block_next_i = 1'b0;
	end
endtask

task send_simple_tx_data(int l);
	
	/* send head */
	app_early_v_i = 1'b1;
	
	/* verilator lint_off WIDTHTRUNC */
	app_pkt_len_i = l;
	/* verilator lint_on WIDTHTRUNC */
	
	while( app_ready_v_o == 1'b0) begin
		/* wait for ready signal */
		#10;
		app_early_v_i = 1'b1;
	end 

	app_early_v_i = 1'b0;	

	for(int i=0; i<l/KEEP_W; i++)begin
		/* verilator lint_off WIDTHTRUNC */
		app_data_i = $random;
		app_len_i = KEEP_W;
		/* verilator lint_on WIDTHTRUNC */
		set_last_tx(i*KEEP_W,l);
		#10
		assert(~$isunknown(phy_data_o));
	end

	app_len_i = {KEEP_W{1'b0}};	
	app_data_i = {DATA_W{1'bx}};
	app_last_block_next_i = 1'b0;
	app_last_block_next_len_i = {BLOCK_LEN_W{1'bx}};
	app_len_i = 0;

	for(int i=0; i < l%KEEP_W; i++)begin
		$display("i %d l %d",i,l);
		app_len_i = app_len_i + 1;
		/* verilator lint_off WIDTHTRUNC */
		app_data_i[i*8+:8] = $random;
		/* verilator lint_on WIDTHTRUNC */
	end

	app_last_i = 1'b1;
	#10
	app_last_i = 1'b0;
endtask

initial begin
	$dumpfile("wave/eth_tb.vcd");
	$dumpvars(0, eth_tb);
	$tb_init();
	nreset = 1'b0;
	#10
	nreset = 1'b1;
	phy_cancel_i = 1'b0;
	mac_valid_i = 1'b0;
	/* generated tx header */
	set_tx_default();
	set_rx_idle();
	for(int i=0; i < `TB_LOOP_CNT; i++) begin 
		#10
		$tb_mac(mac_valid_i,
			phy_cancel_i,
			mac_data_i,
			mac_start_i,
			mac_term_i,
			mac_len_i);
	end
	#10
	$tb_free();	
	$display("Test finised");
	$finish;		
end

/* UUT RX */
eth_rx #(
	.IS_10G(IS_10G),
	.DATA_W(DATA_W)
)m_eth_rx(
	.clk(clk),
	.nreset(nreset),
	.phy_cancel_i(phy_cancel_i),
	.mac_valid_i(mac_valid_i),
	.mac_data_i(mac_data_i),
	.mac_start_i(mac_start_i),
	.mac_term_i(mac_term_i),
	.mac_len_i(mac_len_i),
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
	.app_early_v_i(app_early_v_i),
	.app_ready_v_o(app_ready_v_o),
	.app_cancel_i(app_cancel_i),
//	.app_valid_i(app_valid_i),
	.app_data_i(app_data_i),
	.app_len_i(app_len_i),
	.app_pkt_len_i(app_pkt_len_i),
	.app_cs_i(app_cs_i),

	.app_last_i(app_last_i),
	.app_last_block_next_i(app_last_block_next_i),
	.app_last_block_next_len_i(app_last_block_next_len_i),

	.phy_ready_i(phy_ready_i),	

	.phy_ctrl_v_o(phy_ctrl_v_o),
	.phy_data_o(phy_data_o),	
	.phy_start_o(phy_start_o),
	.phy_idle_o(phy_idle_o),
	.phy_term_o(phy_term_o),
	.phy_term_len_o(phy_term_len_o)
);

endmodule

`define TB_LOOP_CNT 10000

`ifdef INTERACTIVE
/* Adding extra 10 cycles for debuging after failure detection */
`define assert_stop( X ) \
if (~( X )) begin \
$display("ERROR : assert failed : time %t , line %0d",$time, `__LINE__); \
#10\
$stop; \
end 
`else
`define assert_stop( X ) \
	assert( X )
`endif


/* Top level tb for ethernet modules */
module eth_tb;

localparam IS_10G = 1;
localparam VLAN_TAG = 1;

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

localparam IP_ADDR_W = 32;
localparam MATCH_IP_SRC_ADDR = 1; 
localparam MATCH_IP_DST_ADDR = 1; 
//localparam [IP_ADDR_W-1:0] IP_SRC_ADDR = {8'd206, 8'd200, 8'd127, 8'd128};
localparam [IP_ADDR_W-1:0] IP_SRC_ADDR = 32'h1;
//localparam [IP_ADDR_W-1:0] IP_DST_ADDR = {8'd206, 8'd200, 8'd127, 8'd128};
localparam [IP_ADDR_W-1:0] IP_DST_ADDR = 32'h0;

/* TB */
localparam DEBUG_ID_W = 32;
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
logic                  app_start_o;
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

/* tb debug id */
logic [DEBUG_ID_W-1:0] pkt_debug_id_i;

/* tb expected values */
logic                  tb_exp_app_valid_o;
logic                  tb_exp_app_start_o;
logic [DATA_W-1:0]     tb_exp_app_data_o;
logic [LEN_W-1:0]      tb_exp_app_len_o;
logic [DEBUG_ID_W-1:0] tb_exp_app_debug_id_o;

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
		`assert_stop(~$isunknown(phy_data_o));
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

	`ifdef WAVE
	$dumpfile("wave/eth_tb.vcd");
	$dumpvars(0, eth_tb);
	`endif

	$tb_init();
	nreset = 1'b0;
	#10
	$display("Test start");
	nreset = 1'b1;
	phy_cancel_i = 1'b0;
	mac_valid_i = 1'b0;
	/* generated tx header */
	set_tx_default();
	set_rx_idle();
	for(int i=0; i < `TB_LOOP_CNT; i++) begin 
		#10
		/* add invalid cycles in the middle of valid packet, mimice behavior
         * when we do not have any cdc between phy and the rest of the stack.
         * Expect one invalid cycle every 32 cycles due to gearbox
         * replenishing. */
		if ( i % 33 == 0 )begin : invalid_cycle 
			mac_valid_i = 1'b0;
			phy_cancel_i = 1'b0;
			/* adding x's on data to help detect bugs where data is captured
 			 * when it should have been ignored using xprop */
			mac_data_i = {DATA_W{1'bx}};
			mac_start_i = {LANE0_CNT_N{1'bx}};
			mac_term_i = 1'bx;
			mac_len_i = {LEN_W{1'bx}};
		end else begin
			$tb_mac(
				mac_valid_i,
				phy_cancel_i,
				mac_data_i,
				mac_start_i,
				mac_term_i,
				mac_len_i,
				pkt_debug_id_i);
		end
	end
	#10
	$tb_free();	
	$display("Test finised");
	$finish;		
end

/* debug packet counter */
localparam TB_PKT_CNT_W = 16;

reg   [TB_PKT_CNT_W-1:0] tb_pkt_cnt_q;
logic [TB_PKT_CNT_W-1:0] tb_pkt_cnt_next;
logic [TB_PKT_CNT_W-1:0] tb_pkt_cnt_add;
logic tb_pkt_cnt_rst;

assign tb_pkt_cnt_rst = mac_valid_i & mac_start_i;
assign tb_pkt_cnt_add = tb_pkt_cnt_rst ? '0 : tb_pkt_cnt_q;
assign tb_pkt_cnt_next = tb_pkt_cnt_add + {{TB_PKT_CNT_W-LEN_W{1'b0}}, mac_len_i};
always @(posedge clk) begin
	if(mac_valid_i)begin
		tb_pkt_cnt_q <= tb_pkt_cnt_next;
	end
end

task check_term_data_match(
	logic [LEN_W-1:0] exp_len,
	logic [DATA_W-1:0] exp_data,
	logic [DATA_W-1:0] app_data);
	
	for(int i=0; i<exp_len; i++)begin
		`assert_stop(app_data[i*8+:8] == exp_data[i*8+:8]); 
	end
endtask

/* compare expected values */
always @(posedge clk) begin
	if(nreset & app_valid_o)begin
		/* get expected values from tb */
		$tb_trans(tb_exp_app_valid_o,
			tb_exp_app_start_o,
			tb_exp_app_len_o,
			tb_exp_app_data_o,
			tb_exp_app_debug_id_o);
		/* compare values */
		`assert_stop(tb_exp_app_valid_o == app_valid_o);
		`assert_stop(tb_exp_app_start_o == app_start_o);
		`assert_stop(tb_exp_app_len_o == app_len_o);
		check_term_data_match(tb_exp_app_len_o, tb_exp_app_data_o, app_data_o);
	end	
end


/* UUT RX */
eth_rx #(
	.IS_10G(IS_10G),
	.VLAN_TAG(VLAN_TAG),
	.DATA_W(DATA_W),
	.MATCH_IP_DST_ADDR(1),
	.MATCH_IP_SRC_ADDR(1),
	.IP_SRC_ADDR(IP_SRC_ADDR),
	.IP_DST_ADDR(IP_DST_ADDR)
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
	.app_start_o(app_start_o),
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

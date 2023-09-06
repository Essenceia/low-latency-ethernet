`define TB_DATA_CYCLES 3


module mac_tb;
localparam DATA_W = 16;
localparam KEEP_W = DATA_W/8;
localparam VLAN_TAG = 1;
localparam IS_10G = 1;
localparam LANE0_CNT_N = IS_10G & ( DATA_W == 64 )? 2 : 1;

localparam [7:0] START_CHAR = 8'haa;
localparam [15:0] VLAN_TYPE = 16'h8100;
localparam [15:0] IPV4_TYPE = 16'h8000;

localparam HEAD_LEN = 22 + ( VLAN_TAG ? 4 : 0 );
localparam TB_PKT_LEN = HEAD_LEN + KEEP_W*`TB_DATA_CYCLES;

reg   clk = 1'b0;
/* verilator lint_off BLKSEQ */
always clk = #5 ~clk; 
/* verilator lint_on BLKSEQ */

logic nreset;
logic                   cancel_i;
logic                   valid_i;
logic [DATA_W-1:0]      data_i;
logic                   ctrl_v_i;
logic                   idle_i;
logic [LANE0_CNT_N-1:0] start_i;
logic                   term_i;
logic [KEEP_W-1:0]      term_keep_i;
/* verilator lint_off UNUSEDSIGNAL */
logic                   cancel_o;
logic                   valid_o;
logic [DATA_W-1:0]      data_o;
logic [KEEP_W-1:0]      keep_o;
logic                   crc_err_o;
/* verilator lint_on UNUSEDSIGNAL */

function void set_default();
	cancel_i = 1'b0;
	valid_i = 1'b0;
	ctrl_v_i = 1'b0;
	idle_i = 1'b0;
	start_i = {LANE0_CNT_N{1'b0}};
	term_i = 1'b0;
	term_keep_i = {KEEP_W{1'b0}};	
	data_i = {DATA_W{1'b0}};
endfunction

task idle_cycle();
	valid_i = 1'b1;
	ctrl_v_i = 1'b1;
	idle_i = 1'b1;
	#10
	ctrl_v_i = 1'b0;
	idle_i = 1'b0;
endtask


function logic [HEAD_LEN*8-1:0] set_head();
	static logic [HEAD_LEN*8-1:0] head;
	/* preambule */
	static logic [63:0] pre = {56'hAAAAAAAAAAAAAA, 8'hAB};

	/* mac addr */
	// coca cola company
	static logic [6*8-1:0] dst_addr = {24'h0 ,24'hFCD4F2};
	// molex
	static logic [6*8-1:0] src_addr = {24'h0 ,24'hF82F08};
	

	/* type and vlan */
	static logic [15:0] h_type = IPV4_TYPE;

	if ( VLAN_TAG ) begin
		static logic [31:0] vlan_tag;
		static logic [2:0]  pcp;
		static logic        dei;
		static logic [11:0] vid;

		/* verilator lint_off WIDTHTRUNC */
		{ vid, dei, pcp } = $random; 
		/* verilator lint_on WIDTHTRUNC */

		vlan_tag = {vid, dei, pcp, VLAN_TYPE};
		head[HEAD_LEN*8-1-:8*6] = {h_type, vlan_tag};	
	end else begin
		head[HEAD_LEN*8-1-:16] = h_type;	
	end
	head[20*8-1:0] = {src_addr, dst_addr, pre};
	return head;
endfunction

/* Send simple random packet */
task send_packet(); 
	logic [TB_PKT_LEN*8-1:0] tmp; 
	tmp = {TB_PKT_LEN*8{1'bx}};
	
	/* head */
	tmp[HEAD_LEN*8-1:0] = set_head();

	/* set data packet content */
	for(int i=HEAD_LEN; i < TB_PKT_LEN; i++) begin
		if ( i == 0 ) begin
			tmp[i*8+:8] = START_CHAR;
		end else begin
			/* verilator lint_off WIDTHTRUNC */	
			tmp[i*8+:8] = $random;
			/* verilator lint_on WIDTHTRUNC */	
		end
	end
	set_default();
	valid_i = 1'b1;
	ctrl_v_i = 1'b1;
	start_i = 'b1;
	data_i = tmp[0+:DATA_W];
	for(int i=KEEP_W; i < TB_PKT_LEN/KEEP_W; i++) begin
		#10
		ctrl_v_i = 1'b0;
		data_i = tmp[i*DATA_W+:DATA_W];	
	end
	#10
	/* send term */
	data_i = {DATA_W{1'bX}};
	ctrl_v_i = 1'b1;
	term_i = 1'b1;
	start_i = '0;
	term_keep_i = {KEEP_W{1'b0}};
	#10
	ctrl_v_i = 1'b0;
	valid_i = 1'b0;	
endtask

initial begin
	$dumpfile("wave/mac_tb.vcd");
	$dumpvars(0, mac_tb);
	nreset = 1'b0;
	set_default();
	#10
	nreset = 1'b1;

	/* set idle cycle */
	idle_cycle();

	/* Test 1 */
	$display("test 1 %t",$time);
	send_packet();
	#10
	$display("Test finished %t",$time);
	$finish;
end


/* uut */
mac_rx#(
	.IS_10G(IS_10G),
	.VLAN_TAG(VLAN_TAG),
	.DATA_W(DATA_W),
	.KEEP_W(KEEP_W)
)m_mac_rx(
.clk(clk),
.nreset(nreset),
.cancel_i(cancel_i),
.valid_i(valid_i),
.data_i(data_i),
.ctrl_v_i(ctrl_v_i),
.idle_i(idle_i),
.start_i(start_i),
.term_i(term_i),
.term_keep_i(term_keep_i),
.cancel_o(cancel_o),
.valid_o(valid_o),
.data_o(data_o),
.keep_o(keep_o),
.crc_err_o(crc_err_o)
);
endmodule

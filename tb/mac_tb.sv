`define TB_PKT_LEN 3

module mac_tb;
localparam DATA_W = 16;
localparam KEEP_W = DATA_W/8;
localparam VLAN_TAG = 1;
localparam IS_10G = 1;
localparam LANE0_CNT_N = IS_10G & ( DATA_W == 64 )? 2 : 1;

localparam START_CHAR = 8'haa;

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
logic                   cancel_o;
logic                   valid_o;
logic [DATA_W-1:0]      data_o;
logic [KEEP_W-1:0]      keep_o;
logic                   crc_err_o;

function void set_default();
	cancel_i = 1'b0;
	valid_i = 1'b0;
	ctrl_v_i = 1'b0;
	idle_i = 1'b0;
	start_i = 2'b00;
	term_i = 1'b0;
	term_keep_i = {KEEP_W{1'b0}};	
	data_i = {DATA_W{1'b0}};
endfunction

/* Send simple random packet */
task send_packet(); 
	logic [`TB_PKT_LEN*DATA_W-1:0] tmp;
	for(int i=0; i < `TB_PKT_LEN*KEEP_W; i++) begin
		if ( i == 0 ) begin
			tmp[i] = START_CHAR;
		end else begin	
			tmp[i] = $random;
		end
	end
	set_default();
	valid_i = 1'b1;
	ctrl_v_i = 1'b1;
	start_i = 'b1;
	data_i = tmp[0+:DATA_W];
	for(int i=1; i < `TB_PKT_LEN; i++) begin
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

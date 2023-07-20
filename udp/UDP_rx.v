/* UDP rx module
*
* Features :
* No src/dst port check 
*/
module udp_rx #(
	parameter IP_DATA_W  = 32,
	parameter UDP_DATA_W = IP_DATA_W,
	parameter UDP_KEEP_W = $clog2(UDP_DATA_W),

	// ip configuration 
	parameter CHECK_CRC = 1
)
(
	input clk,
	input nreset,
	
	// ip payload
	input                 valid_i,
	input                 last_i,
	input [IP_DATA_W-1:0] data_i,
	
	// mac crc check failed
	input                   flush_i,

	// udp payload
	output                  valid_o,
	output                  last_o,
	output [UDP_DATA_W-1:0] data_o, 
	output [UDP_KEEP_W-1:0] keep_o	
);
localparam UDP_CRC_W = 16;

// crc
reg   [UDP_CRC_W-1:0] crc_q;
logic [UDP_CRC_W-1:0] crc_next;

// header arrives in 2 cycles
logic fsm_h0;
reg   fsm_h1_q;
logic fsm_h1_next;
reg   fsm_pload_q;
reg   fsm_pload_next;
reg   fsm_idle_q;
logic fsm_idle_next;

// crc

// output
assign valid_o = fsm_pload_q & valid_i;
assign last_o  = last_i;
assign data_o  = data_i;

// FSM
// assume a one cycle gap between 2 ip playloads
assign fsm_h0         = fsm_idle_q & valid_i;
assign fsm_pload_next = fsm_h1_q 
					  | fsm_pload_q & ~( valid_i & last_i );
assign fsm_idle_next  = valid_i & last_i 
					  | fsm_idle_q & ~valid_i;
always @(posedge clk) begin
	if ( ~nreset ) begin
		fsm_idle_q  <= 1'b1;
		fsm_h1_q    <= 1'b0;
		fsm_pload_q <= 1'b0;
		fsm_idle_q  <= 1'b0;
	end else begin
		fsm_idle_q  <= fsm_idle_next;  
		fsm_h1_q    <= fsm_h1_next;
		fsm_pload_q <= fsm_pload_next;
		fsm_idle_q  <= fsm_idle_next;
	end
end
`ifdef FORMAL
initial begin
	a_reset : assume ( ~nreset );
end 
always @(posedge clk) begin
	sva_fsm_onehot : assert ( $onehot( { fsm_h1_q, fsm_pload_q, fsm_idle_q } );	
	// xcheck
	sva_xcheck_valid_o : assert ( ~$isunknown( valid_o ));
	sva_xcheck_last_o  : assert ( ~valid_o | ( valid_o & ~$isunknown( last_o )));
	sva_xcheck_keep_o  : assert ( ~valid_o | ( valid_o & ~$isunknown( keep_o )));
	genvar i;
	generate
		for( i = 0; i < UDP_KEEP_W; i ++) begin
			assert ( ~( valid_o & keep_o[i]) | ( valid_o & keep_o[i] & ~$isunknown( data_o[i*8+7:i*8] )));
		end
	endgenerate
end
`endif
endmodule

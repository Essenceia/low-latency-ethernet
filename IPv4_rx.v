/* IPv4 RX module */

module IPv4_rx #(
	parameter MAC 
	parameter TYPE = 17, // 17 : UDP, 6 : TCP 
	parameter FRAG = 0  // Support fragmentation
)(
	input clk,
	input nreset,

	input llc_v	

);

endmodule

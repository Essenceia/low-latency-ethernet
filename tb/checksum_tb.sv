/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 * 
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License. 
 * 
 * This code is provided "as is" without any express or implied warranties. */

module udp_checksum_tb #(
	parameter SUM_W  = 16,
	parameter DATA_W = 32
)
();
localparam N = DATA_W/SUM_W;
localparam C_W = $clog2(N);
localparam L_W = C_W + SUM_W;

task test_checksum(input exp_err_v, input integer cycles); 
	// generate new test values 
	logic [DATA_W-1:0] data;
	logic [SUM_W-1:0]  sum;
	logic [L_W-1:0] tmp;
	logic [C_W:0]   carry;
	for( int c = 0; c < cycles; c++) begin
		data = $random; // random also generates 32 bits, will need to update if I go to 64 
		tmp = sum;
		for( int i = 0; i < N; i ++ ) begin
			tmp += data[i*SUM_W+SUM_W-1:i*SUM_W];
		end
		carry = tmp[L_W-1:SUM_W];
		tmp = tmp[SUM_W-1:0] + carry;
		sum = ~tmp;	
	end
endtask;

endmodule

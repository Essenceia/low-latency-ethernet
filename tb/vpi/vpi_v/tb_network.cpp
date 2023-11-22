/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 * 
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License. 
 * 
 * This code is provided "as is" without any express or implied warranties. */ 
#include "tb_network.hpp"
#include "verilated.h"
#include "verilated_vpi.h"  // Required to get definitions

#if VM_TRACE
# include <verilated_vcd_c.h>	// Trace file format header
#endif

uint64_t main_time = 0;   // See comments in first example
double sc_time_stamp() { return main_time; }


int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);


	const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
    const std::unique_ptr<VMODULE> top{new VMODULE{contextp.get()}};

	#if VM_TRACE // makefile wave invoked with wave=1 
    Verilated::traceEverOn(true);// computer trace signals
    VL_PRINTF("Enabling waves...\n");
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace (tfp, 5);// trace 5 levels of hierachy
    tfp->open ("wave/"STR(MODULE)".vcd");	// Open the dump file
	#endif


    //contextp->internalsDump();  // See scopes to help debug

	// vpiHandlers
	//vpiHandle h_head_i = vpi_handle_by_name((PLI_BYTE8*)"TOP.am_tx_tb.head_i", NULL);

	/* reset sequence
	* Hold reset for 1 clk cycle -> 10 C cycles */
	for(; main_time<10; main_time++){
		top->eval();
		#if VM_TRACE
		if (tfp) tfp->dump (main_time);	// Create waveform trace for this timestamp
		#endif
	}
    while (!contextp->gotFinish()) {
        top->eval();
        VerilatedVpi::callValueCbs();  // For signal callbacks
		if ( main_time % 10 == 0 ){
			/* TODO : add code */
		}
		#if VM_TRACE
		if (tfp) tfp->dump (main_time);	// Create waveform trace for this timestamp
		#endif

		main_time++;
    }


	#if VM_TRACE
    if (tfp) tfp->close();
	#endif

    return 0;
}

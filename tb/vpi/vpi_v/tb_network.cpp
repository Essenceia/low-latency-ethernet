/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 * 
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License. 
 * 
 * This code is provided "as is" without any express or implied warranties. */ 
#include "tb_network.hpp"
#include "verilated.h"
#include "verilated_vpi.h"  // Required to get definitions
extern "C"{
#include "../tb.h"
#include "../inc/tb_all.h"
}
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
    top->trace (tfp, 15);// trace 15 levels of hierachy
    tfp->open ("wave/"STR(MODULE)".vcd");	// Open the dump file
	#endif

	/* init tb */
	init_tb();

    //contextp->internalsDump();  // See scopes to help debug

	/* get signals handlers 
 	 * mac interface */
	vpiHandle h_mac_valid_i = vpi_handle_by_name((PLI_BYTE8*)"TOP."STR(MODULE)".mac_valid_i", NULL);
	vpiHandle h_mac_data_i  = vpi_handle_by_name((PLI_BYTE8*)"TOP."STR(MODULE)".mac_data_i", NULL);
	vpiHandle h_mac_start_i = vpi_handle_by_name((PLI_BYTE8*)"TOP."STR(MODULE)".mac_start_i", NULL);
	vpiHandle h_mac_term_i  = vpi_handle_by_name((PLI_BYTE8*)"TOP."STR(MODULE)".mac_term_i", NULL);
	vpiHandle h_mac_len_i   = vpi_handle_by_name((PLI_BYTE8*)"TOP."STR(MODULE)".mac_len_i", NULL);
	vpiHandle h_mac_pkt_debug_id_i = vpi_handle_by_name((PLI_BYTE8*)"TOP."STR(MODULE)".pkt_debug_id_i", NULL);
	vpiHandle h_phy_cancel_i       = vpi_handle_by_name((PLI_BYTE8*)"TOP."STR(MODULE)".phy_cancel_i", NULL);

	/* upd output */
	vpiHandle h_app_valid_o = vpi_handle_by_name((PLI_BYTE8*)"TOP."STR(MODULE)".app_valid_o", NULL);
	s_vpi_value app_valid;
	app_valid.format = vpiIntVal;
	
	/* expected udp output interface */
	vpiHandle h_exp_app_valid_o = vpi_handle_by_name((PLI_BYTE8*)"TOP."STR(MODULE)".tb_exp_app_valid_o", NULL);
	vpiHandle h_exp_app_start_o = vpi_handle_by_name((PLI_BYTE8*)"TOP."STR(MODULE)".tb_exp_app_start_o", NULL);
	vpiHandle h_exp_app_len_o   = vpi_handle_by_name((PLI_BYTE8*)"TOP."STR(MODULE)".tb_exp_app_len_o", NULL);
	vpiHandle h_exp_app_data_o  = vpi_handle_by_name((PLI_BYTE8*)"TOP."STR(MODULE)".tb_exp_app_data_o", NULL);
	vpiHandle h_exp_app_debug_id_o  = vpi_handle_by_name((PLI_BYTE8*)"TOP."STR(MODULE)".tb_exp_app_debug_id_o", NULL);

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
			if ((main_time/10) % 33 == 0){
				/* drive invalid mac interface one cycle every 32 cycles */
				vpi_put_logic_1b_t(h_mac_valid_i, 0);
				vpi_put_logic_1b_t(h_phy_cancel_i,0);	
			}else{
				/* drive mac interface */
				tb_mac_rx(
					h_mac_valid_i, 
					h_phy_cancel_i,
					h_mac_data_i,
					h_mac_start_i, 
					h_mac_term_i,
					h_mac_len_i,
					h_mac_pkt_debug_id_i);
			}

		}
		if (main_time % 10 == 1){
			/* check if transport layer is driving signal */
			vpi_get_value(h_app_valid_o, &app_valid);
			if(app_valid){
				/* app valid: drive new expected value */
				tb_udp_data_rx(
					h_exp_app_valid_o,
					h_exp_app_data_o,
					h_exp_app_len_o,
					h_exp_app_start_o,
					h_exp_app_debug_id_o);
			}
		}

		#if VM_TRACE
		if (tfp) tfp->dump (main_time);	// Create waveform trace for this timestamp
		#endif

		main_time++;
    }


	#if VM_TRACE
    if (tfp) tfp->close();
	#endif

	// free
	vpi_release_handle(h_mac_valid_i);
	vpi_release_handle(h_mac_data_i);
	vpi_release_handle(h_mac_start_i);
	vpi_release_handle(h_mac_term_i);
	vpi_release_handle(h_mac_len_i);
	vpi_release_handle(h_mac_pkt_debug_id_i);
	vpi_release_handle(h_phy_cancel_i);
	vpi_release_handle(h_app_valid_o);
	vpi_release_handle(h_exp_app_valid_o);
	vpi_release_handle(h_exp_app_start_o);
	vpi_release_handle(h_exp_app_len_o);
	vpi_release_handle(h_exp_app_data_o);
	vpi_release_handle(h_exp_app_debug_id_o);

	free_tb();

	top->final();
    return 0;
}

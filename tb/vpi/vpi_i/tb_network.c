/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 * 
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License. 
 * 
 * This code is provided "as is" without any express or implied warranties. */ 

/* Iverilog specific vpi wrapping */

#include "tb_network.h"
#include "../tb.h"
#include "../inc/tb_all.h"

/* compliletf
 * current unused */
static int tb_init_compiletf(char*user_data)
{
    return 0;
}
static int tb_free_compiletf(char*user_data)
{
    return 0;
}
static int tb_mac_compiletf(char*user_data)
{
    return 0;
}
static int tb_trans_compiletf(char*user_data)
{
    return 0;
}

/* init */
static int tb_init_calltf(char*user_data)
{
	info("$tb_init called\n");
	init_tb();
	return 0;
}


static int tb_mac_calltf(char*user_data)
{
	info("$tb_mac called\n");
	
	vpiHandle sys = vpi_handle(vpiSysTfCall, 0);
	assert(sys);
	vpiHandle argv = vpi_iterate(vpiArgument, sys);
	assert(argv);

	// handlers : the order matters
	vpiHandle h_valid_i = vpi_scan(argv);
	assert(h_valid_i);
	vpiHandle h_cancel_i = vpi_scan(argv);
	assert(h_cancel_i);
	vpiHandle h_ctrl_i = vpi_scan(argv);
	assert(h_ctrl_i);
	vpiHandle h_idle_i = vpi_scan(argv);
	assert(h_idle_i);
	vpiHandle h_data_i = vpi_scan(argv);
	assert(h_data_i);
	vpiHandle h_start_i = vpi_scan(argv);
	assert(h_start_i);
	vpiHandle h_term_i = vpi_scan(argv);
	assert(h_term_i);
	vpiHandle h_len_i = vpi_scan(argv);
	assert(h_len_i);

	/* drive mac rx signals */
	tb_mac_rx(h_valid_i, 
		h_cancel_i,
		h_ctrl_i,
		h_idle_i,
		h_data_i,
		h_start_i, 
		h_term_i,
		h_len_i);

	return 0;
}

static int tb_trans_calltf(char*user_data)
{
	/* TODO network handler */
	info("$tb_trans called\n");
	return 0;
}

/* free */
static int tb_free_calltf(char*user_data)
{
	info("$tb_free called\n");
	free_tb();
	return 0;
}

/* Async call through verilator vpi isn't possible, only
 * for iverilog as of writting
 *
 * init */
void tb_init_register()
{
      s_vpi_systf_data tf_data;

      tf_data.type      = vpiSysTask;
      tf_data.sysfunctype  = 0;
      tf_data.tfname    = "$tb_init";
      tf_data.calltf    = tb_init_calltf;
      tf_data.compiletf = tb_init_compiletf;
      tf_data.sizetf    = 0;
      tf_data.user_data = 0;
      vpi_register_systf(&tf_data);
}
/* main loop */
void tb_mac_register()
{
      s_vpi_systf_data tf_data;

      tf_data.type      = vpiSysTask;
      tf_data.sysfunctype  = 0;
      tf_data.tfname    = "$tb_mac";
      tf_data.calltf    = tb_mac_calltf;
      tf_data.compiletf = tb_mac_compiletf;
      tf_data.sizetf    = 0;
      tf_data.user_data = 0;
      vpi_register_systf(&tf_data);
}
void tb_trans_register()
{
      s_vpi_systf_data tf_data;

      tf_data.type      = vpiSysTask;
      tf_data.sysfunctype  = 0;
      tf_data.tfname    = "$tb_trans";
      tf_data.calltf    = tb_trans_calltf;
      tf_data.compiletf = tb_trans_compiletf;
      tf_data.sizetf    = 0;
      tf_data.user_data = 0;
      vpi_register_systf(&tf_data);
}/* close */
void tb_free_register()
{
      s_vpi_systf_data tf_data;

      tf_data.type      = vpiSysTask;
      tf_data.sysfunctype  = 0;
      tf_data.tfname    = "$tb_free";
      tf_data.calltf    = tb_free_calltf;
      tf_data.compiletf = tb_free_compiletf;
      tf_data.sizetf    = 0;
      tf_data.user_data = 0;
      vpi_register_systf(&tf_data);
}


void (*vlog_startup_routines[])() = {
    tb_init_register,
    tb_mac_register,
    tb_trans_register,
    tb_free_register,
    0
};



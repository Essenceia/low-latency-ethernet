/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 * 
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License. 
 * 
 * This code is provided "as is" without any express or implied warranties. */ 

/* Iverilog specific vpi wrapping */

#include "tb_network.h"
#include <assert.h>

static int tb_network_compiletf(char*user_data)
{
    return 0;
}

// Drive PCS marker aligment input values
static int tb_network_calltf(char*user_data)
{
	/* TODO network handler */
	return 0;
}

/* Async call through verilator vpi isn't possible, only
 * for iverilog as of writting */ 
void tb_network_register()
{
      s_vpi_systf_data tf_data;

      tf_data.type      = vpiSysTask;
      tf_data.sysfunctype  = 0;
      tf_data.tfname    = "$tb_network";
      tf_data.calltf    = tb_network_calltf;
      tf_data.compiletf = tb_network_compiletf;
      tf_data.sizetf    = 0;
      tf_data.user_data = 0;
      vpi_register_systf(&tf_data);
}

void (*vlog_startup_routines[])() = {
    tb_network_register,
    0
};



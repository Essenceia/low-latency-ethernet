#ifndef TB_H
#define TB_H

#include "vpi_utils.h"

void init_tb();

void free_tb();

/* mac interface 
 * drive values on mac rx interface */
void tb_mac_rx(	
	vpiHandle h_valid_i,
	vpiHandle h_cancel_i,
	vpiHandle h_data_i,
	vpiHandle h_start_i,
	vpiHandle h_term_v_i,
	vpiHandle h_len_i);

#endif // TB_H

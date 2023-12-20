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
	vpiHandle h_len_i,
	vpiHandle h_debug_id_i);

/* udp data output interfave
 * dirve expected output on the rx udp to 
 * application layer interface */
void tb_udp_data_rx(
	vpiHandle h_valid_o,
	vpiHandle h_data_o,
	vpiHandle h_len_o,
	vpiHandle h_start_o,
	vpiHandle h_debug_id_o
);
#endif // TB_H

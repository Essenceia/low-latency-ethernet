#include "tb.h"

static tv_s *tv;

void init_tb(){
	tv = init_tv();
	/* generate first packet */
	gen_new_pkt(tv, 0);
}

void free_tb(){
	free_tv(tv);
}
void tb_mac_rx(	
	vpiHandle h_valid_i,
	vpiHandle h_cancel_i,
	vpiHandle h_ctrl_i,
	vpiHandle h_idle_i,
	vpiHandle h_data_i,
	vpiHandle h_start_i,
	vpiHandle h_term_i,
	vpiHandle h_len_i
){
	mac_intf_s *mac;	
	/* check if we have a mac interface
     * fifo entry to deque 
     * if not generate a new packet sent by 
     * a random network node */ 
	READ_MAC_FIFO:
	mac = mac_intf_s_fifo_read(tv->mac_fifo);
	if (!mac){
		gen_new_pkt(tv, tb_rand_uint16_t() % NODE_CNT);
		goto READ_MAC_FIFO
	}
	/* translate content of mac struct to 
 	 * vpi signal handlers */
	vpi_put_logic_1b_t(h_valid_i, mac->valid);	
	vpi_put_logic_1b_t(h_cancel_i, mac->cancel);	
	vpi_put_logic_1b_t(h_ctrl_i, mac->ctrl);	
	vpi_put_logic_1b_t(h_idle_i, mac->idle);
	/* call correct put function depending on the DATA_WIDTH */	
	CAT3(vpi_put_logic_,DATA_WIDTH,b_t(h_data_i, mac->data));
	vpi_put_logic_8b_t(h_start_i, get_mac_start(mac));
	vpi_put_logic_1b_t(h_term_i, mac->term);
	vpi_put_logic_8b_t(h_len_i, mac->len);
	free(mac);
}

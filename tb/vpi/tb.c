#include "tb.h"
#include "tv.h"
#include "tb_rand.h"

static tv_s *tv = NULL;

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
	vpiHandle h_data_i,
	vpiHandle h_start_i,
	vpiHandle h_term_i,
	vpiHandle h_len_i
){
	assert(tv);
	mac_intf_s *mac;	
	/* check if we have a mac interface
     * fifo entry to deque 
     * if not generate a new packet sent by 
     * a random network node */ 
	READ_MAC_FIFO:
	mac = mac_intf_s_fifo_read(tv->mac_fifo);
	if (!mac){
		gen_new_pkt(tv, tb_rand_uint16_t() % NODE_CNT);
		goto READ_MAC_FIFO;
	}
	assert(mac);
	/* translate content of mac struct to 
 	 * vpi signal handlers */
	vpi_put_logic_1b_t(h_valid_i, mac->valid);	
	vpi_put_logic_1b_t(h_cancel_i, mac->cancel);	
	/* call correct put function depending on the DATA_WIDTH */	
	CAT3(vpi_put_logic_uint,DATA_WIDTH,_t(h_data_i, mac->data));
	vpi_put_logic_uint8_t(h_start_i, get_mac_start(mac));
	vpi_put_logic_1b_t(h_term_i, mac->term);
	vpi_put_logic_uint8_t(h_len_i, mac->len);
	
	/* delete first element of the fifo */
	mac_intf_s_fifo_del(tv->mac_fifo);
}

void tb_udp_data_rx(
	vpiHandle h_valid_o,
	vpiHandle h_data_o,
	vpiHandle h_len_o,
	vpiHandle h_start_o
){
	assert(tv);
	trans_data_s *udp_data;
	bool start = false;
	bool valid = false;
	uint8_t len = 0;
	data_t data = 0;
	udp_data = trans_data_s_fifo_read(tv->data_fifo);
	if(udp_data){
		valid = udp_data->state != TRANS_DATA_INVALID;
		start = udp_data->state == TRANS_DATA_START;	
		data = udp_data->data;
		len = udp_data->len;
		/* delete fifo element */
		trans_data_s_fifo_del(tv->data_fifo);
	}else{
		/* missing fifo entry, set data as invalid */
		info("ERROR: Empty fifo, no entry for upd data rx expected value\n");	
	}
	/* set tb signals via vpi interface
     * write default values with valid == 0 if no fifo entry poped */
	vpi_put_logic_1b_t(h_valid_o, valid);
	CAT3(vpi_put_logic_uint,DATA_WIDTH,_t(h_data_o, data));
	vpi_put_logic_uint8_t(h_len_o, len);
	vpi_put_logic_1b_t(h_start_o, start);
	
}

#ifndef TV_H
#define TV_H
#include "inc/eth.h"
#include "mac_intf.h"
#include "trans_data.h"

/* Common test vector interface */
typedef struct{
	eth_packet_s *eth[NODE_CNT];// packet generator, sender nodes 

	/* mac rx interface */
	mac_intf_s_fifo *mac_fifo;

	/* output of transport data */
	trans_data_s_fifo *data_fifo;

	/* next debug id */
	debug_id_t pkt_id;
}tv_s;

/* init tv */
tv_s* init_tv();

/* generate new packet */
void gen_new_pkt(tv_s *tv, size_t node_id);

/* get next data on input interface */
mac_intf_s *get_next_mac_intf(tv_s* tv);

void free_tv(tv_s* tv_ptr);

/* segment packet
 * get next packet segment whose size depends on the hw system data width, 
 * derements len */
data_t get_nxt_pkt_seg(
	uint8_t *pkt,
	size_t *pos,
	uint8_t *seg_len, 
	const size_t len);

#endif // TV_H

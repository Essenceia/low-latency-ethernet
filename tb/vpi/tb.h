#ifndef TB_H
#define TB_H
#include "inc/eth.h"
#include "mac_intf.h"
#include "trans_data.h"

/* Common tb interface */
typedef struct{
	eth_packet_s *eth[NODE_CNT];// packet generator, sender nodes 

	/* mac rx interface */
	mac_intf_s_fifo *mac_fifo;

	/* output of transport data */
	trans_data_s_fifo *data_fifo;
}tb_s;

/* init tb */
tb_s* init_tb();

/* generate new packet */
void gen_new_pkt(tb_s *tb, size_t node_id);

/* get next data on input interface */
mac_intf_s *get_next_mac_intf(tb_s* tb);

void free_tb(tb_s* tb_ptr);

/* segment packet
 * get next packet segment whose size depends on the hw system data width, 
 * derements len */
data_t get_nxt_pkt_seg(
	uint8_t *pkt,
	size_t *pos,
	uint8_t *seg_len, 
	const size_t len);

#endif // TB_H

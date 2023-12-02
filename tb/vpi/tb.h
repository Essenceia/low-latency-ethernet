#ifndef TB_H
#define TB_H
#include "mac_intf.h"

#define NODE_CNT 5

/* Common tb interface */
typedef struct{
	eth_packet_s *eth;// packet generator, sender nodes 

	/* mac rx interface */
	mac_intf_fifo *mac_fifo;

	/* output of transport data */
	trans_data_fifo *data_fifo;
}tb_s;

/* init tb */
tb_s* init_tb();

/* generate new packet */
void gen_new_pkt(tb_s *tb, size_t node_id);

/* get next data on input interface */
mac_intf_s *get_next_mac_intf(tb_s* tb);

void free_tb(tb_s* tb_ptr);

#endif // TB_H

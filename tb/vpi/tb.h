#ifndef TB_H
#define TB_H

#define NODE_CNT 5

/* Common tb interface */
typedef struct{
	eth_packet_s *node[NODE_CNT];// packet generator, sender nodes 
}tb_s;

/* init tb */
tb_s* init_tb();

/* generate new packet */
void gen_new_pkt(tb_s *tb);

void free_tb(tb_s* tb_ptr);

#endif // TB_H

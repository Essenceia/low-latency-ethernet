#include "tb.h"
#include "eth.h"
#include "dump.h"
#include "defs.h"

#define RAND_MAC { \ 
	tb_rand_uint8_t(),tb_rand_uint8_t(),\
	tb_rand_uint8_t(),tb_rand_uint8_t(),\
	tb_rand_uint8_t(),tb_rand_uint8_t() }

static tb_s* tb_p = NULL;

/* init function */
tb_s* init_tb(){
	/* init tb struct */
	tb_p = malloc(sizeof(tb_s));
	tb_p->eth[0] = init_eth_packet(
			DEFAULT_DST_MAC,
			DEFAULT_SRC_MAC,
			DEFAULT_SRC_IP,
			DEFAULT_DST_IP,
			DEFAULT_SRC_PORT,
			DEFAULT_DST_PORT,
			DEFAULT_HAS_VLAN);	
	for(int i=0; i<NODE_CNT; i++){
		tb_p->eth[i] = init_eth_packet(
			RAND_MAC,
			RAND_MAC,
			tb_rand_uint64_t(),
			tb_rand_uint64_t(),
			tb_rand_uint32_t(),
			tb_rand_uint32_t(),
			tb_rand_uint8_t()%2);	
	}
 
}

void gen_new_pkt(tb_s *tb){

}


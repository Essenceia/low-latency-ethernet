#include "tb.h"
#include "inc/dump.h"
#include "inc/eth_defs.h"
#include "tb_rand.h"
#include "inc/dump.h"

#define RAND_MAC { \ 
	tb_rand_uint8_t(),tb_rand_uint8_t(),\
	tb_rand_uint8_t(),tb_rand_uint8_t(),\
	tb_rand_uint8_t(),tb_rand_uint8_t() }

/* init function */
tb_s* init_tb(){
	/* init tb struct */
	tb_s *tb_p = malloc(sizeof(tb_s*));
	tb_p->eth[0] = init_eth_packet(
			DEFAULT_DST_MAC,
			DEFAULT_SRC_MAC,
			DEFAULT_SRC_IP,
			DEFAULT_DST_IP,
			DEFAULT_SRC_PORT,
			DEFAULT_DST_PORT,
			DEFAULT_HAS_VLAN);	
	for(int i=0; i<NODE_CNT; i++){
		uint8_t *mac_dst = tb_rand_uint48_t();
		uint8_t *mac_src = tb_rand_uint48_t();
		tb_p->eth[i] = init_eth_packet(
			mac_dst,
			mac_src,
			tb_rand_uint32_t(),
			tb_rand_uint32_t(),
			tb_rand_uint16_t(),
			tb_rand_uint16_t(),
			tb_rand_uint8_t()%2);	
		free(mac_dst);
		free(mac_src);
	}
	/* fifo */
	tb_p->mac_fifo = mac_intf_s_fifo_ctor();
	tb_p->data_fifo = trans_data_s_fifo_ctor();

	return tb_p; 
}

void gen_new_pkt(
	tb_s *tb,
	size_t node_id	
){

	size_t len;
	assert(node_id <= NODE_CNT);

	/* create new rand packet, fill transport data*/
	len = tb_rand_get_packet_len();
	uint8_t *data = malloc(sizeof(uint8_t)*len);
	tb_rand_fill_packet(data, len);

	/* update node packet content */
	update_eth_packet_data(
		tb->eth[node_id],
		data,
		len);

	/* generate new packet */
	uint8_t *pkt_data = write_eth_packet(
			tb->eth[node_id],
			 &len);

	#ifdef WIRESHARK
	/* dump to wireshark */
	dump_eth_packet(
		pkt_data,
		len,
		true);
	#endif

	free(data);
	free(pkt_data);

}

void free_tb(tb_s *tb){

	for(int i=0; i<NODE_CNT; i++){
		assert(tb->eth[i]);
		free_eth_packet(tb->eth[i]);
	}
	/* delete fifo's */
	assert(tb->mac_fifo);
	mac_intf_s_fifo_dtor(tb->mac_fifo);
	assert(tb->data_fifo);
	trans_data_s_fifo_dtor(tb->data_fifo);
	
	#ifdef WIRESHARK
	close_dump();
	#endif	

};

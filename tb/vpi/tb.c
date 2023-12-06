#include "tb.h"
#include "inc/dump.h"
#include "inc/eth_defs.h"
#include "tb_rand.h"
#include "inc/dump.h"

#define RAND_MAC {\ 
	tb_rand_uint8_t(),tb_rand_uint8_t(),\
	tb_rand_uint8_t(),tb_rand_uint8_t(),\
	tb_rand_uint8_t(),tb_rand_uint8_t() }

/* init function */
tb_s* init_tb(){
	/* init tb struct */
	tb_s *tb_p = malloc(sizeof(tb_s));
	tb_p->eth[0] = init_eth_packet(
			DEFAULT_DST_MAC,
			DEFAULT_SRC_MAC,
			DEFAULT_SRC_IP,
			DEFAULT_DST_IP,
			DEFAULT_SRC_PORT,
			DEFAULT_DST_PORT,
			DEFAULT_HAS_VLAN);	
	for(int i=1; i<NODE_CNT; i++){
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

	
	/* segment packet */
	size_t pos = 0;
	uint8_t seg_len;
	/* start */
	data_t seg = get_nxt_pkt_seg(
		pkt_data,
		&pos,
		&seg_len,
		len);
	
	// TODO allow randomly starting on start 2 if supported
	mac_intf_s_fifo_push(tb->mac_fifo,
		init_mac_intf(
			MAC_START,
			seg,
			DATA_WIDTH_BYTE));
	
	info("pos/len %d/%d\n", pos+DATA_WIDTH_BYTE , len);		
	/* send data until term */
	while(pos+DATA_WIDTH_BYTE > len){
		info("pos/len %d/%d\n", pos, len);
	
		seg = get_nxt_pkt_seg(
		pkt_data,
		&pos,
		&seg_len,
		len);
	
		mac_intf_s_fifo_push(
			tb->mac_fifo,
			init_mac_intf(
				MAC_DATA,
				seg,
				seg_len));
			
	}
	info("last packet\n");

	/* term */
	seg = get_nxt_pkt_seg(
		pkt_data,
		&pos,
		&seg_len,
		len);
	mac_intf_s_fifo_push(tb->mac_fifo,
		init_mac_intf(
			get_mac_term(seg_len),
			seg,
			seg_len));
	/* append idle cycles if the last valid transfer wasn't on the
 	 * same cycle as the end of the PHY block
 	 * eg : 
 	 * 	X - valid byte
 	 * 	_ - invalid byte
 	 * let DATA_WIDTH_BYTE = 2, and the PHY block 8
 	 * mac interface values over time for data_len % 8 == 3 :
 	 * | XX
 	 * | X_
 	 * | __ inserted idle interface transaction 1
 	 * | __ inserted idle interface transaction 2
 	 * v t 	
 	 *
	 * mac interface values over time for data_len % 8 == 7 :
 	 * | XX
 	 * | XX
 	 * | XX
 	 * | X_
 	 * v t 	
 	 * there is no need to insert an idle cycle in this case.
 	 */
	int idle_cnt = (8 - ((int)pos)%8)/DATA_WIDTH_BYTE;
	while(idle_cnt>0){
		mac_intf_s_fifo_push(
			tb->mac_fifo,
			init_mac_intf(
				MAC_IDLE,
				0,
				0));
		idle_cnt -= DATA_WIDTH_BYTE;
	}
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

data_t get_nxt_pkt_seg(
	uint8_t *pkt, 
	size_t *pos,
	uint8_t *seg_len,
	const size_t len
){
	assert(pkt);
	assert(pos);
	assert(len);
	assert(*pos < len);
	data_t seg = 0;
	*seg_len = 0;
	size_t i;
	for(i = 0; (i < DATA_WIDTH_BYTE) && (*pos+i < len); i++){
		seg |= (data_t)pkt[*pos+i] << i*8;
	}
	*seg_len =(uint8_t) i;
	*pos += i;

	#ifdef DEBUG
	printf("pos %d\n",*pos);
	#endif

	return seg;
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

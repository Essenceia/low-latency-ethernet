#include "tv.h"
#include "inc/dump.h"
#include "inc/eth_defs.h"
#include "tb_rand.h"
#include "inc/dump.h"

#define RAND_MAC {\
	tb_rand_uint8_t(),tb_rand_uint8_t(),\
	tb_rand_uint8_t(),tb_rand_uint8_t(),\
	tb_rand_uint8_t(),tb_rand_uint8_t() }

/* overwrite state on error */
#define SET_STATE(s, p,err_v, err_p, err_s) ({ \
	const bool __set_state_cdt = err_v && ((err_p==p) || ((err_p < p+DATA_WIDTH_BYTE) && (err_p > p))); \
	const typeof(s) __set_state_val = __set_state_cdt ? err_s : s; \
	__set_state_val; \
})

/* init function */
tv_s* init_tv(){
	/* init tv struct */
	tv_s *tv_p = malloc(sizeof(tv_s));

	/* should have at least 2 nodes to support default
 	 * packet parameters with and without vlan */ 
	assert(NODE_CNT>=2);

	/* storing mac array to r value, risk hitting g++
 	 * internal compiler error on version 13.2.1 
 	 * otherwise */
	uint8_t default_dst_mac[6] = DEFAULT_DST_MAC;
	uint8_t default_src_mac[6] = DEFAULT_SRC_MAC;
	
	tv_p->eth[0] = init_eth_packet(
			default_dst_mac,
			default_src_mac,
			DEFAULT_SRC_IP,
			DEFAULT_DST_IP,
			DEFAULT_SRC_PORT,
			DEFAULT_DST_PORT,
			DEFAULT_HAS_VLAN);	
	tv_p->eth[1] = init_eth_packet(
			default_dst_mac,
			default_src_mac,
			DEFAULT_SRC_IP,
			DEFAULT_DST_IP,
			DEFAULT_SRC_PORT,
			DEFAULT_DST_PORT,
			!DEFAULT_HAS_VLAN);	
	
	for(int i=2; i<NODE_CNT; i++){
		uint8_t *mac_dst = tb_rand_uint48_t();
		uint8_t *mac_src = tb_rand_uint48_t();
		tv_p->eth[i] = init_eth_packet(
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
	tv_p->mac_fifo = mac_intf_s_fifo_ctor();
	tv_p->data_fifo = trans_data_s_fifo_ctor();

	/* pkt debug id */
	tv_p->pkt_id = 0;

	return tv_p; 
}

void gen_new_pkt(
	tv_s *tv,
	size_t node_id	
){

	assert(node_id <= NODE_CNT);

	/* increment pkt debug id, count sounds start at 1 to match
 	 * wireshark pkt cnt */
	tv->pkt_id += 1;

	/* create new rand packet, fill transport data*/
	size_t data_len = tb_rand_get_packet_len();
	uint8_t *data = malloc(sizeof(uint8_t)*data_len);
	tb_rand_fill_packet(data, data_len);

	/* update node packet content */
	update_eth_packet_data(
		tv->eth[node_id],
		data,
		data_len);

	#ifdef DEBUG
	info("node id %ld\n", node_id);
	print_eth_packet(tv->eth[node_id]);
	#endif

	/* generate new packet */
	size_t pkt_len;
	uint8_t *pkt_data = write_eth_packet(
			tv->eth[node_id],
			 &pkt_len);

	/* randomly inject a phy layer error */
	bool phy_err = (tb_rand_uint8_t() % PHY_ERR_RATE) == 0; 
	size_t err_pos = tb_rand_uint16_t() % pkt_len;

	/* mac interface	
	 * segment packet */
	size_t pos = 0;
	uint8_t seg_len;
	/* start */
	mac_intf_e mac_state = SET_STATE(MAC_START, pos, phy_err, err_pos, MAC_ERROR); 
	data_t seg = get_nxt_pkt_seg(pkt_data, &pos, &seg_len, pkt_len);
	
	// TODO allow randomly starting on start 2 if supported
	mac_intf_s *mac = init_mac_intf(mac_state,seg,DATA_WIDTH_BYTE, tv->pkt_id); 
	mac_intf_s_fifo_push(tv->mac_fifo,mac);

	#ifdef DEBUG_POS	
	info("pos/pkt_len %ld/%ld\n", pos+DATA_WIDTH_BYTE , pkt_len);		
	#endif

	/* send data until term */
	while(pos+DATA_WIDTH_BYTE < pkt_len){
		#ifdef DEBUG_POS
		info("pos/pkt_len %ld/%ld\n", pos, pkt_len);
		#endif

		mac_state = SET_STATE(MAC_DATA, pos, phy_err, err_pos, MAC_ERROR); 
		seg = get_nxt_pkt_seg(pkt_data,	&pos, &seg_len,	pkt_len);
		fill_mac_intf(mac, mac_state, seg, seg_len, tv->pkt_id);	
		mac_intf_s_fifo_push(tv->mac_fifo,mac);
			
	}
	#ifdef DEBUG_POS
	info("last packet\n");
	#endif

	/* term */
	seg = get_nxt_pkt_seg(pkt_data,&pos,&seg_len,pkt_len);
	mac_state = SET_STATE(get_mac_term(seg_len), pos, phy_err, err_pos, MAC_ERROR); 
	fill_mac_intf(mac,mac_state,seg,seg_len, tv->pkt_id);
	mac_intf_s_fifo_push(tv->mac_fifo,mac);

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
		fill_mac_intf(mac,MAC_INVALID,0,0,0);
		mac_intf_s_fifo_push(tv->mac_fifo,mac);
		idle_cnt -= DATA_WIDTH_BYTE;
	}

	/* transport data 
 	 * 
 	 * if node_id == 0, which is the only node with the accepted
 	 * mac/ip/port values, we expect the transport data to be driven
 	 * on the output of the transport layer.
 	 * Segement transport data and start adding it to fifo */
	if (node_id <= 1){
		/* TODO: this version of the testbench is written for 
	 	 * DATA_WIDTH == 16, we are guarantied that the transport
	 	 * data will allways start at the begining of a bus payload
	 	 * for width of 16 and 32 but,  this is not a guaranty for 
	 	 * DATA_WIDTH == 64 .
	 	 * Writing assertion of rember add support for this latter */
		assert(DATA_WIDTH < 64 );

		/* start */
		pos = 0;
		seg = get_nxt_pkt_seg(data, &pos, &seg_len, data_len);
		trans_data_s *trans = init_trans_data(DATA_WIDTH_BYTE, seg, TRANS_DATA_START, tv->pkt_id); 	
		trans_data_s_fifo_push(tv->data_fifo,trans);

		/* data */
		while(pos+DATA_WIDTH_BYTE < data_len){
			seg = get_nxt_pkt_seg(data, &pos, &seg_len, data_len);
			fill_trans_data(trans, DATA_WIDTH_BYTE, seg, TRANS_DATA_DATA,tv->pkt_id);
			trans_data_s_fifo_push(tv->data_fifo, trans);
		}
		/* term */
		seg = get_nxt_pkt_seg(data, &pos, &seg_len, data_len);
		info("trans data term pos %ld seg_len %d data_len %ld\n", pos, seg_len, data_len);
		fill_trans_data(trans, seg_len,	seg, TRANS_DATA_TERM, tv->pkt_id);
		trans_data_s_fifo_push(tv->data_fifo, trans);
		
		free(trans);
 	}
	#ifdef WIRESHARK
	/* dump to wireshark */
	dump_eth_packet(
		pkt_data,
		pkt_len,
		true);
	#endif

	free(mac);
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

	#ifdef DEBUG_POS
	info("pos %ld\n",*pos);
	#endif

	return seg;
}


void free_tv(tv_s *tv){

	for(int i=0; i<NODE_CNT; i++){
		assert(tv->eth[i]);
		free_eth_packet(tv->eth[i]);
	}
	/* delete fifo's */
	assert(tv->mac_fifo);
	mac_intf_s_fifo_dtor(tv->mac_fifo);
	assert(tv->data_fifo);
	trans_data_s_fifo_dtor(tv->data_fifo);
	
	#ifdef WIRESHARK
	close_dump();
	#endif	

};

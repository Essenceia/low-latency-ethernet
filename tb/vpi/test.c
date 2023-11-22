/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 *
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License.
 *
 * This code is provided "as is" without any express or implied warranties. */

#include "eth.h"
#include "dump.h"
#include "defs.h"
#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <time.h>
#include <stdlib.h>

#define PKT_LEN_MAX 1800
#define PKT_LEN_MIN 30
#define PKT_CNT 10

int main(){
	/* create node structs */
	eth_packet_s *node;	
	node = init_eth_packet(
		DEFAULT_DST_MAC,
		DEFAULT_SRC_MAC,
		DEFAULT_SRC_IP,
		DEFAULT_DST_IP,
		DEFAULT_SRC_PORT,
		DEFAULT_DST_PORT,
		false);
	print_eth_packet(node);

	/* fill packets and dump packet to file */
	uint8_t data[PKT_LEN_MAX];
	size_t data_len;
	size_t dump_len;
	uint8_t *dump;
	
	srand((unsigned int)time(NULL));   
	int r;
	for(int i=0; i<PKT_CNT; i++){
		#ifdef DEBUG
		printf("creating packet %d\n",i);
		#endif
		r = rand();
		/* fill packet with fake data */
		data_len = (size_t)(r % (PKT_LEN_MAX-PKT_LEN_MIN) + PKT_LEN_MIN);
		for(size_t l=0; l < data_len; l++){
			data[l] = (uint8_t) rand();
		}	
		/* update node packet content */
		update_eth_packet_data(node,data, data_len);
		/* dump */
		dump = write_eth_packet(
				node,
				&dump_len);
		#ifdef DEBUG
		info("dump:\nlen %ld\n",dump_len);
		#endif
		dump_eth_packet(
			dump, 
			dump_len, 
			true);
		free(dump);
	}
	
	free_eth_packet(node);
	close_dump();
	
	printf("End of test\n");
	return 0;
}

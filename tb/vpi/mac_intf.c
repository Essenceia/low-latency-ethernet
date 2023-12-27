#include "mac_intf.h"
#include <stdio.h>
#include <assert.h>
#include <string.h>

mac_intf_s *init_mac_intf(
	mac_intf_e state, 
	data_t data,
	uint8_t data_len,
	debug_id_t id	
){
	mac_intf_s *ret = (mac_intf_s*)malloc(sizeof(mac_intf_s));
	fill_mac_intf(ret, state, data, data_len,id);
	return ret;		
}

void fill_mac_intf(
	mac_intf_s *mac, 
	mac_intf_e state, 
	data_t data,
	uint8_t data_len,
	debug_id_t id
){
	assert(mac);
	memset(mac, 0, sizeof(mac_intf_s));
	mac->id = id;
	if(state != MAC_INVALID){
		/* if invalid, leave anything to 0, else valid=1 */
		mac->valid = true;
		mac->data = data;
		mac->len = data_len;
		mac->ctrl = true;
		switch(state){
			case MAC_START: 
				mac->start = true;
				break;
			#ifdef MAC_INTF_START_2
			case MAC_START_2:
				mac->start_2 = true;
				break;		
			#endif
			case MAC_TERM_1:
				assert(data_len==1);
				mac->term = true;
				break;
			case MAC_TERM_2:
				if(data_len != 2)
					printf("data_len %d\n", data_len);
				assert(data_len==2);
				mac->term = true;
				break;		
			#if DATA_WIDTH > 16
			case MAC_TERM_3:
				assert(data_len==3);
				mac->term = true;
				break;
			case MAC_TERM_4;
				assert(data_len==4);
				mac->term = true;
				break;	
			#if DATA_WIDTH > 32
			case MAC_TERM_5:
				assert(data_len==5);
				mac->term = true;
				break;	
			case MAC_TERM_6;
				assert(data_len==6);
				mac->term = true;
				break;	
			case MAC_TERM_7;
				assert(data_len==7);
				mac->term = true;
				break;	
			case MAC_TERM_8;
				assert(data_len==8);
				mac->term = true;
				break;	
			#endif
			#endif
			case MAC_ERROR:
				mac->cancel = true;
				break;
			case MAC_DATA:
				/* unset ctrl, set by default as true expect for data */
				mac->ctrl = false;
				break;
			case MAC_INVALID : break;
			default:
				fprintf(stderr, "ERROR: missmatch MAC_INTT_TYPE\n");
				assert(0);
				break;
		}
	}
	#ifdef DEBUG_MAC
	printf("Set mac, state %d :\n",state );
	print_mac_intf(mac);
	#endif
}

void print_mac_intf(mac_intf_s* mac){
	assert(mac);
	printf("mac inft: ");
	if(mac->valid){
			if(mac->start)
				printf("start");
			#ifdef MAC_INTF_START_2
			if(mac->start_2)
				printf("start_2");
			#endif
			if(mac->term)
				printf("term");
			if(mac->cancel)
				printf("cancel ");
			if(!mac->ctrl)
				printf("data");
		printf(", %u, 0x%0*x",mac->len, DATA_WIDTH/8,  mac->data);
	}else{
		printf("invalid");
	}
	printf(" id %08x\n",mac->id);
}

uint8_t get_mac_start(mac_intf_s *mac){
	assert(mac);
	uint8_t ret = mac->start;
	#ifdef MAC_INTF_START_2
	ret |= mac->start_2 << 1;
	#endif
	return ret;
}


#include "mac_intf.h"
#include <stdio.h>
#include <assert.h>
#include <string.h>

void fill_mac_intf(
	mac_intf_s *mac, 
	mac_intf_e state, 
	data_t data,
	uint8_t data_len
){
	assert(mac);
	memset(mac, 0, sizeof(mac_intf_s));
	if(state != MAC_INVALID){
		/* if invalid, leave anything to 0, else valid=1 */
		mac->valid = true;
		mac->data = data;
		mac->len = data_len;
		switch(state){
			case MAC_START: 
				mac->start = true;
				break;
			#ifdef MAC_INTF_START_2
			case MAC_START_2:
				mac->start_2 = true;
				break;		
			#endif
			case MAC_IDLE:
				mac->idle = true;
				break;
			case MAC_TERM_0:
				assert(data_len==0);
				mac->term = true;
				break;
			case MAC_TERM_1:
				assert(data_len==1);
				mac->term = true;
				break;
			#if DATA_WIDTH > 16
			case MAC_TERM_2;
				assert(data_len==2);
				mac->term = true;
				break;		
			case MAC_TERM_3:
				assert(data_len==3);
				mac->term = true;
				break;
			#if DATA_WIDTH > 32
			case MAC_TERM_4;
				assert(data_len==4);
				mac->term = true;
				break;	
			case MAC_TERM_5:
				assert(data_len==5);
				mac->term = true;
				break;	
			case MAC_TERM_6;
				assert(data_len==6);
				mac->term = true;
				break;	
			case MAC_TERM_7;
				assert(data_len==6);
				mac->term = true;
				break;	
			#endif
			#endif
			case MAC_ERROR:
				mac->cancel = true;
				break;
			case MAC_DATA: break;
			case MAC_INVALID : break;
			default:
				fprintf(stderr, "ERROR: missmatch MAC_INTT_TYPE\n");
				assert(0);
				break;
		
		}

	}
	
}



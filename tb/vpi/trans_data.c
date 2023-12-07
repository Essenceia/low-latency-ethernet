#include "trans_data.h"

trans_data_s *init_trans_data(
	uint8_t len,
	data_t data,
	trans_data_state_e state
){
	trans_data_s* ret = (trans_data_s*)malloc(sizeof(trans_data_s));
	assert(len <= DATA_WIDTH/8);
	ret->len = len;
	ret->data = data;
	ret->state = state;
	return ret;
}

void print_trans_data(trans_data_s *t){
	assert(t);
	printf("trans out:");
	if(t->state == TRANS_DATA_INVALID){
		printf(" invalid");
	}else{
		switch(t->state){
			case TRANS_DATA_START:
				printf(" start");
				break;
			case TRANS_DATA_TERM:
				printf(" end");
				break;
			default: break;
			}
			printf(" data: %u, 0x%0*x",t->len,DATA_WIDTH/8,t->data);
		
	}
	printf("\n");
}


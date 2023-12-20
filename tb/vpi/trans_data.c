#include "trans_data.h"

trans_data_s *init_trans_data(
	uint8_t len,
	data_t data,
	trans_data_state_e state,
	debug_id_t id
){
	trans_data_s* ret = (trans_data_s*)malloc(sizeof(trans_data_s));
	fill_trans_data(ret, len, data,state,id);
	return ret;
}

void fill_trans_data(
	trans_data_s *trans,
	uint8_t len,
	data_t data,
	trans_data_state_e state,
	debug_id_t id
){
	assert(len <= DATA_WIDTH/8);
	trans->len = len;
	trans->data = data;
	trans->state = state;
	trans->id = id;
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
				printf(" term");
				break;
			default: break;
			}
			printf(" data: %u, 0x%0*x",t->len,DATA_WIDTH/8,t->data);
		
	}
	printf(" id %08x\n",t->id);
}


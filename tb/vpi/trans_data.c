#include "trans_data.h"

trans_data_s *init_trans_data(
	uint8_t len,
	data_t data
){
	trans_data_s* ret = (trans_data_s*)malloc(sizeof(trans_data_s));
	assert(len <= DATA_WIDTH/8);
	ret->len = len;
	ret->data = data;
	return ret;
}

void print_trans_data(trans_data_s *t){
	assert(t);
	printf("trans data: %u, 0x%0*x\n",t->len,DATA_WIDTH/8,t->data);
}


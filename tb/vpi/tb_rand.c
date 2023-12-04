/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 * 
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License. 
 * 
 * This code is provided "as is" without any express or implied warranties. */ 

#include "tb_rand.h"

#include <stdlib.h>
#include "defs.h"
#include <stdbool.h>

static bool lfsr_init = false;
static uint16_t lfsr; 

#define LFSR_INIT if(lfsr_init == false)tb_rand_init(SEED)

void tb_rand_init(uint16_t seed){
	lfsr = seed;
	lfsr_init = true;
}

uint16_t tb_rand_get_lfsr(){
	return lfsr;
};

uint16_t tb_rand_get_packet_len(){
	LFSR_INIT;
	lfsr = LFSR(lfsr);
	uint16_t rand_cnt = (uint16_t) ( lfsr % (PACKET_LEN_MAX-PACKET_LEN_MIN)) + PACKET_LEN_MIN;
	return rand_cnt;
}

uint64_t tb_rand_uint64_t(){
	uint64_t r = 0;
	LFSR_INIT;
	for( int i=0; i<4; i++){
		lfsr = LFSR(lfsr);
		r |= (uint64_t)lfsr << 16*i;
	}
	return r;
}

uint8_t* tb_rand_uint48_t(){
	uint8_t *r;
	r = malloc(sizeof(uint8_t)*6);
	LFSR_INIT;
	for( int i=0; i<6; i++){
		if(i%2==0)
			lfsr = LFSR(lfsr);
		r[i] = (uint8_t)lfsr << 8*(i%2);
	}
	return r;
}

uint32_t tb_rand_uint32_t(){
	uint32_t r = 0;
	LFSR_INIT;
	for( int i=0; i<2; i++){
		lfsr = LFSR(lfsr);
		r |= (uint64_t)lfsr << 16*i;
	}
	return r;
}


uint8_t tb_rand_uint8_t(){
	LFSR_INIT;
	lfsr = LFSR(lfsr);
	return (uint8_t) lfsr;
}

uint16_t tb_rand_uint16_t(){
	LFSR_INIT;
	lfsr = LFSR(lfsr);
	return (uint16_t) lfsr;
}

void tb_rand_fill_packet(uint8_t * p, size_t len){
	LFSR_INIT;
	for(size_t i=0; i < len; i++){
		lfsr = LFSR(lfsr);
		p[i] = (uint8_t) lfsr;
	}
}





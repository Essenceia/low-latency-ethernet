/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 * 
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License. 
 * 
 * This code is provided "as is" without any express or implied warranties. */ 

#ifndef TB_RAND_H
#define TB_RAND_H

#include <stdint.h>
#include <stddef.h>

#ifndef SEED
#define SEED 10
#endif

#define LFSR(x) ((x >> 1) | (( ((x >> 0) ^ (x >> 2) ^ (x >> 3) ^ (x >> 5)) & 1u) << 15)) 

void tb_rand_init(uint16_t seed);

uint16_t tb_rand_get_lfsr();

uint16_t tb_rand_get_packet_len();

uint16_t tb_rand_packet_idle_cntdown();

uint64_t tb_rand_uint64_t();

uint32_t tb_rand_uint32_t();

uint8_t tb_rand_uint8_t();

void tb_rand_fill_packet(uint8_t * p, size_t len);

#endif//TB_RAND_H

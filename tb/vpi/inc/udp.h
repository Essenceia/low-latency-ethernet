#ifndef UDP_H 
#define UDP_H

/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 *
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License.
 *
 * This code is provided "as is" without any express or implied warranties. */

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

/* udp header 
 * The UDP header CS field is optional, we don not fill it, 
 * unused value is 0 */
typedef struct{
	uint16_t src_port;
	uint16_t dst_port;
	uint16_t len;
	uint16_t cs;
}__attribute__((__packed__)) udp_head_s;

udp_head_s *read_udp_head(uint8_t *buff, size_t len);

void set_udp_len(udp_head_s *head, size_t data_len);

uint8_t *write_udp_head(udp_head_s* head, size_t *len); 

udp_head_s * init_udp_head(
	const uint16_t scr_port,
	const uint16_t dst_port,
	const uint16_t udp_data_len);	

void print_udp_head(udp_head_s * head);

#endif // UDP_H

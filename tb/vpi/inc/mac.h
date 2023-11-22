#ifndef MAC_H
#define MAC_H

/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 *
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License.
 *
 * This code is provided "as is" without any express or implied warranties. */

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdio.h>


typedef struct{
	uint8_t pre[7];
	uint8_t sfd; /* start of frame delimiter */
	uint8_t dst_addr[6];
	uint8_t src_addr[6];
	/* tag */
	uint16_t tpid;
	uint16_t tci; /* tag control information */
	/* type */
	uint16_t type;
}__attribute__((__packed__)) mac_head_s;

mac_head_s *read_mac_head(uint8_t *buff, size_t len);

uint8_t *write_mac_head(mac_head_s *head, size_t *len);

bool mac_has_tag(mac_head_s *mac_head);

size_t get_mac_head_len(mac_head_s *head);

void print_mac_head(mac_head_s *head);

mac_head_s *init_mac_head(
	const uint8_t dst_addr[6],
	const uint8_t src_addr[6],
	const bool vtag);


typedef struct{
	uint32_t crc;
}__attribute__((__packed__)) mac_foot_s;

mac_foot_s *read_mac_foot(uint8_t *buff, size_t len);
uint8_t *write_mac_foot(mac_foot_s*foot, size_t *len);

mac_foot_s *init_mac_foot();

uint32_t calculate_crc(uint8_t *buff, size_t len);

void print_mac_foot(mac_foot_s * foot);

/* utils */
static inline void print_mac_addr(const uint8_t addr[6]){
	for(int i=0; i<6; i++){
		printf("%x",addr[i]);
		if ( i != 5 )printf("-");
	}
}
#endif //MAC_H

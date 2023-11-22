#ifndef IPV4_H
#define IPV4_H

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

/* ipv4 */
typedef struct{
	uint8_t ver;/* 4 bits */
	uint8_t ihl;/* 4 bits */
	uint8_t dscp;/* 6 bits */
	uint8_t ecn;/* 2 bits */
	uint16_t tot_len;
	uint16_t id;
	uint8_t flags;/* 3 bits */
	uint16_t frag_off;/* 13 bits */
	uint8_t ttl;
	uint8_t prot;
	uint16_t head_cs;
	uint32_t src_addr;
	uint32_t dst_addr;
}__attribute__((__packed__)) ipv4_head_s;

ipv4_head_s *read_ipv4_head(uint8_t *buff, size_t len);
uint8_t *write_ipv4_head(ipv4_head_s *head, size_t *len);

bool ipv4_protocol_is_udp(ipv4_head_s *head);

/* constructor */
ipv4_head_s *init_ipv4_head(
	const uint32_t src_addr,
	const uint32_t dst_addr,
	const size_t ip_data_len,
	const uint8_t protocol
);

/* update data length and recalculate cs */
void update_ipv4_header_data_len(ipv4_head_s* head, size_t ip_data_len);

/* calculate header checksum */
uint16_t calculate_ipv4_header_checksum(ipv4_head_s *head);

/* print struct */
void print_ipv4_head(ipv4_head_s *head);

/* print ipv4 address */
static inline void print_ipv4_addr(const uint32_t addr){
	printf("%u.%u.%u.%u",
		(uint8_t)(addr >> 24),
		(uint8_t)(addr >> 16),
		(uint8_t)(addr >> 8),
		(uint8_t)(addr));
}
#endif //IPV4_H

#ifndef ETH_H
#define ETH_H

/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 *
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License.
 *
 * This code is provided "as is" without any express or implied warranties. */

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include "eth_defs.h"
#include "mac.h"
#include "ipv4.h"
#include "udp.h"
#include "tcp.h"

/* udp/tcp packet */
typedef struct{
	/* head */
	mac_head_s  *mac_head;
	ipv4_head_s *ipv4_head;
	udp_head_s  *udp_head;
	tcp_head_s  *tcp_head;
	/* data */
	uint8_t *data;
	size_t data_len;
	/* footer */
	mac_foot_s *mac_foot;
}eth_packet_s;

bool is_udp(eth_packet_s *eth);

eth_packet_s * read_eth_packet(uint8_t *buff, size_t len);
uint8_t *write_eth_packet(eth_packet_s* eth, size_t *len);


/* constructors with default values
 * protocol : code of the transport protocol*/
eth_packet_s *init_eth_packet(
	const uint8_t dst_mac[6],
	const uint8_t src_mac[6],
	const uint32_t src_ip,
	const uint32_t dst_ip,
	const uint16_t src_port,
	const uint16_t dst_port, 
	const bool vtag);

/* update application data */
void update_eth_packet_data(
	eth_packet_s *eth, 
	uint8_t *app_data, 
	size_t app_data_len);

/* re-calculate content of mac crc footer */
void update_eth_packet_crc(eth_packet_s *eth);

/* destructor */
void free_eth_packet(eth_packet_s* eth);

/* print */
void print_eth_packet(eth_packet_s * eth);

#endif //ETH_S_H

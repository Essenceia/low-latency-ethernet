#ifndef DUMP_H
#define DUMP_H

/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 *
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License.
 *
 * This code is provided "as is" without any express or implied warranties. */

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

void dump_eth_packet(
	const uint8_t *buff,
	const size_t len,
	const bool inbound
);

void close_dump();
#endif //DUMP_H

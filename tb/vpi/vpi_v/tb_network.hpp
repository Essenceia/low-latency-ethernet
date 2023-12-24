/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 * 
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License. 
 * 
 * This code is provided "as is" without any express or implied warranties. */ 

#ifndef TB_NETWORK_HPP 
#define TB_NETWORK_HPP 

#define MODULE eth_tb

extern "C" {
#include "../defs.h"
}

#include "Veth_tb.h"

int main(int argc, char ** argv);

#endif

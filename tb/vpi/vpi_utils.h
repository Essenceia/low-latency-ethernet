/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 * 
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License. 
 * 
 * This code is provided "as is" without any express or implied warranties. */ 

#ifndef VPI_UTILS_H
#define VPI_UTILS_H
#ifdef VERILATOR
#include "verilated_vpi.h" 
#else
#include <vpi_user.h>
#endif

/* Includes scanning */
void vpi_put_logic_1b_t(vpiHandle h, uint8_t var);

void vpi_put_logic_uint8_t(vpiHandle h, uint8_t var);

void vpi_put_logic_uint32_t(vpiHandle h, uint32_t var);

static inline void vpi_put_logic_uint16_t(vpiHandle h, uint16_t var){
	vpi_put_logic_uint32_t(h, (uint32_t) var);
};

void vpi_put_logic_uint64_t(vpiHandle h, uint64_t var);


// puts an array of char of variable length to a vector
void _vpi_put_logic_char_var_arr(vpiHandle h, uint8_t *arr, size_t len);

// puts an array of uint64_t of variable length to a vector
void vpi_put_logic_uint64_t_var_arr(vpiHandle h, uint64_t *arr, size_t len);

#define VPI_UTILS_PUT_CHAR_ARR(X) \
 static inline void vpi_put_logic_char_##X##_t(vpiHandle h, uint8_t *arr){ \
	_vpi_put_logic_char_var_arr( h, arr, X ); \
}
static inline void vpi_put_logic_char(vpiHandle argc, char var){
	vpi_put_logic_uint8_t(argc, (uint8_t) var);
 }
VPI_UTILS_PUT_CHAR_ARR(2)
VPI_UTILS_PUT_CHAR_ARR(4)
VPI_UTILS_PUT_CHAR_ARR(8)
VPI_UTILS_PUT_CHAR_ARR(10)
VPI_UTILS_PUT_CHAR_ARR(20)

// debug id
VPI_UTILS_PUT_CHAR_ARR(18)


#endif // VPI_UTILS_H

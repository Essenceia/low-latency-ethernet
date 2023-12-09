/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 * 
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License. 
 * 
 * This code is provided "as is" without any express or implied warranties. */ 

#include "vpi_utils.h"
#include "inc/tb_all.h"
#include <stdlib.h>
#include "defs.h"
/* Note : Eventhough calloc set bits to 0 we are still manually
 * writing bval's to 0 for clarity */

void vpi_put_logic_1b_t(vpiHandle h, uint8_t var){
	
	s_vpi_value v;
	
	assert(h);
	v.format = vpiScalarVal;
	v.value.scalar = ( var )? vpi1 : vpi0;
	vpi_put_value(h, &v, 0, vpiNoDelay);
}

void vpi_put_logic_uint8_t(vpiHandle h, uint8_t var){
	
	s_vpi_value v;
	
	assert(h);
	v.format = vpiVectorVal;
	v.value.vector = calloc(1, sizeof(s_vpi_vecval));
	v.value.vector[0].aval = (PLI_INT32) 0xffffff00 | (PLI_INT32)var;
	v.value.vector[0].bval = (PLI_INT32) 0xffffff00;
	vpi_put_value(h, &v, 0, vpiNoDelay);
	free(v.value.vector);	
}
void vpi_put_logic_uint32_t(vpiHandle h, uint32_t var){
	
	s_vpi_value v;
	
	assert(h);

	v.format = vpiVectorVal;
	v.value.vector = calloc(1, sizeof(s_vpi_vecval));
	v.value.vector[0].aval = (PLI_INT32)var;
	v.value.vector[0].bval = 0;
	vpi_put_value(h, &v, 0, vpiNoDelay);
	free(v.value.vector);	
}

void vpi_put_logic_uint64_t(vpiHandle h, uint64_t var){
	
	s_vpi_value v;
	
	assert(h);
	v.format = vpiVectorVal;
	v.value.vector = calloc(2, sizeof(s_vpi_vecval));
	v.value.vector[0].aval =(PLI_INT32) var; //32 lsb 
	v.value.vector[0].bval = 0;
	v.value.vector[1].aval =(PLI_INT32) ( var >> 32 ); //32 msb 
	v.value.vector[1].bval = 0;
	vpi_put_value(h, &v, 0, vpiNoDelay);	
	free(v.value.vector);	
}

void _vpi_put_logic_char_var_arr(vpiHandle h, uint8_t *arr, size_t len){
	size_t w_cnt; // word count, vpi vector val elems are only of 32b wide each
	size_t off;
	
	s_vpi_value v;
	
	assert(h);
	w_cnt = ((len*8)/ 32) + (((len*8) % 32 )? 1 :0 );// round to supperior
	v.format = vpiVectorVal;
	v.value.vector = calloc(w_cnt, sizeof(s_vpi_vecval));
	for (size_t i = 0; i < w_cnt; i++){
		v.value.vector[i].aval = 0;
	}	
	
	for (size_t i = 0; i < w_cnt*4; i++){
		off = (i%4)*8;
		if ( i < len ){
			v.value.vector[i/4].aval |= (PLI_INT32) ( 0x000000ff & (uint32_t)arr[i] ) << off ;	
			v.value.vector[i/4].bval |= ((PLI_INT32)0x00  ) << ((i%4)*8);
		}else{
			v.value.vector[i/4].aval |= ((PLI_INT32)0xff) << ((i%4)*8);	
			v.value.vector[i/4].bval |= ((PLI_INT32)0xff) << ((i%4)*8);	
		}
	}
	vpi_put_value(h, &v, 0, vpiNoDelay);	
	free(v.value.vector);	
}


void vpi_put_logic_uint64_t_var_arr(vpiHandle h, uint64_t *arr, size_t len){
	size_t w_cnt; // word count, vpi vector val elems are only of 32b wide each
	size_t off;
	
	s_vpi_value v;
	
	assert(h);
	w_cnt = len*2;
	v.format = vpiVectorVal;
	v.value.vector = calloc(w_cnt, sizeof(s_vpi_vecval));
	for (size_t i = 0; i < w_cnt; i++){
		v.value.vector[i].aval = 0;
	}	
	
	for (size_t i = 0; i < w_cnt; i++){
		off = (i%2)*32;
		v.value.vector[i].aval = (PLI_INT32)(arr[i/2] >> off);	
		v.value.vector[i].bval = (PLI_INT32)0x00 ;
	}
	vpi_put_value(h, &v, 0, vpiNoDelay);	
	free(v.value.vector);	
}

void vpi_put_lite_logic_uint64_t_var_arr(vpiHandle h, uint64_t *arr, size_t len){
	size_t w_cnt; // word count, vpi vector val elems are only of 32b wide each
	size_t off;
	s_vpi_value v;	
	
	assert(h);
	w_cnt = len*2;
	v.format = vpiVectorVal;
	v.value.vector = calloc(w_cnt, sizeof(s_vpi_vecval));
	for (size_t i = 0; i < w_cnt; i++){
		v.value.vector[i].aval = 0;
	}	
	
	for (size_t i = 0; i < w_cnt; i++){
		off = (i%2)*32;
		v.value.vector[i].aval = (PLI_INT32)(arr[i/2] >> off);	
		v.value.vector[i].bval = (PLI_INT32)0x00 ;
	}
	vpi_put_value(h, &v, 0, vpiNoDelay);	
	free(v.value.vector);	
}


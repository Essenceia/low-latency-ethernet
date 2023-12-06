/* Copyright (c) 2023, Julia Desmazes. All rights reserved.
 *
 * This work is licensed under the Creative Commons Attribution-NonCommercial
 * 4.0 International License.
 *
 * This code is provided "as is" without any express or implied warranties. */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdlib.h>
#include "tb.h"

int main(){
	printf("Start test\n");

	tb_s *tb; 
	tb = init_tb();

	gen_new_pkt(tb, 0);

	/* print mac interface fifo */
	mac_intf_s_fifo_log(tb->mac_fifo);
	
	free_tb(tb);
	
	printf("End of test\n");
	return 0;
}

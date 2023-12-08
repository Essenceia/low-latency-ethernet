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
#include "tv.h"

int main(){
	printf("Start test\n");

	tv_s *tv; 
	tv = init_tv();

	gen_new_pkt(tv, 0);

	/* print mac interface fifo */
	//mac_intf_s_fifo_log(tv->mac_fifo);

	/* print trans data interface fifo */
	//trans_data_s_fifo_log(tv->data_fifo);
	
	info("finished building mac interface\n");
	
	free_tv(tv);
	
	printf("End of test\n");
	return 0;
}

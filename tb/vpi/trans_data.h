#ifndef TRANS_DATA_H
#define TRANS_DATA_H

#include "defs.h"
#include "inc/tb_all.h"

/* transport layer data structure */
typedef struct{
	uint8_t len;
	data_t data;
}trans_data_s;

trans_data_s *init_trans_data(
	uint8_t len,
	data_t data
);

void print_trans_data(
	trans_data_s *t
);

/* transport layer data fifo */

/* fifo */
static void trans_data_fifo_dtor(
	trans_data_s *e
) {
	free(e);
}
static void trans_data_fifo_log(
	trans_data_s *e
)
{
	print_trans_data(e);
}
/* macro "template" to declare fifo containing trans_data_s elemenets*/
TB_FIFO_API(
	trans_data_s, 
	&trans_data_fifo_dtor, 
	&trans_data_fifo_log
);


#endif

#ifndef MAC_INTF_H
#define MAC_INTF_H

#include <stdint.h>
#include <stdbool.h>

#include "defs.h"
#include "inc/tb_all.h"

#ifdef _40GBASE
#if (DATA_WIDTH > 32)
#define MAC_INTF_START_2
#endif
#endif 

typedef struct{
	bool valid;
	bool cancel;
	bool ctrl;
	bool idle;
	data_t data; 
	bool start;
	#ifdef MAC_INTF_START_2
	bool start_2;
	#endif
	bool term;
	uint8_t len; // data len
}mac_intf_s;

/* MAC interface states */
typedef enum {
	MAC_INVALID,
	MAC_START,
	#ifdef MAC_INTF_START_2
	MAC_START_2,// start on second lane 
	#endif
	MAC_IDLE,
	MAC_TERM_0,
	MAC_TERM_1,
	#if (DATA_WIDTH > 16)
	MAC_TERM_2,
	MAC_TERM_3,
	#if (DATA_WIDTH > 32)
	MAC_TERM_4,
	MAC_TERM_5,
	MAC_TERM_6,
	MAC_TERM_7,
	#endif
	#endif
	MAC_ERROR,
	MAC_DATA
}mac_intf_e ;

/* init and fill struct */
mac_intf_s *init_mac_intf(
	mac_intf_e state, 
	data_t data,
	uint8_t data_len
);

/* fill structure */
void fill_mac_intf(
	mac_intf_s *mac, 
	mac_intf_e state, 
	data_t data,
	uint8_t data_len
);

/* get mac signal value, used to handle the where we have start 2 */ 
uint8_t get_mac_start(mac_intf_s *mac);

/* print */
void print_mac_intf(
	mac_intf_s * mac 
);

/* fifo */
static void mac_fifo_log(
	mac_intf_s *e
)
{
	print_mac_intf(e);
}
static void mac_fifo_dtor(
	mac_intf_s *e
) {
}
TB_FIFO_API(
	mac_intf_s, 
	&mac_fifo_dtor, 
	&mac_fifo_log
);

/* get correct term based on length of the remaining data */
static inline mac_intf_e get_mac_term(size_t data_len){
	/* at worst ( DATA_WIDTH == 64 ), term data_len should
 	 * never be more than 7 bytes */  
	assert(data_len <= 7);
	return (mac_intf_e)(MAC_TERM_0 + data_len);
}
#endif // MAC_INTF_H

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
	data_t data; 
	bool start;
	#ifdef MAC_INTF_START_2
	bool start_2;
	#endif
	bool term;
	uint8_t len; // data len
	debug_id_t id;
}mac_intf_s;

/* MAC interface states */
typedef enum {
	MAC_INVALID = 0,
	MAC_START = 1,
	#ifdef MAC_INTF_START_2
	MAC_START_2 = 2,// start on second lane 
	#endif
	MAC_TERM_1 = 3,
	MAC_TERM_2 = 4,
	#if (DATA_WIDTH > 16)
	MAC_TERM_3 = 5,
	MAC_TERM_4 = 6,
	#if (DATA_WIDTH > 32)
	MAC_TERM_5 = 7,
	MAC_TERM_6 = 8,
	MAC_TERM_7 = 9,
	MAC_TERM_8 = 10,
	#endif
	#endif
	MAC_ERROR = 11,
	MAC_DATA = 12
}mac_intf_e ;

/* init and fill struct */
mac_intf_s *init_mac_intf(
	mac_intf_e state, 
	data_t data,
	uint8_t data_len,
	debug_id_t id
);

/* fill structure */
void fill_mac_intf(
	mac_intf_s *mac, 
	mac_intf_e state, 
	data_t data,
	uint8_t data_len,
	debug_id_t id
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
	assert(data_len);
	#if (DATA_WIDTH == 16)
	assert(data_len <= 2);
	#endif 
	mac_intf_e state = (MAC_TERM_1 + data_len -1);
	return state;
}
#endif // MAC_INTF_H

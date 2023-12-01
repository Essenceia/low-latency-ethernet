#ifndef MAC_INTF_H
#define MAC_INTF_H

#include <stdint.h>
#include <stdbool.h>

#include "defs.h"

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

/* fill structure */
void fill_mac_intf(
	mac_intf_s *mac, 
	mac_intf_e state, 
	data_t data,
	uint8_t data_len
);


#endif // MAC_INTF_H

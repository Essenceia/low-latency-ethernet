#ifndef MAC_INTF_H
#define MAC_INTF_H

#include <stdint.h>

#include "defs.h"

typedef struct{
	bool valid;
	bool cancel;
	bool ctrl;
	bool idle;
	data_t data; 
	uint8_t start;
	bool term;
	uint8_t keep;
}mac_intf_s;

/* MAC interface states */
typedef enum mac_intf_e {
	MAC_START,
	#ifndef 40GBASE
	MAC_START_2,// start on second lane 
	#endif
	MAC_IDLE,
	MAC_TERM_0,
	MAC_TERM_1,
	MAC_TERM_2,
	MAC_TERM_3,
	MAC_TERM_4,
	MAC_TERM_5,
	MAC_TERM_6,
	MAC_ERROR,
	MAC_DATA
};


#endif // MAC_INTF_H

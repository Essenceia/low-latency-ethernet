#ifndef DEFS_H
#define DEFS_H

#include <stdint.h>

#define STR_(x) #x
#define STR(x) STR_(x)


#define CAT2_(a,b) a##b
#define CAT2(a,b) CAT2_(a,b)

#define CAT3_(a,b,c) a##b##c
#define CAT3(a,b,c) CAT3_(a,b,c)

#define INC_STR STR(CAT2(V,MODULE).h)
#define VMODULE CAT2(V,MODULE)
#define MODULE_SIG_STR(x) STR(CAT3(TOP.,MODULE,.)x)

/* rtl data width */
#define DATA_WIDTH 16

typedef CAT3(uint,DATA_WIDTH,_t) data_t;

#endif // DEFS_H

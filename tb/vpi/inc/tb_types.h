#ifndef TB_TYPES_H
#define TB_TYPES_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdarg.h>

/* Base unsigned types */
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

/* Base signed types */
typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;

/* Sized floating point types. */
typedef float f32;
typedef double f64;

/* Pointer-sized type. */
typedef size_t uaddr;

#endif // TB_TYPES_H

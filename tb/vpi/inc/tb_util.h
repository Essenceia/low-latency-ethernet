#ifndef TB_UTILS_H
#define TB_UTILS_H
#include <stdio.h>


/***********
 * Logging *
 ***********/

#ifdef DEBUG
#define info(...) printf(__VA_ARGS__)
#else
#define info(...)
#endif
 
/*****************
 * Concatenation *
 *****************/

#define CAT2_(x, y) x ## y
#define CAT2(...) CAT2_(__VA_ARGS__)
#define CAT3_(x, y, z) x ## y ## z
#define CAT3(...) CAT3_(__VA_ARGS__)
#define CAT4_(a, b, c, d) a ## b ## c ## d
#define CAT4(...) CAT4_(__VA_ARGS__)
#define CAT5_(a, b, c, d, e) a ## b ## c ## d ## e
#define CAT5(...) CAT5_(__VA_ARGS__)

/*********************
 * String conversion *
 *********************/

#define TOSTR_(x) #x
#define TOSTR(x) TOSTR_(x)

/************
 * Counting *
 ************/

#define COUNT__(\
	_0, _1, _2, _3, _4, _5, _6, _7, _8, _9, \
	_10, _11, _12, _13, _14, _15, _16, _17, _18, _19, \
	_20, _21, _22, _23, _24, _25, _26, _27, _28, _29, \
	_30, _31, _32, _33, _34, _35, _36, _37, _38, _39, \
	_40, _41, _42, _43, _44, _45, _46, _47, _48, _49, \
	_50, _51, _52, _53, _54, _55, _56, _57, _58, _59, \
	_60, _61, _62, _63, _64, _65, _66, _67, _68, _69, \
	_70, _N, ...) _N

#define COUNT_(...) COUNT__(_, ##__VA_ARGS__, 70, \
	69, 68, 67, 66, 62, 64, 63, 62, 61, 60, \
	59, 58, 57, 56, 52, 54, 53, 52, 51, 50, \
	49, 48, 47, 46, 42, 44, 43, 42, 41, 40, \
	39, 38, 37, 36, 32, 34, 33, 32, 31, 30, \
	29, 28, 27, 26, 25, 24, 23, 22, 21, 20, \
	19, 18, 17, 16, 15, 14, 13, 12, 11, 10, \
	9, 8, 7, 6, 5, 4, 3, 2 ,1, 0)

#define COUNT(...) COUNT_(__VA_ARGS__)

/****************
 * Conditionals *
 ****************/

/* 
 * IF(x) (...) : "x == 1 ? __VA_ARGS__ :"
 * IFN(x) (...) : "x == 1 ? : __VA_ARGS__"
 * IFS(x) (...1) (...0) : "x == 1 ? __VA_ARGS1__ : __VA_ARGS0__"
 */
#define IF_SELECT_(a, b, c, ...) c
#define IF_EXPAND(...) __VA_ARGS__
#define IF_NOEXPAND(...)
#define IF_EXPAND_NOEXPAND(...) __VA_ARGS__ IF_NOEXPAND
#define IF_NOEXPAND_EXPAND(...) IF_EXPAND
#define IF1 _, _
#define IFCAT(b) IF##b
#define IF_SELECT(...) IF_SELECT_(__VA_ARGS__)
#define IF(x) IF_SELECT(IFCAT(x), IF_EXPAND, IF_NOEXPAND, _) 
#define IFN(x) IF_SELECT(IFCAT(x), IF_NOEXPAND, IF_EXPAND, _) 
#define IFS(x) IF_SELECT(IFCAT(x), IF_EXPAND_NOEXPAND, IF_NOEXPAND_EXPAND, _) 

#define _IF_PAREN(...) 1
#define IF_PAREN(x) IF(_IF_PAREN x)
#define IFN_PAREN(x) IFN(_IF_PAREN x)
#define IFS_PAREN(x) IFS(_IF_PAREN x)

#define IF_EMPTY_0 1
#define _IF_EMPTY(...) CAT2(IF_EMPTY_,COUNT(__VA_ARGS__))
#define IF_EMPTY(...) IF(_IF_EMPTY(__VA_ARGS__))
#define IFN_EMPTY(...) IFN(_IF_EMPTY(__VA_ARGS__))
#define IFS_EMPTY(...) IFS(_IF_EMPTY(__VA_ARGS__))

/*
 * SELECT_PE(x, paren, nempty, empty) :
 * if x has parenthesis, evaluate to paren.
 * elif x is not empty, evaluate to nempty.
 * else evaluate to empty.
 */
#define SELECT_PE_EV(...) __VA_ARGS__
#define SELECT_PE(x, paren, nempty, empty) \
SELECT_PE_EV( \
	IF_PAREN(x) paren \
	IFN_PAREN(x) EMPTY() ( \
		IFS_EMPTY IFN_PAREN(x) ((x)) empty nempty \
	) \
)

/*
 * SELECT(x, c0, c1, c2, ..., cN) : "x <= N ? cx : c0"
 */
#define SELECT__(_, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, x, ...) x
#define SELECT0 ,,,,,,,,,,
#define SELECT1 ,,,,,,,,,
#define SELECT2 ,,,,,,,,
#define SELECT3 ,,,,,,,
#define SELECT4 ,,,,,,
#define SELECT5 ,,,,,
#define SELECT6 ,,,,
#define SELECT7 ,,,
#define SELECT8 ,,
#define SELECT9 ,
#define SELECT10 
#define SELECT_CAT(x) SELECT##x
#define SELECT_(...) SELECT__(__VA_ARGS__)
#define SELECT(x, ...) SELECT_(SELECT_CAT(x), __VA_ARGS__,,,,,,,,,,,) 

/***********
 * Pointer *
 ***********/

/*
 * Evaluate to the address located @offset (relative) bytes after pointer @ptr.
 */
#define psum(ptr, offset)\
    ((void *) (((u8 *) (ptr)) + ((uaddr) (offset))))

/*
 * Evaluate to a bytewise subtraction between a and b.
 */
#define psub(a, b)\
     ((uaddr) (((u8 *) (a)) - ((u8 *) (b))))

/*
 * Evaluate to the offset of member @member in structure @type.
 */
#define offof(type, member) ((uaddr) (&(((type *) 0)->member)))

/*
 * Evaluate to the difference between offsets of member0 and member1 in structure @type.
 */
#define offbtw(type, member0, member1) (offof(type, member0) - offof(type, member1))

/*
 * Evaluate to the ref of the object of type @type that contains a member
 * @member whose location is @ptr.
 */
#define cntof(ptr, type, member)\
    ((type *) (psum(ptr, - offof(type, member))))
#define cntof_def(type, var, ptr, member) \
type *var = cntof(ptr, type, member);

/*
 * If @ptr if non-null, evaluate to the ref of the object of type @type that contains a member
 * @member whose location is @ptr.
 * Otherwise, evaluate to 0.
 */
#define cntofs(ptr, type, member)\
    ({type *p = cntof(ptr, type, member); ((p) ? p : (type *) 0);})

/*
 * Evaluate to 1 if @ptr points to a valid element of the array of @nb
 * elements of size @elsize starting at @start.
 */
#define iselof(ptr, start, nb, size) (\
	((void *) (start) <= (void *) (ptr)) && \
	((void *) (ptr) < psum((void *) start, nb * size)) && \
	(!(psub(ptr, start) % size)) \
)

/*********
 * Order *
 *********/

/*
 * Evaluate to 1 if var is a power of 2, 0 otherwise.
 * 0 is not considered to be a power of 2.
 */
#define is_2pow(var) (!!((var) && (!((var) & ((var) - 1)))))

/* Compute the size for an order. size = 2^order. */
#define order_to_size(order) ((uaddr) ((uaddr) 1 << (order)))

/* Compute the mask for and order. mask = 2^order - 1. */
#define order_to_mask(order) (order_to_size(order) - (uaddr) 1)

/* Compute the first order with a size greater or equal to the provided size. */
static inline u8 size_to_order(uaddr size)
{u8 order; uaddr i = 1;for (order = 0;(size) > i; i<<=1) {order++;}return order;}

/* Evaluate to 1 if @var is aligned on @order. */
#define is_aligned(var, order) (!((uaddr) (var) & order_to_mask(order)))

/****************
 * Integer swap *
 ****************/

/*
 * Set of clear some bits given by the mask with no branch.
 */

#define _bswap(a, b) (((a) ^ (b)) && ((b) ^= (a) ^= (b), (a) ^= (b)))

/* Implementations. */
#define u8_swap(a, b) _bswap(a, b, 8)
#define u16_swap(a, b) _bswap(a, b, 16)
#define u32_swap(a, b) _bswap(a, b, 32)
#define u64_swap(a, b) _bswap(a, b, 64)

/********
 * Swap *
 ********/

#define _swap(a, b) ({typeof(a) __swap_tmp = a; a = b; b = __swap_tmp;})

/**********
 * Memory *
 **********/

/*
 * Call malloc on @var computing
 * automatically its size.
 */
#define malloc_(var) (var = malloc(sizeof(*var)))

/*
 * Same than malloc_, but also defines the variable.
 * The type must be provided.
 */
#define malloc__(type, var) type *var = malloc(sizeof(type))

/**********
 * Assert *
 **********/

#define assert(x) ({ \
	if (!(x)) { \
		printf("%s:%u : assert '%s' failed.\n", __FILE__, __LINE__, #x); \
		abort(); \
	} \
})

#define check(x) ({ \
	if (!(x)) { \
		printf("%s:%u : check '%s' failed.\n", __FILE__, __LINE__, #x); \
		abort(); \
	} \
})

/************************
 * Increment operations *
 ************************/

#define SAFE_INCR(var) ({var++; check(var);})
#define SAFE_DECR(var) ({check(var); var--;})
#define SAFE_ADD(var, addend) ({check(var <= ((typeof(var)) (var + addend))); var = ((typeof(var)) (var + addend));})
#define SAFE_SUB(var, addend) ({check(((typeof(var)) (var - addend)) <= var); var = ((typeof(var)) (var - addend));})

#endif 

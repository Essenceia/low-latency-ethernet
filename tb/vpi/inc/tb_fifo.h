#ifndef TB_UTIL_FIFO_H
#define TB_UTIL_FIFO_H

/**************
 * Structures *
 **************/

/*
 * TB fifo header.
 */
typedef struct tb_fifo_elm {

	/* Elements of the same fifo. */
	tb_list elms;

	/* Implementation struct. */
	void *impl;

} tb_fifo_elm;

/*
 * The tb fifo stores internally allocated structs.
 */
typedef struct tb_fifo {

	/* Elements. */
	tb_list elms;

	/* Number of elements. */
	uaddr nb;

	/* Size of elements implementation. */
	size_t size;

	/*
	 * Element destructor.
	 * Does not free memory.
	 */
	void (*elm_dtor)(
		void *impl
	);

	/*
	 * Log.
	 */
	void (*elm_log)(
		void *elm
	);

} tb_fifo;

/*******
 * API *
 *******/

/*
 * Construct a fifo.
 */
tb_fifo *tb_fifo_ctor(
	size_t size,
	void (*elm_dtor)(void *),
	void (*elm_log)(void *)
);

/*
 * Destruct a fifo, delete all its elements.
 */
void tb_fifo_dtor(
	tb_fifo *fifo
);

/*
 * Print the content of @fifo.
 */
void tb_fifo_log(
	tb_fifo *fifo
);

/*
 * Allocate a new element, initialize it with @init, and push it
 * at the end of the fifo.
 * @size must be @fifo->size.
 */
void tb_fifo_push(
	tb_fifo *fifo,
	void *init,
	size_t size
);

/*
 * Read the first element of the fifo, return its pointer.
 * @size must be @fifo->size.
 * If @fifo is empty, return 0.
 */
void *tb_fifo_read(
	tb_fifo *fifo,
	uaddr size 
);

/*
 * Delete the first element of the fifo.
 * It must exist.
 */
void tb_fifo_del(
	tb_fifo *fifo
);

/*
 * Return the number of elements in @fifo.
 */
uaddr tb_fifo_nb(
	tb_fifo *fifo
);

/**********************
 * Implementation API *
 **********************/

/*
 * Generate an API for a fifo managing instances of type '@type'.
 */
#define TB_FIFO_API(type, type_dtor, type_log) \
typedef tb_fifo type##_fifo; \
static inline type##_fifo *type##_fifo_ctor( \
	void \
) { \
	return tb_fifo_ctor( \
		sizeof(type), \
		(void (*)(void *)) type_dtor, \
		(void (*)(void *)) type_log \
	); \
} \
static inline void type##_fifo_dtor( \
	type##_fifo *fifo \
) { \
	return tb_fifo_dtor( \
		fifo \
	); \
} \
static inline void type##_fifo_log( \
	type##_fifo *fifo \
) { \
	return tb_fifo_log( \
		fifo \
	); \
} \
static inline void type##_fifo_push( \
	type##_fifo *fifo, \
	type *init \
) { \
	return tb_fifo_push( \
		fifo, \
		init, \
		sizeof(type) \
	); \
} \
static inline type *type##_fifo_read( \
	type##_fifo *fifo \
) { \
	return tb_fifo_read( \
		fifo, \
		sizeof(type) \
	); \
} \
static inline void type##_fifo_del( \
	type##_fifo *fifo \
) { \
	return tb_fifo_del( \
		fifo \
	); \
}

#endif /* TB_UTIL_FIFO_H */

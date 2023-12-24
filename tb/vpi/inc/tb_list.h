#ifndef TB_UTIL_LIST_H
#define TB_UTIL_LIST_H

/**************
 * Structures *
 **************/

/*
 * A doubly linked circular list.
 */
struct tb_list;
typedef struct tb_list tb_list;
struct tb_list {

	/* Pointers to next and previous elements. */
	tb_list *next;
	tb_list *prev;

};

/*******
 * API *
 *******/

/* Link the head to itself. */
#define tb_list_init(h) ({(h)->next = (h)->prev = h;})
#define tb_list_inits(...) NS_MCALL_(tb_list_init, EMPTY, __VA_ARGS__)

/* Declare and initialize a local tb_list. */
#define tb_list_def(name) tb_list name; tb_list_init(&name);
/* Is a list empty ? */
#define tb_list_empty(h) ((u8) (((h)->next) == (h)))

/* Same as tb_list_empty, but saves the ref of the successor. */
#define tb_list_emptyn(h, n) ((u8) (((n) = ((h)->next)) == (h)))
#define tb_list_emptyne(h, n, type, member) \
	((u8) (&((n) = cntof((h)->next, type, member))->member == (h)))

/* Same as tb_list_empty, but saves the ref of the predecessor. */
#define tb_list_emptyp(h, n) ((u8) (((n) = ((h)->prev)) == (h)))
#define tb_list_emptype(h, n, type, member) \
	((u8) (&((n) = cntof((h)->prev, type, member))->member == (h)))

/* Has a list one element (head not comprised) ? */
#define tb_list_singleton(h) (((h) != (h)->next) && ((h)->next == (h)->prev))

/* Link the couple of list heads. */
#define tb_list_link(p, n) {(p)->next = (n); (n)->prev = (p);}

/* Access next and previous implementation structs. */
#define tb_list_nel(var, member) cntof(var->member.next, typeof(*var), member)
#define tb_list_pel(var, member) cntof(var->member.prev, typeof(*var), member)

/*
 * From h::t and a singleton l, build h:l::t.
 */
static inline void tb_list_ia(
	tb_list *h,
	tb_list *next
)
{

	/* Fetch the successor of h. */
	tb_list *n = h->next;

	/* Link h and l, and link l and n. */
	tb_list_link(h, next);
	tb_list_link(next, n);

}

/*
 * From t::h and a singleton l, build l:h::t.
 */
static inline void tb_list_ib(
	tb_list *h,
	tb_list *prev
)
{

	tb_list *p;

	/* Fetch the successor of h. */
	p = h->prev;

	/* Link p and l, and link l and h. */
	tb_list_link(p, prev);
	tb_list_link(prev, h);

}

/*
 * From h0::t0 and h1::t1, forms h0::t0:h1::t1.
 */
static inline void tb_list_cb(
	tb_list *n0,
	tb_list *n1
)
{

	tb_list *t0, *t1;

	/* Fetch t0 and t1. */
	t0 = n0->prev;
	t1 = n1->prev;

	/* Link t1 and h0, and link h1 t0 and h1. */
	tb_list_link(t1, n0);
	tb_list_link(t0, n1);

}

/*
 * From h0::t0 and h1::t1, build h0:h1::t1::t0.
 */

static inline void tb_list_ca(
	tb_list *h0,
	tb_list *h1
)
{

	/* Concatenate the list headed by the successor of h0 and h1. */
	tb_list_cb(h0->next, h1);

}

/*
 * Switch p and its successor in the list, and return p's new successor.
 */
static inline tb_list *tb_list_sn(
	tb_list *p
) {

	tb_list *n;
	tb_list *pp;

	/* Fetch neighbors. */
	n = p->next;
	pp = p->prev;

	/* If the list has not two elements (singleton comprised), switch : */
	if (pp != n) {

		tb_list *nn;
		nn = n->next;
		tb_list_link(pp, n);
		tb_list_link(n, p);
		tb_list_link(p, nn);
		return nn;
	} else return n;

}

/*
 * Switch h and its predecessor in the list and return n's new predecessor.
 */
static inline tb_list *tb_list_sp(
	tb_list *n
) {

	tb_list *p;
	tb_list *nn;

	/* Fetch neighbors. */
	p = n->prev;
	nn = n->next;

	/* If the list has not two elements (singleton comprised), switch : */
	if (nn != p) {

		tb_list *pp;
		pp = p->prev;
		tb_list_link(p, nn);
		tb_list_link(n, p);
		tb_list_link(pp, n);
		return pp;
	} else return p;
}

/*
 * Remove the list head from its list, but do not modify it.
 * The list head gets in an unsafe state, only init and insert_one may be used.
 */

static inline void tb_list_rmu(tb_list *l)
{

	tb_list *prev, *next;

	prev = l->prev;
	next = l->next;

	/* Link prev and next */
	tb_list_link(prev, next);

}

/*
 * Remove the list head from its list and links it to itself.
 */
static inline void tb_list_rm(tb_list *l)
{

	/* Remove n from its list. */
	tb_list_rmu(l);

	/* Link l with itself. */
	tb_list_init(l);

}

/*
 * Replace old by new in its list.
 * @new must be part of no list.
 * @old is left uninitialized.
 */
static inline void tb_list_rpu(
	tb_list *old,
	tb_list *nv
)
{

	tb_list *p, *n;

	/* Fetch the successor. */
	n = old->next;

	/* If the old node is a singleton : */
	if (n == old) {

		/* Link new to itself. */
		tb_list_init(nv);

		/* Complete. */
		return;

	}

	/* If old is not a singleton, fetch the predecessor. */
	p = old->prev;

	/* Link new. */
	tb_list_link(p, nv);
	tb_list_link(nv, n);

}

/*
 * Replace old by new in its list.
 * @new must be part of no list.
 * @old is reset as singleton.
 */
static inline void tb_list_rp(
	tb_list *old,
	tb_list *nv
)
{

	tb_list *p, *n;

	/* Fetch the successor. */
	n = old->next;

	/* If the old node is a singleton : */
	if (n == old) {

		/* Link new to itself. */
		tb_list_init(nv);

		/* Complete. */
		return;

	}

	/* If old is not a singleton, fetch the predecessor. */
	p = old->prev;

	/* Link new. */
	tb_list_link(p, nv);
	tb_list_link(nv, n);

	/* Reset the old node. */
	tb_list_init(old);

}

/*
 * Remove all nodes of src and insert them all at the end of dst.
 * src is empty in safe state after the function returns.
 * If @src is empty, return 1.
 * If nodes are transferred, return 0.
 */
static inline u8 tb_list_trb(
	tb_list *dst,
	tb_list *src
)
{

	tb_list *node;
	u8 empty;

	/* If the list is not empty : */
	empty = tb_list_emptyn(src, node);
	if (!empty) {

		/* Remove the src. */
		tb_list_rm(src);

		/* Concatenate the node to the src. */
		tb_list_cb(dst, node);

	}

	/* Return the emptyness. */
	return empty;

}

/*
 * Remove all nodes of src and insert them all at the end of dst.
 * src is in unsafe state after the function returns.
 * If @src is empty, return 1.
 * If nodes are transferred, return 0.
 */
static inline u8 tb_list_trbu(
	tb_list *dst,
	tb_list *src
)
{

	tb_list *node;
	u8 empty;

	/* If the list is not empty : */
	empty = tb_list_emptyn(src, node);
	if (!empty) {

		/* Remove the src. */
		tb_list_rmu(src);

		/* Concatenate the node to the src. */
		tb_list_cb(dst, node);

	}

	/* Return the emptyness. */
	return empty;

}

/*
 * Remove all nodes of src and insert them all at the start of dst.
 * src is empty in safe state after the function returns.
 * If @src is empty, return 1.
 * If nodes are transferred, return 0.
 */
static inline u8 tb_list_tra(
	tb_list *dst,
	tb_list *src
)
{

	tb_list *node;
	u8 empty;

	/* If the list is not empty : */
	empty = tb_list_emptyn(src, node);
	if (!empty) {

		/* Remove the src. */
		tb_list_rm(src);

		/* Concatenate the node to the src. */
		tb_list_ca(dst, node);

	}

	/* Return the emptyness. */
	return empty;

}

/*
 * Remove all nodes of src and insert them all at the start of dst.
 * src is in unsafe state after the function returns.
 * If @src is empty, return 1.
 * If nodes are transferred, return 0.
 */
static inline u8 tb_list_trau(
	tb_list *dst,
	tb_list *src
)
{

	tb_list *node;
	u8 empty;

	/* If the list is not empty : */
	empty = tb_list_emptyn(src, node);
	if (!empty) {

		/* Remove the src. */
		tb_list_rmu(src);

		/* Concatenate the node to the src. */
		tb_list_ca(dst, node);

	}

	/* Return the emptyness. */
	return empty;

}

/*
 * For loop that evaluates all successors of @head from @head->next to
 * @head->prev, storing the current one in @var.
 * @head is never evaluated.
 * @var should not be modified, for this, use tb_list_fs.
 */
#define tb_list_f(var, head) \
for ((var) = (head)->next; (var) != (head); (var) = (var)->next)

/*
 * For loop that evaluates all successors elements of @head from
 * element of @head->next to element of @head->prev, storing the current
 * one in @var.
 * @head is never evaluated.
 * @var should not be modified, for this, use tb_list_fes.
 */
#define tb_list_fe(var, head, member) \
for ( \
	(var) = cntof((head)->next, typeof(*(var)), member); \
	(&(var)->member != (head)); \
	(var) = tb_list_nel(var, member) \
) 

/*
 * For loop that evaluates all predecessors of @head from @head->prev to
 * @head->next, storing the current one in @var.
 * @head is never evaluated.
 * @var should not be modified, for this, use tb_list_fs.
 */
#define tb_list_fr(var, head) \
for ((var) = (head)->prev; (var) != (head); (var) = (var)->prev)

/*
 * For loop that evaluates all successors elements of @head from
 * element of @head->prev to element of @head->next, storing the current
 * one in @var.
 * @head is never evaluated.
 * @var should not be modified, for this, use tb_list_fes.
 */
#define tb_list_fer(var, head, member) \
for ( \
	(var) = cntof((head)->prev, typeof(*(var)), member); \
	(&(var)->member != (head)); \
	(var) = tb_list_pel(var, member) \
)

/*
 * For loop that evaluates all successors of @head from @head->next to
 * @head->prev, storing the current one in @var.
 * @var can be modified.
 */
#define tb_list_fs(var, head) \
for ( \
	typeof(var) _s = ({var = (head)->next; (typeof(var)) 0;}); \
	(((var) != (head)) && (_s = (var)->next,1)); \
	(var) = _s \
) 

/*
 * For loop that evaluates all successors elements of @head from
 * element of @head->next to element of @head->prev, storing the current
 * one in @var.
 * @var can be modified.
 */
#define tb_list_fes(var, head, member) \
for ( \
	typeof(var) _s = ({(var) = cntof((head)->next, typeof(*(var)), member); (typeof(var)) 0;}); \
	((&(var)->member != (head)) && (_s = tb_list_nel(var, member),1)); \
	(var) = _s \
) 

/*
 * For loop that evaluates all successors of @head from @head->prev to
 * @head->nbext, storing the current one in @var.
 * @var can be modified.
 */
#define tb_list_fsr(var, head) \
for ( \
	typeof(var) _s = ({var = (head)->prev; (typeof(var)) 0;}); \
	(((var) != (head)) && (_s = (var)->prev,1)); \
	(var) = _s \
) 

/*
 * For loop that evaluates all successors elements of @head from
 * element of @head->prev to element of @head->next, storing the current
 * one in @var.
 * @var can be modified.
 */
#define tb_list_fesr(var, head, member) \
for ( \
	typeof(var) _s = ({(var) = cntof((head)->prev, typeof(*(var)), member); (typeof(var)) 0;}); \
	((&(var)->member != (head)) && (_s = tb_list_pel(var, member),1)); \
	(var) = _s \
) 

/*
 * Invert the list headed by @head.
 */
static inline void tb_list_inv(
	tb_list *head
)
{
	tb_list *node;
	tb_list_fs(node, head) {
		_swap(node->prev, node->next);
	}
	_swap(head->prev, head->next);
}

/*
 * Invert all elements of the list headed by @head
 * and the list.
 */
#define tb_list_inve(head, type, member, fnc) { \
	type *__inve_var; \
	tb_list_fes(__inve_var, (head), member) { \
		fnc(__inve_var); \
		_swap(__inve_var->member.prev, __inve_var->member.next); \
	} \
	_swap((head)->prev, (head)->next); \
}

#endif /* TB_UTIL_LIST_H */

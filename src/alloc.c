/* Storage allocation and gc for GNU Emacs Lisp interpreter.

Copyright (C) 1985-1986, 1988, 1993-1995, 1997-2013 Free Software
Foundation, Inc.

This file is part of GNU Emacs.

GNU Emacs is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

GNU Emacs is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.  */

#include <config.h>

#define LISP_INLINE EXTERN_INLINE

#include <stdio.h>
#include <limits.h>		/* For CHAR_BIT.  */

#ifdef ENABLE_CHECKING
#include <signal.h>		/* For SIGABRT. */
#endif

#ifdef HAVE_PTHREAD
#include <pthread.h>
#endif

#include "lisp.h"
#include "process.h"
#include "intervals.h"
#include "puresize.h"
#include "character.h"
#include "buffer.h"
#include "window.h"
#include "keyboard.h"
#include "frame.h"
#include "blockinput.h"
#include "termhooks.h"		/* For struct terminal.  */

#include <verify.h>

/* GC_CHECK_MARKED_OBJECTS means do sanity checks on allocated objects.
   Doable only if GC_MARK_STACK.  */
#if ! GC_MARK_STACK
# undef GC_CHECK_MARKED_OBJECTS
#endif

/* GC_MALLOC_CHECK defined means perform validity checks of malloc'd
   memory.  Can do this only if using gmalloc.c and if not checking
   marked objects.  */

#if (defined SYSTEM_MALLOC || defined DOUG_LEA_MALLOC \
     || defined GC_CHECK_MARKED_OBJECTS)
#undef GC_MALLOC_CHECK
#endif

#include <unistd.h>
#include <fcntl.h>

#ifdef USE_GTK
# include "gtkutil.h"
#endif
#ifdef WINDOWSNT
#include "w32.h"
#include "w32heap.h"	/* for sbrk */
#endif

#ifdef DOUG_LEA_MALLOC

#include <malloc.h>

/* Specify maximum number of areas to mmap.  It would be nice to use a
   value that explicitly means "no limit".  */

#define MMAP_MAX_AREAS 100000000

#endif /* not DOUG_LEA_MALLOC */

/* Mark, unmark, query mark bit of a Lisp string.  S must be a pointer
   to a struct Lisp_String.  */

#define MARK_STRING(S)		((S)->size |= ARRAY_MARK_FLAG)
#define UNMARK_STRING(S)	((S)->size &= ~ARRAY_MARK_FLAG)
#define STRING_MARKED_P(S)	(((S)->size & ARRAY_MARK_FLAG) != 0)

#define VECTOR_MARK(V)		((V)->header.size |= ARRAY_MARK_FLAG)
#define VECTOR_UNMARK(V)	((V)->header.size &= ~ARRAY_MARK_FLAG)
#define VECTOR_MARKED_P(V)	(((V)->header.size & ARRAY_MARK_FLAG) != 0)

/* Default value of gc_cons_threshold (see below).  */

#define GC_DEFAULT_THRESHOLD (100000 * word_size)

/* Global variables.  */
struct emacs_globals globals;

/* Number of bytes of consing done since the last gc.  */

EMACS_INT consing_since_gc;

/* Similar minimum, computed from Vgc_cons_percentage.  */

EMACS_INT gc_relative_threshold;

/* Minimum number of bytes of consing since GC before next GC,
   when memory is full.  */

EMACS_INT memory_full_cons_threshold;

/* True during GC.  */

bool gc_in_progress;

/* True means abort if try to GC.
   This is for code which is written on the assumption that
   no GC will happen, so as to verify that assumption.  */

bool abort_on_gc;

/* Number of live and free conses etc.  */

static EMACS_INT total_conses, total_markers, total_symbols, total_buffers;
static EMACS_INT total_free_conses, total_free_markers, total_free_symbols;
static EMACS_INT total_free_floats, total_floats;

/* Points to memory space allocated as "spare", to be freed if we run
   out of memory.  We keep one large block, four cons-blocks, and
   two string blocks.  */

static char *spare_memory[7];

/* Amount of spare memory to keep in large reserve block, or to see
   whether this much is available when malloc fails on a larger request.  */

#define SPARE_MEMORY (1 << 14)

/* Initialize it to a nonzero value to force it into data space
   (rather than bss space).  That way unexec will remap it into text
   space (pure), on some systems.  We have not implemented the
   remapping on more recent systems because this is less important
   nowadays than in the days of small memories and timesharing.  */

EMACS_INT pure[(PURESIZE + sizeof (EMACS_INT) - 1) / sizeof (EMACS_INT)] = {1,};
#define PUREBEG (char *) pure

/* Pointer to the pure area, and its size.  */

static char *purebeg;
static ptrdiff_t pure_size;

/* Number of bytes of pure storage used before pure storage overflowed.
   If this is non-zero, this implies that an overflow occurred.  */

static ptrdiff_t pure_bytes_used_before_overflow;

/* True if P points into pure space.  */

#define PURE_POINTER_P(P)					\
  ((uintptr_t) (P) - (uintptr_t) purebeg <= pure_size)

/* Index in pure at which next pure Lisp object will be allocated..  */

static ptrdiff_t pure_bytes_used_lisp;

/* Number of bytes allocated for non-Lisp objects in pure storage.  */

static ptrdiff_t pure_bytes_used_non_lisp;

/* If nonzero, this is a warning delivered by malloc and not yet
   displayed.  */

const char *pending_malloc_warning;

/* Maximum amount of C stack to save when a GC happens.  */

#ifndef MAX_SAVE_STACK
#define MAX_SAVE_STACK 16000
#endif

/* Buffer in which we save a copy of the C stack at each GC.  */

#if MAX_SAVE_STACK > 0
static char *stack_copy;
static ptrdiff_t stack_copy_size;
#endif

static Lisp_Object Qconses;
static Lisp_Object Qsymbols;
static Lisp_Object Qmiscs;
static Lisp_Object Qstrings;
static Lisp_Object Qvectors;
static Lisp_Object Qfloats;
static Lisp_Object Qintervals;
static Lisp_Object Qbuffers;
static Lisp_Object Qstring_bytes, Qvector_slots, Qheap;
static Lisp_Object Qgc_cons_threshold;
Lisp_Object Qautomatic_gc;
Lisp_Object Qchar_table_extra_slots;

/* Hook run after GC has finished.  */

static Lisp_Object Qpost_gc_hook;

static void mark_terminals (void);
static void gc_sweep (void);
static Lisp_Object make_pure_vector (ptrdiff_t);
static void mark_buffer (struct buffer *);

#if !defined REL_ALLOC || defined SYSTEM_MALLOC
static void refill_memory_reserve (void);
#endif
static void compact_small_strings (void);
static void free_large_strings (void);
static void free_misc (Lisp_Object);
extern Lisp_Object which_symbols (Lisp_Object, EMACS_INT) EXTERNALLY_VISIBLE;

/* When scanning the C stack for live Lisp objects, Emacs keeps track of
   what memory allocated via lisp_malloc and lisp_align_malloc is intended
   for what purpose.  This enumeration specifies the type of memory.  */

enum mem_type
{
  MEM_TYPE_NON_LISP,
  MEM_TYPE_BUFFER,
  MEM_TYPE_CONS,
  MEM_TYPE_STRING,
  MEM_TYPE_MISC,
  MEM_TYPE_SYMBOL,
  MEM_TYPE_FLOAT,
  /* Since all non-bool pseudovectors are small enough to be
     allocated from vector blocks, this memory type denotes
     large regular vectors and large bool pseudovectors.  */
  MEM_TYPE_VECTORLIKE,
  /* Special type to denote vector blocks.  */
  MEM_TYPE_VECTOR_BLOCK,
  /* Special type to denote reserved memory.  */
  MEM_TYPE_SPARE
};

#if GC_MARK_STACK || defined GC_MALLOC_CHECK

#if GC_MARK_STACK == GC_USE_GCPROS_CHECK_ZOMBIES
#include <stdio.h>		/* For fprintf.  */
#endif

/* A unique object in pure space used to make some Lisp objects
   on free lists recognizable in O(1).  */

static Lisp_Object Vdead;
#define DEADP(x) EQ (x, Vdead)

#ifdef GC_MALLOC_CHECK

enum mem_type allocated_mem_type;

#endif /* GC_MALLOC_CHECK */

/* A node in the red-black tree describing allocated memory containing
   Lisp data.  Each such block is recorded with its start and end
   address when it is allocated, and removed from the tree when it
   is freed.

   A red-black tree is a balanced binary tree with the following
   properties:

   1. Every node is either red or black.
   2. Every leaf is black.
   3. If a node is red, then both of its children are black.
   4. Every simple path from a node to a descendant leaf contains
   the same number of black nodes.
   5. The root is always black.

   When nodes are inserted into the tree, or deleted from the tree,
   the tree is "fixed" so that these properties are always true.

   A red-black tree with N internal nodes has height at most 2
   log(N+1).  Searches, insertions and deletions are done in O(log N).
   Please see a text book about data structures for a detailed
   description of red-black trees.  Any book worth its salt should
   describe them.  */

struct mem_node
{
  /* Children of this node.  These pointers are never NULL.  When there
     is no child, the value is MEM_NIL, which points to a dummy node.  */
  struct mem_node *left, *right;

  /* The parent of this node.  In the root node, this is NULL.  */
  struct mem_node *parent;

  /* Start and end of allocated region.  */
  void *start, *end;

  /* Node color.  */
  enum {MEM_BLACK, MEM_RED} color;

  /* Memory type.  */
  enum mem_type type;
};

/* Base address of stack.  Set in main.  */

Lisp_Object *stack_base;

/* Root of the tree describing allocated Lisp memory.  */

static struct mem_node *mem_root;

/* Lowest and highest known address in the heap.  */

static void *min_heap_address, *max_heap_address;

/* Sentinel node of the tree.  */

static struct mem_node mem_z;
#define MEM_NIL &mem_z

static struct Lisp_Vector *allocate_vectorlike (ptrdiff_t);
static void lisp_free (void *);
static void mark_stack (void);
static bool live_vector_p (struct mem_node *, void *);
static bool live_buffer_p (struct mem_node *, void *);
static bool live_string_p (struct mem_node *, void *);
static bool live_cons_p (struct mem_node *, void *);
static bool live_symbol_p (struct mem_node *, void *);
static bool live_float_p (struct mem_node *, void *);
static bool live_misc_p (struct mem_node *, void *);
static void mark_maybe_object (Lisp_Object);
static void mark_memory (void *, void *);
#if GC_MARK_STACK || defined GC_MALLOC_CHECK
static void mem_init (void);
static struct mem_node *mem_insert (void *, void *, enum mem_type);
static void mem_insert_fixup (struct mem_node *);
static void mem_rotate_left (struct mem_node *);
static void mem_rotate_right (struct mem_node *);
static void mem_delete (struct mem_node *);
static void mem_delete_fixup (struct mem_node *);
static struct mem_node *mem_find (void *);
#endif


#if GC_MARK_STACK == GC_MARK_STACK_CHECK_GCPROS
static void check_gcpros (void);
#endif

#endif /* GC_MARK_STACK || GC_MALLOC_CHECK */

#ifndef DEADP
# define DEADP(x) 0
#endif

/* Recording what needs to be marked for gc.  */

struct gcpro *gcprolist;

/* Addresses of staticpro'd variables.  Initialize it to a nonzero
   value; otherwise some compilers put it into BSS.  */

#define NSTATICS 0x800
static Lisp_Object *staticvec[NSTATICS] = {&Vpurify_flag};

/* Index of next unused slot in staticvec.  */

static int staticidx;

static void *pure_alloc (size_t, int);


/* Value is SZ rounded up to the next multiple of ALIGNMENT.
   ALIGNMENT must be a power of 2.  */

#define ALIGN(ptr, ALIGNMENT) \
  ((void *) (((uintptr_t) (ptr) + (ALIGNMENT) - 1) \
	     & ~ ((ALIGNMENT) - 1)))



/************************************************************************
				Malloc
 ************************************************************************/

/* Function malloc calls this if it finds we are near exhausting storage.  */

void
malloc_warning (const char *str)
{
  pending_malloc_warning = str;
}


/* Display an already-pending malloc warning.  */

void
display_malloc_warning (void)
{
  call3 (intern ("display-warning"),
	 intern ("alloc"),
	 build_string (pending_malloc_warning),
	 intern ("emergency"));
  pending_malloc_warning = 0;
}

/* Called if we can't allocate relocatable space for a buffer.  */

void
buffer_memory_full (ptrdiff_t nbytes)
{
  /* If buffers use the relocating allocator, no need to free
     spare_memory, because we may have plenty of malloc space left
     that we could get, and if we don't, the malloc that fails will
     itself cause spare_memory to be freed.  If buffers don't use the
     relocating allocator, treat this like any other failing
     malloc.  */

#ifndef REL_ALLOC
  memory_full (nbytes);
#endif

  /* This used to call error, but if we've run out of memory, we could
     get infinite recursion trying to build the string.  */
  xsignal (Qnil, Vmemory_signal_data);
}

/* A common multiple of the positive integers A and B.  Ideally this
   would be the least common multiple, but there's no way to do that
   as a constant expression in C, so do the best that we can easily do.  */
#define COMMON_MULTIPLE(a, b) \
  ((a) % (b) == 0 ? (a) : (b) % (a) == 0 ? (b) : (a) * (b))

#ifndef XMALLOC_OVERRUN_CHECK
#define XMALLOC_OVERRUN_CHECK_OVERHEAD 0
#else

/* Check for overrun in malloc'ed buffers by wrapping a header and trailer
   around each block.

   The header consists of XMALLOC_OVERRUN_CHECK_SIZE fixed bytes
   followed by XMALLOC_OVERRUN_SIZE_SIZE bytes containing the original
   block size in little-endian order.  The trailer consists of
   XMALLOC_OVERRUN_CHECK_SIZE fixed bytes.

   The header is used to detect whether this block has been allocated
   through these functions, as some low-level libc functions may
   bypass the malloc hooks.  */

#define XMALLOC_OVERRUN_CHECK_SIZE 16
#define XMALLOC_OVERRUN_CHECK_OVERHEAD \
  (2 * XMALLOC_OVERRUN_CHECK_SIZE + XMALLOC_OVERRUN_SIZE_SIZE)

/* Define XMALLOC_OVERRUN_SIZE_SIZE so that (1) it's large enough to
   hold a size_t value and (2) the header size is a multiple of the
   alignment that Emacs needs for C types and for USE_LSB_TAG.  */
#define XMALLOC_BASE_ALIGNMENT				\
  alignof (union { long double d; intmax_t i; void *p; })

#if USE_LSB_TAG
# define XMALLOC_HEADER_ALIGNMENT \
    COMMON_MULTIPLE (GCALIGNMENT, XMALLOC_BASE_ALIGNMENT)
#else
# define XMALLOC_HEADER_ALIGNMENT XMALLOC_BASE_ALIGNMENT
#endif
#define XMALLOC_OVERRUN_SIZE_SIZE				\
   (((XMALLOC_OVERRUN_CHECK_SIZE + sizeof (size_t)		\
      + XMALLOC_HEADER_ALIGNMENT - 1)				\
     / XMALLOC_HEADER_ALIGNMENT * XMALLOC_HEADER_ALIGNMENT)	\
    - XMALLOC_OVERRUN_CHECK_SIZE)

static char const xmalloc_overrun_check_header[XMALLOC_OVERRUN_CHECK_SIZE] =
  { '\x9a', '\x9b', '\xae', '\xaf',
    '\xbf', '\xbe', '\xce', '\xcf',
    '\xea', '\xeb', '\xec', '\xed',
    '\xdf', '\xde', '\x9c', '\x9d' };

static char const xmalloc_overrun_check_trailer[XMALLOC_OVERRUN_CHECK_SIZE] =
  { '\xaa', '\xab', '\xac', '\xad',
    '\xba', '\xbb', '\xbc', '\xbd',
    '\xca', '\xcb', '\xcc', '\xcd',
    '\xda', '\xdb', '\xdc', '\xdd' };

/* Insert and extract the block size in the header.  */

static void
xmalloc_put_size (unsigned char *ptr, size_t size)
{
  int i;
  for (i = 0; i < XMALLOC_OVERRUN_SIZE_SIZE; i++)
    {
      *--ptr = size & ((1 << CHAR_BIT) - 1);
      size >>= CHAR_BIT;
    }
}

static size_t
xmalloc_get_size (unsigned char *ptr)
{
  size_t size = 0;
  int i;
  ptr -= XMALLOC_OVERRUN_SIZE_SIZE;
  for (i = 0; i < XMALLOC_OVERRUN_SIZE_SIZE; i++)
    {
      size <<= CHAR_BIT;
      size += *ptr++;
    }
  return size;
}


/* Like malloc, but wraps allocated block with header and trailer.  */

static void *
overrun_check_malloc (size_t size)
{
  register unsigned char *val;
  if (SIZE_MAX - XMALLOC_OVERRUN_CHECK_OVERHEAD < size)
    emacs_abort ();

  val = malloc (size + XMALLOC_OVERRUN_CHECK_OVERHEAD);
  if (val)
    {
      memcpy (val, xmalloc_overrun_check_header, XMALLOC_OVERRUN_CHECK_SIZE);
      val += XMALLOC_OVERRUN_CHECK_SIZE + XMALLOC_OVERRUN_SIZE_SIZE;
      xmalloc_put_size (val, size);
      memcpy (val + size, xmalloc_overrun_check_trailer,
	      XMALLOC_OVERRUN_CHECK_SIZE);
    }
  return val;
}


/* Like realloc, but checks old block for overrun, and wraps new block
   with header and trailer.  */

static void *
overrun_check_realloc (void *block, size_t size)
{
  register unsigned char *val = (unsigned char *) block;
  if (SIZE_MAX - XMALLOC_OVERRUN_CHECK_OVERHEAD < size)
    emacs_abort ();

  if (val
      && memcmp (xmalloc_overrun_check_header,
		 val - XMALLOC_OVERRUN_CHECK_SIZE - XMALLOC_OVERRUN_SIZE_SIZE,
		 XMALLOC_OVERRUN_CHECK_SIZE) == 0)
    {
      size_t osize = xmalloc_get_size (val);
      if (memcmp (xmalloc_overrun_check_trailer, val + osize,
		  XMALLOC_OVERRUN_CHECK_SIZE))
	emacs_abort ();
      memset (val + osize, 0, XMALLOC_OVERRUN_CHECK_SIZE);
      val -= XMALLOC_OVERRUN_CHECK_SIZE + XMALLOC_OVERRUN_SIZE_SIZE;
      memset (val, 0, XMALLOC_OVERRUN_CHECK_SIZE + XMALLOC_OVERRUN_SIZE_SIZE);
    }

  val = realloc (val, size + XMALLOC_OVERRUN_CHECK_OVERHEAD);

  if (val)
    {
      memcpy (val, xmalloc_overrun_check_header, XMALLOC_OVERRUN_CHECK_SIZE);
      val += XMALLOC_OVERRUN_CHECK_SIZE + XMALLOC_OVERRUN_SIZE_SIZE;
      xmalloc_put_size (val, size);
      memcpy (val + size, xmalloc_overrun_check_trailer,
	      XMALLOC_OVERRUN_CHECK_SIZE);
    }
  return val;
}

/* Like free, but checks block for overrun.  */

static void
overrun_check_free (void *block)
{
  unsigned char *val = (unsigned char *) block;

  if (val
      && memcmp (xmalloc_overrun_check_header,
		 val - XMALLOC_OVERRUN_CHECK_SIZE - XMALLOC_OVERRUN_SIZE_SIZE,
		 XMALLOC_OVERRUN_CHECK_SIZE) == 0)
    {
      size_t osize = xmalloc_get_size (val);
      if (memcmp (xmalloc_overrun_check_trailer, val + osize,
		  XMALLOC_OVERRUN_CHECK_SIZE))
	emacs_abort ();
#ifdef XMALLOC_CLEAR_FREE_MEMORY
      val -= XMALLOC_OVERRUN_CHECK_SIZE + XMALLOC_OVERRUN_SIZE_SIZE;
      memset (val, 0xff, osize + XMALLOC_OVERRUN_CHECK_OVERHEAD);
#else
      memset (val + osize, 0, XMALLOC_OVERRUN_CHECK_SIZE);
      val -= XMALLOC_OVERRUN_CHECK_SIZE + XMALLOC_OVERRUN_SIZE_SIZE;
      memset (val, 0, XMALLOC_OVERRUN_CHECK_SIZE + XMALLOC_OVERRUN_SIZE_SIZE);
#endif
    }

  free (val);
}

#undef malloc
#undef realloc
#undef free
#define malloc overrun_check_malloc
#define realloc overrun_check_realloc
#define free overrun_check_free
#endif

/* If compiled with XMALLOC_BLOCK_INPUT_CHECK, define a symbol
   BLOCK_INPUT_IN_MEMORY_ALLOCATORS that is visible to the debugger.
   If that variable is set, block input while in one of Emacs's memory
   allocation functions.  There should be no need for this debugging
   option, since signal handlers do not allocate memory, but Emacs
   formerly allocated memory in signal handlers and this compile-time
   option remains as a way to help debug the issue should it rear its
   ugly head again.  */
#ifdef XMALLOC_BLOCK_INPUT_CHECK
bool block_input_in_memory_allocators EXTERNALLY_VISIBLE;
static void
malloc_block_input (void)
{
  if (block_input_in_memory_allocators)
    block_input ();
}
static void
malloc_unblock_input (void)
{
  if (block_input_in_memory_allocators)
    unblock_input ();
}
# define MALLOC_BLOCK_INPUT malloc_block_input ()
# define MALLOC_UNBLOCK_INPUT malloc_unblock_input ()
#else
# define MALLOC_BLOCK_INPUT ((void) 0)
# define MALLOC_UNBLOCK_INPUT ((void) 0)
#endif

#define MALLOC_PROBE(size)			\
  do {						\
    if (profiler_memory_running)		\
      malloc_probe (size);			\
  } while (0)


/* Like malloc but check for no memory and block interrupt input..  */

void *
xmalloc (size_t size)
{
  void *val;

  MALLOC_BLOCK_INPUT;
  val = malloc (size);
  MALLOC_UNBLOCK_INPUT;

  if (!val && size)
    memory_full (size);
  MALLOC_PROBE (size);
  return val;
}

/* Like the above, but zeroes out the memory just allocated.  */

void *
xzalloc (size_t size)
{
  void *val;

  MALLOC_BLOCK_INPUT;
  val = malloc (size);
  MALLOC_UNBLOCK_INPUT;

  if (!val && size)
    memory_full (size);
  memset (val, 0, size);
  MALLOC_PROBE (size);
  return val;
}

/* Like realloc but check for no memory and block interrupt input..  */

void *
xrealloc (void *block, size_t size)
{
  void *val;

  MALLOC_BLOCK_INPUT;
  /* We must call malloc explicitly when BLOCK is 0, since some
     reallocs don't do this.  */
  if (! block)
    val = malloc (size);
  else
    val = realloc (block, size);
  MALLOC_UNBLOCK_INPUT;

  if (!val && size)
    memory_full (size);
  MALLOC_PROBE (size);
  return val;
}


/* Like free but block interrupt input.  */

void
xfree (void *block)
{
  if (!block)
    return;
  MALLOC_BLOCK_INPUT;
  free (block);
  MALLOC_UNBLOCK_INPUT;
  /* We don't call refill_memory_reserve here
     because in practice the call in r_alloc_free seems to suffice.  */
}


/* Other parts of Emacs pass large int values to allocator functions
   expecting ptrdiff_t.  This is portable in practice, but check it to
   be safe.  */
verify (INT_MAX <= PTRDIFF_MAX);


/* Allocate an array of NITEMS items, each of size ITEM_SIZE.
   Signal an error on memory exhaustion, and block interrupt input.  */

void *
xnmalloc (ptrdiff_t nitems, ptrdiff_t item_size)
{
  eassert (0 <= nitems && 0 < item_size);
  if (min (PTRDIFF_MAX, SIZE_MAX) / item_size < nitems)
    memory_full (SIZE_MAX);
  return xmalloc (nitems * item_size);
}


/* Reallocate an array PA to make it of NITEMS items, each of size ITEM_SIZE.
   Signal an error on memory exhaustion, and block interrupt input.  */

void *
xnrealloc (void *pa, ptrdiff_t nitems, ptrdiff_t item_size)
{
  eassert (0 <= nitems && 0 < item_size);
  if (min (PTRDIFF_MAX, SIZE_MAX) / item_size < nitems)
    memory_full (SIZE_MAX);
  return xrealloc (pa, nitems * item_size);
}


/* Grow PA, which points to an array of *NITEMS items, and return the
   location of the reallocated array, updating *NITEMS to reflect its
   new size.  The new array will contain at least NITEMS_INCR_MIN more
   items, but will not contain more than NITEMS_MAX items total.
   ITEM_SIZE is the size of each item, in bytes.

   ITEM_SIZE and NITEMS_INCR_MIN must be positive.  *NITEMS must be
   nonnegative.  If NITEMS_MAX is -1, it is treated as if it were
   infinity.

   If PA is null, then allocate a new array instead of reallocating
   the old one.

   Block interrupt input as needed.  If memory exhaustion occurs, set
   *NITEMS to zero if PA is null, and signal an error (i.e., do not
   return).

   Thus, to grow an array A without saving its old contents, do
   { xfree (A); A = NULL; A = xpalloc (NULL, &AITEMS, ...); }.
   The A = NULL avoids a dangling pointer if xpalloc exhausts memory
   and signals an error, and later this code is reexecuted and
   attempts to free A.  */

void *
xpalloc (void *pa, ptrdiff_t *nitems, ptrdiff_t nitems_incr_min,
	 ptrdiff_t nitems_max, ptrdiff_t item_size)
{
  /* The approximate size to use for initial small allocation
     requests.  This is the largest "small" request for the GNU C
     library malloc.  */
  enum { DEFAULT_MXFAST = 64 * sizeof (size_t) / 4 };

  /* If the array is tiny, grow it to about (but no greater than)
     DEFAULT_MXFAST bytes.  Otherwise, grow it by about 50%.  */
  ptrdiff_t n = *nitems;
  ptrdiff_t tiny_max = DEFAULT_MXFAST / item_size - n;
  ptrdiff_t half_again = n >> 1;
  ptrdiff_t incr_estimate = max (tiny_max, half_again);

  /* Adjust the increment according to three constraints: NITEMS_INCR_MIN,
     NITEMS_MAX, and what the C language can represent safely.  */
  ptrdiff_t C_language_max = min (PTRDIFF_MAX, SIZE_MAX) / item_size;
  ptrdiff_t n_max = (0 <= nitems_max && nitems_max < C_language_max
		     ? nitems_max : C_language_max);
  ptrdiff_t nitems_incr_max = n_max - n;
  ptrdiff_t incr = max (nitems_incr_min, min (incr_estimate, nitems_incr_max));

  eassert (0 < item_size && 0 < nitems_incr_min && 0 <= n && -1 <= nitems_max);
  if (! pa)
    *nitems = 0;
  if (nitems_incr_max < incr)
    memory_full (SIZE_MAX);
  n += incr;
  pa = xrealloc (pa, n * item_size);
  *nitems = n;
  return pa;
}


/* Like strdup, but uses xmalloc.  */

char *
xstrdup (const char *s)
{
  size_t len = strlen (s) + 1;
  char *p = xmalloc (len);
  memcpy (p, s, len);
  return p;
}

/* Like putenv, but (1) use the equivalent of xmalloc and (2) the
   argument is a const pointer.  */

void
xputenv (char const *string)
{
  if (putenv ((char *) string) != 0)
    memory_full (0);
}

/* Unwind for SAFE_ALLOCA */

Lisp_Object
safe_alloca_unwind (Lisp_Object arg)
{
  free_save_value (arg);
  return Qnil;
}

/* Return a newly allocated memory block of SIZE bytes, remembering
   to free it when unwinding.  */
void *
record_xmalloc (size_t size)
{
  void *p = xmalloc (size);
  record_unwind_protect (safe_alloca_unwind, make_save_value (p, 0));
  return p;
}


/* Like malloc but used for allocating Lisp data.  NBYTES is the
   number of bytes to allocate, TYPE describes the intended use of the
   allocated memory block (for strings, for conses, ...).  */

#if ! USE_LSB_TAG
void *lisp_malloc_loser EXTERNALLY_VISIBLE;
#endif

static void *
lisp_malloc (size_t nbytes, enum mem_type type)
{
  register void *val;

  MALLOC_BLOCK_INPUT;

#ifdef GC_MALLOC_CHECK
  allocated_mem_type = type;
#endif

  val = malloc (nbytes);

#if ! USE_LSB_TAG
  /* If the memory just allocated cannot be addressed thru a Lisp
     object's pointer, and it needs to be,
     that's equivalent to running out of memory.  */
  if (val && type != MEM_TYPE_NON_LISP)
    {
      Lisp_Object tem;
      XSETCONS (tem, (char *) val + nbytes - 1);
      if ((char *) XCONS (tem) != (char *) val + nbytes - 1)
	{
	  lisp_malloc_loser = val;
	  free (val);
	  val = 0;
	}
    }
#endif

#if GC_MARK_STACK && !defined GC_MALLOC_CHECK
  if (val && type != MEM_TYPE_NON_LISP)
    mem_insert (val, (char *) val + nbytes, type);
#endif

  MALLOC_UNBLOCK_INPUT;
  if (!val && nbytes)
    memory_full (nbytes);
  MALLOC_PROBE (nbytes);
  return val;
}

/* Free BLOCK.  This must be called to free memory allocated with a
   call to lisp_malloc.  */

static void
lisp_free (void *block)
{
  MALLOC_BLOCK_INPUT;
  free (block);
#if GC_MARK_STACK && !defined GC_MALLOC_CHECK
  mem_delete (mem_find (block));
#endif
  MALLOC_UNBLOCK_INPUT;
}

/*****  Allocation of aligned blocks of memory to store Lisp data.  *****/

/* The entry point is lisp_align_malloc which returns blocks of at most
   BLOCK_BYTES and guarantees they are aligned on a BLOCK_ALIGN boundary.  */

#if defined (HAVE_POSIX_MEMALIGN) && defined (SYSTEM_MALLOC)
#define USE_POSIX_MEMALIGN 1
#endif

/* BLOCK_ALIGN has to be a power of 2.  */
#define BLOCK_ALIGN (1 << 10)

/* Padding to leave at the end of a malloc'd block.  This is to give
   malloc a chance to minimize the amount of memory wasted to alignment.
   It should be tuned to the particular malloc library used.
   On glibc-2.3.2, malloc never tries to align, so a padding of 0 is best.
   posix_memalign on the other hand would ideally prefer a value of 4
   because otherwise, there's 1020 bytes wasted between each ablocks.
   In Emacs, testing shows that those 1020 can most of the time be
   efficiently used by malloc to place other objects, so a value of 0 can
   still preferable unless you have a lot of aligned blocks and virtually
   nothing else.  */
#define BLOCK_PADDING 0
#define BLOCK_BYTES \
  (BLOCK_ALIGN - sizeof (struct ablocks *) - BLOCK_PADDING)

/* Internal data structures and constants.  */

#define ABLOCKS_SIZE 16

/* An aligned block of memory.  */
struct ablock
{
  union
  {
    char payload[BLOCK_BYTES];
    struct ablock *next_free;
  } x;
  /* `abase' is the aligned base of the ablocks.  */
  /* It is overloaded to hold the virtual `busy' field that counts
     the number of used ablock in the parent ablocks.
     The first ablock has the `busy' field, the others have the `abase'
     field.  To tell the difference, we assume that pointers will have
     integer values larger than 2 * ABLOCKS_SIZE.  The lowest bit of `busy'
     is used to tell whether the real base of the parent ablocks is `abase'
     (if not, the word before the first ablock holds a pointer to the
     real base).  */
  struct ablocks *abase;
  /* The padding of all but the last ablock is unused.  The padding of
     the last ablock in an ablocks is not allocated.  */
#if BLOCK_PADDING
  char padding[BLOCK_PADDING];
#endif
};

/* A bunch of consecutive aligned blocks.  */
struct ablocks
{
  struct ablock blocks[ABLOCKS_SIZE];
};

/* Size of the block requested from malloc or posix_memalign.  */
#define ABLOCKS_BYTES (sizeof (struct ablocks) - BLOCK_PADDING)

#define ABLOCK_ABASE(block) \
  (((uintptr_t) (block)->abase) <= (1 + 2 * ABLOCKS_SIZE)	\
   ? (struct ablocks *)(block)					\
   : (block)->abase)

/* Virtual `busy' field.  */
#define ABLOCKS_BUSY(abase) ((abase)->blocks[0].abase)

/* Pointer to the (not necessarily aligned) malloc block.  */
#ifdef USE_POSIX_MEMALIGN
#define ABLOCKS_BASE(abase) (abase)
#else
#define ABLOCKS_BASE(abase) \
  (1 & (intptr_t) ABLOCKS_BUSY (abase) ? abase : ((void**)abase)[-1])
#endif

/* The list of free ablock.   */
static struct ablock *free_ablock;

/* Allocate an aligned block of nbytes.
   Alignment is on a multiple of BLOCK_ALIGN and `nbytes' has to be
   smaller or equal to BLOCK_BYTES.  */
static void *
lisp_align_malloc (size_t nbytes, enum mem_type type)
{
  void *base, *val;
  struct ablocks *abase;

  eassert (nbytes <= BLOCK_BYTES);

  MALLOC_BLOCK_INPUT;

#ifdef GC_MALLOC_CHECK
  allocated_mem_type = type;
#endif

  if (!free_ablock)
    {
      int i;
      intptr_t aligned; /* int gets warning casting to 64-bit pointer.  */

#ifdef DOUG_LEA_MALLOC
      /* Prevent mmap'ing the chunk.  Lisp data may not be mmap'ed
	 because mapped region contents are not preserved in
	 a dumped Emacs.  */
      mallopt (M_MMAP_MAX, 0);
#endif

#ifdef USE_POSIX_MEMALIGN
      {
	int err = posix_memalign (&base, BLOCK_ALIGN, ABLOCKS_BYTES);
	if (err)
	  base = NULL;
	abase = base;
      }
#else
      base = malloc (ABLOCKS_BYTES);
      abase = ALIGN (base, BLOCK_ALIGN);
#endif

      if (base == 0)
	{
	  MALLOC_UNBLOCK_INPUT;
	  memory_full (ABLOCKS_BYTES);
	}

      aligned = (base == abase);
      if (!aligned)
	((void**)abase)[-1] = base;

#ifdef DOUG_LEA_MALLOC
      /* Back to a reasonable maximum of mmap'ed areas.  */
      mallopt (M_MMAP_MAX, MMAP_MAX_AREAS);
#endif

#if ! USE_LSB_TAG
      /* If the memory just allocated cannot be addressed thru a Lisp
	 object's pointer, and it needs to be, that's equivalent to
	 running out of memory.  */
      if (type != MEM_TYPE_NON_LISP)
	{
	  Lisp_Object tem;
	  char *end = (char *) base + ABLOCKS_BYTES - 1;
	  XSETCONS (tem, end);
	  if ((char *) XCONS (tem) != end)
	    {
	      lisp_malloc_loser = base;
	      free (base);
	      MALLOC_UNBLOCK_INPUT;
	      memory_full (SIZE_MAX);
	    }
	}
#endif

      /* Initialize the blocks and put them on the free list.
	 If `base' was not properly aligned, we can't use the last block.  */
      for (i = 0; i < (aligned ? ABLOCKS_SIZE : ABLOCKS_SIZE - 1); i++)
	{
	  abase->blocks[i].abase = abase;
	  abase->blocks[i].x.next_free = free_ablock;
	  free_ablock = &abase->blocks[i];
	}
      ABLOCKS_BUSY (abase) = (struct ablocks *) aligned;

      eassert (0 == ((uintptr_t) abase) % BLOCK_ALIGN);
      eassert (ABLOCK_ABASE (&abase->blocks[3]) == abase); /* 3 is arbitrary */
      eassert (ABLOCK_ABASE (&abase->blocks[0]) == abase);
      eassert (ABLOCKS_BASE (abase) == base);
      eassert (aligned == (intptr_t) ABLOCKS_BUSY (abase));
    }

  abase = ABLOCK_ABASE (free_ablock);
  ABLOCKS_BUSY (abase) =
    (struct ablocks *) (2 + (intptr_t) ABLOCKS_BUSY (abase));
  val = free_ablock;
  free_ablock = free_ablock->x.next_free;

#if GC_MARK_STACK && !defined GC_MALLOC_CHECK
  if (type != MEM_TYPE_NON_LISP)
    mem_insert (val, (char *) val + nbytes, type);
#endif

  MALLOC_UNBLOCK_INPUT;

  MALLOC_PROBE (nbytes);

  eassert (0 == ((uintptr_t) val) % BLOCK_ALIGN);
  return val;
}

static void
lisp_align_free (void *block)
{
  struct ablock *ablock = block;
  struct ablocks *abase = ABLOCK_ABASE (ablock);

  MALLOC_BLOCK_INPUT;
#if GC_MARK_STACK && !defined GC_MALLOC_CHECK
  mem_delete (mem_find (block));
#endif
  /* Put on free list.  */
  ablock->x.next_free = free_ablock;
  free_ablock = ablock;
  /* Update busy count.  */
  ABLOCKS_BUSY (abase)
    = (struct ablocks *) (-2 + (intptr_t) ABLOCKS_BUSY (abase));

  if (2 > (intptr_t) ABLOCKS_BUSY (abase))
    { /* All the blocks are free.  */
      int i = 0, aligned = (intptr_t) ABLOCKS_BUSY (abase);
      struct ablock **tem = &free_ablock;
      struct ablock *atop = &abase->blocks[aligned ? ABLOCKS_SIZE : ABLOCKS_SIZE - 1];

      while (*tem)
	{
	  if (*tem >= (struct ablock *) abase && *tem < atop)
	    {
	      i++;
	      *tem = (*tem)->x.next_free;
	    }
	  else
	    tem = &(*tem)->x.next_free;
	}
      eassert ((aligned & 1) == aligned);
      eassert (i == (aligned ? ABLOCKS_SIZE : ABLOCKS_SIZE - 1));
#ifdef USE_POSIX_MEMALIGN
      eassert ((uintptr_t) ABLOCKS_BASE (abase) % BLOCK_ALIGN == 0);
#endif
      free (ABLOCKS_BASE (abase));
    }
  MALLOC_UNBLOCK_INPUT;
}


/***********************************************************************
			 Interval Allocation
 ***********************************************************************/

/* Number of intervals allocated in an interval_block structure.
   The 1020 is 1024 minus malloc overhead.  */

#define INTERVAL_BLOCK_SIZE \
  ((1020 - sizeof (struct interval_block *)) / sizeof (struct interval))

/* Intervals are allocated in chunks in form of an interval_block
   structure.  */

struct interval_block
{
  /* Place `intervals' first, to preserve alignment.  */
  struct interval intervals[INTERVAL_BLOCK_SIZE];
  struct interval_block *next;
};

/* Current interval block.  Its `next' pointer points to older
   blocks.  */

static struct interval_block *interval_block;

/* Index in interval_block above of the next unused interval
   structure.  */

static int interval_block_index = INTERVAL_BLOCK_SIZE;

/* Number of free and live intervals.  */

static EMACS_INT total_free_intervals, total_intervals;

/* List of free intervals.  */

static INTERVAL interval_free_list;

/* Return a new interval.  */

INTERVAL
make_interval (void)
{
  INTERVAL val;

  MALLOC_BLOCK_INPUT;

  if (interval_free_list)
    {
      val = interval_free_list;
      interval_free_list = INTERVAL_PARENT (interval_free_list);
    }
  else
    {
      if (interval_block_index == INTERVAL_BLOCK_SIZE)
	{
	  struct interval_block *newi
	    = lisp_malloc (sizeof *newi, MEM_TYPE_NON_LISP);

	  newi->next = interval_block;
	  interval_block = newi;
	  interval_block_index = 0;
	  total_free_intervals += INTERVAL_BLOCK_SIZE;
	}
      val = &interval_block->intervals[interval_block_index++];
    }

  MALLOC_UNBLOCK_INPUT;

  consing_since_gc += sizeof (struct interval);
  intervals_consed++;
  total_free_intervals--;
  RESET_INTERVAL (val);
  val->gcmarkbit = 0;
  return val;
}


/* Mark Lisp objects in interval I.  */

static void
mark_interval (register INTERVAL i, Lisp_Object dummy)
{
  /* Intervals should never be shared.  So, if extra internal checking is
     enabled, GC aborts if it seems to have visited an interval twice.  */
  eassert (!i->gcmarkbit);
  i->gcmarkbit = 1;
  mark_object (i->plist);
}

/* Mark the interval tree rooted in I.  */

#define MARK_INTERVAL_TREE(i)					\
  do {								\
    if (i && !i->gcmarkbit)					\
      traverse_intervals_noorder (i, mark_interval, Qnil);	\
  } while (0)

/***********************************************************************
			  String Allocation
 ***********************************************************************/

/* Lisp_Strings are allocated in string_block structures.  When a new
   string_block is allocated, all the Lisp_Strings it contains are
   added to a free-list string_free_list.  When a new Lisp_String is
   needed, it is taken from that list.  During the sweep phase of GC,
   string_blocks that are entirely free are freed, except two which
   we keep.

   String data is allocated from sblock structures.  Strings larger
   than LARGE_STRING_BYTES, get their own sblock, data for smaller
   strings is sub-allocated out of sblocks of size SBLOCK_SIZE.

   Sblocks consist internally of sdata structures, one for each
   Lisp_String.  The sdata structure points to the Lisp_String it
   belongs to.  The Lisp_String points back to the `u.data' member of
   its sdata structure.

   When a Lisp_String is freed during GC, it is put back on
   string_free_list, and its `data' member and its sdata's `string'
   pointer is set to null.  The size of the string is recorded in the
   `u.nbytes' member of the sdata.  So, sdata structures that are no
   longer used, can be easily recognized, and it's easy to compact the
   sblocks of small strings which we do in compact_small_strings.  */

/* Size in bytes of an sblock structure used for small strings.  This
   is 8192 minus malloc overhead.  */

#define SBLOCK_SIZE 8188

/* Strings larger than this are considered large strings.  String data
   for large strings is allocated from individual sblocks.  */

#define LARGE_STRING_BYTES 1024

/* Structure describing string memory sub-allocated from an sblock.
   This is where the contents of Lisp strings are stored.  */

struct sdata
{
  /* Back-pointer to the string this sdata belongs to.  If null, this
     structure is free, and the NBYTES member of the union below
     contains the string's byte size (the same value that STRING_BYTES
     would return if STRING were non-null).  If non-null, STRING_BYTES
     (STRING) is the size of the data, and DATA contains the string's
     contents.  */
  struct Lisp_String *string;

#ifdef GC_CHECK_STRING_BYTES

  ptrdiff_t nbytes;
  unsigned char data[1];

#define SDATA_NBYTES(S)	(S)->nbytes
#define SDATA_DATA(S)	(S)->data
#define SDATA_SELECTOR(member) member

#else /* not GC_CHECK_STRING_BYTES */

  union
  {
    /* When STRING is non-null.  */
    unsigned char data[1];

    /* When STRING is null.  */
    ptrdiff_t nbytes;
  } u;

#define SDATA_NBYTES(S)	(S)->u.nbytes
#define SDATA_DATA(S)	(S)->u.data
#define SDATA_SELECTOR(member) u.member

#endif /* not GC_CHECK_STRING_BYTES */

#define SDATA_DATA_OFFSET offsetof (struct sdata, SDATA_SELECTOR (data))
};


/* Structure describing a block of memory which is sub-allocated to
   obtain string data memory for strings.  Blocks for small strings
   are of fixed size SBLOCK_SIZE.  Blocks for large strings are made
   as large as needed.  */

struct sblock
{
  /* Next in list.  */
  struct sblock *next;

  /* Pointer to the next free sdata block.  This points past the end
     of the sblock if there isn't any space left in this block.  */
  struct sdata *next_free;

  /* Start of data.  */
  struct sdata first_data;
};

/* Number of Lisp strings in a string_block structure.  The 1020 is
   1024 minus malloc overhead.  */

#define STRING_BLOCK_SIZE \
  ((1020 - sizeof (struct string_block *)) / sizeof (struct Lisp_String))

/* Structure describing a block from which Lisp_String structures
   are allocated.  */

struct string_block
{
  /* Place `strings' first, to preserve alignment.  */
  struct Lisp_String strings[STRING_BLOCK_SIZE];
  struct string_block *next;
};

/* Head and tail of the list of sblock structures holding Lisp string
   data.  We always allocate from current_sblock.  The NEXT pointers
   in the sblock structures go from oldest_sblock to current_sblock.  */

static struct sblock *oldest_sblock, *current_sblock;

/* List of sblocks for large strings.  */

static struct sblock *large_sblocks;

/* List of string_block structures.  */

static struct string_block *string_blocks;

/* Free-list of Lisp_Strings.  */

static struct Lisp_String *string_free_list;

/* Number of live and free Lisp_Strings.  */

static EMACS_INT total_strings, total_free_strings;

/* Number of bytes used by live strings.  */

static EMACS_INT total_string_bytes;

/* Given a pointer to a Lisp_String S which is on the free-list
   string_free_list, return a pointer to its successor in the
   free-list.  */

#define NEXT_FREE_LISP_STRING(S) (*(struct Lisp_String **) (S))

/* Return a pointer to the sdata structure belonging to Lisp string S.
   S must be live, i.e. S->data must not be null.  S->data is actually
   a pointer to the `u.data' member of its sdata structure; the
   structure starts at a constant offset in front of that.  */

#define SDATA_OF_STRING(S) ((struct sdata *) ((S)->data - SDATA_DATA_OFFSET))


#ifdef GC_CHECK_STRING_OVERRUN

/* We check for overrun in string data blocks by appending a small
   "cookie" after each allocated string data block, and check for the
   presence of this cookie during GC.  */

#define GC_STRING_OVERRUN_COOKIE_SIZE	4
static char const string_overrun_cookie[GC_STRING_OVERRUN_COOKIE_SIZE] =
  { '\xde', '\xad', '\xbe', '\xef' };

#else
#define GC_STRING_OVERRUN_COOKIE_SIZE 0
#endif

/* Value is the size of an sdata structure large enough to hold NBYTES
   bytes of string data.  The value returned includes a terminating
   NUL byte, the size of the sdata structure, and padding.  */

#ifdef GC_CHECK_STRING_BYTES

#define SDATA_SIZE(NBYTES)			\
     ((SDATA_DATA_OFFSET			\
       + (NBYTES) + 1				\
       + sizeof (ptrdiff_t) - 1)		\
      & ~(sizeof (ptrdiff_t) - 1))

#else /* not GC_CHECK_STRING_BYTES */

/* The 'max' reserves space for the nbytes union member even when NBYTES + 1 is
   less than the size of that member.  The 'max' is not needed when
   SDATA_DATA_OFFSET is a multiple of sizeof (ptrdiff_t), because then the
   alignment code reserves enough space.  */

#define SDATA_SIZE(NBYTES)				      \
     ((SDATA_DATA_OFFSET				      \
       + (SDATA_DATA_OFFSET % sizeof (ptrdiff_t) == 0	      \
	  ? NBYTES					      \
	  : max (NBYTES, sizeof (ptrdiff_t) - 1))	      \
       + 1						      \
       + sizeof (ptrdiff_t) - 1)			      \
      & ~(sizeof (ptrdiff_t) - 1))

#endif /* not GC_CHECK_STRING_BYTES */

/* Extra bytes to allocate for each string.  */

#define GC_STRING_EXTRA (GC_STRING_OVERRUN_COOKIE_SIZE)

/* Exact bound on the number of bytes in a string, not counting the
   terminating null.  A string cannot contain more bytes than
   STRING_BYTES_BOUND, nor can it be so long that the size_t
   arithmetic in allocate_string_data would overflow while it is
   calculating a value to be passed to malloc.  */
static ptrdiff_t const STRING_BYTES_MAX =
  min (STRING_BYTES_BOUND,
       ((SIZE_MAX - XMALLOC_OVERRUN_CHECK_OVERHEAD
	 - GC_STRING_EXTRA
	 - offsetof (struct sblock, first_data)
	 - SDATA_DATA_OFFSET)
	& ~(sizeof (EMACS_INT) - 1)));

/* Initialize string allocation.  Called from init_alloc_once.  */

static void
init_strings (void)
{
  empty_unibyte_string = make_pure_string ("", 0, 0, 0);
  empty_multibyte_string = make_pure_string ("", 0, 0, 1);
}


#ifdef GC_CHECK_STRING_BYTES

static int check_string_bytes_count;

/* Like STRING_BYTES, but with debugging check.  Can be
   called during GC, so pay attention to the mark bit.  */

ptrdiff_t
string_bytes (struct Lisp_String *s)
{
  ptrdiff_t nbytes =
    (s->size_byte < 0 ? s->size & ~ARRAY_MARK_FLAG : s->size_byte);

  if (!PURE_POINTER_P (s)
      && s->data
      && nbytes != SDATA_NBYTES (SDATA_OF_STRING (s)))
    emacs_abort ();
  return nbytes;
}

/* Check validity of Lisp strings' string_bytes member in B.  */

static void
check_sblock (struct sblock *b)
{
  struct sdata *from, *end, *from_end;

  end = b->next_free;

  for (from = &b->first_data; from < end; from = from_end)
    {
      /* Compute the next FROM here because copying below may
	 overwrite data we need to compute it.  */
      ptrdiff_t nbytes;

      /* Check that the string size recorded in the string is the
	 same as the one recorded in the sdata structure.  */
      nbytes = SDATA_SIZE (from->string ? string_bytes (from->string)
			   : SDATA_NBYTES (from));
      from_end = (struct sdata *) ((char *) from + nbytes + GC_STRING_EXTRA);
    }
}


/* Check validity of Lisp strings' string_bytes member.  ALL_P
   means check all strings, otherwise check only most
   recently allocated strings.  Used for hunting a bug.  */

static void
check_string_bytes (bool all_p)
{
  if (all_p)
    {
      struct sblock *b;

      for (b = large_sblocks; b; b = b->next)
	{
	  struct Lisp_String *s = b->first_data.string;
	  if (s)
	    string_bytes (s);
	}

      for (b = oldest_sblock; b; b = b->next)
	check_sblock (b);
    }
  else if (current_sblock)
    check_sblock (current_sblock);
}

#else /* not GC_CHECK_STRING_BYTES */

#define check_string_bytes(all) ((void) 0)

#endif /* GC_CHECK_STRING_BYTES */

#ifdef GC_CHECK_STRING_FREE_LIST

/* Walk through the string free list looking for bogus next pointers.
   This may catch buffer overrun from a previous string.  */

static void
check_string_free_list (void)
{
  struct Lisp_String *s;

  /* Pop a Lisp_String off the free-list.  */
  s = string_free_list;
  while (s != NULL)
    {
      if ((uintptr_t) s < 1024)
	emacs_abort ();
      s = NEXT_FREE_LISP_STRING (s);
    }
}
#else
#define check_string_free_list()
#endif

/* Return a new Lisp_String.  */

static struct Lisp_String *
allocate_string (void)
{
  struct Lisp_String *s;

  MALLOC_BLOCK_INPUT;

  /* If the free-list is empty, allocate a new string_block, and
     add all the Lisp_Strings in it to the free-list.  */
  if (string_free_list == NULL)
    {
      struct string_block *b = lisp_malloc (sizeof *b, MEM_TYPE_STRING);
      int i;

      b->next = string_blocks;
      string_blocks = b;

      for (i = STRING_BLOCK_SIZE - 1; i >= 0; --i)
	{
	  s = b->strings + i;
	  /* Every string on a free list should have NULL data pointer.  */
	  s->data = NULL;
	  NEXT_FREE_LISP_STRING (s) = string_free_list;
	  string_free_list = s;
	}

      total_free_strings += STRING_BLOCK_SIZE;
    }

  check_string_free_list ();

  /* Pop a Lisp_String off the free-list.  */
  s = string_free_list;
  string_free_list = NEXT_FREE_LISP_STRING (s);

  MALLOC_UNBLOCK_INPUT;

  --total_free_strings;
  ++total_strings;
  ++strings_consed;
  consing_since_gc += sizeof *s;

#ifdef GC_CHECK_STRING_BYTES
  if (!noninteractive)
    {
      if (++check_string_bytes_count == 200)
	{
	  check_string_bytes_count = 0;
	  check_string_bytes (1);
	}
      else
	check_string_bytes (0);
    }
#endif /* GC_CHECK_STRING_BYTES */

  return s;
}


/* Set up Lisp_String S for holding NCHARS characters, NBYTES bytes,
   plus a NUL byte at the end.  Allocate an sdata structure for S, and
   set S->data to its `u.data' member.  Store a NUL byte at the end of
   S->data.  Set S->size to NCHARS and S->size_byte to NBYTES.  Free
   S->data if it was initially non-null.  */

void
allocate_string_data (struct Lisp_String *s,
		      EMACS_INT nchars, EMACS_INT nbytes)
{
  struct sdata *data, *old_data;
  struct sblock *b;
  ptrdiff_t needed, old_nbytes;

  if (STRING_BYTES_MAX < nbytes)
    string_overflow ();

  /* Determine the number of bytes needed to store NBYTES bytes
     of string data.  */
  needed = SDATA_SIZE (nbytes);
  if (s->data)
    {
      old_data = SDATA_OF_STRING (s);
      old_nbytes = STRING_BYTES (s);
    }
  else
    old_data = NULL;

  MALLOC_BLOCK_INPUT;

  if (nbytes > LARGE_STRING_BYTES)
    {
      size_t size = offsetof (struct sblock, first_data) + needed;

#ifdef DOUG_LEA_MALLOC
      /* Prevent mmap'ing the chunk.  Lisp data may not be mmap'ed
	 because mapped region contents are not preserved in
	 a dumped Emacs.

         In case you think of allowing it in a dumped Emacs at the
         cost of not being able to re-dump, there's another reason:
         mmap'ed data typically have an address towards the top of the
         address space, which won't fit into an EMACS_INT (at least on
         32-bit systems with the current tagging scheme).  --fx  */
      mallopt (M_MMAP_MAX, 0);
#endif

      b = lisp_malloc (size + GC_STRING_EXTRA, MEM_TYPE_NON_LISP);

#ifdef DOUG_LEA_MALLOC
      /* Back to a reasonable maximum of mmap'ed areas. */
      mallopt (M_MMAP_MAX, MMAP_MAX_AREAS);
#endif

      b->next_free = &b->first_data;
      b->first_data.string = NULL;
      b->next = large_sblocks;
      large_sblocks = b;
    }
  else if (current_sblock == NULL
	   || (((char *) current_sblock + SBLOCK_SIZE
		- (char *) current_sblock->next_free)
	       < (needed + GC_STRING_EXTRA)))
    {
      /* Not enough room in the current sblock.  */
      b = lisp_malloc (SBLOCK_SIZE, MEM_TYPE_NON_LISP);
      b->next_free = &b->first_data;
      b->first_data.string = NULL;
      b->next = NULL;

      if (current_sblock)
	current_sblock->next = b;
      else
	oldest_sblock = b;
      current_sblock = b;
    }
  else
    b = current_sblock;

  data = b->next_free;
  b->next_free = (struct sdata *) ((char *) data + needed + GC_STRING_EXTRA);

  MALLOC_UNBLOCK_INPUT;

  data->string = s;
  s->data = SDATA_DATA (data);
#ifdef GC_CHECK_STRING_BYTES
  SDATA_NBYTES (data) = nbytes;
#endif
  s->size = nchars;
  s->size_byte = nbytes;
  s->data[nbytes] = '\0';
#ifdef GC_CHECK_STRING_OVERRUN
  memcpy ((char *) data + needed, string_overrun_cookie,
	  GC_STRING_OVERRUN_COOKIE_SIZE);
#endif

  /* Note that Faset may call to this function when S has already data
     assigned.  In this case, mark data as free by setting it's string
     back-pointer to null, and record the size of the data in it.  */
  if (old_data)
    {
      SDATA_NBYTES (old_data) = old_nbytes;
      old_data->string = NULL;
    }

  consing_since_gc += needed;
}


/* Sweep and compact strings.  */

static void
sweep_strings (void)
{
  struct string_block *b, *next;
  struct string_block *live_blocks = NULL;

  string_free_list = NULL;
  total_strings = total_free_strings = 0;
  total_string_bytes = 0;

  /* Scan strings_blocks, free Lisp_Strings that aren't marked.  */
  for (b = string_blocks; b; b = next)
    {
      int i, nfree = 0;
      struct Lisp_String *free_list_before = string_free_list;

      next = b->next;

      for (i = 0; i < STRING_BLOCK_SIZE; ++i)
	{
	  struct Lisp_String *s = b->strings + i;

	  if (s->data)
	    {
	      /* String was not on free-list before.  */
	      if (STRING_MARKED_P (s))
		{
		  /* String is live; unmark it and its intervals.  */
		  UNMARK_STRING (s);

		  /* Do not use string_(set|get)_intervals here.  */
		  s->intervals = balance_intervals (s->intervals);

		  ++total_strings;
		  total_string_bytes += STRING_BYTES (s);
		}
	      else
		{
		  /* String is dead.  Put it on the free-list.  */
		  struct sdata *data = SDATA_OF_STRING (s);

		  /* Save the size of S in its sdata so that we know
		     how large that is.  Reset the sdata's string
		     back-pointer so that we know it's free.  */
#ifdef GC_CHECK_STRING_BYTES
		  if (string_bytes (s) != SDATA_NBYTES (data))
		    emacs_abort ();
#else
		  data->u.nbytes = STRING_BYTES (s);
#endif
		  data->string = NULL;

		  /* Reset the strings's `data' member so that we
		     know it's free.  */
		  s->data = NULL;

		  /* Put the string on the free-list.  */
		  NEXT_FREE_LISP_STRING (s) = string_free_list;
		  string_free_list = s;
		  ++nfree;
		}
	    }
	  else
	    {
	      /* S was on the free-list before.  Put it there again.  */
	      NEXT_FREE_LISP_STRING (s) = string_free_list;
	      string_free_list = s;
	      ++nfree;
	    }
	}

      /* Free blocks that contain free Lisp_Strings only, except
	 the first two of them.  */
      if (nfree == STRING_BLOCK_SIZE
	  && total_free_strings > STRING_BLOCK_SIZE)
	{
	  lisp_free (b);
	  string_free_list = free_list_before;
	}
      else
	{
	  total_free_strings += nfree;
	  b->next = live_blocks;
	  live_blocks = b;
	}
    }

  check_string_free_list ();

  string_blocks = live_blocks;
  free_large_strings ();
  compact_small_strings ();

  check_string_free_list ();
}


/* Free dead large strings.  */

static void
free_large_strings (void)
{
  struct sblock *b, *next;
  struct sblock *live_blocks = NULL;

  for (b = large_sblocks; b; b = next)
    {
      next = b->next;

      if (b->first_data.string == NULL)
	lisp_free (b);
      else
	{
	  b->next = live_blocks;
	  live_blocks = b;
	}
    }

  large_sblocks = live_blocks;
}


/* Compact data of small strings.  Free sblocks that don't contain
   data of live strings after compaction.  */

static void
compact_small_strings (void)
{
  struct sblock *b, *tb, *next;
  struct sdata *from, *to, *end, *tb_end;
  struct sdata *to_end, *from_end;

  /* TB is the sblock we copy to, TO is the sdata within TB we copy
     to, and TB_END is the end of TB.  */
  tb = oldest_sblock;
  tb_end = (struct sdata *) ((char *) tb + SBLOCK_SIZE);
  to = &tb->first_data;

  /* Step through the blocks from the oldest to the youngest.  We
     expect that old blocks will stabilize over time, so that less
     copying will happen this way.  */
  for (b = oldest_sblock; b; b = b->next)
    {
      end = b->next_free;
      eassert ((char *) end <= (char *) b + SBLOCK_SIZE);

      for (from = &b->first_data; from < end; from = from_end)
	{
	  /* Compute the next FROM here because copying below may
	     overwrite data we need to compute it.  */
	  ptrdiff_t nbytes;
	  struct Lisp_String *s = from->string;

#ifdef GC_CHECK_STRING_BYTES
	  /* Check that the string size recorded in the string is the
	     same as the one recorded in the sdata structure. */
	  if (s && string_bytes (s) != SDATA_NBYTES (from))
	    emacs_abort ();
#endif /* GC_CHECK_STRING_BYTES */

	  nbytes = s ? STRING_BYTES (s) : SDATA_NBYTES (from);
	  eassert (nbytes <= LARGE_STRING_BYTES);

	  nbytes = SDATA_SIZE (nbytes);
	  from_end = (struct sdata *) ((char *) from + nbytes + GC_STRING_EXTRA);

#ifdef GC_CHECK_STRING_OVERRUN
	  if (memcmp (string_overrun_cookie,
		      (char *) from_end - GC_STRING_OVERRUN_COOKIE_SIZE,
		      GC_STRING_OVERRUN_COOKIE_SIZE))
	    emacs_abort ();
#endif

	  /* Non-NULL S means it's alive.  Copy its data.  */
	  if (s)
	    {
	      /* If TB is full, proceed with the next sblock.  */
	      to_end = (struct sdata *) ((char *) to + nbytes + GC_STRING_EXTRA);
	      if (to_end > tb_end)
		{
		  tb->next_free = to;
		  tb = tb->next;
		  tb_end = (struct sdata *) ((char *) tb + SBLOCK_SIZE);
		  to = &tb->first_data;
		  to_end = (struct sdata *) ((char *) to + nbytes + GC_STRING_EXTRA);
		}

	      /* Copy, and update the string's `data' pointer.  */
	      if (from != to)
		{
		  eassert (tb != b || to < from);
		  memmove (to, from, nbytes + GC_STRING_EXTRA);
		  to->string->data = SDATA_DATA (to);
		}

	      /* Advance past the sdata we copied to.  */
	      to = to_end;
	    }
	}
    }

  /* The rest of the sblocks following TB don't contain live data, so
     we can free them.  */
  for (b = tb->next; b; b = next)
    {
      next = b->next;
      lisp_free (b);
    }

  tb->next_free = to;
  tb->next = NULL;
  current_sblock = tb;
}

void
string_overflow (void)
{
  error ("Maximum string size exceeded");
}

DEFUN ("make-string", Fmake_string, Smake_string, 2, 2, 0,
       doc: /* Return a newly created string of length LENGTH, with INIT in each element.
LENGTH must be an integer.
INIT must be an integer that represents a character.  */)
  (Lisp_Object length, Lisp_Object init)
{
  register Lisp_Object val;
  register unsigned char *p, *end;
  int c;
  EMACS_INT nbytes;

  CHECK_NATNUM (length);
  CHECK_CHARACTER (init);

  c = XFASTINT (init);
  if (ASCII_CHAR_P (c))
    {
      nbytes = XINT (length);
      val = make_uninit_string (nbytes);
      p = SDATA (val);
      end = p + SCHARS (val);
      while (p != end)
	*p++ = c;
    }
  else
    {
      unsigned char str[MAX_MULTIBYTE_LENGTH];
      int len = CHAR_STRING (c, str);
      EMACS_INT string_len = XINT (length);

      if (string_len > STRING_BYTES_MAX / len)
	string_overflow ();
      nbytes = len * string_len;
      val = make_uninit_multibyte_string (string_len, nbytes);
      p = SDATA (val);
      end = p + nbytes;
      while (p != end)
	{
	  memcpy (p, str, len);
	  p += len;
	}
    }

  *p = 0;
  return val;
}


DEFUN ("make-bool-vector", Fmake_bool_vector, Smake_bool_vector, 2, 2, 0,
       doc: /* Return a new bool-vector of length LENGTH, using INIT for each element.
LENGTH must be a number.  INIT matters only in whether it is t or nil.  */)
  (Lisp_Object length, Lisp_Object init)
{
  register Lisp_Object val;
  struct Lisp_Bool_Vector *p;
  ptrdiff_t length_in_chars;
  EMACS_INT length_in_elts;
  int bits_per_value;
  int extra_bool_elts = ((bool_header_size - header_size + word_size - 1)
			 / word_size);

  CHECK_NATNUM (length);

  bits_per_value = sizeof (EMACS_INT) * BOOL_VECTOR_BITS_PER_CHAR;

  length_in_elts = (XFASTINT (length) + bits_per_value - 1) / bits_per_value;

  val = Fmake_vector (make_number (length_in_elts + extra_bool_elts), Qnil);

  /* No Lisp_Object to trace in there.  */
  XSETPVECTYPESIZE (XVECTOR (val), PVEC_BOOL_VECTOR, 0, 0);

  p = XBOOL_VECTOR (val);
  p->size = XFASTINT (length);

  length_in_chars = ((XFASTINT (length) + BOOL_VECTOR_BITS_PER_CHAR - 1)
		     / BOOL_VECTOR_BITS_PER_CHAR);
  if (length_in_chars)
    {
      memset (p->data, ! NILP (init) ? -1 : 0, length_in_chars);

      /* Clear any extraneous bits in the last byte.  */
      p->data[length_in_chars - 1]
	&= (1 << ((XFASTINT (length) - 1) % BOOL_VECTOR_BITS_PER_CHAR + 1)) - 1;
    }

  return val;
}


/* Make a string from NBYTES bytes at CONTENTS, and compute the number
   of characters from the contents.  This string may be unibyte or
   multibyte, depending on the contents.  */

Lisp_Object
make_string (const char *contents, ptrdiff_t nbytes)
{
  register Lisp_Object val;
  ptrdiff_t nchars, multibyte_nbytes;

  parse_str_as_multibyte ((const unsigned char *) contents, nbytes,
			  &nchars, &multibyte_nbytes);
  if (nbytes == nchars || nbytes != multibyte_nbytes)
    /* CONTENTS contains no multibyte sequences or contains an invalid
       multibyte sequence.  We must make unibyte string.  */
    val = make_unibyte_string (contents, nbytes);
  else
    val = make_multibyte_string (contents, nchars, nbytes);
  return val;
}


/* Make an unibyte string from LENGTH bytes at CONTENTS.  */

Lisp_Object
make_unibyte_string (const char *contents, ptrdiff_t length)
{
  register Lisp_Object val;
  val = make_uninit_string (length);
  memcpy (SDATA (val), contents, length);
  return val;
}


/* Make a multibyte string from NCHARS characters occupying NBYTES
   bytes at CONTENTS.  */

Lisp_Object
make_multibyte_string (const char *contents,
		       ptrdiff_t nchars, ptrdiff_t nbytes)
{
  register Lisp_Object val;
  val = make_uninit_multibyte_string (nchars, nbytes);
  memcpy (SDATA (val), contents, nbytes);
  return val;
}


/* Make a string from NCHARS characters occupying NBYTES bytes at
   CONTENTS.  It is a multibyte string if NBYTES != NCHARS.  */

Lisp_Object
make_string_from_bytes (const char *contents,
			ptrdiff_t nchars, ptrdiff_t nbytes)
{
  register Lisp_Object val;
  val = make_uninit_multibyte_string (nchars, nbytes);
  memcpy (SDATA (val), contents, nbytes);
  if (SBYTES (val) == SCHARS (val))
    STRING_SET_UNIBYTE (val);
  return val;
}


/* Make a string from NCHARS characters occupying NBYTES bytes at
   CONTENTS.  The argument MULTIBYTE controls whether to label the
   string as multibyte.  If NCHARS is negative, it counts the number of
   characters by itself.  */

Lisp_Object
make_specified_string (const char *contents,
		       ptrdiff_t nchars, ptrdiff_t nbytes, bool multibyte)
{
  Lisp_Object val;

  if (nchars < 0)
    {
      if (multibyte)
	nchars = multibyte_chars_in_text ((const unsigned char *) contents,
					  nbytes);
      else
	nchars = nbytes;
    }
  val = make_uninit_multibyte_string (nchars, nbytes);
  memcpy (SDATA (val), contents, nbytes);
  if (!multibyte)
    STRING_SET_UNIBYTE (val);
  return val;
}


/* Return an unibyte Lisp_String set up to hold LENGTH characters
   occupying LENGTH bytes.  */

Lisp_Object
make_uninit_string (EMACS_INT length)
{
  Lisp_Object val;

  if (!length)
    return empty_unibyte_string;
  val = make_uninit_multibyte_string (length, length);
  STRING_SET_UNIBYTE (val);
  return val;
}


/* Return a multibyte Lisp_String set up to hold NCHARS characters
   which occupy NBYTES bytes.  */

Lisp_Object
make_uninit_multibyte_string (EMACS_INT nchars, EMACS_INT nbytes)
{
  Lisp_Object string;
  struct Lisp_String *s;

  if (nchars < 0)
    emacs_abort ();
  if (!nbytes)
    return empty_multibyte_string;

  s = allocate_string ();
  s->intervals = NULL;
  allocate_string_data (s, nchars, nbytes);
  XSETSTRING (string, s);
  string_chars_consed += nbytes;
  return string;
}

/* Print arguments to BUF according to a FORMAT, then return
   a Lisp_String initialized with the data from BUF.  */

Lisp_Object
make_formatted_string (char *buf, const char *format, ...)
{
  va_list ap;
  int length;

  va_start (ap, format);
  length = vsprintf (buf, format, ap);
  va_end (ap);
  return make_string (buf, length);
}


/***********************************************************************
			   Float Allocation
 ***********************************************************************/

/* We store float cells inside of float_blocks, allocating a new
   float_block with malloc whenever necessary.  Float cells reclaimed
   by GC are put on a free list to be reallocated before allocating
   any new float cells from the latest float_block.  */

#define FLOAT_BLOCK_SIZE					\
  (((BLOCK_BYTES - sizeof (struct float_block *)		\
     /* The compiler might add padding at the end.  */		\
     - (sizeof (struct Lisp_Float) - sizeof (int))) * CHAR_BIT) \
   / (sizeof (struct Lisp_Float) * CHAR_BIT + 1))

#define GETMARKBIT(block,n)				\
  (((block)->gcmarkbits[(n) / (sizeof (int) * CHAR_BIT)]	\
    >> ((n) % (sizeof (int) * CHAR_BIT)))		\
   & 1)

#define SETMARKBIT(block,n)				\
  (block)->gcmarkbits[(n) / (sizeof (int) * CHAR_BIT)]	\
  |= 1 << ((n) % (sizeof (int) * CHAR_BIT))

#define UNSETMARKBIT(block,n)				\
  (block)->gcmarkbits[(n) / (sizeof (int) * CHAR_BIT)]	\
  &= ~(1 << ((n) % (sizeof (int) * CHAR_BIT)))

#define FLOAT_BLOCK(fptr) \
  ((struct float_block *) (((uintptr_t) (fptr)) & ~(BLOCK_ALIGN - 1)))

#define FLOAT_INDEX(fptr) \
  ((((uintptr_t) (fptr)) & (BLOCK_ALIGN - 1)) / sizeof (struct Lisp_Float))

struct float_block
{
  /* Place `floats' at the beginning, to ease up FLOAT_INDEX's job.  */
  struct Lisp_Float floats[FLOAT_BLOCK_SIZE];
  int gcmarkbits[1 + FLOAT_BLOCK_SIZE / (sizeof (int) * CHAR_BIT)];
  struct float_block *next;
};

#define FLOAT_MARKED_P(fptr) \
  GETMARKBIT (FLOAT_BLOCK (fptr), FLOAT_INDEX ((fptr)))

#define FLOAT_MARK(fptr) \
  SETMARKBIT (FLOAT_BLOCK (fptr), FLOAT_INDEX ((fptr)))

#define FLOAT_UNMARK(fptr) \
  UNSETMARKBIT (FLOAT_BLOCK (fptr), FLOAT_INDEX ((fptr)))

/* Current float_block.  */

static struct float_block *float_block;

/* Index of first unused Lisp_Float in the current float_block.  */

static int float_block_index = FLOAT_BLOCK_SIZE;

/* Free-list of Lisp_Floats.  */

static struct Lisp_Float *float_free_list;

/* Return a new float object with value FLOAT_VALUE.  */

Lisp_Object
make_float (double float_value)
{
  register Lisp_Object val;

  MALLOC_BLOCK_INPUT;

  if (float_free_list)
    {
      /* We use the data field for chaining the free list
	 so that we won't use the same field that has the mark bit.  */
      XSETFLOAT (val, float_free_list);
      float_free_list = float_free_list->u.chain;
    }
  else
    {
      if (float_block_index == FLOAT_BLOCK_SIZE)
	{
	  struct float_block *new
	    = lisp_align_malloc (sizeof *new, MEM_TYPE_FLOAT);
	  new->next = float_block;
	  memset (new->gcmarkbits, 0, sizeof new->gcmarkbits);
	  float_block = new;
	  float_block_index = 0;
	  total_free_floats += FLOAT_BLOCK_SIZE;
	}
      XSETFLOAT (val, &float_block->floats[float_block_index]);
      float_block_index++;
    }

  MALLOC_UNBLOCK_INPUT;

  XFLOAT_INIT (val, float_value);
  eassert (!FLOAT_MARKED_P (XFLOAT (val)));
  consing_since_gc += sizeof (struct Lisp_Float);
  floats_consed++;
  total_free_floats--;
  return val;
}



/***********************************************************************
			   Cons Allocation
 ***********************************************************************/

/* We store cons cells inside of cons_blocks, allocating a new
   cons_block with malloc whenever necessary.  Cons cells reclaimed by
   GC are put on a free list to be reallocated before allocating
   any new cons cells from the latest cons_block.  */

#define CONS_BLOCK_SIZE						\
  (((BLOCK_BYTES - sizeof (struct cons_block *)			\
     /* The compiler might add padding at the end.  */		\
     - (sizeof (struct Lisp_Cons) - sizeof (int))) * CHAR_BIT)	\
   / (sizeof (struct Lisp_Cons) * CHAR_BIT + 1))

#define CONS_BLOCK(fptr) \
  ((struct cons_block *) ((uintptr_t) (fptr) & ~(BLOCK_ALIGN - 1)))

#define CONS_INDEX(fptr) \
  (((uintptr_t) (fptr) & (BLOCK_ALIGN - 1)) / sizeof (struct Lisp_Cons))

struct cons_block
{
  /* Place `conses' at the beginning, to ease up CONS_INDEX's job.  */
  struct Lisp_Cons conses[CONS_BLOCK_SIZE];
  int gcmarkbits[1 + CONS_BLOCK_SIZE / (sizeof (int) * CHAR_BIT)];
  struct cons_block *next;
};

#define CONS_MARKED_P(fptr) \
  GETMARKBIT (CONS_BLOCK (fptr), CONS_INDEX ((fptr)))

#define CONS_MARK(fptr) \
  SETMARKBIT (CONS_BLOCK (fptr), CONS_INDEX ((fptr)))

#define CONS_UNMARK(fptr) \
  UNSETMARKBIT (CONS_BLOCK (fptr), CONS_INDEX ((fptr)))

/* Current cons_block.  */

static struct cons_block *cons_block;

/* Index of first unused Lisp_Cons in the current block.  */

static int cons_block_index = CONS_BLOCK_SIZE;

/* Free-list of Lisp_Cons structures.  */

static struct Lisp_Cons *cons_free_list;

/* Explicitly free a cons cell by putting it on the free-list.  */

void
free_cons (struct Lisp_Cons *ptr)
{
  ptr->u.chain = cons_free_list;
#if GC_MARK_STACK
  ptr->car = Vdead;
#endif
  cons_free_list = ptr;
  consing_since_gc -= sizeof *ptr;
  total_free_conses++;
}

DEFUN ("cons", Fcons, Scons, 2, 2, 0,
       doc: /* Create a new cons, give it CAR and CDR as components, and return it.  */)
  (Lisp_Object car, Lisp_Object cdr)
{
  register Lisp_Object val;

  MALLOC_BLOCK_INPUT;

  if (cons_free_list)
    {
      /* We use the cdr for chaining the free list
	 so that we won't use the same field that has the mark bit.  */
      XSETCONS (val, cons_free_list);
      cons_free_list = cons_free_list->u.chain;
    }
  else
    {
      if (cons_block_index == CONS_BLOCK_SIZE)
	{
	  struct cons_block *new
	    = lisp_align_malloc (sizeof *new, MEM_TYPE_CONS);
	  memset (new->gcmarkbits, 0, sizeof new->gcmarkbits);
	  new->next = cons_block;
	  cons_block = new;
	  cons_block_index = 0;
	  total_free_conses += CONS_BLOCK_SIZE;
	}
      XSETCONS (val, &cons_block->conses[cons_block_index]);
      cons_block_index++;
    }

  MALLOC_UNBLOCK_INPUT;

  XSETCAR (val, car);
  XSETCDR (val, cdr);
  eassert (!CONS_MARKED_P (XCONS (val)));
  consing_since_gc += sizeof (struct Lisp_Cons);
  total_free_conses--;
  cons_cells_consed++;
  return val;
}

#ifdef GC_CHECK_CONS_LIST
/* Get an error now if there's any junk in the cons free list.  */
void
check_cons_list (void)
{
  struct Lisp_Cons *tail = cons_free_list;

  while (tail)
    tail = tail->u.chain;
}
#endif

/* Make a list of 1, 2, 3, 4 or 5 specified objects.  */

Lisp_Object
list1 (Lisp_Object arg1)
{
  return Fcons (arg1, Qnil);
}

Lisp_Object
list2 (Lisp_Object arg1, Lisp_Object arg2)
{
  return Fcons (arg1, Fcons (arg2, Qnil));
}


Lisp_Object
list3 (Lisp_Object arg1, Lisp_Object arg2, Lisp_Object arg3)
{
  return Fcons (arg1, Fcons (arg2, Fcons (arg3, Qnil)));
}


Lisp_Object
list4 (Lisp_Object arg1, Lisp_Object arg2, Lisp_Object arg3, Lisp_Object arg4)
{
  return Fcons (arg1, Fcons (arg2, Fcons (arg3, Fcons (arg4, Qnil))));
}


Lisp_Object
list5 (Lisp_Object arg1, Lisp_Object arg2, Lisp_Object arg3, Lisp_Object arg4, Lisp_Object arg5)
{
  return Fcons (arg1, Fcons (arg2, Fcons (arg3, Fcons (arg4,
						       Fcons (arg5, Qnil)))));
}

/* Make a list of COUNT Lisp_Objects, where ARG is the
   first one.  Allocate conses from pure space if TYPE
   is CONSTYPE_PURE, or allocate as usual if type is CONSTYPE_HEAP.  */

Lisp_Object
listn (enum constype type, ptrdiff_t count, Lisp_Object arg, ...)
{
  va_list ap;
  ptrdiff_t i;
  Lisp_Object val, *objp;

  /* Change to SAFE_ALLOCA if you hit this eassert.  */
  eassert (count <= MAX_ALLOCA / word_size);

  objp = alloca (count * word_size);
  objp[0] = arg;
  va_start (ap, arg);
  for (i = 1; i < count; i++)
    objp[i] = va_arg (ap, Lisp_Object);
  va_end (ap);

  for (val = Qnil, i = count - 1; i >= 0; i--)
    {
      if (type == CONSTYPE_PURE)
	val = pure_cons (objp[i], val);
      else if (type == CONSTYPE_HEAP)
	val = Fcons (objp[i], val);
      else
	emacs_abort ();
    }
  return val;
}

DEFUN ("list", Flist, Slist, 0, MANY, 0,
       doc: /* Return a newly created list with specified arguments as elements.
Any number of arguments, even zero arguments, are allowed.
usage: (list &rest OBJECTS)  */)
  (ptrdiff_t nargs, Lisp_Object *args)
{
  register Lisp_Object val;
  val = Qnil;

  while (nargs > 0)
    {
      nargs--;
      val = Fcons (args[nargs], val);
    }
  return val;
}


DEFUN ("make-list", Fmake_list, Smake_list, 2, 2, 0,
       doc: /* Return a newly created list of length LENGTH, with each element being INIT.  */)
  (register Lisp_Object length, Lisp_Object init)
{
  register Lisp_Object val;
  register EMACS_INT size;

  CHECK_NATNUM (length);
  size = XFASTINT (length);

  val = Qnil;
  while (size > 0)
    {
      val = Fcons (init, val);
      --size;

      if (size > 0)
	{
	  val = Fcons (init, val);
	  --size;

	  if (size > 0)
	    {
	      val = Fcons (init, val);
	      --size;

	      if (size > 0)
		{
		  val = Fcons (init, val);
		  --size;

		  if (size > 0)
		    {
		      val = Fcons (init, val);
		      --size;
		    }
		}
	    }
	}

      QUIT;
    }

  return val;
}



/***********************************************************************
			   Vector Allocation
 ***********************************************************************/

/* This value is balanced well enough to avoid too much internal overhead
   for the most common cases; it's not required to be a power of two, but
   it's expected to be a mult-of-ROUNDUP_SIZE (see below).  */

#define VECTOR_BLOCK_SIZE 4096

/* Align allocation request sizes to be a multiple of ROUNDUP_SIZE.  */
enum
  {
    roundup_size = COMMON_MULTIPLE (word_size, USE_LSB_TAG ? GCALIGNMENT : 1)
  };

/* ROUNDUP_SIZE must be a power of 2.  */
verify ((roundup_size & (roundup_size - 1)) == 0);

/* Verify assumptions described above.  */
verify ((VECTOR_BLOCK_SIZE % roundup_size) == 0);
verify (VECTOR_BLOCK_SIZE <= (1 << PSEUDOVECTOR_SIZE_BITS));

/* Round up X to nearest mult-of-ROUNDUP_SIZE.  */

#define vroundup(x) (((x) + (roundup_size - 1)) & ~(roundup_size - 1))

/* Rounding helps to maintain alignment constraints if USE_LSB_TAG.  */

#define VECTOR_BLOCK_BYTES (VECTOR_BLOCK_SIZE - vroundup (sizeof (void *)))

/* Size of the minimal vector allocated from block.  */

#define VBLOCK_BYTES_MIN vroundup (sizeof (struct Lisp_Vector))

/* Size of the largest vector allocated from block.  */

#define VBLOCK_BYTES_MAX					\
  vroundup ((VECTOR_BLOCK_BYTES / 2) - word_size)

/* We maintain one free list for each possible block-allocated
   vector size, and this is the number of free lists we have.  */

#define VECTOR_MAX_FREE_LIST_INDEX				\
  ((VECTOR_BLOCK_BYTES - VBLOCK_BYTES_MIN) / roundup_size + 1)

/* Common shortcut to advance vector pointer over a block data.  */

#define ADVANCE(v, nbytes) ((struct Lisp_Vector *) ((char *) (v) + (nbytes)))

/* Common shortcut to calculate NBYTES-vector index in VECTOR_FREE_LISTS.  */

#define VINDEX(nbytes) (((nbytes) - VBLOCK_BYTES_MIN) / roundup_size)

/* Get and set the next field in block-allocated vectorlike objects on
   the free list.  Doing it this way respects C's aliasing rules.
   We could instead make 'contents' a union, but that would mean
   changes everywhere that the code uses 'contents'.  */
static struct Lisp_Vector *
next_in_free_list (struct Lisp_Vector *v)
{
  intptr_t i = XLI (v->contents[0]);
  return (struct Lisp_Vector *) i;
}
static void
set_next_in_free_list (struct Lisp_Vector *v, struct Lisp_Vector *next)
{
  v->contents[0] = XIL ((intptr_t) next);
}

/* Common shortcut to setup vector on a free list.  */

#define SETUP_ON_FREE_LIST(v, nbytes, tmp)		\
  do {							\
    (tmp) = ((nbytes - header_size) / word_size);	\
    XSETPVECTYPESIZE (v, PVEC_FREE, 0, (tmp));		\
    eassert ((nbytes) % roundup_size == 0);		\
    (tmp) = VINDEX (nbytes);				\
    eassert ((tmp) < VECTOR_MAX_FREE_LIST_INDEX);	\
    set_next_in_free_list (v, vector_free_lists[tmp]);	\
    vector_free_lists[tmp] = (v);			\
    total_free_vector_slots += (nbytes) / word_size;	\
  } while (0)

/* This internal type is used to maintain the list of large vectors
   which are allocated at their own, e.g. outside of vector blocks.  */

struct large_vector
{
  union {
    struct large_vector *vector;
#if USE_LSB_TAG
    /* We need to maintain ROUNDUP_SIZE alignment for the vector member.  */
    unsigned char c[vroundup (sizeof (struct large_vector *))];
#endif
  } next;
  struct Lisp_Vector v;
};

/* This internal type is used to maintain an underlying storage
   for small vectors.  */

struct vector_block
{
  char data[VECTOR_BLOCK_BYTES];
  struct vector_block *next;
};

/* Chain of vector blocks.  */

static struct vector_block *vector_blocks;

/* Vector free lists, where NTH item points to a chain of free
   vectors of the same NBYTES size, so NTH == VINDEX (NBYTES).  */

static struct Lisp_Vector *vector_free_lists[VECTOR_MAX_FREE_LIST_INDEX];

/* Singly-linked list of large vectors.  */

static struct large_vector *large_vectors;

/* The only vector with 0 slots, allocated from pure space.  */

Lisp_Object zero_vector;

/* Number of live vectors.  */

static EMACS_INT total_vectors;

/* Total size of live and free vectors, in Lisp_Object units.  */

static EMACS_INT total_vector_slots, total_free_vector_slots;

/* Get a new vector block.  */

static struct vector_block *
allocate_vector_block (void)
{
  struct vector_block *block = xmalloc (sizeof *block);

#if GC_MARK_STACK && !defined GC_MALLOC_CHECK
  mem_insert (block->data, block->data + VECTOR_BLOCK_BYTES,
	      MEM_TYPE_VECTOR_BLOCK);
#endif

  block->next = vector_blocks;
  vector_blocks = block;
  return block;
}

/* Called once to initialize vector allocation.  */

static void
init_vectors (void)
{
  zero_vector = make_pure_vector (0);
}

/* Allocate vector from a vector block.  */

static struct Lisp_Vector *
allocate_vector_from_block (size_t nbytes)
{
  struct Lisp_Vector *vector;
  struct vector_block *block;
  size_t index, restbytes;

  eassert (VBLOCK_BYTES_MIN <= nbytes && nbytes <= VBLOCK_BYTES_MAX);
  eassert (nbytes % roundup_size == 0);

  /* First, try to allocate from a free list
     containing vectors of the requested size.  */
  index = VINDEX (nbytes);
  if (vector_free_lists[index])
    {
      vector = vector_free_lists[index];
      vector_free_lists[index] = next_in_free_list (vector);
      total_free_vector_slots -= nbytes / word_size;
      return vector;
    }

  /* Next, check free lists containing larger vectors.  Since
     we will split the result, we should have remaining space
     large enough to use for one-slot vector at least.  */
  for (index = VINDEX (nbytes + VBLOCK_BYTES_MIN);
       index < VECTOR_MAX_FREE_LIST_INDEX; index++)
    if (vector_free_lists[index])
      {
	/* This vector is larger than requested.  */
	vector = vector_free_lists[index];
	vector_free_lists[index] = next_in_free_list (vector);
	total_free_vector_slots -= nbytes / word_size;

	/* Excess bytes are used for the smaller vector,
	   which should be set on an appropriate free list.  */
	restbytes = index * roundup_size + VBLOCK_BYTES_MIN - nbytes;
	eassert (restbytes % roundup_size == 0);
	SETUP_ON_FREE_LIST (ADVANCE (vector, nbytes), restbytes, index);
	return vector;
      }

  /* Finally, need a new vector block.  */
  block = allocate_vector_block ();

  /* New vector will be at the beginning of this block.  */
  vector = (struct Lisp_Vector *) block->data;

  /* If the rest of space from this block is large enough
     for one-slot vector at least, set up it on a free list.  */
  restbytes = VECTOR_BLOCK_BYTES - nbytes;
  if (restbytes >= VBLOCK_BYTES_MIN)
    {
      eassert (restbytes % roundup_size == 0);
      SETUP_ON_FREE_LIST (ADVANCE (vector, nbytes), restbytes, index);
    }
  return vector;
}

/* Nonzero if VECTOR pointer is valid pointer inside BLOCK.  */

#define VECTOR_IN_BLOCK(vector, block)		\
  ((char *) (vector) <= (block)->data		\
   + VECTOR_BLOCK_BYTES - VBLOCK_BYTES_MIN)

/* Return the memory footprint of V in bytes.  */

static ptrdiff_t
vector_nbytes (struct Lisp_Vector *v)
{
  ptrdiff_t size = v->header.size & ~ARRAY_MARK_FLAG;

  if (size & PSEUDOVECTOR_FLAG)
    {
      if (PSEUDOVECTOR_TYPEP (&v->header, PVEC_BOOL_VECTOR))
	size = (bool_header_size
		+ (((struct Lisp_Bool_Vector *) v)->size
		   + BOOL_VECTOR_BITS_PER_CHAR - 1)
		/ BOOL_VECTOR_BITS_PER_CHAR);
      else
	size = (header_size
		+ ((size & PSEUDOVECTOR_SIZE_MASK)
		   + ((size & PSEUDOVECTOR_REST_MASK)
		      >> PSEUDOVECTOR_SIZE_BITS)) * word_size);
    }
  else
    size = header_size + size * word_size;
  return vroundup (size);
}

/* Reclaim space used by unmarked vectors.  */

static void
sweep_vectors (void)
{
  struct vector_block *block = vector_blocks, **bprev = &vector_blocks;
  struct large_vector *lv, **lvprev = &large_vectors;
  struct Lisp_Vector *vector, *next;

  total_vectors = total_vector_slots = total_free_vector_slots = 0;
  memset (vector_free_lists, 0, sizeof (vector_free_lists));

  /* Looking through vector blocks.  */

  for (block = vector_blocks; block; block = *bprev)
    {
      bool free_this_block = 0;
      ptrdiff_t nbytes;

      for (vector = (struct Lisp_Vector *) block->data;
	   VECTOR_IN_BLOCK (vector, block); vector = next)
	{
	  if (VECTOR_MARKED_P (vector))
	    {
	      VECTOR_UNMARK (vector);
	      total_vectors++;
	      nbytes = vector_nbytes (vector);
	      total_vector_slots += nbytes / word_size;
	      next = ADVANCE (vector, nbytes);
	    }
	  else
	    {
	      ptrdiff_t total_bytes;

	      nbytes = vector_nbytes (vector);
	      total_bytes = nbytes;
	      next = ADVANCE (vector, nbytes);

	      /* While NEXT is not marked, try to coalesce with VECTOR,
		 thus making VECTOR of the largest possible size.  */

	      while (VECTOR_IN_BLOCK (next, block))
		{
		  if (VECTOR_MARKED_P (next))
		    break;
		  nbytes = vector_nbytes (next);
		  total_bytes += nbytes;
		  next = ADVANCE (next, nbytes);
		}

	      eassert (total_bytes % roundup_size == 0);

	      if (vector == (struct Lisp_Vector *) block->data
		  && !VECTOR_IN_BLOCK (next, block))
		/* This block should be freed because all of it's
		   space was coalesced into the only free vector.  */
		free_this_block = 1;
	      else
		{
		  int tmp;
		  SETUP_ON_FREE_LIST (vector, total_bytes, tmp);
		}
	    }
	}

      if (free_this_block)
	{
	  *bprev = block->next;
#if GC_MARK_STACK && !defined GC_MALLOC_CHECK
	  mem_delete (mem_find (block->data));
#endif
	  xfree (block);
	}
      else
	bprev = &block->next;
    }

  /* Sweep large vectors.  */

  for (lv = large_vectors; lv; lv = *lvprev)
    {
      vector = &lv->v;
      if (VECTOR_MARKED_P (vector))
	{
	  VECTOR_UNMARK (vector);
	  total_vectors++;
	  if (vector->header.size & PSEUDOVECTOR_FLAG)
	    {
	      struct Lisp_Bool_Vector *b = (struct Lisp_Bool_Vector *) vector;

	      /* All non-bool pseudovectors are small enough to be allocated
		 from vector blocks.  This code should be redesigned if some
		 pseudovector type grows beyond VBLOCK_BYTES_MAX.  */
	      eassert (PSEUDOVECTOR_TYPEP (&vector->header, PVEC_BOOL_VECTOR));

	      total_vector_slots
		+= (bool_header_size
		    + ((b->size + BOOL_VECTOR_BITS_PER_CHAR - 1)
		       / BOOL_VECTOR_BITS_PER_CHAR)) / word_size;
	    }
	  else
	    total_vector_slots
	      += header_size / word_size + vector->header.size;
	  lvprev = &lv->next.vector;
	}
      else
	{
	  *lvprev = lv->next.vector;
	  lisp_free (lv);
	}
    }
}

/* Value is a pointer to a newly allocated Lisp_Vector structure
   with room for LEN Lisp_Objects.  */

static struct Lisp_Vector *
allocate_vectorlike (ptrdiff_t len)
{
  struct Lisp_Vector *p;

  MALLOC_BLOCK_INPUT;

  if (len == 0)
    p = XVECTOR (zero_vector);
  else
    {
      size_t nbytes = header_size + len * word_size;

#ifdef DOUG_LEA_MALLOC
      /* Prevent mmap'ing the chunk.  Lisp data may not be mmap'ed
	 because mapped region contents are not preserved in
	 a dumped Emacs.  */
      mallopt (M_MMAP_MAX, 0);
#endif

      if (nbytes <= VBLOCK_BYTES_MAX)
	p = allocate_vector_from_block (vroundup (nbytes));
      else
	{
	  struct large_vector *lv
	    = lisp_malloc (sizeof (*lv) + (len - 1) * word_size,
			   MEM_TYPE_VECTORLIKE);
	  lv->next.vector = large_vectors;
	  large_vectors = lv;
	  p = &lv->v;
	}

#ifdef DOUG_LEA_MALLOC
      /* Back to a reasonable maximum of mmap'ed areas.  */
      mallopt (M_MMAP_MAX, MMAP_MAX_AREAS);
#endif

      consing_since_gc += nbytes;
      vector_cells_consed += len;
    }

  MALLOC_UNBLOCK_INPUT;

  return p;
}


/* Allocate a vector with LEN slots.  */

struct Lisp_Vector *
allocate_vector (EMACS_INT len)
{
  struct Lisp_Vector *v;
  ptrdiff_t nbytes_max = min (PTRDIFF_MAX, SIZE_MAX);

  if (min ((nbytes_max - header_size) / word_size, MOST_POSITIVE_FIXNUM) < len)
    memory_full (SIZE_MAX);
  v = allocate_vectorlike (len);
  v->header.size = len;
  return v;
}


/* Allocate other vector-like structures.  */

struct Lisp_Vector *
allocate_pseudovector (int memlen, int lisplen, enum pvec_type tag)
{
  struct Lisp_Vector *v = allocate_vectorlike (memlen);
  int i;

  /* Catch bogus values.  */
  eassert (tag <= PVEC_FONT);
  eassert (memlen - lisplen <= (1 << PSEUDOVECTOR_REST_BITS) - 1);
  eassert (lisplen <= (1 << PSEUDOVECTOR_SIZE_BITS) - 1);

  /* Only the first lisplen slots will be traced normally by the GC.  */
  for (i = 0; i < lisplen; ++i)
    v->contents[i] = Qnil;

  XSETPVECTYPESIZE (v, tag, lisplen, memlen - lisplen);
  return v;
}

struct buffer *
allocate_buffer (void)
{
  struct buffer *b = lisp_malloc (sizeof *b, MEM_TYPE_BUFFER);

  BUFFER_PVEC_INIT (b);
  /* Put B on the chain of all buffers including killed ones.  */
  b->next = all_buffers;
  all_buffers = b;
  /* Note that the rest fields of B are not initialized.  */
  return b;
}

struct Lisp_Hash_Table *
allocate_hash_table (void)
{
  return ALLOCATE_PSEUDOVECTOR (struct Lisp_Hash_Table, count, PVEC_HASH_TABLE);
}

struct window *
allocate_window (void)
{
  struct window *w;

  w = ALLOCATE_PSEUDOVECTOR (struct window, current_matrix, PVEC_WINDOW);
  /* Users assumes that non-Lisp data is zeroed.  */
  memset (&w->current_matrix, 0,
	  sizeof (*w) - offsetof (struct window, current_matrix));
  return w;
}

struct terminal *
allocate_terminal (void)
{
  struct terminal *t;

  t = ALLOCATE_PSEUDOVECTOR (struct terminal, next_terminal, PVEC_TERMINAL);
  /* Users assumes that non-Lisp data is zeroed.  */
  memset (&t->next_terminal, 0,
	  sizeof (*t) - offsetof (struct terminal, next_terminal));
  return t;
}

struct frame *
allocate_frame (void)
{
  struct frame *f;

  f = ALLOCATE_PSEUDOVECTOR (struct frame, face_cache, PVEC_FRAME);
  /* Users assumes that non-Lisp data is zeroed.  */
  memset (&f->face_cache, 0,
	  sizeof (*f) - offsetof (struct frame, face_cache));
  return f;
}

struct Lisp_Process *
allocate_process (void)
{
  struct Lisp_Process *p;

  p = ALLOCATE_PSEUDOVECTOR (struct Lisp_Process, pid, PVEC_PROCESS);
  /* Users assumes that non-Lisp data is zeroed.  */
  memset (&p->pid, 0,
	  sizeof (*p) - offsetof (struct Lisp_Process, pid));
  return p;
}

DEFUN ("make-vector", Fmake_vector, Smake_vector, 2, 2, 0,
       doc: /* Return a newly created vector of length LENGTH, with each element being INIT.
See also the function `vector'.  */)
  (register Lisp_Object length, Lisp_Object init)
{
  Lisp_Object vector;
  register ptrdiff_t sizei;
  register ptrdiff_t i;
  register struct Lisp_Vector *p;

  CHECK_NATNUM (length);

  p = allocate_vector (XFASTINT (length));
  sizei = XFASTINT (length);
  for (i = 0; i < sizei; i++)
    p->contents[i] = init;

  XSETVECTOR (vector, p);
  return vector;
}


DEFUN ("vector", Fvector, Svector, 0, MANY, 0,
       doc: /* Return a newly created vector with specified arguments as elements.
Any number of arguments, even zero arguments, are allowed.
usage: (vector &rest OBJECTS)  */)
  (ptrdiff_t nargs, Lisp_Object *args)
{
  register Lisp_Object len, val;
  ptrdiff_t i;
  register struct Lisp_Vector *p;

  XSETFASTINT (len, nargs);
  val = Fmake_vector (len, Qnil);
  p = XVECTOR (val);
  for (i = 0; i < nargs; i++)
    p->contents[i] = args[i];
  return val;
}

void
make_byte_code (struct Lisp_Vector *v)
{
  if (v->header.size > 1 && STRINGP (v->contents[1])
      && STRING_MULTIBYTE (v->contents[1]))
    /* BYTECODE-STRING must have been produced by Emacs 20.2 or the
       earlier because they produced a raw 8-bit string for byte-code
       and now such a byte-code string is loaded as multibyte while
       raw 8-bit characters converted to multibyte form.  Thus, now we
       must convert them back to the original unibyte form.  */
    v->contents[1] = Fstring_as_unibyte (v->contents[1]);
  XSETPVECTYPE (v, PVEC_COMPILED);
}

DEFUN ("make-byte-code", Fmake_byte_code, Smake_byte_code, 4, MANY, 0,
       doc: /* Create a byte-code object with specified arguments as elements.
The arguments should be the ARGLIST, bytecode-string BYTE-CODE, constant
vector CONSTANTS, maximum stack size DEPTH, (optional) DOCSTRING,
and (optional) INTERACTIVE-SPEC.
The first four arguments are required; at most six have any
significance.
The ARGLIST can be either like the one of `lambda', in which case the arguments
will be dynamically bound before executing the byte code, or it can be an
integer of the form NNNNNNNRMMMMMMM where the 7bit MMMMMMM specifies the
minimum number of arguments, the 7-bit NNNNNNN specifies the maximum number
of arguments (ignoring &rest) and the R bit specifies whether there is a &rest
argument to catch the left-over arguments.  If such an integer is used, the
arguments will not be dynamically bound but will be instead pushed on the
stack before executing the byte-code.
usage: (make-byte-code ARGLIST BYTE-CODE CONSTANTS DEPTH &optional DOCSTRING INTERACTIVE-SPEC &rest ELEMENTS)  */)
  (ptrdiff_t nargs, Lisp_Object *args)
{
  register Lisp_Object len, val;
  ptrdiff_t i;
  register struct Lisp_Vector *p;

  /* We used to purecopy everything here, if purify-flag was set.  This worked
     OK for Emacs-23, but with Emacs-24's lexical binding code, it can be
     dangerous, since make-byte-code is used during execution to build
     closures, so any closure built during the preload phase would end up
     copied into pure space, including its free variables, which is sometimes
     just wasteful and other times plainly wrong (e.g. those free vars may want
     to be setcar'd).  */

  XSETFASTINT (len, nargs);
  val = Fmake_vector (len, Qnil);

  p = XVECTOR (val);
  for (i = 0; i < nargs; i++)
    p->contents[i] = args[i];
  make_byte_code (p);
  XSETCOMPILED (val, p);
  return val;
}



/***********************************************************************
			   Symbol Allocation
 ***********************************************************************/

/* Like struct Lisp_Symbol, but padded so that the size is a multiple
   of the required alignment if LSB tags are used.  */

union aligned_Lisp_Symbol
{
  struct Lisp_Symbol s;
#if USE_LSB_TAG
  unsigned char c[(sizeof (struct Lisp_Symbol) + GCALIGNMENT - 1)
		  & -GCALIGNMENT];
#endif
};

/* Each symbol_block is just under 1020 bytes long, since malloc
   really allocates in units of powers of two and uses 4 bytes for its
   own overhead.  */

#define SYMBOL_BLOCK_SIZE \
  ((1020 - sizeof (struct symbol_block *)) / sizeof (union aligned_Lisp_Symbol))

struct symbol_block
{
  /* Place `symbols' first, to preserve alignment.  */
  union aligned_Lisp_Symbol symbols[SYMBOL_BLOCK_SIZE];
  struct symbol_block *next;
};

/* Current symbol block and index of first unused Lisp_Symbol
   structure in it.  */

static struct symbol_block *symbol_block;
static int symbol_block_index = SYMBOL_BLOCK_SIZE;

/* List of free symbols.  */

static struct Lisp_Symbol *symbol_free_list;

DEFUN ("make-symbol", Fmake_symbol, Smake_symbol, 1, 1, 0,
       doc: /* Return a newly allocated uninterned symbol whose name is NAME.
Its value is void, and its function definition and property list are nil.  */)
  (Lisp_Object name)
{
  register Lisp_Object val;
  register struct Lisp_Symbol *p;

  CHECK_STRING (name);

  MALLOC_BLOCK_INPUT;

  if (symbol_free_list)
    {
      XSETSYMBOL (val, symbol_free_list);
      symbol_free_list = symbol_free_list->next;
    }
  else
    {
      if (symbol_block_index == SYMBOL_BLOCK_SIZE)
	{
	  struct symbol_block *new
	    = lisp_malloc (sizeof *new, MEM_TYPE_SYMBOL);
	  new->next = symbol_block;
	  symbol_block = new;
	  symbol_block_index = 0;
	  total_free_symbols += SYMBOL_BLOCK_SIZE;
	}
      XSETSYMBOL (val, &symbol_block->symbols[symbol_block_index].s);
      symbol_block_index++;
    }

  MALLOC_UNBLOCK_INPUT;

  p = XSYMBOL (val);
  set_symbol_name (val, name);
  set_symbol_plist (val, Qnil);
  p->redirect = SYMBOL_PLAINVAL;
  SET_SYMBOL_VAL (p, Qunbound);
  set_symbol_function (val, Qnil);
  set_symbol_next (val, NULL);
  p->gcmarkbit = 0;
  p->interned = SYMBOL_UNINTERNED;
  p->constant = 0;
  p->declared_special = 0;
  consing_since_gc += sizeof (struct Lisp_Symbol);
  symbols_consed++;
  total_free_symbols--;
  return val;
}



/***********************************************************************
		       Marker (Misc) Allocation
 ***********************************************************************/

/* Like union Lisp_Misc, but padded so that its size is a multiple of
   the required alignment when LSB tags are used.  */

union aligned_Lisp_Misc
{
  union Lisp_Misc m;
#if USE_LSB_TAG
  unsigned char c[(sizeof (union Lisp_Misc) + GCALIGNMENT - 1)
		  & -GCALIGNMENT];
#endif
};

/* Allocation of markers and other objects that share that structure.
   Works like allocation of conses. */

#define MARKER_BLOCK_SIZE \
  ((1020 - sizeof (struct marker_block *)) / sizeof (union aligned_Lisp_Misc))

struct marker_block
{
  /* Place `markers' first, to preserve alignment.  */
  union aligned_Lisp_Misc markers[MARKER_BLOCK_SIZE];
  struct marker_block *next;
};

static struct marker_block *marker_block;
static int marker_block_index = MARKER_BLOCK_SIZE;

static union Lisp_Misc *marker_free_list;

/* Return a newly allocated Lisp_Misc object of specified TYPE.  */

static Lisp_Object
allocate_misc (enum Lisp_Misc_Type type)
{
  Lisp_Object val;

  MALLOC_BLOCK_INPUT;

  if (marker_free_list)
    {
      XSETMISC (val, marker_free_list);
      marker_free_list = marker_free_list->u_free.chain;
    }
  else
    {
      if (marker_block_index == MARKER_BLOCK_SIZE)
	{
	  struct marker_block *new = lisp_malloc (sizeof *new, MEM_TYPE_MISC);
	  new->next = marker_block;
	  marker_block = new;
	  marker_block_index = 0;
	  total_free_markers += MARKER_BLOCK_SIZE;
	}
      XSETMISC (val, &marker_block->markers[marker_block_index].m);
      marker_block_index++;
    }

  MALLOC_UNBLOCK_INPUT;

  --total_free_markers;
  consing_since_gc += sizeof (union Lisp_Misc);
  misc_objects_consed++;
  XMISCTYPE (val) = type;
  XMISCANY (val)->gcmarkbit = 0;
  return val;
}

/* Free a Lisp_Misc object */

static void
free_misc (Lisp_Object misc)
{
  XMISCTYPE (misc) = Lisp_Misc_Free;
  XMISC (misc)->u_free.chain = marker_free_list;
  marker_free_list = XMISC (misc);
  consing_since_gc -= sizeof (union Lisp_Misc);
  total_free_markers++;
}

/* Return a Lisp_Misc_Save_Value object containing POINTER and
   INTEGER.  This is used to package C values to call record_unwind_protect.
   The unwind function can get the C values back using XSAVE_VALUE.  */

Lisp_Object
make_save_value (void *pointer, ptrdiff_t integer)
{
  register Lisp_Object val;
  register struct Lisp_Save_Value *p;

  val = allocate_misc (Lisp_Misc_Save_Value);
  p = XSAVE_VALUE (val);
  p->pointer = pointer;
  p->integer = integer;
  p->dogc = 0;
  return val;
}

/* Free a Lisp_Misc_Save_Value object.  */

void
free_save_value (Lisp_Object save)
{
  register struct Lisp_Save_Value *p = XSAVE_VALUE (save);

  p->dogc = 0;
  xfree (p->pointer);
  p->pointer = NULL;
  free_misc (save);
}

/* Return a Lisp_Misc_Overlay object with specified START, END and PLIST.  */

Lisp_Object
build_overlay (Lisp_Object start, Lisp_Object end, Lisp_Object plist)
{
  register Lisp_Object overlay;

  overlay = allocate_misc (Lisp_Misc_Overlay);
  OVERLAY_START (overlay) = start;
  OVERLAY_END (overlay) = end;
  set_overlay_plist (overlay, plist);
  XOVERLAY (overlay)->next = NULL;
  return overlay;
}

DEFUN ("make-marker", Fmake_marker, Smake_marker, 0, 0, 0,
       doc: /* Return a newly allocated marker which does not point at any place.  */)
  (void)
{
  register Lisp_Object val;
  register struct Lisp_Marker *p;

  val = allocate_misc (Lisp_Misc_Marker);
  p = XMARKER (val);
  p->buffer = 0;
  p->bytepos = 0;
  p->charpos = 0;
  p->next = NULL;
  p->insertion_type = 0;
  return val;
}

/* Return a newly allocated marker which points into BUF
   at character position CHARPOS and byte position BYTEPOS.  */

Lisp_Object
build_marker (struct buffer *buf, ptrdiff_t charpos, ptrdiff_t bytepos)
{
  Lisp_Object obj;
  struct Lisp_Marker *m;

  /* No dead buffers here.  */
  eassert (BUFFER_LIVE_P (buf));

  /* Every character is at least one byte.  */
  eassert (charpos <= bytepos);

  obj = allocate_misc (Lisp_Misc_Marker);
  m = XMARKER (obj);
  m->buffer = buf;
  m->charpos = charpos;
  m->bytepos = bytepos;
  m->insertion_type = 0;
  m->next = BUF_MARKERS (buf);
  BUF_MARKERS (buf) = m;
  return obj;
}

/* Put MARKER back on the free list after using it temporarily.  */

void
free_marker (Lisp_Object marker)
{
  unchain_marker (XMARKER (marker));
  free_misc (marker);
}


/* Return a newly created vector or string with specified arguments as
   elements.  If all the arguments are characters that can fit
   in a string of events, make a string; otherwise, make a vector.

   Any number of arguments, even zero arguments, are allowed.  */

Lisp_Object
make_event_array (register int nargs, Lisp_Object *args)
{
  int i;

  for (i = 0; i < nargs; i++)
    /* The things that fit in a string
       are characters that are in 0...127,
       after discarding the meta bit and all the bits above it.  */
    if (!INTEGERP (args[i])
	|| (XINT (args[i]) & ~(-CHAR_META)) >= 0200)
      return Fvector (nargs, args);

  /* Since the loop exited, we know that all the things in it are
     characters, so we can make a string.  */
  {
    Lisp_Object result;

    result = Fmake_string (make_number (nargs), make_number (0));
    for (i = 0; i < nargs; i++)
      {
	SSET (result, i, XINT (args[i]));
	/* Move the meta bit to the right place for a string char.  */
	if (XINT (args[i]) & CHAR_META)
	  SSET (result, i, SREF (result, i) | 0x80);
      }

    return result;
  }
}



/************************************************************************
			   Memory Full Handling
 ************************************************************************/


/* Called if malloc (NBYTES) returns zero.  If NBYTES == SIZE_MAX,
   there may have been size_t overflow so that malloc was never
   called, or perhaps malloc was invoked successfully but the
   resulting pointer had problems fitting into a tagged EMACS_INT.  In
   either case this counts as memory being full even though malloc did
   not fail.  */

void
memory_full (size_t nbytes)
{
  /* Do not go into hysterics merely because a large request failed.  */
  bool enough_free_memory = 0;
  if (SPARE_MEMORY < nbytes)
    {
      void *p;

      MALLOC_BLOCK_INPUT;
      p = malloc (SPARE_MEMORY);
      if (p)
	{
	  free (p);
	  enough_free_memory = 1;
	}
      MALLOC_UNBLOCK_INPUT;
    }

  if (! enough_free_memory)
    {
      int i;

      Vmemory_full = Qt;

      memory_full_cons_threshold = sizeof (struct cons_block);

      /* The first time we get here, free the spare memory.  */
      for (i = 0; i < sizeof (spare_memory) / sizeof (char *); i++)
	if (spare_memory[i])
	  {
	    if (i == 0)
	      free (spare_memory[i]);
	    else if (i >= 1 && i <= 4)
	      lisp_align_free (spare_memory[i]);
	    else
	      lisp_free (spare_memory[i]);
	    spare_memory[i] = 0;
	  }
    }

  /* This used to call error, but if we've run out of memory, we could
     get infinite recursion trying to build the string.  */
  xsignal (Qnil, Vmemory_signal_data);
}

/* If we released our reserve (due to running out of memory),
   and we have a fair amount free once again,
   try to set aside another reserve in case we run out once more.

   This is called when a relocatable block is freed in ralloc.c,
   and also directly from this file, in case we're not using ralloc.c.  */

void
refill_memory_reserve (void)
{
#ifndef SYSTEM_MALLOC
  if (spare_memory[0] == 0)
    spare_memory[0] = malloc (SPARE_MEMORY);
  if (spare_memory[1] == 0)
    spare_memory[1] = lisp_align_malloc (sizeof (struct cons_block),
						  MEM_TYPE_SPARE);
  if (spare_memory[2] == 0)
    spare_memory[2] = lisp_align_malloc (sizeof (struct cons_block),
					 MEM_TYPE_SPARE);
  if (spare_memory[3] == 0)
    spare_memory[3] = lisp_align_malloc (sizeof (struct cons_block),
					 MEM_TYPE_SPARE);
  if (spare_memory[4] == 0)
    spare_memory[4] = lisp_align_malloc (sizeof (struct cons_block),
					 MEM_TYPE_SPARE);
  if (spare_memory[5] == 0)
    spare_memory[5] = lisp_malloc (sizeof (struct string_block),
				   MEM_TYPE_SPARE);
  if (spare_memory[6] == 0)
    spare_memory[6] = lisp_malloc (sizeof (struct string_block),
				   MEM_TYPE_SPARE);
  if (spare_memory[0] && spare_memory[1] && spare_memory[5])
    Vmemory_full = Qnil;
#endif
}

/************************************************************************
			   C Stack Marking
 ************************************************************************/

#if GC_MARK_STACK || defined GC_MALLOC_CHECK

/* Conservative C stack marking requires a method to identify possibly
   live Lisp objects given a pointer value.  We do this by keeping
   track of blocks of Lisp data that are allocated in a red-black tree
   (see also the comment of mem_node which is the type of nodes in
   that tree).  Function lisp_malloc adds information for an allocated
   block to the red-black tree with calls to mem_insert, and function
   lisp_free removes it with mem_delete.  Functions live_string_p etc
   call mem_find to lookup information about a given pointer in the
   tree, and use that to determine if the pointer points to a Lisp
   object or not.  */

/* Initialize this part of alloc.c.  */

static void
mem_init (void)
{
  mem_z.left = mem_z.right = MEM_NIL;
  mem_z.parent = NULL;
  mem_z.color = MEM_BLACK;
  mem_z.start = mem_z.end = NULL;
  mem_root = MEM_NIL;
}


/* Value is a pointer to the mem_node containing START.  Value is
   MEM_NIL if there is no node in the tree containing START.  */

static struct mem_node *
mem_find (void *start)
{
  struct mem_node *p;

  if (start < min_heap_address || start > max_heap_address)
    return MEM_NIL;

  /* Make the search always successful to speed up the loop below.  */
  mem_z.start = start;
  mem_z.end = (char *) start + 1;

  p = mem_root;
  while (start < p->start || start >= p->end)
    p = start < p->start ? p->left : p->right;
  return p;
}


/* Insert a new node into the tree for a block of memory with start
   address START, end address END, and type TYPE.  Value is a
   pointer to the node that was inserted.  */

static struct mem_node *
mem_insert (void *start, void *end, enum mem_type type)
{
  struct mem_node *c, *parent, *x;

  if (min_heap_address == NULL || start < min_heap_address)
    min_heap_address = start;
  if (max_heap_address == NULL || end > max_heap_address)
    max_heap_address = end;

  /* See where in the tree a node for START belongs.  In this
     particular application, it shouldn't happen that a node is already
     present.  For debugging purposes, let's check that.  */
  c = mem_root;
  parent = NULL;

#if GC_MARK_STACK != GC_MAKE_GCPROS_NOOPS

  while (c != MEM_NIL)
    {
      if (start >= c->start && start < c->end)
	emacs_abort ();
      parent = c;
      c = start < c->start ? c->left : c->right;
    }

#else /* GC_MARK_STACK == GC_MARK_STACK_CHECK_GCPROS */

  while (c != MEM_NIL)
    {
      parent = c;
      c = start < c->start ? c->left : c->right;
    }

#endif /* GC_MARK_STACK == GC_MARK_STACK_CHECK_GCPROS */

  /* Create a new node.  */
#ifdef GC_MALLOC_CHECK
  x = malloc (sizeof *x);
  if (x == NULL)
    emacs_abort ();
#else
  x = xmalloc (sizeof *x);
#endif
  x->start = start;
  x->end = end;
  x->type = type;
  x->parent = parent;
  x->left = x->right = MEM_NIL;
  x->color = MEM_RED;

  /* Insert it as child of PARENT or install it as root.  */
  if (parent)
    {
      if (start < parent->start)
	parent->left = x;
      else
	parent->right = x;
    }
  else
    mem_root = x;

  /* Re-establish red-black tree properties.  */
  mem_insert_fixup (x);

  return x;
}


/* Re-establish the red-black properties of the tree, and thereby
   balance the tree, after node X has been inserted; X is always red.  */

static void
mem_insert_fixup (struct mem_node *x)
{
  while (x != mem_root && x->parent->color == MEM_RED)
    {
      /* X is red and its parent is red.  This is a violation of
	 red-black tree property #3.  */

      if (x->parent == x->parent->parent->left)
	{
	  /* We're on the left side of our grandparent, and Y is our
	     "uncle".  */
	  struct mem_node *y = x->parent->parent->right;

	  if (y->color == MEM_RED)
	    {
	      /* Uncle and parent are red but should be black because
		 X is red.  Change the colors accordingly and proceed
		 with the grandparent.  */
	      x->parent->color = MEM_BLACK;
	      y->color = MEM_BLACK;
	      x->parent->parent->color = MEM_RED;
	      x = x->parent->parent;
            }
	  else
	    {
	      /* Parent and uncle have different colors; parent is
		 red, uncle is black.  */
	      if (x == x->parent->right)
		{
		  x = x->parent;
		  mem_rotate_left (x);
                }

	      x->parent->color = MEM_BLACK;
	      x->parent->parent->color = MEM_RED;
	      mem_rotate_right (x->parent->parent);
            }
        }
      else
	{
	  /* This is the symmetrical case of above.  */
	  struct mem_node *y = x->parent->parent->left;

	  if (y->color == MEM_RED)
	    {
	      x->parent->color = MEM_BLACK;
	      y->color = MEM_BLACK;
	      x->parent->parent->color = MEM_RED;
	      x = x->parent->parent;
            }
	  else
	    {
	      if (x == x->parent->left)
		{
		  x = x->parent;
		  mem_rotate_right (x);
		}

	      x->parent->color = MEM_BLACK;
	      x->parent->parent->color = MEM_RED;
	      mem_rotate_left (x->parent->parent);
            }
        }
    }

  /* The root may have been changed to red due to the algorithm.  Set
     it to black so that property #5 is satisfied.  */
  mem_root->color = MEM_BLACK;
}


/*   (x)                   (y)
     / \                   / \
    a   (y)      ===>    (x)  c
        / \              / \
       b   c            a   b  */

static void
mem_rotate_left (struct mem_node *x)
{
  struct mem_node *y;

  /* Turn y's left sub-tree into x's right sub-tree.  */
  y = x->right;
  x->right = y->left;
  if (y->left != MEM_NIL)
    y->left->parent = x;

  /* Y's parent was x's parent.  */
  if (y != MEM_NIL)
    y->parent = x->parent;

  /* Get the parent to point to y instead of x.  */
  if (x->parent)
    {
      if (x == x->parent->left)
	x->parent->left = y;
      else
	x->parent->right = y;
    }
  else
    mem_root = y;

  /* Put x on y's left.  */
  y->left = x;
  if (x != MEM_NIL)
    x->parent = y;
}


/*     (x)                (Y)
       / \                / \
     (y)  c      ===>    a  (x)
     / \                    / \
    a   b                  b   c  */

static void
mem_rotate_right (struct mem_node *x)
{
  struct mem_node *y = x->left;

  x->left = y->right;
  if (y->right != MEM_NIL)
    y->right->parent = x;

  if (y != MEM_NIL)
    y->parent = x->parent;
  if (x->parent)
    {
      if (x == x->parent->right)
	x->parent->right = y;
      else
	x->parent->left = y;
    }
  else
    mem_root = y;

  y->right = x;
  if (x != MEM_NIL)
    x->parent = y;
}


/* Delete node Z from the tree.  If Z is null or MEM_NIL, do nothing.  */

static void
mem_delete (struct mem_node *z)
{
  struct mem_node *x, *y;

  if (!z || z == MEM_NIL)
    return;

  if (z->left == MEM_NIL || z->right == MEM_NIL)
    y = z;
  else
    {
      y = z->right;
      while (y->left != MEM_NIL)
	y = y->left;
    }

  if (y->left != MEM_NIL)
    x = y->left;
  else
    x = y->right;

  x->parent = y->parent;
  if (y->parent)
    {
      if (y == y->parent->left)
	y->parent->left = x;
      else
	y->parent->right = x;
    }
  else
    mem_root = x;

  if (y != z)
    {
      z->start = y->start;
      z->end = y->end;
      z->type = y->type;
    }

  if (y->color == MEM_BLACK)
    mem_delete_fixup (x);

#ifdef GC_MALLOC_CHECK
  free (y);
#else
  xfree (y);
#endif
}


/* Re-establish the red-black properties of the tree, after a
   deletion.  */

static void
mem_delete_fixup (struct mem_node *x)
{
  while (x != mem_root && x->color == MEM_BLACK)
    {
      if (x == x->parent->left)
	{
	  struct mem_node *w = x->parent->right;

	  if (w->color == MEM_RED)
	    {
	      w->color = MEM_BLACK;
	      x->parent->color = MEM_RED;
	      mem_rotate_left (x->parent);
	      w = x->parent->right;
            }

	  if (w->left->color == MEM_BLACK && w->right->color == MEM_BLACK)
	    {
	      w->color = MEM_RED;
	      x = x->parent;
            }
	  else
	    {
	      if (w->right->color == MEM_BLACK)
		{
		  w->left->color = MEM_BLACK;
		  w->color = MEM_RED;
		  mem_rotate_right (w);
		  w = x->parent->right;
                }
	      w->color = x->parent->color;
	      x->parent->color = MEM_BLACK;
	      w->right->color = MEM_BLACK;
	      mem_rotate_left (x->parent);
	      x = mem_root;
            }
        }
      else
	{
	  struct mem_node *w = x->parent->left;

	  if (w->color == MEM_RED)
	    {
	      w->color = MEM_BLACK;
	      x->parent->color = MEM_RED;
	      mem_rotate_right (x->parent);
	      w = x->parent->left;
            }

	  if (w->right->color == MEM_BLACK && w->left->color == MEM_BLACK)
	    {
	      w->color = MEM_RED;
	      x = x->parent;
            }
	  else
	    {
	      if (w->left->color == MEM_BLACK)
		{
		  w->right->color = MEM_BLACK;
		  w->color = MEM_RED;
		  mem_rotate_left (w);
		  w = x->parent->left;
                }

	      w->color = x->parent->color;
	      x->parent->color = MEM_BLACK;
	      w->left->color = MEM_BLACK;
	      mem_rotate_right (x->parent);
	      x = mem_root;
            }
        }
    }

  x->color = MEM_BLACK;
}


/* Value is non-zero if P is a pointer to a live Lisp string on
   the heap.  M is a pointer to the mem_block for P.  */

static bool
live_string_p (struct mem_node *m, void *p)
{
  if (m->type == MEM_TYPE_STRING)
    {
      struct string_block *b = (struct string_block *) m->start;
      ptrdiff_t offset = (char *) p - (char *) &b->strings[0];

      /* P must point to the start of a Lisp_String structure, and it
	 must not be on the free-list.  */
      return (offset >= 0
	      && offset % sizeof b->strings[0] == 0
	      && offset < (STRING_BLOCK_SIZE * sizeof b->strings[0])
	      && ((struct Lisp_String *) p)->data != NULL);
    }
  else
    return 0;
}


/* Value is non-zero if P is a pointer to a live Lisp cons on
   the heap.  M is a pointer to the mem_block for P.  */

static bool
live_cons_p (struct mem_node *m, void *p)
{
  if (m->type == MEM_TYPE_CONS)
    {
      struct cons_block *b = (struct cons_block *) m->start;
      ptrdiff_t offset = (char *) p - (char *) &b->conses[0];

      /* P must point to the start of a Lisp_Cons, not be
	 one of the unused cells in the current cons block,
	 and not be on the free-list.  */
      return (offset >= 0
	      && offset % sizeof b->conses[0] == 0
	      && offset < (CONS_BLOCK_SIZE * sizeof b->conses[0])
	      && (b != cons_block
		  || offset / sizeof b->conses[0] < cons_block_index)
	      && !EQ (((struct Lisp_Cons *) p)->car, Vdead));
    }
  else
    return 0;
}


/* Value is non-zero if P is a pointer to a live Lisp symbol on
   the heap.  M is a pointer to the mem_block for P.  */

static bool
live_symbol_p (struct mem_node *m, void *p)
{
  if (m->type == MEM_TYPE_SYMBOL)
    {
      struct symbol_block *b = (struct symbol_block *) m->start;
      ptrdiff_t offset = (char *) p - (char *) &b->symbols[0];

      /* P must point to the start of a Lisp_Symbol, not be
	 one of the unused cells in the current symbol block,
	 and not be on the free-list.  */
      return (offset >= 0
	      && offset % sizeof b->symbols[0] == 0
	      && offset < (SYMBOL_BLOCK_SIZE * sizeof b->symbols[0])
	      && (b != symbol_block
		  || offset / sizeof b->symbols[0] < symbol_block_index)
	      && !EQ (((struct Lisp_Symbol *)p)->function, Vdead));
    }
  else
    return 0;
}


/* Value is non-zero if P is a pointer to a live Lisp float on
   the heap.  M is a pointer to the mem_block for P.  */

static bool
live_float_p (struct mem_node *m, void *p)
{
  if (m->type == MEM_TYPE_FLOAT)
    {
      struct float_block *b = (struct float_block *) m->start;
      ptrdiff_t offset = (char *) p - (char *) &b->floats[0];

      /* P must point to the start of a Lisp_Float and not be
	 one of the unused cells in the current float block.  */
      return (offset >= 0
	      && offset % sizeof b->floats[0] == 0
	      && offset < (FLOAT_BLOCK_SIZE * sizeof b->floats[0])
	      && (b != float_block
		  || offset / sizeof b->floats[0] < float_block_index));
    }
  else
    return 0;
}


/* Value is non-zero if P is a pointer to a live Lisp Misc on
   the heap.  M is a pointer to the mem_block for P.  */

static bool
live_misc_p (struct mem_node *m, void *p)
{
  if (m->type == MEM_TYPE_MISC)
    {
      struct marker_block *b = (struct marker_block *) m->start;
      ptrdiff_t offset = (char *) p - (char *) &b->markers[0];

      /* P must point to the start of a Lisp_Misc, not be
	 one of the unused cells in the current misc block,
	 and not be on the free-list.  */
      return (offset >= 0
	      && offset % sizeof b->markers[0] == 0
	      && offset < (MARKER_BLOCK_SIZE * sizeof b->markers[0])
	      && (b != marker_block
		  || offset / sizeof b->markers[0] < marker_block_index)
	      && ((union Lisp_Misc *) p)->u_any.type != Lisp_Misc_Free);
    }
  else
    return 0;
}


/* Value is non-zero if P is a pointer to a live vector-like object.
   M is a pointer to the mem_block for P.  */

static bool
live_vector_p (struct mem_node *m, void *p)
{
  if (m->type == MEM_TYPE_VECTOR_BLOCK)
    {
      /* This memory node corresponds to a vector block.  */
      struct vector_block *block = (struct vector_block *) m->start;
      struct Lisp_Vector *vector = (struct Lisp_Vector *) block->data;

      /* P is in the block's allocation range.  Scan the block
	 up to P and see whether P points to the start of some
	 vector which is not on a free list.  FIXME: check whether
	 some allocation patterns (probably a lot of short vectors)
	 may cause a substantial overhead of this loop.  */
      while (VECTOR_IN_BLOCK (vector, block)
	     && vector <= (struct Lisp_Vector *) p)
	{
	  if (!PSEUDOVECTOR_TYPEP (&vector->header, PVEC_FREE) && vector == p)
	    return 1;
	  else
	    vector = ADVANCE (vector, vector_nbytes (vector));
	}
    }
  else if (m->type == MEM_TYPE_VECTORLIKE
	   && (char *) p == ((char *) m->start
			     + offsetof (struct large_vector, v)))
    /* This memory node corresponds to a large vector.  */
    return 1;
  return 0;
}


/* Value is non-zero if P is a pointer to a live buffer.  M is a
   pointer to the mem_block for P.  */

static bool
live_buffer_p (struct mem_node *m, void *p)
{
  /* P must point to the start of the block, and the buffer
     must not have been killed.  */
  return (m->type == MEM_TYPE_BUFFER
	  && p == m->start
	  && !NILP (((struct buffer *) p)->INTERNAL_FIELD (name)));
}

#endif /* GC_MARK_STACK || defined GC_MALLOC_CHECK */

#if GC_MARK_STACK

#if GC_MARK_STACK == GC_USE_GCPROS_CHECK_ZOMBIES

/* Array of objects that are kept alive because the C stack contains
   a pattern that looks like a reference to them .  */

#define MAX_ZOMBIES 10
static Lisp_Object zombies[MAX_ZOMBIES];

/* Number of zombie objects.  */

static EMACS_INT nzombies;

/* Number of garbage collections.  */

static EMACS_INT ngcs;

/* Average percentage of zombies per collection.  */

static double avg_zombies;

/* Max. number of live and zombie objects.  */

static EMACS_INT max_live, max_zombies;

/* Average number of live objects per GC.  */

static double avg_live;

DEFUN ("gc-status", Fgc_status, Sgc_status, 0, 0, "",
       doc: /* Show information about live and zombie objects.  */)
  (void)
{
  Lisp_Object args[8], zombie_list = Qnil;
  EMACS_INT i;
  for (i = 0; i < min (MAX_ZOMBIES, nzombies); i++)
    zombie_list = Fcons (zombies[i], zombie_list);
  args[0] = build_string ("%d GCs, avg live/zombies = %.2f/%.2f (%f%%), max %d/%d\nzombies: %S");
  args[1] = make_number (ngcs);
  args[2] = make_float (avg_live);
  args[3] = make_float (avg_zombies);
  args[4] = make_float (avg_zombies / avg_live / 100);
  args[5] = make_number (max_live);
  args[6] = make_number (max_zombies);
  args[7] = zombie_list;
  return Fmessage (8, args);
}

#endif /* GC_MARK_STACK == GC_USE_GCPROS_CHECK_ZOMBIES */


/* Mark OBJ if we can prove it's a Lisp_Object.  */

static void
mark_maybe_object (Lisp_Object obj)
{
  void *po;
  struct mem_node *m;

  if (INTEGERP (obj))
    return;

  po = (void *) XPNTR (obj);
  m = mem_find (po);

  if (m != MEM_NIL)
    {
      bool mark_p = 0;

      switch (XTYPE (obj))
	{
	case Lisp_String:
	  mark_p = (live_string_p (m, po)
		    && !STRING_MARKED_P ((struct Lisp_String *) po));
	  break;

	case Lisp_Cons:
	  mark_p = (live_cons_p (m, po) && !CONS_MARKED_P (XCONS (obj)));
	  break;

	case Lisp_Symbol:
	  mark_p = (live_symbol_p (m, po) && !XSYMBOL (obj)->gcmarkbit);
	  break;

	case Lisp_Float:
	  mark_p = (live_float_p (m, po) && !FLOAT_MARKED_P (XFLOAT (obj)));
	  break;

	case Lisp_Vectorlike:
	  /* Note: can't check BUFFERP before we know it's a
	     buffer because checking that dereferences the pointer
	     PO which might point anywhere.  */
	  if (live_vector_p (m, po))
	    mark_p = !SUBRP (obj) && !VECTOR_MARKED_P (XVECTOR (obj));
	  else if (live_buffer_p (m, po))
	    mark_p = BUFFERP (obj) && !VECTOR_MARKED_P (XBUFFER (obj));
	  break;

	case Lisp_Misc:
	  mark_p = (live_misc_p (m, po) && !XMISCANY (obj)->gcmarkbit);
	  break;

	default:
	  break;
	}

      if (mark_p)
	{
#if GC_MARK_STACK == GC_USE_GCPROS_CHECK_ZOMBIES
	  if (nzombies < MAX_ZOMBIES)
	    zombies[nzombies] = obj;
	  ++nzombies;
#endif
	  mark_object (obj);
	}
    }
}


/* If P points to Lisp data, mark that as live if it isn't already
   marked.  */

static void
mark_maybe_pointer (void *p)
{
  struct mem_node *m;

  /* Quickly rule out some values which can't point to Lisp data.
     USE_LSB_TAG needs Lisp data to be aligned on multiples of GCALIGNMENT.
     Otherwise, assume that Lisp data is aligned on even addresses.  */
  if ((intptr_t) p % (USE_LSB_TAG ? GCALIGNMENT : 2))
    return;

  m = mem_find (p);
  if (m != MEM_NIL)
    {
      Lisp_Object obj = Qnil;

      switch (m->type)
	{
	case MEM_TYPE_NON_LISP:
	case MEM_TYPE_SPARE:
	  /* Nothing to do; not a pointer to Lisp memory.  */
	  break;

	case MEM_TYPE_BUFFER:
	  if (live_buffer_p (m, p) && !VECTOR_MARKED_P ((struct buffer *)p))
	    XSETVECTOR (obj, p);
	  break;

	case MEM_TYPE_CONS:
	  if (live_cons_p (m, p) && !CONS_MARKED_P ((struct Lisp_Cons *) p))
	    XSETCONS (obj, p);
	  break;

	case MEM_TYPE_STRING:
	  if (live_string_p (m, p)
	      && !STRING_MARKED_P ((struct Lisp_String *) p))
	    XSETSTRING (obj, p);
	  break;

	case MEM_TYPE_MISC:
	  if (live_misc_p (m, p) && !((struct Lisp_Free *) p)->gcmarkbit)
	    XSETMISC (obj, p);
	  break;

	case MEM_TYPE_SYMBOL:
	  if (live_symbol_p (m, p) && !((struct Lisp_Symbol *) p)->gcmarkbit)
	    XSETSYMBOL (obj, p);
	  break;

	case MEM_TYPE_FLOAT:
	  if (live_float_p (m, p) && !FLOAT_MARKED_P (p))
	    XSETFLOAT (obj, p);
	  break;

	case MEM_TYPE_VECTORLIKE:
	case MEM_TYPE_VECTOR_BLOCK:
	  if (live_vector_p (m, p))
	    {
	      Lisp_Object tem;
	      XSETVECTOR (tem, p);
	      if (!SUBRP (tem) && !VECTOR_MARKED_P (XVECTOR (tem)))
		obj = tem;
	    }
	  break;

	default:
	  emacs_abort ();
	}

      if (!NILP (obj))
	mark_object (obj);
    }
}


/* Alignment of pointer values.  Use alignof, as it sometimes returns
   a smaller alignment than GCC's __alignof__ and mark_memory might
   miss objects if __alignof__ were used.  */
#define GC_POINTER_ALIGNMENT alignof (void *)

/* Define POINTERS_MIGHT_HIDE_IN_OBJECTS to 1 if marking via C pointers does
   not suffice, which is the typical case.  A host where a Lisp_Object is
   wider than a pointer might allocate a Lisp_Object in non-adjacent halves.
   If USE_LSB_TAG, the bottom half is not a valid pointer, but it should
   suffice to widen it to to a Lisp_Object and check it that way.  */
#if USE_LSB_TAG || VAL_MAX < UINTPTR_MAX
# if !USE_LSB_TAG && VAL_MAX < UINTPTR_MAX >> GCTYPEBITS
  /* If tag bits straddle pointer-word boundaries, neither mark_maybe_pointer
     nor mark_maybe_object can follow the pointers.  This should not occur on
     any practical porting target.  */
#  error "MSB type bits straddle pointer-word boundaries"
# endif
  /* Marking via C pointers does not suffice, because Lisp_Objects contain
     pointer words that hold pointers ORed with type bits.  */
# define POINTERS_MIGHT_HIDE_IN_OBJECTS 1
#else
  /* Marking via C pointers suffices, because Lisp_Objects contain pointer
     words that hold unmodified pointers.  */
# define POINTERS_MIGHT_HIDE_IN_OBJECTS 0
#endif

/* Mark Lisp objects referenced from the address range START+OFFSET..END
   or END+OFFSET..START. */

static void
mark_memory (void *start, void *end)
#if defined (__clang__) && defined (__has_feature)
#if __has_feature(address_sanitizer)
  /* Do not allow -faddress-sanitizer to check this function, since it
     crosses the function stack boundary, and thus would yield many
     false positives. */
  __attribute__((no_address_safety_analysis))
#endif
#endif
{
  void **pp;
  int i;

#if GC_MARK_STACK == GC_USE_GCPROS_CHECK_ZOMBIES
  nzombies = 0;
#endif

  /* Make START the pointer to the start of the memory region,
     if it isn't already.  */
  if (end < start)
    {
      void *tem = start;
      start = end;
      end = tem;
    }

  /* Mark Lisp data pointed to.  This is necessary because, in some
     situations, the C compiler optimizes Lisp objects away, so that
     only a pointer to them remains.  Example:

     DEFUN ("testme", Ftestme, Stestme, 0, 0, 0, "")
     ()
     {
       Lisp_Object obj = build_string ("test");
       struct Lisp_String *s = XSTRING (obj);
       Fgarbage_collect ();
       fprintf (stderr, "test `%s'\n", s->data);
       return Qnil;
     }

     Here, `obj' isn't really used, and the compiler optimizes it
     away.  The only reference to the life string is through the
     pointer `s'.  */

  for (pp = start; (void *) pp < end; pp++)
    for (i = 0; i < sizeof *pp; i += GC_POINTER_ALIGNMENT)
      {
	void *p = *(void **) ((char *) pp + i);
	mark_maybe_pointer (p);
	if (POINTERS_MIGHT_HIDE_IN_OBJECTS)
	  mark_maybe_object (XIL ((intptr_t) p));
      }
}

/* setjmp will work with GCC unless NON_SAVING_SETJMP is defined in
   the GCC system configuration.  In gcc 3.2, the only systems for
   which this is so are i386-sco5 non-ELF, i386-sysv3 (maybe included
   by others?) and ns32k-pc532-min.  */

#if !defined GC_SAVE_REGISTERS_ON_STACK && !defined GC_SETJMP_WORKS

static bool setjmp_tested_p;
static int longjmps_done;

#define SETJMP_WILL_LIKELY_WORK "\
\n\
Emacs garbage collector has been changed to use conservative stack\n\
marking.  Emacs has determined that the method it uses to do the\n\
marking will likely work on your system, but this isn't sure.\n\
\n\
If you are a system-programmer, or can get the help of a local wizard\n\
who is, please take a look at the function mark_stack in alloc.c, and\n\
verify that the methods used are appropriate for your system.\n\
\n\
Please mail the result to <emacs-devel@gnu.org>.\n\
"

#define SETJMP_WILL_NOT_WORK "\
\n\
Emacs garbage collector has been changed to use conservative stack\n\
marking.  Emacs has determined that the default method it uses to do the\n\
marking will not work on your system.  We will need a system-dependent\n\
solution for your system.\n\
\n\
Please take a look at the function mark_stack in alloc.c, and\n\
try to find a way to make it work on your system.\n\
\n\
Note that you may get false negatives, depending on the compiler.\n\
In particular, you need to use -O with GCC for this test.\n\
\n\
Please mail the result to <emacs-devel@gnu.org>.\n\
"


/* Perform a quick check if it looks like setjmp saves registers in a
   jmp_buf.  Print a message to stderr saying so.  When this test
   succeeds, this is _not_ a proof that setjmp is sufficient for
   conservative stack marking.  Only the sources or a disassembly
   can prove that.  */

static void
test_setjmp (void)
{
  char buf[10];
  register int x;
  sys_jmp_buf jbuf;

  /* Arrange for X to be put in a register.  */
  sprintf (buf, "1");
  x = strlen (buf);
  x = 2 * x - 1;

  sys_setjmp (jbuf);
  if (longjmps_done == 1)
    {
      /* Came here after the longjmp at the end of the function.

         If x == 1, the longjmp has restored the register to its
         value before the setjmp, and we can hope that setjmp
         saves all such registers in the jmp_buf, although that
	 isn't sure.

         For other values of X, either something really strange is
         taking place, or the setjmp just didn't save the register.  */

      if (x == 1)
	fprintf (stderr, SETJMP_WILL_LIKELY_WORK);
      else
	{
	  fprintf (stderr, SETJMP_WILL_NOT_WORK);
	  exit (1);
	}
    }

  ++longjmps_done;
  x = 2;
  if (longjmps_done == 1)
    sys_longjmp (jbuf, 1);
}

#endif /* not GC_SAVE_REGISTERS_ON_STACK && not GC_SETJMP_WORKS */


#if GC_MARK_STACK == GC_MARK_STACK_CHECK_GCPROS

/* Abort if anything GCPRO'd doesn't survive the GC.  */

static void
check_gcpros (void)
{
  struct gcpro *p;
  ptrdiff_t i;

  for (p = gcprolist; p; p = p->next)
    for (i = 0; i < p->nvars; ++i)
      if (!survives_gc_p (p->var[i]))
	/* FIXME: It's not necessarily a bug.  It might just be that the
	   GCPRO is unnecessary or should release the object sooner.  */
	emacs_abort ();
}

#elif GC_MARK_STACK == GC_USE_GCPROS_CHECK_ZOMBIES

static void
dump_zombies (void)
{
  int i;

  fprintf (stderr, "\nZombies kept alive = %"pI"d:\n", nzombies);
  for (i = 0; i < min (MAX_ZOMBIES, nzombies); ++i)
    {
      fprintf (stderr, "  %d = ", i);
      debug_print (zombies[i]);
    }
}

#endif /* GC_MARK_STACK == GC_USE_GCPROS_CHECK_ZOMBIES */


/* Mark live Lisp objects on the C stack.

   There are several system-dependent problems to consider when
   porting this to new architectures:

   Processor Registers

   We have to mark Lisp objects in CPU registers that can hold local
   variables or are used to pass parameters.

   If GC_SAVE_REGISTERS_ON_STACK is defined, it should expand to
   something that either saves relevant registers on the stack, or
   calls mark_maybe_object passing it each register's contents.

   If GC_SAVE_REGISTERS_ON_STACK is not defined, the current
   implementation assumes that calling setjmp saves registers we need
   to see in a jmp_buf which itself lies on the stack.  This doesn't
   have to be true!  It must be verified for each system, possibly
   by taking a look at the source code of setjmp.

   If __builtin_unwind_init is available (defined by GCC >= 2.8) we
   can use it as a machine independent method to store all registers
   to the stack.  In this case the macros described in the previous
   two paragraphs are not used.

   Stack Layout

   Architectures differ in the way their processor stack is organized.
   For example, the stack might look like this

     +----------------+
     |  Lisp_Object   |  size = 4
     +----------------+
     | something else |  size = 2
     +----------------+
     |  Lisp_Object   |  size = 4
     +----------------+
     |	...	      |

   In such a case, not every Lisp_Object will be aligned equally.  To
   find all Lisp_Object on the stack it won't be sufficient to walk
   the stack in steps of 4 bytes.  Instead, two passes will be
   necessary, one starting at the start of the stack, and a second
   pass starting at the start of the stack + 2.  Likewise, if the
   minimal alignment of Lisp_Objects on the stack is 1, four passes
   would be necessary, each one starting with one byte more offset
   from the stack start.  */

static void
mark_stack (void)
{
  void *end;

#ifdef HAVE___BUILTIN_UNWIND_INIT
  /* Force callee-saved registers and register windows onto the stack.
     This is the preferred method if available, obviating the need for
     machine dependent methods.  */
  __builtin_unwind_init ();
  end = &end;
#else /* not HAVE___BUILTIN_UNWIND_INIT */
#ifndef GC_SAVE_REGISTERS_ON_STACK
  /* jmp_buf may not be aligned enough on darwin-ppc64 */
  union aligned_jmpbuf {
    Lisp_Object o;
    sys_jmp_buf j;
  } j;
  volatile bool stack_grows_down_p = (char *) &j > (char *) stack_base;
#endif
  /* This trick flushes the register windows so that all the state of
     the process is contained in the stack.  */
  /* Fixme: Code in the Boehm GC suggests flushing (with `flushrs') is
     needed on ia64 too.  See mach_dep.c, where it also says inline
     assembler doesn't work with relevant proprietary compilers.  */
#ifdef __sparc__
#if defined (__sparc64__) && defined (__FreeBSD__)
  /* FreeBSD does not have a ta 3 handler.  */
  asm ("flushw");
#else
  asm ("ta 3");
#endif
#endif

  /* Save registers that we need to see on the stack.  We need to see
     registers used to hold register variables and registers used to
     pass parameters.  */
#ifdef GC_SAVE_REGISTERS_ON_STACK
  GC_SAVE_REGISTERS_ON_STACK (end);
#else /* not GC_SAVE_REGISTERS_ON_STACK */

#ifndef GC_SETJMP_WORKS  /* If it hasn't been checked yet that
			    setjmp will definitely work, test it
			    and print a message with the result
			    of the test.  */
  if (!setjmp_tested_p)
    {
      setjmp_tested_p = 1;
      test_setjmp ();
    }
#endif /* GC_SETJMP_WORKS */

  sys_setjmp (j.j);
  end = stack_grows_down_p ? (char *) &j + sizeof j : (char *) &j;
#endif /* not GC_SAVE_REGISTERS_ON_STACK */
#endif /* not HAVE___BUILTIN_UNWIND_INIT */

  /* This assumes that the stack is a contiguous region in memory.  If
     that's not the case, something has to be done here to iterate
     over the stack segments.  */
  mark_memory (stack_base, end);

  /* Allow for marking a secondary stack, like the register stack on the
     ia64.  */
#ifdef GC_MARK_SECONDARY_STACK
  GC_MARK_SECONDARY_STACK ();
#endif

#if GC_MARK_STACK == GC_MARK_STACK_CHECK_GCPROS
  check_gcpros ();
#endif
}

#endif /* GC_MARK_STACK != 0 */


/* Determine whether it is safe to access memory at address P.  */
static int
valid_pointer_p (void *p)
{
#ifdef WINDOWSNT
  return w32_valid_pointer_p (p, 16);
#else
  int fd[2];

  /* Obviously, we cannot just access it (we would SEGV trying), so we
     trick the o/s to tell us whether p is a valid pointer.
     Unfortunately, we cannot use NULL_DEVICE here, as emacs_write may
     not validate p in that case.  */

  if (pipe (fd) == 0)
    {
      bool valid = emacs_write (fd[1], (char *) p, 16) == 16;
      emacs_close (fd[1]);
      emacs_close (fd[0]);
      return valid;
    }

    return -1;
#endif
}

/* Return 2 if OBJ is a killed or special buffer object, 1 if OBJ is a
   valid lisp object, 0 if OBJ is NOT a valid lisp object, or -1 if we
   cannot validate OBJ.  This function can be quite slow, so its primary
   use is the manual debugging.  The only exception is print_object, where
   we use it to check whether the memory referenced by the pointer of
   Lisp_Save_Value object contains valid objects.  */

int
valid_lisp_object_p (Lisp_Object obj)
{
  void *p;
#if GC_MARK_STACK
  struct mem_node *m;
#endif

  if (INTEGERP (obj))
    return 1;

  p = (void *) XPNTR (obj);
  if (PURE_POINTER_P (p))
    return 1;

  if (p == &buffer_defaults || p == &buffer_local_symbols)
    return 2;

#if !GC_MARK_STACK
  return valid_pointer_p (p);
#else

  m = mem_find (p);

  if (m == MEM_NIL)
    {
      int valid = valid_pointer_p (p);
      if (valid <= 0)
	return valid;

      if (SUBRP (obj))
	return 1;

      return 0;
    }

  switch (m->type)
    {
    case MEM_TYPE_NON_LISP:
    case MEM_TYPE_SPARE:
      return 0;

    case MEM_TYPE_BUFFER:
      return live_buffer_p (m, p) ? 1 : 2;

    case MEM_TYPE_CONS:
      return live_cons_p (m, p);

    case MEM_TYPE_STRING:
      return live_string_p (m, p);

    case MEM_TYPE_MISC:
      return live_misc_p (m, p);

    case MEM_TYPE_SYMBOL:
      return live_symbol_p (m, p);

    case MEM_TYPE_FLOAT:
      return live_float_p (m, p);

    case MEM_TYPE_VECTORLIKE:
    case MEM_TYPE_VECTOR_BLOCK:
      return live_vector_p (m, p);

    default:
      break;
    }

  return 0;
#endif
}




/***********************************************************************
		       Pure Storage Management
 ***********************************************************************/

/* Allocate room for SIZE bytes from pure Lisp storage and return a
   pointer to it.  TYPE is the Lisp type for which the memory is
   allocated.  TYPE < 0 means it's not used for a Lisp object.  */

static void *
pure_alloc (size_t size, int type)
{
  void *result;
#if USE_LSB_TAG
  size_t alignment = GCALIGNMENT;
#else
  size_t alignment = alignof (EMACS_INT);

  /* Give Lisp_Floats an extra alignment.  */
  if (type == Lisp_Float)
    alignment = alignof (struct Lisp_Float);
#endif

 again:
  if (type >= 0)
    {
      /* Allocate space for a Lisp object from the beginning of the free
	 space with taking account of alignment.  */
      result = ALIGN (purebeg + pure_bytes_used_lisp, alignment);
      pure_bytes_used_lisp = ((char *)result - (char *)purebeg) + size;
    }
  else
    {
      /* Allocate space for a non-Lisp object from the end of the free
	 space.  */
      pure_bytes_used_non_lisp += size;
      result = purebeg + pure_size - pure_bytes_used_non_lisp;
    }
  pure_bytes_used = pure_bytes_used_lisp + pure_bytes_used_non_lisp;

  if (pure_bytes_used <= pure_size)
    return result;

  /* Don't allocate a large amount here,
     because it might get mmap'd and then its address
     might not be usable.  */
  purebeg = xmalloc (10000);
  pure_size = 10000;
  pure_bytes_used_before_overflow += pure_bytes_used - size;
  pure_bytes_used = 0;
  pure_bytes_used_lisp = pure_bytes_used_non_lisp = 0;
  goto again;
}


/* Print a warning if PURESIZE is too small.  */

void
check_pure_size (void)
{
  if (pure_bytes_used_before_overflow)
    message (("emacs:0:Pure Lisp storage overflow (approx. %"pI"d"
	      " bytes needed)"),
	     pure_bytes_used + pure_bytes_used_before_overflow);
}


/* Find the byte sequence {DATA[0], ..., DATA[NBYTES-1], '\0'} from
   the non-Lisp data pool of the pure storage, and return its start
   address.  Return NULL if not found.  */

static char *
find_string_data_in_pure (const char *data, ptrdiff_t nbytes)
{
  int i;
  ptrdiff_t skip, bm_skip[256], last_char_skip, infinity, start, start_max;
  const unsigned char *p;
  char *non_lisp_beg;

  if (pure_bytes_used_non_lisp <= nbytes)
    return NULL;

  /* Set up the Boyer-Moore table.  */
  skip = nbytes + 1;
  for (i = 0; i < 256; i++)
    bm_skip[i] = skip;

  p = (const unsigned char *) data;
  while (--skip > 0)
    bm_skip[*p++] = skip;

  last_char_skip = bm_skip['\0'];

  non_lisp_beg = purebeg + pure_size - pure_bytes_used_non_lisp;
  start_max = pure_bytes_used_non_lisp - (nbytes + 1);

  /* See the comments in the function `boyer_moore' (search.c) for the
     use of `infinity'.  */
  infinity = pure_bytes_used_non_lisp + 1;
  bm_skip['\0'] = infinity;

  p = (const unsigned char *) non_lisp_beg + nbytes;
  start = 0;
  do
    {
      /* Check the last character (== '\0').  */
      do
	{
	  start += bm_skip[*(p + start)];
	}
      while (start <= start_max);

      if (start < infinity)
	/* Couldn't find the last character.  */
	return NULL;

      /* No less than `infinity' means we could find the last
	 character at `p[start - infinity]'.  */
      start -= infinity;

      /* Check the remaining characters.  */
      if (memcmp (data, non_lisp_beg + start, nbytes) == 0)
	/* Found.  */
	return non_lisp_beg + start;

      start += last_char_skip;
    }
  while (start <= start_max);

  return NULL;
}


/* Return a string allocated in pure space.  DATA is a buffer holding
   NCHARS characters, and NBYTES bytes of string data.  MULTIBYTE
   means make the result string multibyte.

   Must get an error if pure storage is full, since if it cannot hold
   a large string it may be able to hold conses that point to that
   string; then the string is not protected from gc.  */

Lisp_Object
make_pure_string (const char *data,
		  ptrdiff_t nchars, ptrdiff_t nbytes, bool multibyte)
{
  Lisp_Object string;
  struct Lisp_String *s = pure_alloc (sizeof *s, Lisp_String);
  s->data = (unsigned char *) find_string_data_in_pure (data, nbytes);
  if (s->data == NULL)
    {
      s->data = pure_alloc (nbytes + 1, -1);
      memcpy (s->data, data, nbytes);
      s->data[nbytes] = '\0';
    }
  s->size = nchars;
  s->size_byte = multibyte ? nbytes : -1;
  s->intervals = NULL;
  XSETSTRING (string, s);
  return string;
}

/* Return a string allocated in pure space.  Do not
   allocate the string data, just point to DATA.  */

Lisp_Object
make_pure_c_string (const char *data, ptrdiff_t nchars)
{
  Lisp_Object string;
  struct Lisp_String *s = pure_alloc (sizeof *s, Lisp_String);
  s->size = nchars;
  s->size_byte = -1;
  s->data = (unsigned char *) data;
  s->intervals = NULL;
  XSETSTRING (string, s);
  return string;
}

/* Return a cons allocated from pure space.  Give it pure copies
   of CAR as car and CDR as cdr.  */

Lisp_Object
pure_cons (Lisp_Object car, Lisp_Object cdr)
{
  Lisp_Object new;
  struct Lisp_Cons *p = pure_alloc (sizeof *p, Lisp_Cons);
  XSETCONS (new, p);
  XSETCAR (new, Fpurecopy (car));
  XSETCDR (new, Fpurecopy (cdr));
  return new;
}


/* Value is a float object with value NUM allocated from pure space.  */

static Lisp_Object
make_pure_float (double num)
{
  Lisp_Object new;
  struct Lisp_Float *p = pure_alloc (sizeof *p, Lisp_Float);
  XSETFLOAT (new, p);
  XFLOAT_INIT (new, num);
  return new;
}


/* Return a vector with room for LEN Lisp_Objects allocated from
   pure space.  */

static Lisp_Object
make_pure_vector (ptrdiff_t len)
{
  Lisp_Object new;
  size_t size = header_size + len * word_size;
  struct Lisp_Vector *p = pure_alloc (size, Lisp_Vectorlike);
  XSETVECTOR (new, p);
  XVECTOR (new)->header.size = len;
  return new;
}


DEFUN ("purecopy", Fpurecopy, Spurecopy, 1, 1, 0,
       doc: /* Make a copy of object OBJ in pure storage.
Recursively copies contents of vectors and cons cells.
Does not copy symbols.  Copies strings without text properties.  */)
  (register Lisp_Object obj)
{
  if (NILP (Vpurify_flag))
    return obj;

  if (PURE_POINTER_P (XPNTR (obj)))
    return obj;

  if (HASH_TABLE_P (Vpurify_flag)) /* Hash consing.  */
    {
      Lisp_Object tmp = Fgethash (obj, Vpurify_flag, Qnil);
      if (!NILP (tmp))
	return tmp;
    }

  if (CONSP (obj))
    obj = pure_cons (XCAR (obj), XCDR (obj));
  else if (FLOATP (obj))
    obj = make_pure_float (XFLOAT_DATA (obj));
  else if (STRINGP (obj))
    obj = make_pure_string (SSDATA (obj), SCHARS (obj),
			    SBYTES (obj),
			    STRING_MULTIBYTE (obj));
  else if (COMPILEDP (obj) || VECTORP (obj))
    {
      register struct Lisp_Vector *vec;
      register ptrdiff_t i;
      ptrdiff_t size;

      size = ASIZE (obj);
      if (size & PSEUDOVECTOR_FLAG)
	size &= PSEUDOVECTOR_SIZE_MASK;
      vec = XVECTOR (make_pure_vector (size));
      for (i = 0; i < size; i++)
	vec->contents[i] = Fpurecopy (AREF (obj, i));
      if (COMPILEDP (obj))
	{
	  XSETPVECTYPE (vec, PVEC_COMPILED);
	  XSETCOMPILED (obj, vec);
	}
      else
	XSETVECTOR (obj, vec);
    }
  else if (MARKERP (obj))
    error ("Attempt to copy a marker to pure storage");
  else
    /* Not purified, don't hash-cons.  */
    return obj;

  if (HASH_TABLE_P (Vpurify_flag)) /* Hash consing.  */
    Fputhash (obj, obj, Vpurify_flag);

  return obj;
}



/***********************************************************************
			  Protection from GC
 ***********************************************************************/

/* Put an entry in staticvec, pointing at the variable with address
   VARADDRESS.  */

void
staticpro (Lisp_Object *varaddress)
{
  staticvec[staticidx++] = varaddress;
  if (staticidx >= NSTATICS)
    fatal ("NSTATICS too small; try increasing and recompiling Emacs.");
}


/***********************************************************************
			  Protection from GC
 ***********************************************************************/

/* Temporarily prevent garbage collection.  */

ptrdiff_t
inhibit_garbage_collection (void)
{
  ptrdiff_t count = SPECPDL_INDEX ();

  specbind (Qgc_cons_threshold, make_number (MOST_POSITIVE_FIXNUM));
  return count;
}

/* Used to avoid possible overflows when
   converting from C to Lisp integers.  */

static Lisp_Object
bounded_number (EMACS_INT number)
{
  return make_number (min (MOST_POSITIVE_FIXNUM, number));
}

/* Calculate total bytes of live objects.  */

static size_t
total_bytes_of_live_objects (void)
{
  size_t tot = 0;
  tot += total_conses  * sizeof (struct Lisp_Cons);
  tot += total_symbols * sizeof (struct Lisp_Symbol);
  tot += total_markers * sizeof (union Lisp_Misc);
  tot += total_string_bytes;
  tot += total_vector_slots * word_size;
  tot += total_floats  * sizeof (struct Lisp_Float);
  tot += total_intervals * sizeof (struct interval);
  tot += total_strings * sizeof (struct Lisp_String);
  return tot;
}

DEFUN ("garbage-collect", Fgarbage_collect, Sgarbage_collect, 0, 0, "",
       doc: /* Reclaim storage for Lisp objects no longer needed.
Garbage collection happens automatically if you cons more than
`gc-cons-threshold' bytes of Lisp data since previous garbage collection.
`garbage-collect' normally returns a list with info on amount of space in use,
where each entry has the form (NAME SIZE USED FREE), where:
- NAME is a symbol describing the kind of objects this entry represents,
- SIZE is the number of bytes used by each one,
- USED is the number of those objects that were found live in the heap,
- FREE is the number of those objects that are not live but that Emacs
  keeps around for future allocations (maybe because it does not know how
  to return them to the OS).
However, if there was overflow in pure space, `garbage-collect'
returns nil, because real GC can't be done.
See Info node `(elisp)Garbage Collection'.  */)
  (void)
{
  struct specbinding *bind;
  struct buffer *nextb;
  char stack_top_variable;
  ptrdiff_t i;
  bool message_p;
  ptrdiff_t count = SPECPDL_INDEX ();
  EMACS_TIME start;
  Lisp_Object retval = Qnil;
  size_t tot_before = 0;
  struct backtrace backtrace;

  if (abort_on_gc)
    emacs_abort ();

  /* Can't GC if pure storage overflowed because we can't determine
     if something is a pure object or not.  */
  if (pure_bytes_used_before_overflow)
    return Qnil;

  /* Record this function, so it appears on the profiler's backtraces.  */
  backtrace.next = backtrace_list;
  backtrace.function = Qautomatic_gc;
  backtrace.args = &Qnil;
  backtrace.nargs = 0;
  backtrace.debug_on_exit = 0;
  backtrace_list = &backtrace;

  check_cons_list ();

  /* Don't keep undo information around forever.
     Do this early on, so it is no problem if the user quits.  */
  FOR_EACH_BUFFER (nextb)
    compact_buffer (nextb);

  if (profiler_memory_running)
    tot_before = total_bytes_of_live_objects ();

  start = current_emacs_time ();

  /* In case user calls debug_print during GC,
     don't let that cause a recursive GC.  */
  consing_since_gc = 0;

  /* Save what's currently displayed in the echo area.  */
  message_p = push_message ();
  record_unwind_protect (pop_message_unwind, Qnil);

  /* Save a copy of the contents of the stack, for debugging.  */
#if MAX_SAVE_STACK > 0
  if (NILP (Vpurify_flag))
    {
      char *stack;
      ptrdiff_t stack_size;
      if (&stack_top_variable < stack_bottom)
	{
	  stack = &stack_top_variable;
	  stack_size = stack_bottom - &stack_top_variable;
	}
      else
	{
	  stack = stack_bottom;
	  stack_size = &stack_top_variable - stack_bottom;
	}
      if (stack_size <= MAX_SAVE_STACK)
	{
	  if (stack_copy_size < stack_size)
	    {
	      stack_copy = xrealloc (stack_copy, stack_size);
	      stack_copy_size = stack_size;
	    }
	  memcpy (stack_copy, stack, stack_size);
	}
    }
#endif /* MAX_SAVE_STACK > 0 */

  if (garbage_collection_messages)
    message1_nolog ("Garbage collecting...");

  block_input ();

  shrink_regexp_cache ();

  gc_in_progress = 1;

  /* Mark all the special slots that serve as the roots of accessibility.  */

  mark_buffer (&buffer_defaults);
  mark_buffer (&buffer_local_symbols);

  for (i = 0; i < staticidx; i++)
    mark_object (*staticvec[i]);

  for (bind = specpdl; bind != specpdl_ptr; bind++)
    {
      mark_object (bind->symbol);
      mark_object (bind->old_value);
    }
  mark_terminals ();
  mark_kboards ();

#ifdef USE_GTK
  xg_mark_data ();
#endif

#if (GC_MARK_STACK == GC_MAKE_GCPROS_NOOPS \
     || GC_MARK_STACK == GC_MARK_STACK_CHECK_GCPROS)
  mark_stack ();
#else
  {
    register struct gcpro *tail;
    for (tail = gcprolist; tail; tail = tail->next)
      for (i = 0; i < tail->nvars; i++)
	mark_object (tail->var[i]);
  }
  mark_byte_stack ();
  {
    struct catchtag *catch;
    struct handler *handler;

  for (catch = catchlist; catch; catch = catch->next)
    {
      mark_object (catch->tag);
      mark_object (catch->val);
    }
  for (handler = handlerlist; handler; handler = handler->next)
    {
      mark_object (handler->handler);
      mark_object (handler->var);
    }
  }
  mark_backtrace ();
#endif

#ifdef HAVE_WINDOW_SYSTEM
  mark_fringe_data ();
#endif

#if GC_MARK_STACK == GC_USE_GCPROS_CHECK_ZOMBIES
  mark_stack ();
#endif

  /* Everything is now marked, except for the things that require special
     finalization, i.e. the undo_list.
     Look thru every buffer's undo list
     for elements that update markers that were not marked,
     and delete them.  */
  FOR_EACH_BUFFER (nextb)
    {
      /* If a buffer's undo list is Qt, that means that undo is
	 turned off in that buffer.  Calling truncate_undo_list on
	 Qt tends to return NULL, which effectively turns undo back on.
	 So don't call truncate_undo_list if undo_list is Qt.  */
      if (! EQ (nextb->INTERNAL_FIELD (undo_list), Qt))
	{
	  Lisp_Object tail, prev;
	  tail = nextb->INTERNAL_FIELD (undo_list);
	  prev = Qnil;
	  while (CONSP (tail))
	    {
	      if (CONSP (XCAR (tail))
		  && MARKERP (XCAR (XCAR (tail)))
		  && !XMARKER (XCAR (XCAR (tail)))->gcmarkbit)
		{
		  if (NILP (prev))
		    nextb->INTERNAL_FIELD (undo_list) = tail = XCDR (tail);
		  else
		    {
		      tail = XCDR (tail);
		      XSETCDR (prev, tail);
		    }
		}
	      else
		{
		  prev = tail;
		  tail = XCDR (tail);
		}
	    }
	}
      /* Now that we have stripped the elements that need not be in the
	 undo_list any more, we can finally mark the list.  */
      mark_object (nextb->INTERNAL_FIELD (undo_list));
    }

  gc_sweep ();

  /* Clear the mark bits that we set in certain root slots.  */

  unmark_byte_stack ();
  VECTOR_UNMARK (&buffer_defaults);
  VECTOR_UNMARK (&buffer_local_symbols);

#if GC_MARK_STACK == GC_USE_GCPROS_CHECK_ZOMBIES && 0
  dump_zombies ();
#endif

  check_cons_list ();

  gc_in_progress = 0;

  unblock_input ();

  consing_since_gc = 0;
  if (gc_cons_threshold < GC_DEFAULT_THRESHOLD / 10)
    gc_cons_threshold = GC_DEFAULT_THRESHOLD / 10;

  gc_relative_threshold = 0;
  if (FLOATP (Vgc_cons_percentage))
    { /* Set gc_cons_combined_threshold.  */
      double tot = total_bytes_of_live_objects ();

      tot *= XFLOAT_DATA (Vgc_cons_percentage);
      if (0 < tot)
	{
	  if (tot < TYPE_MAXIMUM (EMACS_INT))
	    gc_relative_threshold = tot;
	  else
	    gc_relative_threshold = TYPE_MAXIMUM (EMACS_INT);
	}
    }

  if (garbage_collection_messages)
    {
      if (message_p || minibuf_level > 0)
	restore_message ();
      else
	message1_nolog ("Garbage collecting...done");
    }

  unbind_to (count, Qnil);
  {
    Lisp_Object total[11];
    int total_size = 10;

    total[0] = list4 (Qconses, make_number (sizeof (struct Lisp_Cons)),
		      bounded_number (total_conses),
		      bounded_number (total_free_conses));

    total[1] = list4 (Qsymbols, make_number (sizeof (struct Lisp_Symbol)),
		      bounded_number (total_symbols),
		      bounded_number (total_free_symbols));

    total[2] = list4 (Qmiscs, make_number (sizeof (union Lisp_Misc)),
		      bounded_number (total_markers),
		      bounded_number (total_free_markers));

    total[3] = list4 (Qstrings, make_number (sizeof (struct Lisp_String)),
		      bounded_number (total_strings),
		      bounded_number (total_free_strings));

    total[4] = list3 (Qstring_bytes, make_number (1),
		      bounded_number (total_string_bytes));

    total[5] = list3 (Qvectors, make_number (sizeof (struct Lisp_Vector)),
		      bounded_number (total_vectors));

    total[6] = list4 (Qvector_slots, make_number (word_size),
		      bounded_number (total_vector_slots),
		      bounded_number (total_free_vector_slots));

    total[7] = list4 (Qfloats, make_number (sizeof (struct Lisp_Float)),
		      bounded_number (total_floats),
		      bounded_number (total_free_floats));

    total[8] = list4 (Qintervals, make_number (sizeof (struct interval)),
		      bounded_number (total_intervals),
		      bounded_number (total_free_intervals));

    total[9] = list3 (Qbuffers, make_number (sizeof (struct buffer)),
		      bounded_number (total_buffers));

#ifdef DOUG_LEA_MALLOC
    total_size++;
    total[10] = list4 (Qheap, make_number (1024),
                       bounded_number ((mallinfo ().uordblks + 1023) >> 10),
                       bounded_number ((mallinfo ().fordblks + 1023) >> 10));
#endif
    retval = Flist (total_size, total);
  }

#if GC_MARK_STACK == GC_USE_GCPROS_CHECK_ZOMBIES
  {
    /* Compute average percentage of zombies.  */
    double nlive
      = (total_conses + total_symbols + total_markers + total_strings
         + total_vectors + total_floats + total_intervals + total_buffers);

    avg_live = (avg_live * ngcs + nlive) / (ngcs + 1);
    max_live = max (nlive, max_live);
    avg_zombies = (avg_zombies * ngcs + nzombies) / (ngcs + 1);
    max_zombies = max (nzombies, max_zombies);
    ++ngcs;
  }
#endif

  if (!NILP (Vpost_gc_hook))
    {
      ptrdiff_t gc_count = inhibit_garbage_collection ();
      safe_run_hooks (Qpost_gc_hook);
      unbind_to (gc_count, Qnil);
    }

  /* Accumulate statistics.  */
  if (FLOATP (Vgc_elapsed))
    {
      EMACS_TIME since_start = sub_emacs_time (current_emacs_time (), start);
      Vgc_elapsed = make_float (XFLOAT_DATA (Vgc_elapsed)
				+ EMACS_TIME_TO_DOUBLE (since_start));
    }

  gcs_done++;

  /* Collect profiling data.  */
  if (profiler_memory_running)
    {
      size_t swept = 0;
      size_t tot_after = total_bytes_of_live_objects ();
      if (tot_before > tot_after)
	swept = tot_before - tot_after;
      malloc_probe (swept);
    }

  backtrace_list = backtrace.next;
  return retval;
}


/* Mark Lisp objects in glyph matrix MATRIX.  Currently the
   only interesting objects referenced from glyphs are strings.  */

static void
mark_glyph_matrix (struct glyph_matrix *matrix)
{
  struct glyph_row *row = matrix->rows;
  struct glyph_row *end = row + matrix->nrows;

  for (; row < end; ++row)
    if (row->enabled_p)
      {
	int area;
	for (area = LEFT_MARGIN_AREA; area < LAST_AREA; ++area)
	  {
	    struct glyph *glyph = row->glyphs[area];
	    struct glyph *end_glyph = glyph + row->used[area];

	    for (; glyph < end_glyph; ++glyph)
	      if (STRINGP (glyph->object)
		  && !STRING_MARKED_P (XSTRING (glyph->object)))
		mark_object (glyph->object);
	  }
      }
}


/* Mark Lisp faces in the face cache C.  */

static void
mark_face_cache (struct face_cache *c)
{
  if (c)
    {
      int i, j;
      for (i = 0; i < c->used; ++i)
	{
	  struct face *face = FACE_FROM_ID (c->f, i);

	  if (face)
	    {
	      for (j = 0; j < LFACE_VECTOR_SIZE; ++j)
		mark_object (face->lface[j]);
	    }
	}
    }
}



/* Mark reference to a Lisp_Object.
   If the object referred to has not been seen yet, recursively mark
   all the references contained in it.  */

#define LAST_MARKED_SIZE 500
static Lisp_Object last_marked[LAST_MARKED_SIZE];
static int last_marked_index;

/* For debugging--call abort when we cdr down this many
   links of a list, in mark_object.  In debugging,
   the call to abort will hit a breakpoint.
   Normally this is zero and the check never goes off.  */
ptrdiff_t mark_object_loop_halt EXTERNALLY_VISIBLE;

static void
mark_vectorlike (struct Lisp_Vector *ptr)
{
  ptrdiff_t size = ptr->header.size;
  ptrdiff_t i;

  eassert (!VECTOR_MARKED_P (ptr));
  VECTOR_MARK (ptr);		/* Else mark it.  */
  if (size & PSEUDOVECTOR_FLAG)
    size &= PSEUDOVECTOR_SIZE_MASK;

  /* Note that this size is not the memory-footprint size, but only
     the number of Lisp_Object fields that we should trace.
     The distinction is used e.g. by Lisp_Process which places extra
     non-Lisp_Object fields at the end of the structure...  */
  for (i = 0; i < size; i++) /* ...and then mark its elements.  */
    mark_object (ptr->contents[i]);
}

/* Like mark_vectorlike but optimized for char-tables (and
   sub-char-tables) assuming that the contents are mostly integers or
   symbols.  */

static void
mark_char_table (struct Lisp_Vector *ptr)
{
  int size = ptr->header.size & PSEUDOVECTOR_SIZE_MASK;
  int i;

  eassert (!VECTOR_MARKED_P (ptr));
  VECTOR_MARK (ptr);
  for (i = 0; i < size; i++)
    {
      Lisp_Object val = ptr->contents[i];

      if (INTEGERP (val) || (SYMBOLP (val) && XSYMBOL (val)->gcmarkbit))
	continue;
      if (SUB_CHAR_TABLE_P (val))
	{
	  if (! VECTOR_MARKED_P (XVECTOR (val)))
	    mark_char_table (XVECTOR (val));
	}
      else
	mark_object (val);
    }
}

/* Mark the chain of overlays starting at PTR.  */

static void
mark_overlay (struct Lisp_Overlay *ptr)
{
  for (; ptr && !ptr->gcmarkbit; ptr = ptr->next)
    {
      ptr->gcmarkbit = 1;
      mark_object (ptr->start);
      mark_object (ptr->end);
      mark_object (ptr->plist);
    }
}

/* Mark Lisp_Objects and special pointers in BUFFER.  */

static void
mark_buffer (struct buffer *buffer)
{
  /* This is handled much like other pseudovectors...  */
  mark_vectorlike ((struct Lisp_Vector *) buffer);

  /* ...but there are some buffer-specific things.  */

  MARK_INTERVAL_TREE (buffer_intervals (buffer));

  /* For now, we just don't mark the undo_list.  It's done later in
     a special way just before the sweep phase, and after stripping
     some of its elements that are not needed any more.  */

  mark_overlay (buffer->overlays_before);
  mark_overlay (buffer->overlays_after);

  /* If this is an indirect buffer, mark its base buffer.  */
  if (buffer->base_buffer && !VECTOR_MARKED_P (buffer->base_buffer))
    mark_buffer (buffer->base_buffer);
}

/* Remove killed buffers or items whose car is a killed buffer from
   LIST, and mark other items.  Return changed LIST, which is marked.  */

static Lisp_Object
mark_discard_killed_buffers (Lisp_Object list)
{
  Lisp_Object tail, *prev = &list;

  for (tail = list; CONSP (tail) && !CONS_MARKED_P (XCONS (tail));
       tail = XCDR (tail))
    {
      Lisp_Object tem = XCAR (tail);
      if (CONSP (tem))
	tem = XCAR (tem);
      if (BUFFERP (tem) && !BUFFER_LIVE_P (XBUFFER (tem)))
	*prev = XCDR (tail);
      else
	{
	  CONS_MARK (XCONS (tail));
	  mark_object (XCAR (tail));
	  prev = &XCDR_AS_LVALUE (tail);
	}
    }
  mark_object (tail);
  return list;
}

/* Determine type of generic Lisp_Object and mark it accordingly.  */

void
mark_object (Lisp_Object arg)
{
  register Lisp_Object obj = arg;
#ifdef GC_CHECK_MARKED_OBJECTS
  void *po;
  struct mem_node *m;
#endif
  ptrdiff_t cdr_count = 0;

 loop:

  if (PURE_POINTER_P (XPNTR (obj)))
    return;

  last_marked[last_marked_index++] = obj;
  if (last_marked_index == LAST_MARKED_SIZE)
    last_marked_index = 0;

  /* Perform some sanity checks on the objects marked here.  Abort if
     we encounter an object we know is bogus.  This increases GC time
     by ~80%, and requires compilation with GC_MARK_STACK != 0.  */
#ifdef GC_CHECK_MARKED_OBJECTS

  po = (void *) XPNTR (obj);

  /* Check that the object pointed to by PO is known to be a Lisp
     structure allocated from the heap.  */
#define CHECK_ALLOCATED()			\
  do {						\
    m = mem_find (po);				\
    if (m == MEM_NIL)				\
      emacs_abort ();				\
  } while (0)

  /* Check that the object pointed to by PO is live, using predicate
     function LIVEP.  */
#define CHECK_LIVE(LIVEP)			\
  do {						\
    if (!LIVEP (m, po))				\
      emacs_abort ();				\
  } while (0)

  /* Check both of the above conditions.  */
#define CHECK_ALLOCATED_AND_LIVE(LIVEP)		\
  do {						\
    CHECK_ALLOCATED ();				\
    CHECK_LIVE (LIVEP);				\
  } while (0)					\

#else /* not GC_CHECK_MARKED_OBJECTS */

#define CHECK_LIVE(LIVEP)		(void) 0
#define CHECK_ALLOCATED_AND_LIVE(LIVEP)	(void) 0

#endif /* not GC_CHECK_MARKED_OBJECTS */

  switch (XTYPE (obj))
    {
    case Lisp_String:
      {
	register struct Lisp_String *ptr = XSTRING (obj);
	if (STRING_MARKED_P (ptr))
	  break;
	CHECK_ALLOCATED_AND_LIVE (live_string_p);
	MARK_STRING (ptr);
	MARK_INTERVAL_TREE (ptr->intervals);
#ifdef GC_CHECK_STRING_BYTES
	/* Check that the string size recorded in the string is the
	   same as the one recorded in the sdata structure.  */
	string_bytes (ptr);
#endif /* GC_CHECK_STRING_BYTES */
      }
      break;

    case Lisp_Vectorlike:
      {
	register struct Lisp_Vector *ptr = XVECTOR (obj);
	register ptrdiff_t pvectype;

	if (VECTOR_MARKED_P (ptr))
	  break;

#ifdef GC_CHECK_MARKED_OBJECTS
	m = mem_find (po);
	if (m == MEM_NIL && !SUBRP (obj))
	  emacs_abort ();
#endif /* GC_CHECK_MARKED_OBJECTS */

	if (ptr->header.size & PSEUDOVECTOR_FLAG)
	  pvectype = ((ptr->header.size & PVEC_TYPE_MASK)
		      >> PSEUDOVECTOR_AREA_BITS);
	else
	  pvectype = PVEC_NORMAL_VECTOR;

	if (pvectype != PVEC_SUBR && pvectype != PVEC_BUFFER)
	  CHECK_LIVE (live_vector_p);

	switch (pvectype)
	  {
	  case PVEC_BUFFER:
#ifdef GC_CHECK_MARKED_OBJECTS
	    {
	      struct buffer *b;
	      FOR_EACH_BUFFER (b)
		if (b == po)
		  break;
	      if (b == NULL)
		emacs_abort ();
	    }
#endif /* GC_CHECK_MARKED_OBJECTS */
	    mark_buffer ((struct buffer *) ptr);
	    break;

	  case PVEC_COMPILED:
	    { /* We could treat this just like a vector, but it is better
		 to save the COMPILED_CONSTANTS element for last and avoid
		 recursion there.  */
	      int size = ptr->header.size & PSEUDOVECTOR_SIZE_MASK;
	      int i;

	      VECTOR_MARK (ptr);
	      for (i = 0; i < size; i++)
		if (i != COMPILED_CONSTANTS)
		  mark_object (ptr->contents[i]);
	      if (size > COMPILED_CONSTANTS)
		{
		  obj = ptr->contents[COMPILED_CONSTANTS];
		  goto loop;
		}
	    }
	    break;

	  case PVEC_FRAME:
	    mark_vectorlike (ptr);
	    mark_face_cache (((struct frame *) ptr)->face_cache);
	    break;

	  case PVEC_WINDOW:
	    {
	      struct window *w = (struct window *) ptr;
	      bool leaf = NILP (w->hchild) && NILP (w->vchild);

	      mark_vectorlike (ptr);

	      /* Mark glyphs for leaf windows.  Marking window
		 matrices is sufficient because frame matrices
		 use the same glyph memory.  */
	      if (leaf && w->current_matrix)
		{
		  mark_glyph_matrix (w->current_matrix);
		  mark_glyph_matrix (w->desired_matrix);
		}

	      /* Filter out killed buffers from both buffer lists
		 in attempt to help GC to reclaim killed buffers faster.
		 We can do it elsewhere for live windows, but this is the
		 best place to do it for dead windows.  */
	      wset_prev_buffers
		(w, mark_discard_killed_buffers (w->prev_buffers));
	      wset_next_buffers
		(w, mark_discard_killed_buffers (w->next_buffers));
	    }
	    break;

	  case PVEC_HASH_TABLE:
	    {
	      struct Lisp_Hash_Table *h = (struct Lisp_Hash_Table *) ptr;

	      mark_vectorlike (ptr);
	      mark_object (h->test.name);
	      mark_object (h->test.user_hash_function);
	      mark_object (h->test.user_cmp_function);
	      /* If hash table is not weak, mark all keys and values.
		 For weak tables, mark only the vector.  */
	      if (NILP (h->weak))
		mark_object (h->key_and_value);
	      else
		VECTOR_MARK (XVECTOR (h->key_and_value));
	    }
	    break;

	  case PVEC_CHAR_TABLE:
	    mark_char_table (ptr);
	    break;

	  case PVEC_BOOL_VECTOR:
	    /* No Lisp_Objects to mark in a bool vector.  */
	    VECTOR_MARK (ptr);
	    break;

	  case PVEC_SUBR:
	    break;

	  case PVEC_FREE:
	    emacs_abort ();

	  default:
	    mark_vectorlike (ptr);
	  }
      }
      break;

    case Lisp_Symbol:
      {
	register struct Lisp_Symbol *ptr = XSYMBOL (obj);
	struct Lisp_Symbol *ptrx;

	if (ptr->gcmarkbit)
	  break;
	CHECK_ALLOCATED_AND_LIVE (live_symbol_p);
	ptr->gcmarkbit = 1;
	mark_object (ptr->function);
	mark_object (ptr->plist);
	switch (ptr->redirect)
	  {
	  case SYMBOL_PLAINVAL: mark_object (SYMBOL_VAL (ptr)); break;
	  case SYMBOL_VARALIAS:
	    {
	      Lisp_Object tem;
	      XSETSYMBOL (tem, SYMBOL_ALIAS (ptr));
	      mark_object (tem);
	      break;
	    }
	  case SYMBOL_LOCALIZED:
	    {
	      struct Lisp_Buffer_Local_Value *blv = SYMBOL_BLV (ptr);
	      Lisp_Object where = blv->where;
	      /* If the value is set up for a killed buffer or deleted
		 frame, restore it's global binding.  If the value is
		 forwarded to a C variable, either it's not a Lisp_Object
		 var, or it's staticpro'd already.  */
	      if ((BUFFERP (where) && !BUFFER_LIVE_P (XBUFFER (where)))
		  || (FRAMEP (where) && !FRAME_LIVE_P (XFRAME (where))))
		swap_in_global_binding (ptr);
	      mark_object (blv->where);
	      mark_object (blv->valcell);
	      mark_object (blv->defcell);
	      break;
	    }
	  case SYMBOL_FORWARDED:
	    /* If the value is forwarded to a buffer or keyboard field,
	       these are marked when we see the corresponding object.
	       And if it's forwarded to a C variable, either it's not
	       a Lisp_Object var, or it's staticpro'd already.  */
	    break;
	  default: emacs_abort ();
	  }
	if (!PURE_POINTER_P (XSTRING (ptr->name)))
	  MARK_STRING (XSTRING (ptr->name));
	MARK_INTERVAL_TREE (string_intervals (ptr->name));

	ptr = ptr->next;
	if (ptr)
	  {
	    ptrx = ptr;		/* Use of ptrx avoids compiler bug on Sun.  */
	    XSETSYMBOL (obj, ptrx);
	    goto loop;
	  }
      }
      break;

    case Lisp_Misc:
      CHECK_ALLOCATED_AND_LIVE (live_misc_p);

      if (XMISCANY (obj)->gcmarkbit)
	break;

      switch (XMISCTYPE (obj))
	{
	case Lisp_Misc_Marker:
	  /* DO NOT mark thru the marker's chain.
	     The buffer's markers chain does not preserve markers from gc;
	     instead, markers are removed from the chain when freed by gc.  */
	  XMISCANY (obj)->gcmarkbit = 1;
	  break;

	case Lisp_Misc_Save_Value:
	  XMISCANY (obj)->gcmarkbit = 1;
#if GC_MARK_STACK
	  {
	    register struct Lisp_Save_Value *ptr = XSAVE_VALUE (obj);
	    /* If DOGC is set, POINTER is the address of a memory
	       area containing INTEGER potential Lisp_Objects.  */
	    if (ptr->dogc)
	      {
		Lisp_Object *p = (Lisp_Object *) ptr->pointer;
		ptrdiff_t nelt;
		for (nelt = ptr->integer; nelt > 0; nelt--, p++)
		  mark_maybe_object (*p);
	      }
	  }
#endif
	  break;

	case Lisp_Misc_Overlay:
	  mark_overlay (XOVERLAY (obj));
	  break;

	default:
	  emacs_abort ();
	}
      break;

    case Lisp_Cons:
      {
	register struct Lisp_Cons *ptr = XCONS (obj);
	if (CONS_MARKED_P (ptr))
	  break;
	CHECK_ALLOCATED_AND_LIVE (live_cons_p);
	CONS_MARK (ptr);
	/* If the cdr is nil, avoid recursion for the car.  */
	if (EQ (ptr->u.cdr, Qnil))
	  {
	    obj = ptr->car;
	    cdr_count = 0;
	    goto loop;
	  }
	mark_object (ptr->car);
	obj = ptr->u.cdr;
	cdr_count++;
	if (cdr_count == mark_object_loop_halt)
	  emacs_abort ();
	goto loop;
      }

    case Lisp_Float:
      CHECK_ALLOCATED_AND_LIVE (live_float_p);
      FLOAT_MARK (XFLOAT (obj));
      break;

    case_Lisp_Int:
      break;

    default:
      emacs_abort ();
    }

#undef CHECK_LIVE
#undef CHECK_ALLOCATED
#undef CHECK_ALLOCATED_AND_LIVE
}
/* Mark the Lisp pointers in the terminal objects.
   Called by Fgarbage_collect.  */

static void
mark_terminals (void)
{
  struct terminal *t;
  for (t = terminal_list; t; t = t->next_terminal)
    {
      eassert (t->name != NULL);
#ifdef HAVE_WINDOW_SYSTEM
      /* If a terminal object is reachable from a stacpro'ed object,
	 it might have been marked already.  Make sure the image cache
	 gets marked.  */
      mark_image_cache (t->image_cache);
#endif /* HAVE_WINDOW_SYSTEM */
      if (!VECTOR_MARKED_P (t))
	mark_vectorlike ((struct Lisp_Vector *)t);
    }
}



/* Value is non-zero if OBJ will survive the current GC because it's
   either marked or does not need to be marked to survive.  */

bool
survives_gc_p (Lisp_Object obj)
{
  bool survives_p;

  switch (XTYPE (obj))
    {
    case_Lisp_Int:
      survives_p = 1;
      break;

    case Lisp_Symbol:
      survives_p = XSYMBOL (obj)->gcmarkbit;
      break;

    case Lisp_Misc:
      survives_p = XMISCANY (obj)->gcmarkbit;
      break;

    case Lisp_String:
      survives_p = STRING_MARKED_P (XSTRING (obj));
      break;

    case Lisp_Vectorlike:
      survives_p = SUBRP (obj) || VECTOR_MARKED_P (XVECTOR (obj));
      break;

    case Lisp_Cons:
      survives_p = CONS_MARKED_P (XCONS (obj));
      break;

    case Lisp_Float:
      survives_p = FLOAT_MARKED_P (XFLOAT (obj));
      break;

    default:
      emacs_abort ();
    }

  return survives_p || PURE_POINTER_P ((void *) XPNTR (obj));
}



/* Sweep: find all structures not marked, and free them. */

static void
gc_sweep (void)
{
  /* Remove or mark entries in weak hash tables.
     This must be done before any object is unmarked.  */
  sweep_weak_hash_tables ();

  sweep_strings ();
  check_string_bytes (!noninteractive);

  /* Put all unmarked conses on free list */
  {
    register struct cons_block *cblk;
    struct cons_block **cprev = &cons_block;
    register int lim = cons_block_index;
    EMACS_INT num_free = 0, num_used = 0;

    cons_free_list = 0;

    for (cblk = cons_block; cblk; cblk = *cprev)
      {
	register int i = 0;
	int this_free = 0;
	int ilim = (lim + BITS_PER_INT - 1) / BITS_PER_INT;

	/* Scan the mark bits an int at a time.  */
	for (i = 0; i < ilim; i++)
	  {
	    if (cblk->gcmarkbits[i] == -1)
	      {
		/* Fast path - all cons cells for this int are marked.  */
		cblk->gcmarkbits[i] = 0;
		num_used += BITS_PER_INT;
	      }
	    else
	      {
		/* Some cons cells for this int are not marked.
		   Find which ones, and free them.  */
		int start, pos, stop;

		start = i * BITS_PER_INT;
		stop = lim - start;
		if (stop > BITS_PER_INT)
		  stop = BITS_PER_INT;
		stop += start;

		for (pos = start; pos < stop; pos++)
		  {
		    if (!CONS_MARKED_P (&cblk->conses[pos]))
		      {
			this_free++;
			cblk->conses[pos].u.chain = cons_free_list;
			cons_free_list = &cblk->conses[pos];
#if GC_MARK_STACK
			cons_free_list->car = Vdead;
#endif
		      }
		    else
		      {
			num_used++;
			CONS_UNMARK (&cblk->conses[pos]);
		      }
		  }
	      }
	  }

	lim = CONS_BLOCK_SIZE;
	/* If this block contains only free conses and we have already
	   seen more than two blocks worth of free conses then deallocate
	   this block.  */
	if (this_free == CONS_BLOCK_SIZE && num_free > CONS_BLOCK_SIZE)
	  {
	    *cprev = cblk->next;
	    /* Unhook from the free list.  */
	    cons_free_list = cblk->conses[0].u.chain;
	    lisp_align_free (cblk);
	  }
	else
	  {
	    num_free += this_free;
	    cprev = &cblk->next;
	  }
      }
    total_conses = num_used;
    total_free_conses = num_free;
  }

  /* Put all unmarked floats on free list */
  {
    register struct float_block *fblk;
    struct float_block **fprev = &float_block;
    register int lim = float_block_index;
    EMACS_INT num_free = 0, num_used = 0;

    float_free_list = 0;

    for (fblk = float_block; fblk; fblk = *fprev)
      {
	register int i;
	int this_free = 0;
	for (i = 0; i < lim; i++)
	  if (!FLOAT_MARKED_P (&fblk->floats[i]))
	    {
	      this_free++;
	      fblk->floats[i].u.chain = float_free_list;
	      float_free_list = &fblk->floats[i];
	    }
	  else
	    {
	      num_used++;
	      FLOAT_UNMARK (&fblk->floats[i]);
	    }
	lim = FLOAT_BLOCK_SIZE;
	/* If this block contains only free floats and we have already
	   seen more than two blocks worth of free floats then deallocate
	   this block.  */
	if (this_free == FLOAT_BLOCK_SIZE && num_free > FLOAT_BLOCK_SIZE)
	  {
	    *fprev = fblk->next;
	    /* Unhook from the free list.  */
	    float_free_list = fblk->floats[0].u.chain;
	    lisp_align_free (fblk);
	  }
	else
	  {
	    num_free += this_free;
	    fprev = &fblk->next;
	  }
      }
    total_floats = num_used;
    total_free_floats = num_free;
  }

  /* Put all unmarked intervals on free list */
  {
    register struct interval_block *iblk;
    struct interval_block **iprev = &interval_block;
    register int lim = interval_block_index;
    EMACS_INT num_free = 0, num_used = 0;

    interval_free_list = 0;

    for (iblk = interval_block; iblk; iblk = *iprev)
      {
	register int i;
	int this_free = 0;

	for (i = 0; i < lim; i++)
	  {
	    if (!iblk->intervals[i].gcmarkbit)
	      {
		set_interval_parent (&iblk->intervals[i], interval_free_list);
		interval_free_list = &iblk->intervals[i];
		this_free++;
	      }
	    else
	      {
		num_used++;
		iblk->intervals[i].gcmarkbit = 0;
	      }
	  }
	lim = INTERVAL_BLOCK_SIZE;
	/* If this block contains only free intervals and we have already
	   seen more than two blocks worth of free intervals then
	   deallocate this block.  */
	if (this_free == INTERVAL_BLOCK_SIZE && num_free > INTERVAL_BLOCK_SIZE)
	  {
	    *iprev = iblk->next;
	    /* Unhook from the free list.  */
	    interval_free_list = INTERVAL_PARENT (&iblk->intervals[0]);
	    lisp_free (iblk);
	  }
	else
	  {
	    num_free += this_free;
	    iprev = &iblk->next;
	  }
      }
    total_intervals = num_used;
    total_free_intervals = num_free;
  }

  /* Put all unmarked symbols on free list */
  {
    register struct symbol_block *sblk;
    struct symbol_block **sprev = &symbol_block;
    register int lim = symbol_block_index;
    EMACS_INT num_free = 0, num_used = 0;

    symbol_free_list = NULL;

    for (sblk = symbol_block; sblk; sblk = *sprev)
      {
	int this_free = 0;
	union aligned_Lisp_Symbol *sym = sblk->symbols;
	union aligned_Lisp_Symbol *end = sym + lim;

	for (; sym < end; ++sym)
	  {
	    /* Check if the symbol was created during loadup.  In such a case
	       it might be pointed to by pure bytecode which we don't trace,
	       so we conservatively assume that it is live.  */
	    bool pure_p = PURE_POINTER_P (XSTRING (sym->s.name));

	    if (!sym->s.gcmarkbit && !pure_p)
	      {
		if (sym->s.redirect == SYMBOL_LOCALIZED)
		  xfree (SYMBOL_BLV (&sym->s));
		sym->s.next = symbol_free_list;
		symbol_free_list = &sym->s;
#if GC_MARK_STACK
		symbol_free_list->function = Vdead;
#endif
		++this_free;
	      }
	    else
	      {
		++num_used;
		if (!pure_p)
		  UNMARK_STRING (XSTRING (sym->s.name));
		sym->s.gcmarkbit = 0;
	      }
	  }

	lim = SYMBOL_BLOCK_SIZE;
	/* If this block contains only free symbols and we have already
	   seen more than two blocks worth of free symbols then deallocate
	   this block.  */
	if (this_free == SYMBOL_BLOCK_SIZE && num_free > SYMBOL_BLOCK_SIZE)
	  {
	    *sprev = sblk->next;
	    /* Unhook from the free list.  */
	    symbol_free_list = sblk->symbols[0].s.next;
	    lisp_free (sblk);
	  }
	else
	  {
	    num_free += this_free;
	    sprev = &sblk->next;
	  }
      }
    total_symbols = num_used;
    total_free_symbols = num_free;
  }

  /* Put all unmarked misc's on free list.
     For a marker, first unchain it from the buffer it points into.  */
  {
    register struct marker_block *mblk;
    struct marker_block **mprev = &marker_block;
    register int lim = marker_block_index;
    EMACS_INT num_free = 0, num_used = 0;

    marker_free_list = 0;

    for (mblk = marker_block; mblk; mblk = *mprev)
      {
	register int i;
	int this_free = 0;

	for (i = 0; i < lim; i++)
	  {
	    if (!mblk->markers[i].m.u_any.gcmarkbit)
	      {
		if (mblk->markers[i].m.u_any.type == Lisp_Misc_Marker)
		  unchain_marker (&mblk->markers[i].m.u_marker);
		/* Set the type of the freed object to Lisp_Misc_Free.
		   We could leave the type alone, since nobody checks it,
		   but this might catch bugs faster.  */
		mblk->markers[i].m.u_marker.type = Lisp_Misc_Free;
		mblk->markers[i].m.u_free.chain = marker_free_list;
		marker_free_list = &mblk->markers[i].m;
		this_free++;
	      }
	    else
	      {
		num_used++;
		mblk->markers[i].m.u_any.gcmarkbit = 0;
	      }
	  }
	lim = MARKER_BLOCK_SIZE;
	/* If this block contains only free markers and we have already
	   seen more than two blocks worth of free markers then deallocate
	   this block.  */
	if (this_free == MARKER_BLOCK_SIZE && num_free > MARKER_BLOCK_SIZE)
	  {
	    *mprev = mblk->next;
	    /* Unhook from the free list.  */
	    marker_free_list = mblk->markers[0].m.u_free.chain;
	    lisp_free (mblk);
	  }
	else
	  {
	    num_free += this_free;
	    mprev = &mblk->next;
	  }
      }

    total_markers = num_used;
    total_free_markers = num_free;
  }

  /* Free all unmarked buffers */
  {
    register struct buffer *buffer, **bprev = &all_buffers;

    total_buffers = 0;
    for (buffer = all_buffers; buffer; buffer = *bprev)
      if (!VECTOR_MARKED_P (buffer))
	{
	  *bprev = buffer->next;
	  lisp_free (buffer);
	}
      else
	{
	  VECTOR_UNMARK (buffer);
	  /* Do not use buffer_(set|get)_intervals here.  */
	  buffer->text->intervals = balance_intervals (buffer->text->intervals);
	  total_buffers++;
	  bprev = &buffer->next;
	}
  }

  sweep_vectors ();
  check_string_bytes (!noninteractive);
}




/* Debugging aids.  */

DEFUN ("memory-limit", Fmemory_limit, Smemory_limit, 0, 0, 0,
       doc: /* Return the address of the last byte Emacs has allocated, divided by 1024.
This may be helpful in debugging Emacs's memory usage.
We divide the value by 1024 to make sure it fits in a Lisp integer.  */)
  (void)
{
  Lisp_Object end;

  XSETINT (end, (intptr_t) (char *) sbrk (0) / 1024);

  return end;
}

DEFUN ("memory-use-counts", Fmemory_use_counts, Smemory_use_counts, 0, 0, 0,
       doc: /* Return a list of counters that measure how much consing there has been.
Each of these counters increments for a certain kind of object.
The counters wrap around from the largest positive integer to zero.
Garbage collection does not decrease them.
The elements of the value are as follows:
  (CONSES FLOATS VECTOR-CELLS SYMBOLS STRING-CHARS MISCS INTERVALS STRINGS)
All are in units of 1 = one object consed
except for VECTOR-CELLS and STRING-CHARS, which count the total length of
objects consed.
MISCS include overlays, markers, and some internal types.
Frames, windows, buffers, and subprocesses count as vectors
  (but the contents of a buffer's text do not count here).  */)
  (void)
{
  return listn (CONSTYPE_HEAP, 8,
		bounded_number (cons_cells_consed),
		bounded_number (floats_consed),
		bounded_number (vector_cells_consed),
		bounded_number (symbols_consed),
		bounded_number (string_chars_consed),
		bounded_number (misc_objects_consed),
		bounded_number (intervals_consed),
		bounded_number (strings_consed));
}

/* Find at most FIND_MAX symbols which have OBJ as their value or
   function.  This is used in gdbinit's `xwhichsymbols' command.  */

Lisp_Object
which_symbols (Lisp_Object obj, EMACS_INT find_max)
{
   struct symbol_block *sblk;
   ptrdiff_t gc_count = inhibit_garbage_collection ();
   Lisp_Object found = Qnil;

   if (! DEADP (obj))
     {
       for (sblk = symbol_block; sblk; sblk = sblk->next)
	 {
	   union aligned_Lisp_Symbol *aligned_sym = sblk->symbols;
	   int bn;

	   for (bn = 0; bn < SYMBOL_BLOCK_SIZE; bn++, aligned_sym++)
	     {
	       struct Lisp_Symbol *sym = &aligned_sym->s;
	       Lisp_Object val;
	       Lisp_Object tem;

	       if (sblk == symbol_block && bn >= symbol_block_index)
		 break;

	       XSETSYMBOL (tem, sym);
	       val = find_symbol_value (tem);
	       if (EQ (val, obj)
		   || EQ (sym->function, obj)
		   || (!NILP (sym->function)
		       && COMPILEDP (sym->function)
		       && EQ (AREF (sym->function, COMPILED_BYTECODE), obj))
		   || (!NILP (val)
		       && COMPILEDP (val)
		       && EQ (AREF (val, COMPILED_BYTECODE), obj)))
		 {
		   found = Fcons (tem, found);
		   if (--find_max == 0)
		     goto out;
		 }
	     }
	 }
     }

  out:
   unbind_to (gc_count, Qnil);
   return found;
}

#ifdef ENABLE_CHECKING

bool suppress_checking;

void
die (const char *msg, const char *file, int line)
{
  fprintf (stderr, "\r\n%s:%d: Emacs fatal error: %s\r\n",
	   file, line, msg);
  terminate_due_to_signal (SIGABRT, INT_MAX);
}
#endif

/* Initialization */

void
init_alloc_once (void)
{
  /* Used to do Vpurify_flag = Qt here, but Qt isn't set up yet!  */
  purebeg = PUREBEG;
  pure_size = PURESIZE;

#if GC_MARK_STACK || defined GC_MALLOC_CHECK
  mem_init ();
  Vdead = make_pure_string ("DEAD", 4, 4, 0);
#endif

#ifdef DOUG_LEA_MALLOC
  mallopt (M_TRIM_THRESHOLD, 128*1024); /* trim threshold */
  mallopt (M_MMAP_THRESHOLD, 64*1024); /* mmap threshold */
  mallopt (M_MMAP_MAX, MMAP_MAX_AREAS); /* max. number of mmap'ed areas */
#endif
  init_strings ();
  init_vectors ();

  refill_memory_reserve ();
  gc_cons_threshold = GC_DEFAULT_THRESHOLD;
}

void
init_alloc (void)
{
  gcprolist = 0;
  byte_stack_list = 0;
#if GC_MARK_STACK
#if !defined GC_SAVE_REGISTERS_ON_STACK && !defined GC_SETJMP_WORKS
  setjmp_tested_p = longjmps_done = 0;
#endif
#endif
  Vgc_elapsed = make_float (0.0);
  gcs_done = 0;
}

void
syms_of_alloc (void)
{
  DEFVAR_INT ("gc-cons-threshold", gc_cons_threshold,
	      doc: /* Number of bytes of consing between garbage collections.
Garbage collection can happen automatically once this many bytes have been
allocated since the last garbage collection.  All data types count.

Garbage collection happens automatically only when `eval' is called.

By binding this temporarily to a large number, you can effectively
prevent garbage collection during a part of the program.
See also `gc-cons-percentage'.  */);

  DEFVAR_LISP ("gc-cons-percentage", Vgc_cons_percentage,
	       doc: /* Portion of the heap used for allocation.
Garbage collection can happen automatically once this portion of the heap
has been allocated since the last garbage collection.
If this portion is smaller than `gc-cons-threshold', this is ignored.  */);
  Vgc_cons_percentage = make_float (0.1);

  DEFVAR_INT ("pure-bytes-used", pure_bytes_used,
	      doc: /* Number of bytes of shareable Lisp data allocated so far.  */);

  DEFVAR_INT ("cons-cells-consed", cons_cells_consed,
	      doc: /* Number of cons cells that have been consed so far.  */);

  DEFVAR_INT ("floats-consed", floats_consed,
	      doc: /* Number of floats that have been consed so far.  */);

  DEFVAR_INT ("vector-cells-consed", vector_cells_consed,
	      doc: /* Number of vector cells that have been consed so far.  */);

  DEFVAR_INT ("symbols-consed", symbols_consed,
	      doc: /* Number of symbols that have been consed so far.  */);

  DEFVAR_INT ("string-chars-consed", string_chars_consed,
	      doc: /* Number of string characters that have been consed so far.  */);

  DEFVAR_INT ("misc-objects-consed", misc_objects_consed,
	      doc: /* Number of miscellaneous objects that have been consed so far.
These include markers and overlays, plus certain objects not visible
to users.  */);

  DEFVAR_INT ("intervals-consed", intervals_consed,
	      doc: /* Number of intervals that have been consed so far.  */);

  DEFVAR_INT ("strings-consed", strings_consed,
	      doc: /* Number of strings that have been consed so far.  */);

  DEFVAR_LISP ("purify-flag", Vpurify_flag,
	       doc: /* Non-nil means loading Lisp code in order to dump an executable.
This means that certain objects should be allocated in shared (pure) space.
It can also be set to a hash-table, in which case this table is used to
do hash-consing of the objects allocated to pure space.  */);

  DEFVAR_BOOL ("garbage-collection-messages", garbage_collection_messages,
	       doc: /* Non-nil means display messages at start and end of garbage collection.  */);
  garbage_collection_messages = 0;

  DEFVAR_LISP ("post-gc-hook", Vpost_gc_hook,
	       doc: /* Hook run after garbage collection has finished.  */);
  Vpost_gc_hook = Qnil;
  DEFSYM (Qpost_gc_hook, "post-gc-hook");

  DEFVAR_LISP ("memory-signal-data", Vmemory_signal_data,
	       doc: /* Precomputed `signal' argument for memory-full error.  */);
  /* We build this in advance because if we wait until we need it, we might
     not be able to allocate the memory to hold it.  */
  Vmemory_signal_data
    = listn (CONSTYPE_PURE, 2, Qerror,
	     build_pure_c_string ("Memory exhausted--use M-x save-some-buffers then exit and restart Emacs"));

  DEFVAR_LISP ("memory-full", Vmemory_full,
	       doc: /* Non-nil means Emacs cannot get much more Lisp memory.  */);
  Vmemory_full = Qnil;

  DEFSYM (Qconses, "conses");
  DEFSYM (Qsymbols, "symbols");
  DEFSYM (Qmiscs, "miscs");
  DEFSYM (Qstrings, "strings");
  DEFSYM (Qvectors, "vectors");
  DEFSYM (Qfloats, "floats");
  DEFSYM (Qintervals, "intervals");
  DEFSYM (Qbuffers, "buffers");
  DEFSYM (Qstring_bytes, "string-bytes");
  DEFSYM (Qvector_slots, "vector-slots");
  DEFSYM (Qheap, "heap");
  DEFSYM (Qautomatic_gc, "Automatic GC");

  DEFSYM (Qgc_cons_threshold, "gc-cons-threshold");
  DEFSYM (Qchar_table_extra_slots, "char-table-extra-slots");

  DEFVAR_LISP ("gc-elapsed", Vgc_elapsed,
	       doc: /* Accumulated time elapsed in garbage collections.
The time is in seconds as a floating point value.  */);
  DEFVAR_INT ("gcs-done", gcs_done,
	      doc: /* Accumulated number of garbage collections done.  */);

  defsubr (&Scons);
  defsubr (&Slist);
  defsubr (&Svector);
  defsubr (&Smake_byte_code);
  defsubr (&Smake_list);
  defsubr (&Smake_vector);
  defsubr (&Smake_string);
  defsubr (&Smake_bool_vector);
  defsubr (&Smake_symbol);
  defsubr (&Smake_marker);
  defsubr (&Spurecopy);
  defsubr (&Sgarbage_collect);
  defsubr (&Smemory_limit);
  defsubr (&Smemory_use_counts);

#if GC_MARK_STACK == GC_USE_GCPROS_CHECK_ZOMBIES
  defsubr (&Sgc_status);
#endif
}

/* When compiled with GCC, GDB might say "No enum type named
   pvec_type" if we don't have at least one symbol with that type, and
   then xbacktrace could fail.  Similarly for the other enums and
   their values.  Some non-GCC compilers don't like these constructs.  */
#ifdef __GNUC__
union
{
  enum CHARTAB_SIZE_BITS CHARTAB_SIZE_BITS;
  enum CHAR_TABLE_STANDARD_SLOTS CHAR_TABLE_STANDARD_SLOTS;
  enum char_bits char_bits;
  enum CHECK_LISP_OBJECT_TYPE CHECK_LISP_OBJECT_TYPE;
  enum DEFAULT_HASH_SIZE DEFAULT_HASH_SIZE;
  enum enum_USE_LSB_TAG enum_USE_LSB_TAG;
  enum FLOAT_TO_STRING_BUFSIZE FLOAT_TO_STRING_BUFSIZE;
  enum Lisp_Bits Lisp_Bits;
  enum Lisp_Compiled Lisp_Compiled;
  enum maxargs maxargs;
  enum MAX_ALLOCA MAX_ALLOCA;
  enum More_Lisp_Bits More_Lisp_Bits;
  enum pvec_type pvec_type;
#if USE_LSB_TAG
  enum lsb_bits lsb_bits;
#endif
} const EXTERNALLY_VISIBLE gdb_make_enums_visible = {0};
#endif	/* __GNUC__ */

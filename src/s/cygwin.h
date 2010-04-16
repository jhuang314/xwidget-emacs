/* System description header file for Cygwin.
   Copyright (C) 1985, 1986, 1992, 1999, 2002, 2003, 2004, 2005, 2006,
                 2007, 2008, 2009, 2010 Free Software Foundation, Inc.

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

/* SYSTEM_TYPE should indicate the kind of system you are using.
 It sets the Lisp variable system-type.  */

#define SYSTEM_TYPE "cygwin"

/* Emacs can read input using SIGIO and buffering characters itself,
   or using CBREAK mode and making C-g cause SIGINT.
   The choice is controlled by the variable interrupt_input.

   Define INTERRUPT_INPUT to make interrupt_input = 1 the default (use SIGIO)

   Emacs uses the presence or absence of the SIGIO and BROKEN_SIGIO macros
   to indicate whether or not signal-driven I/O is possible.  It uses
   INTERRUPT_INPUT to decide whether to use it by default.

   SIGIO can be used only on systems that implement it (4.2 and 4.3).
   CBREAK mode has two disadvantages
     1) At least in 4.2, it is impossible to handle the Meta key properly.
        I hear that in system V this problem does not exist.
     2) Control-G causes output to be discarded.
        I do not know whether this can be fixed in system V.

   Another method of doing input is planned but not implemented.
   It would have Emacs fork off a separate process
   to read the input and send it to the true Emacs process
   through a pipe. */

#undef INTERRUPT_INPUT

/*
 *	Define HAVE_TERMIOS if the system provides POSIX-style
 *	functions and macros for terminal control.
 *
 *	Define HAVE_TERMIO if the system provides sysV-style ioctls
 *	for terminal control.
 *
 *	Do not define both.  HAVE_TERMIOS is preferred, if it is
 *	supported on your system.
 */

#define HAVE_TERMIOS

/*
 *	Define HAVE_PTYS if the system supports pty devices.
 */

#define HAVE_PTYS
#define PTY_ITERATION		for (i = 0; i < 1; i++) /* ick */
#define PTY_NAME_SPRINTF	/* none */
#define PTY_TTY_NAME_SPRINTF	/* none */
#define PTY_OPEN					\
  do							\
    {							\
      int dummy;					\
      SIGMASKTYPE mask;					\
      mask = sigblock (sigmask (SIGCHLD));		\
      if (-1 == openpty (&fd, &dummy, pty_name, 0, 0))	\
	fd = -1;					\
      sigsetmask (mask);				\
      emacs_close (dummy);				\
    }							\
  while (0)

/* Define this symbol if your system has the functions bcopy, etc. */

#define BSTRING

/* Define CLASH_DETECTION if you want lock files to be written
   so that Emacs can tell instantly when you try to modify
   a file that someone else has modified in his Emacs.  */

#define CLASH_DETECTION

/* If the system's imake configuration file defines `NeedWidePrototypes'
   as `NO', we must define NARROWPROTO manually.  Such a define is
   generated in the Makefile generated by `xmkmf'.  If we don't
   define NARROWPROTO, we will see the wrong function prototypes
   for X functions taking float or double parameters.  */

#define NARROWPROTO 1

/* used in various places to enable cygwin-specific code changes */
#define CYGWIN 1

#define PENDING_OUTPUT_COUNT(FILE) ((FILE)->_p - (FILE)->_bf._base)
#define SYSV_SYSTEM_DIR 1
#define UNEXEC unexcw.o
#define POSIX_SIGNALS 1
#define LINKER $(CC)

/* Use terminfo instead of termcap.  Fewer environment variables to
   go wrong, more terminal types. */
#define TERMINFO

#define HAVE_SOCKETS

/* vfork() interacts badly with setsid(), causing ptys to fail to
   change their controlling terminal */
#define vfork fork

/* This should work (at least when compiling with gcc).  But I have no way
   or intention to verify or even test it.  If you encounter a problem with
   it, feel free to change this setting, but please add a comment here about
   why it needed to be changed.  */
#define GC_MARK_STACK GC_MAKE_GCPROS_NOOPS

/* Virtual addresses of pure and impure space can vary, as on Windows.  */
#define VIRT_ADDR_VARIES

/* Emacs supplies its own malloc, but glib (part of Gtk+) calls
   memalign and on Cygwin, that becomes the Cygwin-supplied memalign.
   As malloc is not the Cygwin malloc, the Cygwin memalign always
   returns ENOSYS.  A workaround is to set G_SLICE=always-malloc. */
#define G_SLICE_ALWAYS_MALLOC

/* Don't link against static libgcc */
#define LIB_GCC

/* Don't list system libs on link command line */
#define LIB_STANDARD
#define LIB_MATH
#define LIBS_DEBUG

/* the end */

/* arch-tag: 5ae7ba00-83b0-4ab3-806a-3e845779191b
   (do not change this comment) */

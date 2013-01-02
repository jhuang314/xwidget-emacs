#ifndef EMACS_W32_H
#define EMACS_W32_H

/* Support routines for the NT version of Emacs.
   Copyright (C) 1994, 2001-2013 Free Software Foundation, Inc.

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

#ifdef CYGWIN
#error "w32.h is not compatible with Cygwin"
#endif

#include <windows.h>


/* File descriptor set emulation.  */

/* MSVC runtime library has limit of 64 descriptors by default */
#define FD_SETSIZE  64
typedef struct {
  unsigned int bits[FD_SETSIZE / 32];
} fd_set;

/* standard access macros */
#define FD_SET(n, p) \
  do { \
    if ((n) < FD_SETSIZE) { \
      (p)->bits[(n)/32] |= (1 << (n)%32); \
    } \
  } while (0)
#define FD_CLR(n, p) \
  do { \
    if ((n) < FD_SETSIZE) { \
      (p)->bits[(n)/32] &= ~(1 << (n)%32); \
    } \
  } while (0)
#define FD_ISSET(n, p) ((n) < FD_SETSIZE ? ((p)->bits[(n)/32] & (1 << (n)%32)) : 0)
#define FD_ZERO(p) memset((p), 0, sizeof(fd_set))

#define SELECT_TYPE fd_set

/* ------------------------------------------------------------------------- */

/* child_process.status values */
enum {
  STATUS_READ_ERROR = -1,
  STATUS_READ_READY,
  STATUS_READ_IN_PROGRESS,
  STATUS_READ_FAILED,
  STATUS_READ_SUCCEEDED,
  STATUS_READ_ACKNOWLEDGED
};

/* This structure is used for both pipes and sockets; for
   a socket, the process handle in pi is NULL. */
typedef struct _child_process
{
  /* File descriptor for sockets and serial port connections, and for
     reading output from async subprocesses; otherwise -1.  */
  int                 fd;
  /* PID for subprocess, either async or not; otherwise -1.  */
  int                 pid;
  /* Handle to an event object that is signaled when a read operation
     is completed, either successfully (in which case there're indeed
     "characters available") or not.  Used by sys_select to wait for
     output from subprocesses or socket/serial connections.  */
  HANDLE              char_avail;
  /* Handle to an event that is signaled to wake up the reader thread
     and tell it to try reading more output from a subprocess.  */
  HANDLE              char_consumed;
  /* Handle to the reader thread to read output from a subprocess or a
     socket or a comm port.  */
  HANDLE              thrd;
  /* Handle to the console window of a subprocess.  Used to forcibly
     terminate it by sys_kill.  */
  HWND                hwnd;
  /* Information about subprocess returned by CreateProcess.  Includes
     handles to the subprocess and its primary thread, and the
     corresponding process ID and thread ID numbers.  The PID is
     mirrored by the 'pid' member above.  The process handle is used
     to wait on it.  */
  PROCESS_INFORMATION procinfo;
  /* Status of subprocess/connection and of reading its output.  For
     values, see the enumeration above.  */
  volatile int        status;
  /* Holds a single character read by _sys_read_ahead, when a
     subprocess has some output ready.  */
  char                chr;
  /* Used for async read operations on serial comm ports.  */
  OVERLAPPED          ovl_read;
  /* Used for async write operations on serial comm ports.  */
  OVERLAPPED          ovl_write;
  /* Input file, if any, for this subprocess.  Should only be non-NULL
     for async subprocesses.  */
  char               *input_file;
  /* If non-zero, the subprocess input file is temporary and should be
     deleted when the subprocess exits.  */
  int                 pending_deletion;
} child_process;

#define MAXDESC FD_SETSIZE
#define MAX_CHILDREN  MAXDESC/2
#define CHILD_ACTIVE(cp) ((cp)->char_avail != NULL)

/* parallel array of private info on file handles */
typedef struct
{
  unsigned         flags;
  HANDLE           hnd;
  child_process *  cp;
} filedesc;

extern filedesc fd_info [ MAXDESC ];

/* fd_info flag definitions */
#define FILE_READ               0x0001
#define FILE_WRITE              0x0002
#define FILE_LISTEN		0x0004
#define FILE_BINARY             0x0010
#define FILE_LAST_CR            0x0020
#define FILE_AT_EOF             0x0040
#define FILE_SEND_SIGCHLD       0x0080
#define FILE_PIPE               0x0100
#define FILE_SOCKET             0x0200
#define FILE_NDELAY             0x0400
#define FILE_SERIAL             0x0800

extern child_process * new_child (void);
extern void delete_child (child_process *cp);

/* ------------------------------------------------------------------------- */

/* Equivalent of strerror for W32 error codes.  */
extern char * w32_strerror (int error_no);

/* Validate a pointer.  */
extern int w32_valid_pointer_p (void *, int);

/* Get long (aka "true") form of file name, if it exists.  */
extern BOOL w32_get_long_filename (char * name, char * buf, int size);

/* Prepare our standard handles for proper inheritance by child processes.  */
extern void prepare_standard_handles (int in, int out,
				      int err, HANDLE handles[4]);

/* Reset our standard handles to their original state.  */
extern void reset_standard_handles (int in, int out,
				    int err, HANDLE handles[4]);

/* Return the string resource associated with KEY of type TYPE.  */
extern LPBYTE w32_get_resource (char * key, LPDWORD type);

extern void init_ntproc (int);
extern void term_ntproc (int);
extern void globals_of_w32 (void);

extern void term_timers (void);
extern void init_timers (void);

extern int _sys_read_ahead (int fd);
extern int _sys_wait_accept (int fd);

extern Lisp_Object QCloaded_from;
extern HMODULE w32_delayed_load (Lisp_Object);

extern void init_environment (char **);
extern void check_windows_init_file (void);
extern void syms_of_ntproc (void);
extern void syms_of_ntterm (void);
extern void dostounix_filename (register char *);
extern void unixtodos_filename (register char *);
extern BOOL init_winsock (int load_now);
extern void srandom (int);
extern int random (void);

extern int sys_pipe (int *);

extern void set_process_dir (char *);
extern int sys_spawnve (int, char *, char **, char **);
extern void register_child (pid_t, int);
extern void record_infile (pid_t, char *);
extern void record_pending_deletion (char *);

extern void sys_sleep (int);
extern int sys_link (const char *, const char *);



#ifdef HAVE_GNUTLS
#include <gnutls/gnutls.h>

/* GnuTLS pull (read from remote) interface.  */
extern ssize_t emacs_gnutls_pull (gnutls_transport_ptr_t p,
                                  void* buf, size_t sz);

/* GnuTLS push (write to remote) interface.  */
extern ssize_t emacs_gnutls_push (gnutls_transport_ptr_t p,
                                  const void* buf, size_t sz);
#endif /* HAVE_GNUTLS */

#endif /* EMACS_W32_H */

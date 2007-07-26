/* Handcrafted Emacs site configuration file for Mac OS 9.  -*- C -*- */

/* GNU Emacs site configuration template file.  -*- C -*-
   Copyright (C) 1988, 1993, 1994, 1999, 2000, 2001, 2002, 2003, 2004,
      2005, 2006, 2007  Free Software Foundation, Inc.

This file is part of GNU Emacs.

GNU Emacs is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

GNU Emacs is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301, USA.  */

/* Contributed by Andrew Choi (akochoi@mac.com).  */

/* No code in Emacs #includes config.h twice, but some bits of code
   intended to work with other packages as well (like gmalloc.c)
   think they can include it as many times as they like.  */
#ifndef EMACS_CONFIG_H
#define EMACS_CONFIG_H


/* Define to 1 if the mktime function is broken. */
/* #undef BROKEN_MKTIME */

/* Define to one of `_getb67', `GETB67', `getb67' for Cray-2 and Cray-YMP
   systems. This function is required for `alloca.c' support on those systems.
   */
/* #undef CRAY_STACKSEG_END */

/* Define to 1 if using `alloca.c'. */
#ifndef __MRC__  /* CodeWarrior */
#define C_ALLOCA 1
#endif

/* Define to 1 if using `getloadavg.c'. */
/* #undef C_GETLOADAVG */

/* Define C_SWITCH_X_SITE to contain any special flags your compiler may need
   to deal with X Windows. For instance, if you've defined HAVE_X_WINDOWS
   above and your X include files aren't in a place that your compiler can
   find on its own, you might want to add "-I/..." or something similar. */
/* #undef C_SWITCH_X_SITE */

/* Define to 1 for DGUX with <sys/dg_sys_info.h>. */
/* #undef DGUX */

/* Define to 1 if you are using the GNU C Library. */
/* #undef DOUG_LEA_MALLOC */

/* Define to the canonical Emacs configuration name. */
#ifdef __MRC__
#define EMACS_CONFIGURATION "macos-mpw"
#else  /* Assume CodeWarrior */
#define EMACS_CONFIGURATION "macos-cw"
#endif

/* Define to the options passed to configure. */
#define EMACS_CONFIG_OPTIONS ""

/* Define to 1 if the `getloadavg' function needs to be run setuid or setgid.
   */
/* #undef GETLOADAVG_PRIVILEGED */

/* Define to 1 if the `getpgrp' function requires zero arguments. */
/* #undef GETPGRP_VOID */

/* Define to 1 if gettimeofday accepts only one argument. */
#define GETTIMEOFDAY_ONE_ARGUMENT 1

/* Define to 1 if you want to use the GNU memory allocator. */
/* #undef GNU_MALLOC */

/* Define to 1 if the file /usr/lpp/X11/bin/smt.exp exists. */
/* #undef HAVE_AIX_SMT_EXP */

/* Define to 1 if you have the `alarm' function. */
/* #undef HAVE_ALARM */

/* Define to 1 if you have `alloca', as a function or macro. */
#ifdef __MRC__
#define HAVE_ALLOCA 1
#endif

/* Define to 1 if you have <alloca.h> and it should be used (not on Ultrix).
   */
#ifdef __MRC__
#define HAVE_ALLOCA_H 1
#endif

/* Define to 1 if ALSA is available. */
/* #undef HAVE_ALSA */

/* Define to 1 if you have the `bcmp' function. */
/* #undef HAVE_BCMP */

/* Define to 1 if you have the `bcopy' function. */
/* #undef HAVE_BCOPY */

/* Define to 1 if you have the `bzero' function. */
/* #undef HAVE_BZERO */

/* Define to 1 if you are using the Carbon API on Mac OS X. */
/* #undef HAVE_CARBON */

/* Define to 1 if you have the `cbrt' function. */
/* #undef HAVE_CBRT */

/* Define to 1 if you have the `closedir' function. */
#define HAVE_CLOSEDIR 1

/* Define to 1 if you have the <coff.h> header file. */
/* #undef HAVE_COFF_H */

/* Define to 1 if you have the <com_err.h> header file. */
/* #undef HAVE_COM_ERR_H */

/* Define to 1 if you have /usr/lib/crti.o. */
/* #undef HAVE_CRTIN */

/* Define to 1 if you have the declaration of `sys_siglist', and to 0 if you
   don't. */
/* #undef HAVE_DECL_SYS_SIGLIST */

/* Define to 1 if you have the declaration of `tzname', and to 0 if you don't.
   */
/* #undef HAVE_DECL_TZNAME */

/* Define to 1 if you have the declaration of `__sys_siglist', and to 0 if you
   don't. */
/* #undef HAVE_DECL___SYS_SIGLIST */

/* Define to 1 if you have the <des.h> header file. */
/* #undef HAVE_DES_H */

/* Define to 1 if dynamic ptys are supported. */
/* #undef HAVE_DEV_PTMX */

/* Define to 1 if you have the `difftime' function. */
#define HAVE_DIFFTIME 1

/* Define to 1 if you have the `dup2' function. */
/* #undef HAVE_DUP2 */

/* Define to 1 if you have the `euidaccess' function. */
/* #undef HAVE_EUIDACCESS */

/* Define to 1 if you have the <fcntl.h> header file. */
#define HAVE_FCNTL_H 1

/* Define to 1 if you have the `fmod' function. */
#define HAVE_FMOD 1

/* Define to 1 if you have the `fork' function. */
/* #undef HAVE_FORK */

/* Define to 1 if you have the `fpathconf' function. */
/* #undef HAVE_FPATHCONF */

/* Define to 1 if you have the `frexp' function. */
#define HAVE_FREXP 1

/* Define to 1 if fseeko (and presumably ftello) exists and is declared. */
/* #undef HAVE_FSEEKO */

/* Define to 1 if you have the `fsync' function. */
/* #undef HAVE_FSYNC */

/* Define to 1 if you have the `ftime' function. */
/* #undef HAVE_FTIME */

/* Define to 1 if you have the `gai_strerror' function. */
/* #undef HAVE_GAI_STRERROR */

/* Define to 1 if you have the `gdk_display_open' function. */
/* #undef HAVE_GDK_DISPLAY_OPEN */

/* Define to 1 if you have the `getaddrinfo' function. */
/* #undef HAVE_GETADDRINFO */

/* Define to 1 if you have the `getcwd' function. */
/* #undef HAVE_GETCWD */

/* Define to 1 if you have the `getdelim' function. */
/* #undef HAVE_GETDELIM */

/* Define to 1 if you have the `getdomainname' function. */
/* #undef HAVE_GETDOMAINNAME */

/* Define to 1 if you have the `gethostname' function. */
/* #undef HAVE_GETHOSTNAME */

/* Define to 1 if you have the `getline' function. */
/* #undef HAVE_GETLINE */

/* Define to 1 if you have the `getloadavg' function. */
/* #undef HAVE_GETLOADAVG */

/* Define to 1 if you have the <getopt.h> header file. */
/* #undef HAVE_GETOPT_H */

/* Define to 1 if you have the `getopt_long_only' function. */
/* #undef HAVE_GETOPT_LONG_ONLY */

/* Define to 1 if you have the `getpagesize' function. */
/* #undef HAVE_GETPAGESIZE */

/* Define to 1 if you have the `getpeername' function. */
/* #undef HAVE_GETPEERNAME */

/* Define to 1 if you have the `getpt' function. */
/* #undef HAVE_GETPT */

/* Define to 1 if you have the `getrusage' function. */
/* #undef HAVE_GETRUSAGE */

/* Define to 1 if you have the `getsockname' function. */
/* #undef HAVE_GETSOCKNAME */

/* Define to 1 if you have the `getsockopt' function. */
/* #undef HAVE_GETSOCKOPT */

/* Define to 1 if you have the `gettimeofday' function. */
#define HAVE_GETTIMEOFDAY 1

/* Define to 1 if you have the `getwd' function. */
#define HAVE_GETWD 1

/* Define to 1 if you have the `get_current_dir_name' function. */
/* #undef HAVE_GET_CURRENT_DIR_NAME */

/* Define to 1 if you have the ungif library (-lungif). */
/* #undef HAVE_GIF */

/* Define to 1 if you have the `grantpt' function. */
/* #undef HAVE_GRANTPT */

/* Define to 1 if using GTK. */
/* #undef HAVE_GTK */

/* Define to 1 if you have GTK and pthread (-lpthread). */
/* #undef HAVE_GTK_AND_PTHREAD */

/* Define to 1 if GTK has both file selection and chooser dialog. */
/* #undef HAVE_GTK_FILE_BOTH */

/* Define to 1 if you have the `gtk_file_chooser_dialog_new' function. */
/* #undef HAVE_GTK_FILE_CHOOSER_DIALOG_NEW */

/* Define to 1 if you have the `gtk_file_selection_new' function. */
/* #undef HAVE_GTK_FILE_SELECTION_NEW */

/* Define to 1 if you have the `gtk_main' function. */
/* #undef HAVE_GTK_MAIN */

/* Define to 1 if GTK can handle more than one display. */
/* #undef HAVE_GTK_MULTIDISPLAY */

/* Define to 1 if netdb.h declares h_errno. */
/* #undef HAVE_H_ERRNO */

/* Define to 1 if you have the `index' function. */
/* #undef HAVE_INDEX */

/* Define to 1 if you have inet sockets. */
/* #undef HAVE_INET_SOCKETS */

/* Define to 1 if you have the <inttypes.h> header file. */
/* #undef HAVE_INTTYPES_H */

/* Define to 1 if you have the jpeg library (-ljpeg). */
/* #undef HAVE_JPEG */

/* Define to 1 if you have the <kerberosIV/des.h> header file. */
/* #undef HAVE_KERBEROSIV_DES_H */

/* Define to 1 if you have the <kerberosIV/krb.h> header file. */
/* #undef HAVE_KERBEROSIV_KRB_H */

/* Define to 1 if you have the <kerberos/des.h> header file. */
/* #undef HAVE_KERBEROS_DES_H */

/* Define to 1 if you have the <kerberos/krb.h> header file. */
/* #undef HAVE_KERBEROS_KRB_H */

/* Define to 1 if you have the <krb5.h> header file. */
/* #undef HAVE_KRB5_H */

/* Define to 1 if you have the <krb.h> header file. */
/* #undef HAVE_KRB_H */

/* Define if you have <langinfo.h> and nl_langinfo(CODESET). */
/* #undef HAVE_LANGINFO_CODESET */

/* Define to 1 if you have the `com_err' library (-lcom_err). */
/* #undef HAVE_LIBCOM_ERR */

/* Define to 1 if you have the `crypto' library (-lcrypto). */
/* #undef HAVE_LIBCRYPTO */

/* Define to 1 if you have the `des' library (-ldes). */
/* #undef HAVE_LIBDES */

/* Define to 1 if you have the `des425' library (-ldes425). */
/* #undef HAVE_LIBDES425 */

/* Define to 1 if you have the `dgc' library (-ldgc). */
/* #undef HAVE_LIBDGC */

/* Define to 1 if you have the `dnet' library (-ldnet). */
/* #undef HAVE_LIBDNET */

/* Define to 1 if you have the hesiod library (-lhesiod). */
/* #undef HAVE_LIBHESIOD */

/* Define to 1 if you have the `intl' library (-lintl). */
/* #undef HAVE_LIBINTL */

/* Define to 1 if you have the `k5crypto' library (-lk5crypto). */
/* #undef HAVE_LIBK5CRYPTO */

/* Define to 1 if you have the `krb' library (-lkrb). */
/* #undef HAVE_LIBKRB */

/* Define to 1 if you have the `krb4' library (-lkrb4). */
/* #undef HAVE_LIBKRB4 */

/* Define to 1 if you have the `krb5' library (-lkrb5). */
/* #undef HAVE_LIBKRB5 */

/* Define to 1 if you have the `kstat' library (-lkstat). */
/* #undef HAVE_LIBKSTAT */

/* Define to 1 if you have the `lockfile' library (-llockfile). */
/* #undef HAVE_LIBLOCKFILE */

/* Define to 1 if you have the `m' library (-lm). */
/* #undef HAVE_LIBM */

/* Define to 1 if you have the `mail' library (-lmail). */
/* #undef HAVE_LIBMAIL */

/* Define to 1 if you have the `ncurses' library (-lncurses). */
/* #undef HAVE_LIBNCURSES */

/* Define to 1 if you have the <libpng/png.h> header file. */
/* #undef HAVE_LIBPNG_PNG_H */

/* Define to 1 if you have the `pthreads' library (-lpthreads). */
/* #undef HAVE_LIBPTHREADS */

/* Define to 1 if you have the resolv library (-lresolv). */
/* #undef HAVE_LIBRESOLV */

/* Define to 1 if you have the `Xext' library (-lXext). */
/* #undef HAVE_LIBXEXT */

/* Define to 1 if you have the `Xmu' library (-lXmu). */
/* #undef HAVE_LIBXMU */

/* Define to 1 if you have the Xp library (-lXp). */
/* #undef HAVE_LIBXP */

/* Define to 1 if you have the <limits.h> header file. */
#define HAVE_LIMITS_H 1

/* Define to 1 if you have the <linux/version.h> header file. */
/* #undef HAVE_LINUX_VERSION_H */

/* Define to 1 if you have the <locale.h> header file. */
#define HAVE_LOCALE_H 1

/* Define to 1 if you have the `logb' function. */
#define HAVE_LOGB 1

/* Define to 1 if you support file names longer than 14 characters. */
/* #undef HAVE_LONG_FILE_NAMES */

/* Define to 1 if you have the `lrand48' function. */
/* #undef HAVE_LRAND48 */

/* Define to 1 if you have the <machine/soundcard.h> header file. */
/* #undef HAVE_MACHINE_SOUNDCARD_H */

/* Define to 1 if you have the <mach/mach.h> header file. */
/* #undef HAVE_MACH_MACH_H */

/* Define to 1 if you have the <maillock.h> header file. */
/* #undef HAVE_MAILLOCK_H */

/* Define to 1 if you have the <malloc/malloc.h> header file. */
/* #undef HAVE_MALLOC_MALLOC_H */

/* Define to 1 if you have the `mblen' function. */
/* #undef HAVE_MBLEN */

/* Define to 1 if you have the `mbrlen' function. */
/* #undef HAVE_MBRLEN */

/* Define to 1 if you have the `mbsinit' function. */
/* #undef HAVE_MBSINIT */

/* Define to 1 if <wchar.h> declares mbstate_t. */
/* #undef HAVE_MBSTATE_T */

/* Define to 1 if you have the `memcmp' function. */
#define HAVE_MEMCMP 1

/* Define to 1 if you have the `memcpy' function. */
#define HAVE_MEMCPY 1

/* Define to 1 if you have the `memmove' function. */
#define HAVE_MEMMOVE 1

/* Define to 1 if you have the <memory.h> header file. */
/* #undef HAVE_MEMORY_H */

/* Define to 1 if you have the `mempcpy' function. */
/* #undef HAVE_MEMPCPY */

/* Define to 1 if you have the `memset' function. */
#define HAVE_MEMSET 1

/* Define to 1 if you have mouse menus. (This is automatic if you use X, but
   the option to specify it remains.) It is also defined with other window
   systems that support xmenu.c. */
#define HAVE_MENUS 1

/* Define to 1 if you have the `mkdir' function. */
#define HAVE_MKDIR 1

/* Define to 1 if you have the `mkstemp' function. */
/* #undef HAVE_MKSTEMP */

/* Define to 1 if you have the `mktime' function. */
/* #undef HAVE_MKTIME */

/* Define to 1 if you have a working `mmap' system call. */
/* #undef HAVE_MMAP */

/* Define to 1 if you have Motif 2.1 or newer. */
/* #undef HAVE_MOTIF_2_1 */

/* Define to 1 if you have the `mremap' function. */
/* #undef HAVE_MREMAP */

/* Define to 1 if you have the <net/if.h> header file. */
/* #undef HAVE_NET_IF_H */

/* Define to 1 if you have the <nlist.h> header file. */
/* #undef HAVE_NLIST_H */

/* Define to 1 if personality LINUX32 can be set. */
/* #undef HAVE_PERSONALITY_LINUX32 */

/* Define to 1 if you have the png library (-lpng). */
/* #undef HAVE_PNG */

/* Define to 1 if you have the <png.h> header file. */
/* #undef HAVE_PNG_H */

/* Define to 1 if you have the `posix_memalign' function. */
/* #undef HAVE_POSIX_MEMALIGN */

/* Define to 1 if you have the `pstat_getdynamic' function. */
/* #undef HAVE_PSTAT_GETDYNAMIC */

/* Define to 1 if you have the <pthread.h> header file. */
/* #undef HAVE_PTHREAD_H */

/* Define to 1 if you have the <pty.h> header file. */
/* #undef HAVE_PTY_H */

/* Define to 1 if you have the <pwd.h> header file. */
#define HAVE_PWD_H 1

/* Define to 1 if you have the `random' function. */
/* #undef HAVE_RANDOM */

/* Define to 1 if you have the `recvfrom' function. */
/* #undef HAVE_RECVFROM */

/* Define to 1 if you have the `rename' function. */
#define HAVE_RENAME 1

/* Define to 1 if you have the `res_init' function. */
/* #undef HAVE_RES_INIT */

/* Define to 1 if you have the `rindex' function. */
/* #undef HAVE_RINDEX */

/* Define to 1 if you have the `rint' function. */
#ifdef __MRC__
#undef HAVE_RINT
#else  /* CodeWarrior */
#define HAVE_RINT
#endif

/* Define to 1 if you have the `rmdir' function. */
#define HAVE_RMDIR 1

/* Define to 1 if you have the `select' function. */
#define HAVE_SELECT 1

/* Define to 1 if you have the `sendto' function. */
/* #undef HAVE_SENDTO */

/* Define to 1 if you have the `setitimer' function. */
#define HAVE_SETITIMER 1

/* Define to 1 if you have the `setlocale' function. */
#define HAVE_SETLOCALE 1

/* Define to 1 if you have the `setpgid' function. */
/* #undef HAVE_SETPGID */

/* Define to 1 if you have the `setrlimit' function. */
/* #undef HAVE_SETRLIMIT */

/* Define to 1 if you have the `setsid' function. */
/* #undef HAVE_SETSID */

/* Define to 1 if you have the `setsockopt' function. */
/* #undef HAVE_SETSOCKOPT */

/* Define to 1 if you have the `shutdown' function. */
/* #undef HAVE_SHUTDOWN */

/* Define to 1 if the system has the type `size_t'. */
#define HAVE_SIZE_T 1

/* Define to 1 if you have the <soundcard.h> header file. */
/* #undef HAVE_SOUNDCARD_H */

/* Define to 1 if `speed_t' is declared by <termios.h>. */
/* #undef HAVE_SPEED_T */

/* Define to 1 if you have the <stdint.h> header file. */
/* #undef HAVE_STDINT_H */

/* Define to 1 if you have the <stdio_ext.h> header file. */
/* #undef HAVE_STDIO_EXT_H */

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the `strerror' function. */
#define HAVE_STRERROR 1

/* Define to 1 if you have the `strftime' function. */
#ifndef __MRC__  /* CodeWarrior */
#define HAVE_STRFTIME 1
#endif

/* Define to 1 if you have the <strings.h> header file. */
/* #undef HAVE_STRINGS_H */

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if you have the `strsignal' function. */
/* #undef HAVE_STRSIGNAL */

/* Define to 1 if `ifr_addr' is member of `struct ifreq'. */
/* #undef HAVE_STRUCT_IFREQ_IFR_ADDR */

/* Define to 1 if `ifr_broadaddr' is member of `struct ifreq'. */
/* #undef HAVE_STRUCT_IFREQ_IFR_BROADADDR */

/* Define to 1 if `ifr_flags' is member of `struct ifreq'. */
/* #undef HAVE_STRUCT_IFREQ_IFR_FLAGS */

/* Define to 1 if `ifr_hwaddr' is member of `struct ifreq'. */
/* #undef HAVE_STRUCT_IFREQ_IFR_HWADDR */

/* Define to 1 if `ifr_netmask' is member of `struct ifreq'. */
/* #undef HAVE_STRUCT_IFREQ_IFR_NETMASK */

/* Define to 1 if `n_un.n_name' is member of `struct nlist'. */
/* #undef HAVE_STRUCT_NLIST_N_UN_N_NAME */

/* Define to 1 if `tm_zone' is member of `struct tm'. */
/* #undef HAVE_STRUCT_TM_TM_ZONE */

/* Define to 1 if `struct utimbuf' is declared by <utime.h>. */
#define HAVE_STRUCT_UTIMBUF 1

/* Define to 1 if you have the `sync' function. */
/* #undef HAVE_SYNC */

/* Define to 1 if you have the `sysinfo' function. */
/* #undef HAVE_SYSINFO */

/* Define to 1 if you have the <sys/ioctl.h> header file. */
#define HAVE_SYS_IOCTL_H 1

/* Define to 1 if you have the <sys/mman.h> header file. */
/* #undef HAVE_SYS_MMAN_H */

/* Define to 1 if you have the <sys/param.h> header file. */
#define HAVE_SYS_PARAM_H 1

/* Define to 1 if you have the <sys/resource.h> header file. */
/* #undef HAVE_SYS_RESOURCE_H */

/* Define to 1 if you have the <sys/select.h> header file. */
/* #undef HAVE_SYS_SELECT_H */

/* Define to 1 if you have the <sys/socket.h> header file. */
/* #undef HAVE_SYS_SOCKET_H */

/* Define to 1 if you have the <sys/soundcard.h> header file. */
/* #undef HAVE_SYS_SOUNDCARD_H */

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/systeminfo.h> header file. */
/* #undef HAVE_SYS_SYSTEMINFO_H */

/* Define to 1 if you have the <sys/timeb.h> header file. */
/* #undef HAVE_SYS_TIMEB_H */

/* Define to 1 if you have the <sys/time.h> header file. */
#define HAVE_SYS_TIME_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have the <sys/un.h> header file. */
/* #undef HAVE_SYS_UN_H */

/* Define to 1 if you have the <sys/utsname.h> header file. */
/* #undef HAVE_SYS_UTSNAME_H */

/* Define to 1 if you have the <sys/vlimit.h> header file. */
/* #undef HAVE_SYS_VLIMIT_H */

/* Define to 1 if you have <sys/wait.h> that is POSIX.1 compatible. */
/* #undef HAVE_SYS_WAIT_H */

/* Define to 1 if you have the <sys/_mbstate_t.h> header file. */
/* #undef HAVE_SYS__MBSTATE_T_H */

/* Define to 1 if you have the <termcap.h> header file. */
/* #undef HAVE_TERMCAP_H */

/* Define to 1 if you have the <termios.h> header file. */
/* #undef HAVE_TERMIOS_H */

/* Define to 1 if you have the <term.h> header file. */
/* #undef HAVE_TERM_H */

/* Define to 1 if you have the tiff library (-ltiff). */
/* #undef HAVE_TIFF */

/* Define to 1 if `struct timeval' is declared by <sys/time.h>. */
#define HAVE_TIMEVAL 1

/* Define to 1 if `tm_gmtoff' is member of `struct tm'. */
/* #undef HAVE_TM_GMTOFF */

/* Define to 1 if your `struct tm' has `tm_zone'. Deprecated, use
   `HAVE_STRUCT_TM_TM_ZONE' instead. */
/* #undef HAVE_TM_ZONE */

/* Define to 1 if you have the `touchlock' function. */
/* #undef HAVE_TOUCHLOCK */

/* Define to 1 if you don't have `tm_zone' but do have the external array
   `tzname'. */
/* #undef HAVE_TZNAME */

/* Define to 1 if you have the `tzset' function. */
/* #undef HAVE_TZSET */

/* Define to 1 if you have the `ualarm' function. */
/* #undef HAVE_UALARM */

/* Define to 1 if you have the <unistd.h> header file. */
#ifdef __MRC__
#undef HAVE_UNISTD_H
#else  /* CodeWarrior */
#define HAVE_UNISTD_H 1
#endif

/* Define to 1 if you have the `utimes' function. */
/* #undef HAVE_UTIMES */

/* Define to 1 if you have the <utime.h> header file. */
#define HAVE_UTIME_H 1

/* Define to 1 if you have the `vfork' function. */
/* #undef HAVE_VFORK */

/* Define to 1 if you have the <vfork.h> header file. */
/* #undef HAVE_VFORK_H */

/* Define to 1 if `fork' works. */
/* #undef HAVE_WORKING_FORK */

/* Define to 1 if `vfork' works. */
/* #undef HAVE_WORKING_VFORK */

/* Define to 1 if you want to use version 11 of X windows. Otherwise, Emacs
   expects to use version 10. */
/* #undef HAVE_X11 */

/* Define to 1 if you have the X11R5 or newer version of Xlib. */
/* #undef HAVE_X11R5 */

/* Define to 1 if you have the X11R6 or newer version of Xlib. */
/* #undef HAVE_X11R6 */

/* Define to 1 if you have the X11R6 or newer version of Xt. */
/* #undef HAVE_X11XTR6 */

/* Define to 1 if the file /usr/lib64 exists. */
/* #undef HAVE_X86_64_LIB64_DIR */

/* Define to 1 if you have the Xaw3d library (-lXaw3d). */
/* #undef HAVE_XAW3D */

/* Define to 1 if you're using XFree386. */
/* #undef HAVE_XFREE386 */

/* Define to 1 if you have the Xft library. */
/* #undef HAVE_XFT */

/* Define to 1 if XIM is available */
/* #undef HAVE_XIM */

/* Define to 1 if you have the XkbGetKeyboard function. */
/* #undef HAVE_XKBGETKEYBOARD */

/* Define to 1 if you have the Xpm libary (-lXpm). */
/* #undef HAVE_XPM */

/* Define to 1 if you have the `XrmSetDatabase' function. */
/* #undef HAVE_XRMSETDATABASE */

/* Define to 1 if you have the `XScreenNumberOfScreen' function. */
/* #undef HAVE_XSCREENNUMBEROFSCREEN */

/* Define to 1 if you have the `XScreenResourceString' function. */
/* #undef HAVE_XSCREENRESOURCESTRING */

/* Define to 1 if you have the `XSetWMProtocols' function. */
/* #undef HAVE_XSETWMPROTOCOLS */

/* Define to 1 if you have the SM library (-lSM). */
/* #undef HAVE_X_SM */

/* Define to 1 if you want to use the X window system. */
/* #undef HAVE_X_WINDOWS */

/* Define to 1 if you have the `__fpending' function. */
/* #undef HAVE___FPENDING */

/* Define to support using a Hesiod database to find the POP server. */
/* #undef HESIOD */

/* Define to support Kerberos-authenticated POP mail retrieval. */
/* #undef KERBEROS */

/* Define to use Kerberos 5 instead of Kerberos 4. */
/* #undef KERBEROS5 */

/* Define LD_SWITCH_X_SITE to contain any special flags your loader may need
   to deal with X Windows. For instance, if you've defined HAVE_X_WINDOWS
   above and your X libraries aren't in a place that your loader can find on
   its own, you might want to add "-L/..." or something similar. */
/* #undef LD_SWITCH_X_SITE */

/* Define LD_SWITCH_X_SITE_AUX with an -R option in case it's needed (for
   Solaris, for example). */
/* #undef LD_SWITCH_X_SITE_AUX */

/* Define to 1 if localtime caches TZ. */
/* #undef LOCALTIME_CACHE */

/* Define to support POP mail retrieval. */
/* #undef MAIL_USE_POP 1 */

/* Define to 1 if your `struct nlist' has an `n_un' member. Obsolete, depend
   on `HAVE_STRUCT_NLIST_N_UN_N_NAME */
/* #undef NLIST_NAME_UNION */

/* Define to 1 if you don't have struct exception in math.h. */
/* #undef NO_MATHERR */

/* Define to the address where bug reports for this package should be sent. */
/* #undef PACKAGE_BUGREPORT */

/* Define to the full name of this package. */
/* #undef PACKAGE_NAME */

/* Define to the full name and version of this package. */
/* #undef PACKAGE_STRING */

/* Define to the one symbol short name of this package. */
/* #undef PACKAGE_TARNAME */

/* Define to the version of this package. */
/* #undef PACKAGE_VERSION */

/* Define as `void' if your compiler accepts `void *'; otherwise define as
   `char'. */
#define POINTER_TYPE void

/* Define to 1 if the C compiler supports function prototypes. */
/* #undef PROTOTYPES */

/* Define REL_ALLOC if you want to use the relocating allocator for buffer
   space. */
/* #undef REL_ALLOC */

/* Define as the return type of signal handlers (`int' or `void'). */
#define RETSIGTYPE void

/* If using the C implementation of alloca, define if you know the
   direction of stack growth for your system; otherwise it will be
   automatically deduced at runtime.
	STACK_DIRECTION > 0 => grows toward higher addresses
	STACK_DIRECTION < 0 => grows toward lower addresses
	STACK_DIRECTION = 0 => direction of growth unknown */
/* #undef STACK_DIRECTION */

/* Define to 1 if you have the ANSI C header files. */
/* #undef STDC_HEADERS */

/* Define to 1 on System V Release 4. */
/* #undef SVR4 */

/* Define to 1 if you can safely include both <sys/time.h> and <time.h>. */
#define TIME_WITH_SYS_TIME 1

/* Define to 1 if your <sys/time.h> declares `struct tm'. */
/* #undef TM_IN_SYS_TIME */

/* Define to 1 for Encore UMAX. */
/* #undef UMAX */

/* Define to 1 for Encore UMAX 4.3 that has <inq_status/cpustats.h> instead of
   <sys/cpustats.h>. */
/* #undef UMAX4_3 */

/* Define to the unexec source file name. */
/* #undef UNEXEC_SRC */

/* Define to 1 if we should use toolkit scroll bars. */
#ifdef HAVE_CARBON
#define USE_TOOLKIT_SCROLL_BARS 1
#endif

/* Define to 1 if we should use XIM, if it is available. */
/* #undef USE_XIM */

/* Define to 1 if using an X toolkit. */
/* #undef USE_X_TOOLKIT */

/* Define to the type of the 6th arg of XRegisterIMInstantiateCallback, either
   XPointer or XPointer*. */
/* #undef XRegisterIMInstantiateCallback_arg6 */

/* Define to 1 if on AIX 3.
   System headers sometimes define this.
   We just want to avoid a redefinition error message.  */
#ifndef _ALL_SOURCE
/* #undef _ALL_SOURCE */
#endif

/* Number of bits in a file offset, on hosts where this is settable. */
/* #undef _FILE_OFFSET_BITS */

/* Enable GNU extensions on systems that have them.  */
#ifndef _GNU_SOURCE
/* # undef _GNU_SOURCE */
#endif

/* Define to 1 to make fseeko visible on some hosts (e.g. glibc 2.2). */
/* #undef _LARGEFILE_SOURCE */

/* Define for large files, on AIX-style hosts. */
/* #undef _LARGE_FILES */

/* Define to rpl_ if the getopt replacement functions and variables should be
   used. */
/* #undef __GETOPT_PREFIX */

/* Define like PROTOTYPES; this can be used by system headers. */
/* #undef __PROTOTYPES */

/* Define to compiler's equivalent of C99 restrict keyword. Don't define if
   equivalent is `__restrict'. */
/* #undef __restrict */

/* Define to compiler's equivalent of C99 restrict keyword in array
   declarations. Define as empty for no equivalent. */
/* #undef __restrict_arr */

/* Define to the used machine dependent file. */
#define config_machfile "m-mac.h"

/* Define to the used os dependent file. */
#define config_opsysfile "s-mac.h"

/* Define to empty if `const' does not conform to ANSI C. */
/* #undef const */

/* Define to a type if <wchar.h> does not define. */
/* #undef mbstate_t */

/* Define to `int' if <sys/types.h> does not define. */
#define pid_t int

/* Define to any substitute for sys_siglist. */
/* #undef sys_siglist */

/* Define as `fork' if `vfork' does not work. */
/* #undef vfork */

/* Define to empty if the keyword `volatile' does not work. Warning: valid
   code using `volatile' can become incorrect without. Disable with care. */
/* #undef volatile */


/* If we're using any sort of window system, define some consequences.  */
#ifdef HAVE_X_WINDOWS
#define HAVE_WINDOW_SYSTEM
#define MULTI_KBOARD
#define HAVE_MOUSE
#endif

/* Define for MacOS */
#define HAVE_WINDOW_SYSTEM 1
#define HAVE_MOUSE 1

/* Define USER_FULL_NAME to return a string
   that is the user's full name.
   It can assume that the variable `pw'
   points to the password file entry for this user.

   At some sites, the pw_gecos field contains
   the user's full name.  If neither this nor any other
   field contains the right thing, use pw_name,
   giving the user's login name, since that is better than nothing.  */
#define USER_FULL_NAME pw->pw_name

/* Define AMPERSAND_FULL_NAME if you use the convention
   that & in the full name stands for the login id.  */
/* Turned on June 1996 supposing nobody will mind it.  */
/* #undef AMPERSAND_FULL_NAME */

/* We have blockinput.h.  */
#define DO_BLOCK_INPUT

/* Define HAVE_SOUND if we have sound support.  We know it works
   and compiles only on the specified platforms.   For others,
   it probably doesn't make sense to try.  */

#if defined __FreeBSD__ || defined __NetBSD__ || defined __linux__
#ifdef HAVE_MACHINE_SOUNDCARD_H
#define HAVE_SOUND 1
#endif
#ifdef HAVE_SYS_SOUNDCARD_H
#define HAVE_SOUND 1
#endif
#ifdef HAVE_SOUNDCARD_H
#define HAVE_SOUND 1
#endif
#ifdef HAVE_ALSA
#define HAVE_SOUND 1
#endif
#endif /* __FreeBSD__ || __NetBSD__ || __linux__  */

/* If using GNU, then support inline function declarations. */
/* Don't try to switch on inline handling as detected by AC_C_INLINE
   generally, because even if non-gcc compilers accept `inline', they
   may reject `extern inline'.  */
#if defined (__GNUC__) && defined (OPTIMIZE)
#define INLINE __inline__
#else
#define INLINE
#endif

#ifdef __MRC__
/* Use low-bits for tags.  If ENABLE_CHECKING is turned on together
   with USE_LSB_TAG, optimization flags should be explicitly turned
   off.  */
#define USE_LSB_TAG
#endif

/* Include the os and machine dependent files.  */
#include config_opsysfile
#include config_machfile

/* Load in the conversion definitions if this system
   needs them and the source file being compiled has not
   said to inhibit this.  There should be no need for you
   to alter these lines.  */

#ifdef SHORTNAMES
#ifndef NO_SHORTNAMES
#include "../shortnames/remap.h"
#endif /* not NO_SHORTNAMES */
#endif /* SHORTNAMES */

/* If no remapping takes place, static variables cannot be dumped as
   pure, so don't worry about the `static' keyword. */
#ifdef NO_REMAP
/* #undef static */
#endif

/* Define `subprocesses' should be defined if you want to
   have code for asynchronous subprocesses
   (as used in M-x compile and M-x shell).
   These do not work for some USG systems yet;
   for the ones where they work, the s/SYSTEM.h file defines this flag.  */

#ifndef VMS
#ifndef USG
/* #define subprocesses */
#endif
#endif

/* SIGTYPE is the macro we actually use.  */
#ifndef SIGTYPE
#define SIGTYPE RETSIGTYPE
#endif

#ifdef emacs /* Don't do this for lib-src.  */
/* Tell regex.c to use a type compatible with Emacs.  */
#define RE_TRANSLATE_TYPE Lisp_Object
#define RE_TRANSLATE(TBL, C) CHAR_TABLE_TRANSLATE (TBL, C)
#ifdef make_number
/* If make_number is a macro, use it.  */
#define RE_TRANSLATE_P(TBL) (!EQ (TBL, make_number (0)))
#else
/* If make_number is a function, avoid it.  */
#define RE_TRANSLATE_P(TBL) (!(INTEGERP (TBL) && XINT (TBL) == 0))
#endif
#endif

/* Avoid link-time collision with system mktime if we will use our own.  */
#if ! HAVE_MKTIME || BROKEN_MKTIME
#define mktime emacs_mktime
#endif

#define my_strftime nstrftime	/* for strftime.c */

/* The rest of the code currently tests the CPP symbol BSTRING.
   Override any claims made by the system-description files.
   Note that on some SCO version it is possible to have bcopy and not bcmp.  */
/* #undef BSTRING */
#if defined (HAVE_BCOPY) && defined (HAVE_BCMP)
#define BSTRING
#endif

/* Some of the files of Emacs which are intended for use with other
   programs assume that if you have a config.h file, you must declare
   the type of getenv.

   This declaration shouldn't appear when alloca.s or Makefile.in
   includes config.h.  */
#ifndef NOT_C_CODE
extern char *getenv ();
#endif

/* These default definitions are good for almost all machines.
   The exceptions override them in m/MACHINE.h.  */

#ifndef BITS_PER_CHAR
#define BITS_PER_CHAR 8
#endif

#ifndef BITS_PER_SHORT
#define BITS_PER_SHORT 16
#endif

/* Note that lisp.h uses this in a preprocessor conditional, so it
   would not work to use sizeof.  That being so, we do all of them
   without sizeof, for uniformity's sake.  */
#ifndef BITS_PER_INT
#define BITS_PER_INT 32
#endif

#ifndef BITS_PER_LONG
#ifdef _LP64
#define BITS_PER_LONG 64
#else
#define BITS_PER_LONG 32
#endif
#endif

/* Define if the compiler supports function prototypes.  It may do so
   but not define __STDC__ (e.g. DEC C by default) or may define it as
   zero.  */
/* #undef PROTOTYPES */
/* For mktime.c:  */
#ifndef __P
# if defined PROTOTYPES
#  define __P(args) args
# else
#  define __P(args) ()
# endif  /* GCC.  */
#endif /* __P */

/* Don't include "string.h" or <stdlib.h> in non-C code.  */
#ifndef NOT_C_CODE
#ifdef HAVE_STRING_H
#include "string.h"
#endif
#ifdef HAVE_STRINGS_H
#include "strings.h"  /* May be needed for bcopy & al. */
#endif
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
#ifndef __GNUC__
# ifdef HAVE_ALLOCA_H
#  include <alloca.h>
# else /* AIX files deal with #pragma.  */
#  ifndef alloca /* predefined by HP cc +Olibcalls */
char *alloca ();
#  endif
# endif /* HAVE_ALLOCA_H */
#endif /* __GNUC__ */
#ifndef HAVE_SIZE_T
typedef unsigned size_t;
#endif
#endif /* NOT_C_CODE */

/* Define HAVE_X_I18N if we have usable i18n support.  */

#ifdef HAVE_X11R6
#define HAVE_X_I18N
#elif defined HAVE_X11R5 && !defined X11R5_INHIBIT_I18N
#define HAVE_X_I18N
#endif

/* Define HAVE_X11R6_XIM if we have usable X11R6-style XIM support.  */

#if defined HAVE_X11R6 && !defined INHIBIT_X11R6_XIM
#define HAVE_X11R6_XIM
#endif

/* Should we enable expensive run-time checking of data types?  */
/* #undef ENABLE_CHECKING */

#if defined __GNUC__ && (__GNUC__ > 2 \
                         || (__GNUC__ == 2 && __GNUC_MINOR__ >= 5))
#define NO_RETURN	__attribute__ ((__noreturn__))
#else
#define NO_RETURN	/* nothing */
#endif

/* These won't be used automatically yet.  We also need to know, at least,
   that the stack is continuous.  */
#ifdef __GNUC__
#  ifndef GC_SETJMP_WORKS
  /* GC_SETJMP_WORKS is nearly always appropriate for GCC --
     see NON_SAVING_SETJMP in the target descriptions.  */
  /* Exceptions (see NON_SAVING_SETJMP in target description) are ns32k,
     SCO5 non-ELF (but Emacs specifies ELF) and SVR3 on x86.
     Fixme: Deal with ns32k, SVR3.  */
#    define GC_SETJMP_WORKS 1
#  endif
#  ifndef GC_LISP_OBJECT_ALIGNMENT
#    define GC_LISP_OBJECT_ALIGNMENT (__alignof__ (Lisp_Object))
#  endif
#endif

#ifndef HAVE_BCOPY
#define bcopy(a,b,s) memcpy (b,a,s)
#endif
#ifndef HAVE_BZERO
#define bzero(a,s) memset (a,0,s)
#endif
#ifndef HAVE_BCMP
#define BCMP memcmp
#endif

#define SYNC_INPUT

#endif /* EMACS_CONFIG_H */

/* arch-tag: 2596b649-b569-448e-8880-373d2a9909b7
   (do not change this comment) */

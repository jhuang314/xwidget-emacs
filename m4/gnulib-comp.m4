# DO NOT EDIT! GENERATED AUTOMATICALLY!
# Copyright (C) 2002-2013 Free Software Foundation, Inc.
#
# This file is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this file.  If not, see <http://www.gnu.org/licenses/>.
#
# As a special exception to the GNU General Public License,
# this file may be distributed as part of a program that
# contains a configuration script generated by Autoconf, under
# the same distribution terms as the rest of that program.
#
# Generated by gnulib-tool.
#
# This file represents the compiled summary of the specification in
# gnulib-cache.m4. It lists the computed macro invocations that need
# to be invoked from configure.ac.
# In projects that use version control, this file can be treated like
# other built files.


# This macro should be invoked from ./configure.ac, in the section
# "Checks for programs", right after AC_PROG_CC, and certainly before
# any checks for libraries, header files, types and library functions.
AC_DEFUN([gl_EARLY],
[
  m4_pattern_forbid([^gl_[A-Z]])dnl the gnulib macro namespace
  m4_pattern_allow([^gl_ES$])dnl a valid locale name
  m4_pattern_allow([^gl_LIBOBJS$])dnl a variable
  m4_pattern_allow([^gl_LTLIBOBJS$])dnl a variable
  AC_REQUIRE([gl_PROG_AR_RANLIB])
  # Code from module alloca-opt:
  # Code from module allocator:
  # Code from module at-internal:
  # Code from module binary-io:
  # Code from module c-ctype:
  # Code from module c-strcase:
  # Code from module careadlinkat:
  # Code from module clock-time:
  # Code from module close-stream:
  # Code from module crypto/md5:
  # Code from module crypto/sha1:
  # Code from module crypto/sha256:
  # Code from module crypto/sha512:
  # Code from module dirent:
  # Code from module dosname:
  # Code from module dtoastr:
  # Code from module dtotimespec:
  # Code from module dup2:
  # Code from module environ:
  # Code from module errno:
  # Code from module euidaccess:
  # Code from module execinfo:
  # Code from module extensions:
  AC_REQUIRE([gl_USE_SYSTEM_EXTENSIONS])
  # Code from module extern-inline:
  # Code from module faccessat:
  # Code from module fcntl:
  # Code from module fcntl-h:
  # Code from module fdatasync:
  # Code from module fdopendir:
  # Code from module filemode:
  # Code from module fpending:
  # Code from module fstatat:
  # Code from module fsync:
  # Code from module getdtablesize:
  # Code from module getgroups:
  # Code from module getloadavg:
  # Code from module getopt-gnu:
  # Code from module getopt-posix:
  # Code from module gettext-h:
  # Code from module gettime:
  # Code from module gettimeofday:
  # Code from module group-member:
  # Code from module include_next:
  # Code from module intprops:
  # Code from module inttypes-incomplete:
  # Code from module largefile:
  AC_REQUIRE([AC_SYS_LARGEFILE])
  # Code from module lstat:
  # Code from module manywarnings:
  # Code from module memrchr:
  # Code from module mkostemp:
  # Code from module mktime:
  # Code from module multiarch:
  # Code from module nocrash:
  # Code from module openat-h:
  # Code from module pathmax:
  # Code from module pipe2:
  # Code from module pselect:
  # Code from module pthread_sigmask:
  # Code from module putenv:
  # Code from module qacl:
  # Code from module readlink:
  # Code from module readlinkat:
  # Code from module root-uid:
  # Code from module secure_getenv:
  # Code from module sig2str:
  # Code from module signal-h:
  # Code from module snippet/_Noreturn:
  # Code from module snippet/arg-nonnull:
  # Code from module snippet/c++defs:
  # Code from module snippet/warn-on-use:
  # Code from module socklen:
  # Code from module ssize_t:
  # Code from module stat:
  # Code from module stat-time:
  # Code from module stdalign:
  # Code from module stdarg:
  dnl Some compilers (e.g., AIX 5.3 cc) need to be in c99 mode
  dnl for the builtin va_copy to work.  With Autoconf 2.60 or later,
  dnl gl_PROG_CC_C99 arranges for this.  With older Autoconf gl_PROG_CC_C99
  dnl shouldn't hurt, though installers are on their own to set c99 mode.
  gl_PROG_CC_C99
  # Code from module stdbool:
  # Code from module stddef:
  # Code from module stdint:
  # Code from module stdio:
  # Code from module stdlib:
  # Code from module strftime:
  # Code from module string:
  # Code from module strtoimax:
  # Code from module strtoll:
  # Code from module strtoull:
  # Code from module strtoumax:
  # Code from module symlink:
  # Code from module sys_select:
  # Code from module sys_stat:
  # Code from module sys_time:
  # Code from module tempname:
  # Code from module time:
  # Code from module time_r:
  # Code from module timer-time:
  # Code from module timespec:
  # Code from module timespec-add:
  # Code from module timespec-sub:
  # Code from module u64:
  # Code from module unistd:
  # Code from module unsetenv:
  # Code from module utimens:
  # Code from module verify:
  # Code from module warnings:
  # Code from module xalloc-oversized:
])

# This macro should be invoked from ./configure.ac, in the section
# "Check for header files, types and library functions".
AC_DEFUN([gl_INIT],
[
  AM_CONDITIONAL([GL_COND_LIBTOOL], [false])
  gl_cond_libtool=false
  gl_libdeps=
  gl_ltlibdeps=
  gl_m4_base='m4'
  m4_pushdef([AC_LIBOBJ], m4_defn([gl_LIBOBJ]))
  m4_pushdef([AC_REPLACE_FUNCS], m4_defn([gl_REPLACE_FUNCS]))
  m4_pushdef([AC_LIBSOURCES], m4_defn([gl_LIBSOURCES]))
  m4_pushdef([gl_LIBSOURCES_LIST], [])
  m4_pushdef([gl_LIBSOURCES_DIR], [])
  gl_COMMON
  gl_source_base='lib'
  gl_FUNC_ALLOCA
  AC_CHECK_FUNCS_ONCE([readlinkat])
  gl_CLOCK_TIME
  gl_CLOSE_STREAM
  gl_MODULE_INDICATOR([close-stream])
  gl_MD5
  gl_SHA1
  gl_SHA256
  gl_SHA512
  gl_DIRENT_H
  AC_REQUIRE([gl_C99_STRTOLD])
  gl_FUNC_DUP2
  if test $HAVE_DUP2 = 0 || test $REPLACE_DUP2 = 1; then
    AC_LIBOBJ([dup2])
    gl_PREREQ_DUP2
  fi
  gl_UNISTD_MODULE_INDICATOR([dup2])
  gl_ENVIRON
  gl_UNISTD_MODULE_INDICATOR([environ])
  gl_HEADER_ERRNO_H
  gl_EXECINFO_H
  AC_REQUIRE([gl_EXTERN_INLINE])
  gl_FUNC_FACCESSAT
  if test $HAVE_FACCESSAT = 0; then
    AC_LIBOBJ([faccessat])
    gl_PREREQ_FACCESSAT
  fi
  gl_MODULE_INDICATOR([faccessat])
  gl_UNISTD_MODULE_INDICATOR([faccessat])
  gl_FUNC_FCNTL
  if test $HAVE_FCNTL = 0 || test $REPLACE_FCNTL = 1; then
    AC_LIBOBJ([fcntl])
  fi
  gl_FCNTL_MODULE_INDICATOR([fcntl])
  gl_FCNTL_H
  gl_FUNC_FDATASYNC
  if test $HAVE_FDATASYNC = 0; then
    AC_LIBOBJ([fdatasync])
  fi
  gl_UNISTD_MODULE_INDICATOR([fdatasync])
  gl_FUNC_FDOPENDIR
  if test $HAVE_FDOPENDIR = 0 || test $REPLACE_FDOPENDIR = 1; then
    AC_LIBOBJ([fdopendir])
  fi
  gl_DIRENT_MODULE_INDICATOR([fdopendir])
  gl_MODULE_INDICATOR([fdopendir])
  gl_FILEMODE
  gl_FUNC_FPENDING
  if test $gl_cv_func___fpending = no; then
    AC_LIBOBJ([fpending])
    gl_PREREQ_FPENDING
  fi
  gl_FUNC_FSTATAT
  if test $HAVE_FSTATAT = 0 || test $REPLACE_FSTATAT = 1; then
    AC_LIBOBJ([fstatat])
  fi
  gl_SYS_STAT_MODULE_INDICATOR([fstatat])
  gl_FUNC_FSYNC
  if test $HAVE_FSYNC = 0; then
    AC_LIBOBJ([fsync])
    gl_PREREQ_FSYNC
  fi
  gl_UNISTD_MODULE_INDICATOR([fsync])
  gl_GETLOADAVG
  if test $HAVE_GETLOADAVG = 0; then
    AC_LIBOBJ([getloadavg])
    gl_PREREQ_GETLOADAVG
  fi
  gl_STDLIB_MODULE_INDICATOR([getloadavg])
  gl_FUNC_GETOPT_GNU
  if test $REPLACE_GETOPT = 1; then
    AC_LIBOBJ([getopt])
    AC_LIBOBJ([getopt1])
    gl_PREREQ_GETOPT
    dnl Arrange for unistd.h to include getopt.h.
    GNULIB_GL_UNISTD_H_GETOPT=1
  fi
  AC_SUBST([GNULIB_GL_UNISTD_H_GETOPT])
  gl_MODULE_INDICATOR_FOR_TESTS([getopt-gnu])
  gl_FUNC_GETOPT_POSIX
  if test $REPLACE_GETOPT = 1; then
    AC_LIBOBJ([getopt])
    AC_LIBOBJ([getopt1])
    gl_PREREQ_GETOPT
    dnl Arrange for unistd.h to include getopt.h.
    GNULIB_GL_UNISTD_H_GETOPT=1
  fi
  AC_SUBST([GNULIB_GL_UNISTD_H_GETOPT])
  gl_GETTIME
  gl_FUNC_GETTIMEOFDAY
  if test $HAVE_GETTIMEOFDAY = 0 || test $REPLACE_GETTIMEOFDAY = 1; then
    AC_LIBOBJ([gettimeofday])
    gl_PREREQ_GETTIMEOFDAY
  fi
  gl_SYS_TIME_MODULE_INDICATOR([gettimeofday])
  gl_INTTYPES_INCOMPLETE
  AC_REQUIRE([gl_LARGEFILE])
  gl_FUNC_LSTAT
  if test $REPLACE_LSTAT = 1; then
    AC_LIBOBJ([lstat])
    gl_PREREQ_LSTAT
  fi
  gl_SYS_STAT_MODULE_INDICATOR([lstat])
  gl_FUNC_MEMRCHR
  if test $ac_cv_func_memrchr = no; then
    AC_LIBOBJ([memrchr])
    gl_PREREQ_MEMRCHR
  fi
  gl_STRING_MODULE_INDICATOR([memrchr])
  gl_FUNC_MKOSTEMP
  if test $HAVE_MKOSTEMP = 0; then
    AC_LIBOBJ([mkostemp])
    gl_PREREQ_MKOSTEMP
  fi
  gl_MODULE_INDICATOR([mkostemp])
  gl_STDLIB_MODULE_INDICATOR([mkostemp])
  gl_FUNC_MKTIME
  if test $REPLACE_MKTIME = 1; then
    AC_LIBOBJ([mktime])
    gl_PREREQ_MKTIME
  fi
  gl_TIME_MODULE_INDICATOR([mktime])
  gl_MULTIARCH
  gl_FUNC_PIPE2
  gl_UNISTD_MODULE_INDICATOR([pipe2])
  gl_FUNC_PSELECT
  if test $HAVE_PSELECT = 0 || test $REPLACE_PSELECT = 1; then
    AC_LIBOBJ([pselect])
  fi
  gl_SYS_SELECT_MODULE_INDICATOR([pselect])
  gl_FUNC_PTHREAD_SIGMASK
  if test $HAVE_PTHREAD_SIGMASK = 0 || test $REPLACE_PTHREAD_SIGMASK = 1; then
    AC_LIBOBJ([pthread_sigmask])
    gl_PREREQ_PTHREAD_SIGMASK
  fi
  gl_SIGNAL_MODULE_INDICATOR([pthread_sigmask])
  gl_FUNC_PUTENV
  if test $REPLACE_PUTENV = 1; then
    AC_LIBOBJ([putenv])
    gl_PREREQ_PUTENV
  fi
  gl_STDLIB_MODULE_INDICATOR([putenv])
  gl_FUNC_ACL
  gl_FUNC_READLINK
  if test $HAVE_READLINK = 0 || test $REPLACE_READLINK = 1; then
    AC_LIBOBJ([readlink])
    gl_PREREQ_READLINK
  fi
  gl_UNISTD_MODULE_INDICATOR([readlink])
  gl_FUNC_READLINKAT
  if test $HAVE_READLINKAT = 0; then
    AC_LIBOBJ([readlinkat])
  fi
  gl_UNISTD_MODULE_INDICATOR([readlinkat])
  gl_FUNC_SIG2STR
  if test $ac_cv_func_sig2str = no; then
    AC_LIBOBJ([sig2str])
    gl_PREREQ_SIG2STR
  fi
  gl_SIGNAL_H
  gl_TYPE_SOCKLEN_T
  gt_TYPE_SSIZE_T
  gl_STAT_TIME
  gl_STAT_BIRTHTIME
  gl_STDALIGN_H
  gl_STDARG_H
  AM_STDBOOL_H
  gl_STDDEF_H
  gl_STDINT_H
  gl_STDIO_H
  gl_STDLIB_H
  gl_FUNC_GNU_STRFTIME
  gl_HEADER_STRING_H
  gl_FUNC_STRTOIMAX
  if test $HAVE_STRTOIMAX = 0 || test $REPLACE_STRTOIMAX = 1; then
    AC_LIBOBJ([strtoimax])
    gl_PREREQ_STRTOIMAX
  fi
  gl_INTTYPES_MODULE_INDICATOR([strtoimax])
  gl_FUNC_STRTOUMAX
  if test $ac_cv_func_strtoumax = no; then
    AC_LIBOBJ([strtoumax])
    gl_PREREQ_STRTOUMAX
  fi
  gl_INTTYPES_MODULE_INDICATOR([strtoumax])
  gl_FUNC_SYMLINK
  if test $HAVE_SYMLINK = 0 || test $REPLACE_SYMLINK = 1; then
    AC_LIBOBJ([symlink])
  fi
  gl_UNISTD_MODULE_INDICATOR([symlink])
  gl_HEADER_SYS_SELECT
  AC_PROG_MKDIR_P
  gl_HEADER_SYS_STAT_H
  AC_PROG_MKDIR_P
  gl_HEADER_SYS_TIME_H
  AC_PROG_MKDIR_P
  gl_HEADER_TIME_H
  gl_TIME_R
  if test $HAVE_LOCALTIME_R = 0 || test $REPLACE_LOCALTIME_R = 1; then
    AC_LIBOBJ([time_r])
    gl_PREREQ_TIME_R
  fi
  gl_TIME_MODULE_INDICATOR([time_r])
  gl_TIMER_TIME
  gl_TIMESPEC
  gl_UNISTD_H
  gl_FUNC_UNSETENV
  if test $HAVE_UNSETENV = 0 || test $REPLACE_UNSETENV = 1; then
    AC_LIBOBJ([unsetenv])
    gl_PREREQ_UNSETENV
  fi
  gl_STDLIB_MODULE_INDICATOR([unsetenv])
  gl_UTIMENS
  gl_gnulib_enabled_260941c0e5dc67ec9e87d1fb321c300b=false
  gl_gnulib_enabled_dosname=false
  gl_gnulib_enabled_euidaccess=false
  gl_gnulib_enabled_getdtablesize=false
  gl_gnulib_enabled_getgroups=false
  gl_gnulib_enabled_be453cec5eecf5731a274f2de7f2db36=false
  gl_gnulib_enabled_a9786850e999ae65a836a6041e8e5ed1=false
  gl_gnulib_enabled_03e0aaad4cb89ca757653bd367a6ccb7=false
  gl_gnulib_enabled_pathmax=false
  gl_gnulib_enabled_6099e9737f757db36c47fa9d9f02e88c=false
  gl_gnulib_enabled_secure_getenv=false
  gl_gnulib_enabled_stat=false
  gl_gnulib_enabled_strtoll=false
  gl_gnulib_enabled_strtoull=false
  gl_gnulib_enabled_tempname=false
  gl_gnulib_enabled_682e609604ccaac6be382e4ee3a4eaec=false
  func_gl_gnulib_m4code_260941c0e5dc67ec9e87d1fb321c300b ()
  {
    if ! $gl_gnulib_enabled_260941c0e5dc67ec9e87d1fb321c300b; then
      AC_LIBOBJ([openat-proc])
      gl_gnulib_enabled_260941c0e5dc67ec9e87d1fb321c300b=true
    fi
  }
  func_gl_gnulib_m4code_dosname ()
  {
    if ! $gl_gnulib_enabled_dosname; then
      gl_gnulib_enabled_dosname=true
    fi
  }
  func_gl_gnulib_m4code_euidaccess ()
  {
    if ! $gl_gnulib_enabled_euidaccess; then
      gl_FUNC_EUIDACCESS
      if test $HAVE_EUIDACCESS = 0; then
        AC_LIBOBJ([euidaccess])
        gl_PREREQ_EUIDACCESS
      fi
      gl_UNISTD_MODULE_INDICATOR([euidaccess])
      gl_gnulib_enabled_euidaccess=true
      if test $HAVE_EUIDACCESS = 0; then
        func_gl_gnulib_m4code_a9786850e999ae65a836a6041e8e5ed1
      fi
      func_gl_gnulib_m4code_6099e9737f757db36c47fa9d9f02e88c
      if test $HAVE_EUIDACCESS = 0; then
        func_gl_gnulib_m4code_stat
      fi
    fi
  }
  func_gl_gnulib_m4code_getdtablesize ()
  {
    if ! $gl_gnulib_enabled_getdtablesize; then
      gl_FUNC_GETDTABLESIZE
      if test $HAVE_GETDTABLESIZE = 0; then
        AC_LIBOBJ([getdtablesize])
        gl_PREREQ_GETDTABLESIZE
      fi
      gl_UNISTD_MODULE_INDICATOR([getdtablesize])
      gl_gnulib_enabled_getdtablesize=true
    fi
  }
  func_gl_gnulib_m4code_getgroups ()
  {
    if ! $gl_gnulib_enabled_getgroups; then
      gl_FUNC_GETGROUPS
      if test $HAVE_GETGROUPS = 0 || test $REPLACE_GETGROUPS = 1; then
        AC_LIBOBJ([getgroups])
      fi
      gl_UNISTD_MODULE_INDICATOR([getgroups])
      gl_gnulib_enabled_getgroups=true
    fi
  }
  func_gl_gnulib_m4code_be453cec5eecf5731a274f2de7f2db36 ()
  {
    if ! $gl_gnulib_enabled_be453cec5eecf5731a274f2de7f2db36; then
      AC_SUBST([LIBINTL])
      AC_SUBST([LTLIBINTL])
      gl_gnulib_enabled_be453cec5eecf5731a274f2de7f2db36=true
    fi
  }
  func_gl_gnulib_m4code_a9786850e999ae65a836a6041e8e5ed1 ()
  {
    if ! $gl_gnulib_enabled_a9786850e999ae65a836a6041e8e5ed1; then
      gl_FUNC_GROUP_MEMBER
      if test $HAVE_GROUP_MEMBER = 0; then
        AC_LIBOBJ([group-member])
        gl_PREREQ_GROUP_MEMBER
      fi
      gl_UNISTD_MODULE_INDICATOR([group-member])
      gl_gnulib_enabled_a9786850e999ae65a836a6041e8e5ed1=true
      if test $HAVE_GROUP_MEMBER = 0; then
        func_gl_gnulib_m4code_getgroups
      fi
      if test $HAVE_GROUP_MEMBER = 0; then
        func_gl_gnulib_m4code_682e609604ccaac6be382e4ee3a4eaec
      fi
    fi
  }
  func_gl_gnulib_m4code_03e0aaad4cb89ca757653bd367a6ccb7 ()
  {
    if ! $gl_gnulib_enabled_03e0aaad4cb89ca757653bd367a6ccb7; then
      gl_gnulib_enabled_03e0aaad4cb89ca757653bd367a6ccb7=true
    fi
  }
  func_gl_gnulib_m4code_pathmax ()
  {
    if ! $gl_gnulib_enabled_pathmax; then
      gl_PATHMAX
      gl_gnulib_enabled_pathmax=true
    fi
  }
  func_gl_gnulib_m4code_6099e9737f757db36c47fa9d9f02e88c ()
  {
    if ! $gl_gnulib_enabled_6099e9737f757db36c47fa9d9f02e88c; then
      gl_gnulib_enabled_6099e9737f757db36c47fa9d9f02e88c=true
    fi
  }
  func_gl_gnulib_m4code_secure_getenv ()
  {
    if ! $gl_gnulib_enabled_secure_getenv; then
      gl_FUNC_SECURE_GETENV
      if test $HAVE_SECURE_GETENV = 0; then
        AC_LIBOBJ([secure_getenv])
        gl_PREREQ_SECURE_GETENV
      fi
      gl_STDLIB_MODULE_INDICATOR([secure_getenv])
      gl_gnulib_enabled_secure_getenv=true
    fi
  }
  func_gl_gnulib_m4code_stat ()
  {
    if ! $gl_gnulib_enabled_stat; then
      gl_FUNC_STAT
      if test $REPLACE_STAT = 1; then
        AC_LIBOBJ([stat])
        gl_PREREQ_STAT
      fi
      gl_SYS_STAT_MODULE_INDICATOR([stat])
      gl_gnulib_enabled_stat=true
      if test $REPLACE_STAT = 1; then
        func_gl_gnulib_m4code_dosname
      fi
      if test $REPLACE_STAT = 1; then
        func_gl_gnulib_m4code_pathmax
      fi
    fi
  }
  func_gl_gnulib_m4code_strtoll ()
  {
    if ! $gl_gnulib_enabled_strtoll; then
      gl_FUNC_STRTOLL
      if test $HAVE_STRTOLL = 0; then
        AC_LIBOBJ([strtoll])
        gl_PREREQ_STRTOLL
      fi
      gl_STDLIB_MODULE_INDICATOR([strtoll])
      gl_gnulib_enabled_strtoll=true
    fi
  }
  func_gl_gnulib_m4code_strtoull ()
  {
    if ! $gl_gnulib_enabled_strtoull; then
      gl_FUNC_STRTOULL
      if test $HAVE_STRTOULL = 0; then
        AC_LIBOBJ([strtoull])
        gl_PREREQ_STRTOULL
      fi
      gl_STDLIB_MODULE_INDICATOR([strtoull])
      gl_gnulib_enabled_strtoull=true
    fi
  }
  func_gl_gnulib_m4code_tempname ()
  {
    if ! $gl_gnulib_enabled_tempname; then
      gl_FUNC_GEN_TEMPNAME
      gl_gnulib_enabled_tempname=true
      func_gl_gnulib_m4code_secure_getenv
    fi
  }
  func_gl_gnulib_m4code_682e609604ccaac6be382e4ee3a4eaec ()
  {
    if ! $gl_gnulib_enabled_682e609604ccaac6be382e4ee3a4eaec; then
      gl_gnulib_enabled_682e609604ccaac6be382e4ee3a4eaec=true
    fi
  }
  if test $HAVE_FACCESSAT = 0; then
    func_gl_gnulib_m4code_260941c0e5dc67ec9e87d1fb321c300b
  fi
  if test $HAVE_FACCESSAT = 0; then
    func_gl_gnulib_m4code_dosname
  fi
  if test $HAVE_FACCESSAT = 0; then
    func_gl_gnulib_m4code_euidaccess
  fi
  if test $HAVE_FACCESSAT = 0; then
    func_gl_gnulib_m4code_03e0aaad4cb89ca757653bd367a6ccb7
  fi
  if test $HAVE_FCNTL = 0 || test $REPLACE_FCNTL = 1; then
    func_gl_gnulib_m4code_getdtablesize
  fi
  if test $HAVE_FDOPENDIR = 0; then
    func_gl_gnulib_m4code_260941c0e5dc67ec9e87d1fb321c300b
  fi
  if test $HAVE_FSTATAT = 0 || test $REPLACE_FSTATAT = 1; then
    func_gl_gnulib_m4code_260941c0e5dc67ec9e87d1fb321c300b
  fi
  if test $HAVE_FSTATAT = 0 || test $REPLACE_FSTATAT = 1; then
    func_gl_gnulib_m4code_dosname
  fi
  if test $HAVE_FSTATAT = 0 || test $REPLACE_FSTATAT = 1; then
    func_gl_gnulib_m4code_03e0aaad4cb89ca757653bd367a6ccb7
  fi
  if test $REPLACE_GETOPT = 1; then
    func_gl_gnulib_m4code_be453cec5eecf5731a274f2de7f2db36
  fi
  if test $REPLACE_LSTAT = 1; then
    func_gl_gnulib_m4code_dosname
  fi
  if test $REPLACE_LSTAT = 1; then
    func_gl_gnulib_m4code_stat
  fi
  if test $HAVE_MKOSTEMP = 0; then
    func_gl_gnulib_m4code_tempname
  fi
  if test $HAVE_READLINK = 0 || test $REPLACE_READLINK = 1; then
    func_gl_gnulib_m4code_stat
  fi
  if test $HAVE_READLINKAT = 0; then
    func_gl_gnulib_m4code_260941c0e5dc67ec9e87d1fb321c300b
  fi
  if test $HAVE_READLINKAT = 0; then
    func_gl_gnulib_m4code_dosname
  fi
  if test $HAVE_READLINKAT = 0; then
    func_gl_gnulib_m4code_03e0aaad4cb89ca757653bd367a6ccb7
  fi
  if { test $HAVE_STRTOIMAX = 0 || test $REPLACE_STRTOIMAX = 1; } && test $ac_cv_type_long_long_int = yes; then
    func_gl_gnulib_m4code_strtoll
  fi
  if test $ac_cv_func_strtoumax = no && test $ac_cv_type_unsigned_long_long_int = yes; then
    func_gl_gnulib_m4code_strtoull
  fi
  m4_pattern_allow([^gl_GNULIB_ENABLED_])
  AM_CONDITIONAL([gl_GNULIB_ENABLED_260941c0e5dc67ec9e87d1fb321c300b], [$gl_gnulib_enabled_260941c0e5dc67ec9e87d1fb321c300b])
  AM_CONDITIONAL([gl_GNULIB_ENABLED_dosname], [$gl_gnulib_enabled_dosname])
  AM_CONDITIONAL([gl_GNULIB_ENABLED_euidaccess], [$gl_gnulib_enabled_euidaccess])
  AM_CONDITIONAL([gl_GNULIB_ENABLED_getdtablesize], [$gl_gnulib_enabled_getdtablesize])
  AM_CONDITIONAL([gl_GNULIB_ENABLED_getgroups], [$gl_gnulib_enabled_getgroups])
  AM_CONDITIONAL([gl_GNULIB_ENABLED_be453cec5eecf5731a274f2de7f2db36], [$gl_gnulib_enabled_be453cec5eecf5731a274f2de7f2db36])
  AM_CONDITIONAL([gl_GNULIB_ENABLED_a9786850e999ae65a836a6041e8e5ed1], [$gl_gnulib_enabled_a9786850e999ae65a836a6041e8e5ed1])
  AM_CONDITIONAL([gl_GNULIB_ENABLED_03e0aaad4cb89ca757653bd367a6ccb7], [$gl_gnulib_enabled_03e0aaad4cb89ca757653bd367a6ccb7])
  AM_CONDITIONAL([gl_GNULIB_ENABLED_pathmax], [$gl_gnulib_enabled_pathmax])
  AM_CONDITIONAL([gl_GNULIB_ENABLED_6099e9737f757db36c47fa9d9f02e88c], [$gl_gnulib_enabled_6099e9737f757db36c47fa9d9f02e88c])
  AM_CONDITIONAL([gl_GNULIB_ENABLED_secure_getenv], [$gl_gnulib_enabled_secure_getenv])
  AM_CONDITIONAL([gl_GNULIB_ENABLED_stat], [$gl_gnulib_enabled_stat])
  AM_CONDITIONAL([gl_GNULIB_ENABLED_strtoll], [$gl_gnulib_enabled_strtoll])
  AM_CONDITIONAL([gl_GNULIB_ENABLED_strtoull], [$gl_gnulib_enabled_strtoull])
  AM_CONDITIONAL([gl_GNULIB_ENABLED_tempname], [$gl_gnulib_enabled_tempname])
  AM_CONDITIONAL([gl_GNULIB_ENABLED_682e609604ccaac6be382e4ee3a4eaec], [$gl_gnulib_enabled_682e609604ccaac6be382e4ee3a4eaec])
  # End of code from modules
  m4_ifval(gl_LIBSOURCES_LIST, [
    m4_syscmd([test ! -d ]m4_defn([gl_LIBSOURCES_DIR])[ ||
      for gl_file in ]gl_LIBSOURCES_LIST[ ; do
        if test ! -r ]m4_defn([gl_LIBSOURCES_DIR])[/$gl_file ; then
          echo "missing file ]m4_defn([gl_LIBSOURCES_DIR])[/$gl_file" >&2
          exit 1
        fi
      done])dnl
      m4_if(m4_sysval, [0], [],
        [AC_FATAL([expected source file, required through AC_LIBSOURCES, not found])])
  ])
  m4_popdef([gl_LIBSOURCES_DIR])
  m4_popdef([gl_LIBSOURCES_LIST])
  m4_popdef([AC_LIBSOURCES])
  m4_popdef([AC_REPLACE_FUNCS])
  m4_popdef([AC_LIBOBJ])
  AC_CONFIG_COMMANDS_PRE([
    gl_libobjs=
    gl_ltlibobjs=
    if test -n "$gl_LIBOBJS"; then
      # Remove the extension.
      sed_drop_objext='s/\.o$//;s/\.obj$//'
      for i in `for i in $gl_LIBOBJS; do echo "$i"; done | sed -e "$sed_drop_objext" | sort | uniq`; do
        gl_libobjs="$gl_libobjs $i.$ac_objext"
        gl_ltlibobjs="$gl_ltlibobjs $i.lo"
      done
    fi
    AC_SUBST([gl_LIBOBJS], [$gl_libobjs])
    AC_SUBST([gl_LTLIBOBJS], [$gl_ltlibobjs])
  ])
  gltests_libdeps=
  gltests_ltlibdeps=
  m4_pushdef([AC_LIBOBJ], m4_defn([gltests_LIBOBJ]))
  m4_pushdef([AC_REPLACE_FUNCS], m4_defn([gltests_REPLACE_FUNCS]))
  m4_pushdef([AC_LIBSOURCES], m4_defn([gltests_LIBSOURCES]))
  m4_pushdef([gltests_LIBSOURCES_LIST], [])
  m4_pushdef([gltests_LIBSOURCES_DIR], [])
  gl_COMMON
  gl_source_base='tests'
changequote(,)dnl
  gltests_WITNESS=IN_`echo "${PACKAGE-$PACKAGE_TARNAME}" | LC_ALL=C tr abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ | LC_ALL=C sed -e 's/[^A-Z0-9_]/_/g'`_GNULIB_TESTS
changequote([, ])dnl
  AC_SUBST([gltests_WITNESS])
  gl_module_indicator_condition=$gltests_WITNESS
  m4_pushdef([gl_MODULE_INDICATOR_CONDITION], [$gl_module_indicator_condition])
  m4_pattern_allow([^gl_GNULIB_ENABLED_])
  m4_popdef([gl_MODULE_INDICATOR_CONDITION])
  m4_ifval(gltests_LIBSOURCES_LIST, [
    m4_syscmd([test ! -d ]m4_defn([gltests_LIBSOURCES_DIR])[ ||
      for gl_file in ]gltests_LIBSOURCES_LIST[ ; do
        if test ! -r ]m4_defn([gltests_LIBSOURCES_DIR])[/$gl_file ; then
          echo "missing file ]m4_defn([gltests_LIBSOURCES_DIR])[/$gl_file" >&2
          exit 1
        fi
      done])dnl
      m4_if(m4_sysval, [0], [],
        [AC_FATAL([expected source file, required through AC_LIBSOURCES, not found])])
  ])
  m4_popdef([gltests_LIBSOURCES_DIR])
  m4_popdef([gltests_LIBSOURCES_LIST])
  m4_popdef([AC_LIBSOURCES])
  m4_popdef([AC_REPLACE_FUNCS])
  m4_popdef([AC_LIBOBJ])
  AC_CONFIG_COMMANDS_PRE([
    gltests_libobjs=
    gltests_ltlibobjs=
    if test -n "$gltests_LIBOBJS"; then
      # Remove the extension.
      sed_drop_objext='s/\.o$//;s/\.obj$//'
      for i in `for i in $gltests_LIBOBJS; do echo "$i"; done | sed -e "$sed_drop_objext" | sort | uniq`; do
        gltests_libobjs="$gltests_libobjs $i.$ac_objext"
        gltests_ltlibobjs="$gltests_ltlibobjs $i.lo"
      done
    fi
    AC_SUBST([gltests_LIBOBJS], [$gltests_libobjs])
    AC_SUBST([gltests_LTLIBOBJS], [$gltests_ltlibobjs])
  ])
  LIBGNU_LIBDEPS="$gl_libdeps"
  AC_SUBST([LIBGNU_LIBDEPS])
  LIBGNU_LTLIBDEPS="$gl_ltlibdeps"
  AC_SUBST([LIBGNU_LTLIBDEPS])
])

# Like AC_LIBOBJ, except that the module name goes
# into gl_LIBOBJS instead of into LIBOBJS.
AC_DEFUN([gl_LIBOBJ], [
  AS_LITERAL_IF([$1], [gl_LIBSOURCES([$1.c])])dnl
  gl_LIBOBJS="$gl_LIBOBJS $1.$ac_objext"
])

# Like AC_REPLACE_FUNCS, except that the module name goes
# into gl_LIBOBJS instead of into LIBOBJS.
AC_DEFUN([gl_REPLACE_FUNCS], [
  m4_foreach_w([gl_NAME], [$1], [AC_LIBSOURCES(gl_NAME[.c])])dnl
  AC_CHECK_FUNCS([$1], , [gl_LIBOBJ($ac_func)])
])

# Like AC_LIBSOURCES, except the directory where the source file is
# expected is derived from the gnulib-tool parameterization,
# and alloca is special cased (for the alloca-opt module).
# We could also entirely rely on EXTRA_lib..._SOURCES.
AC_DEFUN([gl_LIBSOURCES], [
  m4_foreach([_gl_NAME], [$1], [
    m4_if(_gl_NAME, [alloca.c], [], [
      m4_define([gl_LIBSOURCES_DIR], [lib])
      m4_append([gl_LIBSOURCES_LIST], _gl_NAME, [ ])
    ])
  ])
])

# Like AC_LIBOBJ, except that the module name goes
# into gltests_LIBOBJS instead of into LIBOBJS.
AC_DEFUN([gltests_LIBOBJ], [
  AS_LITERAL_IF([$1], [gltests_LIBSOURCES([$1.c])])dnl
  gltests_LIBOBJS="$gltests_LIBOBJS $1.$ac_objext"
])

# Like AC_REPLACE_FUNCS, except that the module name goes
# into gltests_LIBOBJS instead of into LIBOBJS.
AC_DEFUN([gltests_REPLACE_FUNCS], [
  m4_foreach_w([gl_NAME], [$1], [AC_LIBSOURCES(gl_NAME[.c])])dnl
  AC_CHECK_FUNCS([$1], , [gltests_LIBOBJ($ac_func)])
])

# Like AC_LIBSOURCES, except the directory where the source file is
# expected is derived from the gnulib-tool parameterization,
# and alloca is special cased (for the alloca-opt module).
# We could also entirely rely on EXTRA_lib..._SOURCES.
AC_DEFUN([gltests_LIBSOURCES], [
  m4_foreach([_gl_NAME], [$1], [
    m4_if(_gl_NAME, [alloca.c], [], [
      m4_define([gltests_LIBSOURCES_DIR], [tests])
      m4_append([gltests_LIBSOURCES_LIST], _gl_NAME, [ ])
    ])
  ])
])

# This macro records the list of files which have been installed by
# gnulib-tool and may be removed by future gnulib-tool invocations.
AC_DEFUN([gl_FILE_LIST], [
  build-aux/snippet/_Noreturn.h
  build-aux/snippet/arg-nonnull.h
  build-aux/snippet/c++defs.h
  build-aux/snippet/warn-on-use.h
  lib/acl-errno-valid.c
  lib/acl-internal.h
  lib/acl.h
  lib/acl_entries.c
  lib/alloca.in.h
  lib/allocator.c
  lib/allocator.h
  lib/at-func.c
  lib/binary-io.c
  lib/binary-io.h
  lib/c-ctype.c
  lib/c-ctype.h
  lib/c-strcase.h
  lib/c-strcasecmp.c
  lib/c-strncasecmp.c
  lib/careadlinkat.c
  lib/careadlinkat.h
  lib/close-stream.c
  lib/close-stream.h
  lib/dirent.in.h
  lib/dosname.h
  lib/dtoastr.c
  lib/dtotimespec.c
  lib/dup2.c
  lib/errno.in.h
  lib/euidaccess.c
  lib/execinfo.c
  lib/execinfo.in.h
  lib/faccessat.c
  lib/fcntl.c
  lib/fcntl.in.h
  lib/fdatasync.c
  lib/fdopendir.c
  lib/file-has-acl.c
  lib/filemode.c
  lib/filemode.h
  lib/fpending.c
  lib/fpending.h
  lib/fstatat.c
  lib/fsync.c
  lib/ftoastr.c
  lib/ftoastr.h
  lib/getdtablesize.c
  lib/getgroups.c
  lib/getloadavg.c
  lib/getopt.c
  lib/getopt.in.h
  lib/getopt1.c
  lib/getopt_int.h
  lib/gettext.h
  lib/gettime.c
  lib/gettimeofday.c
  lib/group-member.c
  lib/intprops.h
  lib/inttypes.in.h
  lib/lstat.c
  lib/md5.c
  lib/md5.h
  lib/memrchr.c
  lib/mkostemp.c
  lib/mktime-internal.h
  lib/mktime.c
  lib/openat-priv.h
  lib/openat-proc.c
  lib/openat.h
  lib/pathmax.h
  lib/pipe2.c
  lib/pselect.c
  lib/pthread_sigmask.c
  lib/putenv.c
  lib/qcopy-acl.c
  lib/qset-acl.c
  lib/readlink.c
  lib/readlinkat.c
  lib/root-uid.h
  lib/secure_getenv.c
  lib/sha1.c
  lib/sha1.h
  lib/sha256.c
  lib/sha256.h
  lib/sha512.c
  lib/sha512.h
  lib/sig2str.c
  lib/sig2str.h
  lib/signal.in.h
  lib/stat-time.c
  lib/stat-time.h
  lib/stat.c
  lib/stdalign.in.h
  lib/stdarg.in.h
  lib/stdbool.in.h
  lib/stddef.in.h
  lib/stdint.in.h
  lib/stdio.in.h
  lib/stdlib.in.h
  lib/strftime.c
  lib/strftime.h
  lib/string.in.h
  lib/strtoimax.c
  lib/strtol.c
  lib/strtoll.c
  lib/strtoul.c
  lib/strtoull.c
  lib/strtoumax.c
  lib/symlink.c
  lib/sys_select.in.h
  lib/sys_stat.in.h
  lib/sys_time.in.h
  lib/tempname.c
  lib/tempname.h
  lib/time.in.h
  lib/time_r.c
  lib/timespec-add.c
  lib/timespec-sub.c
  lib/timespec.c
  lib/timespec.h
  lib/u64.c
  lib/u64.h
  lib/unistd.c
  lib/unistd.in.h
  lib/unsetenv.c
  lib/utimens.c
  lib/utimens.h
  lib/verify.h
  lib/xalloc-oversized.h
  m4/00gnulib.m4
  m4/acl.m4
  m4/alloca.m4
  m4/c-strtod.m4
  m4/clock_time.m4
  m4/close-stream.m4
  m4/dirent_h.m4
  m4/dup2.m4
  m4/environ.m4
  m4/errno_h.m4
  m4/euidaccess.m4
  m4/execinfo.m4
  m4/extensions.m4
  m4/extern-inline.m4
  m4/faccessat.m4
  m4/fcntl-o.m4
  m4/fcntl.m4
  m4/fcntl_h.m4
  m4/fdatasync.m4
  m4/fdopendir.m4
  m4/filemode.m4
  m4/fpending.m4
  m4/fstatat.m4
  m4/fsync.m4
  m4/getdtablesize.m4
  m4/getgroups.m4
  m4/getloadavg.m4
  m4/getopt.m4
  m4/gettime.m4
  m4/gettimeofday.m4
  m4/gnulib-common.m4
  m4/group-member.m4
  m4/include_next.m4
  m4/inttypes.m4
  m4/largefile.m4
  m4/longlong.m4
  m4/lstat.m4
  m4/manywarnings.m4
  m4/md5.m4
  m4/memrchr.m4
  m4/mkostemp.m4
  m4/mktime.m4
  m4/multiarch.m4
  m4/nocrash.m4
  m4/off_t.m4
  m4/pathmax.m4
  m4/pipe2.m4
  m4/pselect.m4
  m4/pthread_sigmask.m4
  m4/putenv.m4
  m4/readlink.m4
  m4/readlinkat.m4
  m4/secure_getenv.m4
  m4/setenv.m4
  m4/sha1.m4
  m4/sha256.m4
  m4/sha512.m4
  m4/sig2str.m4
  m4/signal_h.m4
  m4/socklen.m4
  m4/ssize_t.m4
  m4/st_dm_mode.m4
  m4/stat-time.m4
  m4/stat.m4
  m4/stdalign.m4
  m4/stdarg.m4
  m4/stdbool.m4
  m4/stddef_h.m4
  m4/stdint.m4
  m4/stdio_h.m4
  m4/stdlib_h.m4
  m4/strftime.m4
  m4/string_h.m4
  m4/strtoimax.m4
  m4/strtoll.m4
  m4/strtoull.m4
  m4/strtoumax.m4
  m4/symlink.m4
  m4/sys_select_h.m4
  m4/sys_socket_h.m4
  m4/sys_stat_h.m4
  m4/sys_time_h.m4
  m4/tempname.m4
  m4/time_h.m4
  m4/time_r.m4
  m4/timer_time.m4
  m4/timespec.m4
  m4/tm_gmtoff.m4
  m4/unistd_h.m4
  m4/utimbuf.m4
  m4/utimens.m4
  m4/utimes.m4
  m4/warn-on-use.m4
  m4/warnings.m4
  m4/wchar_t.m4
])

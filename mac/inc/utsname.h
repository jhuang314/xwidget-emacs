/* Replacement utsname.h file for building GNU Emacs on the Macintosh.
   Copyright (C) 2000, 2001, 2002, 2003, 2004, 2005,
      2006, 2007  Free Software Foundation, Inc.

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
along with GNU Emacs; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301, USA.  */

/* Contributed by Andrew Choi (akochoi@mac.com).  */

#ifndef	_UTSNAME_H
#define	_UTSNAME_H

struct utsname {
  char nodename[255];
};

int uname(struct utsname *name);

#endif

/* arch-tag: 8a013744-4d43-4084-8e2f-d3fb66c83160
   (do not change this comment) */

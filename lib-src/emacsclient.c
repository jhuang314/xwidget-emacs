/* Client process that communicates with GNU Emacs acting as server.
   Copyright (C) 1986, 1987, 1994, 1999, 2000, 2001
   Free Software Foundation, Inc.

This file is part of GNU Emacs.

GNU Emacs is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

GNU Emacs is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.  */


#define NO_SHORTNAMES

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#undef signal

#include <ctype.h>
#include <stdio.h>
#include <getopt.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#ifdef VMS
# include "vms-pwd.h"
#else
# include <pwd.h>
#endif /* not VMS */

char *getenv (), *getwd ();
char *getcwd ();

/* This is defined with -D from the compilation command,
   which extracts it from ../lisp/version.el.  */

#ifndef VERSION
#define VERSION "unspecified"
#endif

/* Name used to invoke this program.  */
char *progname;

/* Nonzero means don't wait for a response from Emacs.  --no-wait.  */
int nowait = 0;

/* Nonzero means args are expressions to be evaluated.  --eval.  */
int eval = 0;

/* The display on which Emacs should work.  --display.  */
char *display = NULL;

/* If non-NULL, the name of an editor to fallback to if the server
   is not running.  --alternate-editor.   */
const char * alternate_editor = NULL;

void print_help_and_exit ();

struct option longopts[] =
{
  { "no-wait",	no_argument,	   NULL, 'n' },
  { "eval",	no_argument,	   NULL, 'e' },
  { "help",	no_argument,	   NULL, 'H' },
  { "version",	no_argument,	   NULL, 'V' },
  { "alternate-editor", required_argument, NULL, 'a' },
  { "display",	required_argument, NULL, 'd' },
  { 0, 0, 0, 0 }
};

/* Decode the options from argv and argc.
   The global variable `optind' will say how many arguments we used up.  */

void
decode_options (argc, argv)
     int argc;
     char **argv;
{
  while (1)
    {
      int opt = getopt_long (argc, argv,
			     "VHnea:d:", longopts, 0);

      if (opt == EOF)
	break;

      alternate_editor = getenv ("ALTERNATE_EDITOR");

      switch (opt)
	{
	case 0:
	  /* If getopt returns 0, then it has already processed a
	     long-named option.  We should do nothing.  */
	  break;

	case 'a':
	  alternate_editor = optarg;
	  break;

	case 'd':
	  display = optarg;
	  break;

	case 'n':
	  nowait = 1;
	  break;

	case 'e':
	  eval = 1;
	  break;

	case 'V':
	  fprintf (stderr, "emacsclient %s\n", VERSION);
	  exit (1);
	  break;

	case 'H':
	default:
	  print_help_and_exit ();
	}
    }
}

void
print_help_and_exit ()
{
  fprintf (stderr,
	   "Usage: %s [OPTIONS] FILE...\n\
Tell the Emacs server to visit the specified files.\n\
Every FILE can be either just a FILENAME or [+LINE[:COLUMN]] FILENAME.\n\
The following OPTIONS are accepted:\n\
-V, --version           Just print a version info and return\n\
-H, --help              Print this usage information message\n\
-n, --no-wait           Don't wait for the server to return\n\
-e, --eval              Evaluate the FILE arguments as ELisp expressions\n\
-d, --display=DISPLAY   Visit the file in the given display\n\
-a, --alternate-editor=EDITOR\n\
                        Editor to fallback to if the server is not running\n\
Report bugs to bug-gnu-emacs@gnu.org.\n", progname);
  exit (1);
}

/* Return a copy of NAME, inserting a &
   before each &, each space, each newline, and any initial -.
   Change spaces to underscores, too, so that the
   return value never contains a space.  */

char *
quote_file_name (name)
     char *name;
{
  char *copy = (char *) malloc (strlen (name) * 2 + 1);
  char *p, *q;

  p = name;
  q = copy;
  while (*p)
    {
      if (*p == ' ')
	{
	  *q++ = '&';
	  *q++ = '_';
	  p++;
	}
      else if (*p == '\n')
	{
	  *q++ = '&';
	  *q++ = 'n';
	  p++;
	}
      else
	{
	  if (*p == '&' || (*p == '-' && p == name))
	    *q++ = '&';
	  *q++ = *p++;
	}
    }
  *q++ = 0;

  return copy;
}

/* Like malloc but get fatal error if memory is exhausted.  */

long *
xmalloc (size)
     unsigned int size;
{
  long *result = (long *) malloc (size);
  if (result == NULL)
  {
    perror ("malloc");
    exit (1);
  }
  return result;
}

/*
  Try to run a different command, or --if no alternate editor is
  defined-- exit with an errorcode.
*/
void
fail (argc, argv)
     int argc;
     char **argv;
{
  if (alternate_editor)
    {
      int i = optind - 1;
      execvp (alternate_editor, argv + i);
      return;
    }
  else
    {
      exit (1);
    }
}



#if !defined (HAVE_SOCKETS) || defined (NO_SOCKETS_IN_FILE_SYSTEM)

int
main (argc, argv)
     int argc;
     char **argv;
{
  fprintf (stderr, "%s: Sorry, the Emacs server is supported only\n",
	   argv[0]);
  fprintf (stderr, "on systems with Berkeley sockets.\n");

  fail (argc, argv);
}

#else /* HAVE_SOCKETS */

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <errno.h>

extern char *strerror ();
extern int errno;

/* Three possibilities:
   2 - can't be `stat'ed		(sets errno)
   1 - isn't owned by us
   0 - success: none of the above */

static int
socket_status (socket_name)
     char *socket_name;
{
  struct stat statbfr;

  if (stat (socket_name, &statbfr) == -1)
    return 2;

  if (statbfr.st_uid != geteuid ())
    return 1;

  return 0;
}

int
main (argc, argv)
     int argc;
     char **argv;
{
  char *system_name;
  int system_name_length;
  int s, i, needlf = 0;
  FILE *out, *in;
  struct sockaddr_un server;
  char *cwd, *str;
  char string[BUFSIZ];

  progname = argv[0];

  /* Process options.  */
  decode_options (argc, argv);

  if (argc - optind < 1)
    print_help_and_exit ();

  /*
   * Open up an AF_UNIX socket in this person's home directory
   */

  if ((s = socket (AF_UNIX, SOCK_STREAM, 0)) < 0)
    {
      fprintf (stderr, "%s: ", argv[0]);
      perror ("socket");
      fail (argc, argv);
    }

  server.sun_family = AF_UNIX;

  {
    char *dot;
    system_name_length = 32;

    while (1)
      {
	system_name = (char *) xmalloc (system_name_length + 1);

	/* system_name must be null-terminated string.  */
	system_name[system_name_length] = '\0';

 	if (gethostname (system_name, system_name_length) == 0)
	  break;

	free (system_name);
	system_name_length *= 2;
      }

    /* We always use the non-dotted host name, for simplicity.  */
    dot = index (system_name, '.');
    if (dot)
      *dot = '\0';
  }

  {
    int sock_status = 0;

    sprintf (server.sun_path, "/tmp/esrv%d-%s", (int) geteuid (), system_name);

    /* See if the socket exists, and if it's owned by us. */
    sock_status = socket_status (server.sun_path);
    if (sock_status)
      {
	/* Failing that, see if LOGNAME or USER exist and differ from
	   our euid.  If so, look for a socket based on the UID
	   associated with the name.  This is reminiscent of the logic
	   that init_editfns uses to set the global Vuser_full_name.  */

	char *user_name = (char *) getenv ("LOGNAME");
	if (!user_name)
	  user_name = (char *) getenv ("USER");

	if (user_name)
	  {
	    struct passwd *pw = getpwnam (user_name);
	    if (pw && (pw->pw_uid != geteuid ()))
	      {
		/* We're running under su, apparently. */
		sprintf (server.sun_path, "/tmp/esrv%d-%s",
			 (int) pw->pw_uid, system_name);
		sock_status = socket_status (server.sun_path);
	      }
	  }
      }

     switch (sock_status)
       {
       case 1:
	 /* There's a socket, but it isn't owned by us.  This is OK if
	    we are root. */
	 if (0 != geteuid ())
	   {
	     fprintf (stderr, "%s: Invalid socket owner\n", argv[0]);
	     fail (argc, argv);
	   }
	 break;

       case 2:
	 /* `stat' failed */
	 if (errno == ENOENT)
	   fprintf (stderr,
		    "%s: can't find socket; have you started the server?\n",
		    argv[0]);
	 else
	   fprintf (stderr, "%s: can't stat %s: %s\n",
		    argv[0], server.sun_path, strerror (errno));
	 fail (argc, argv);
	 break;
       }
  }

  if (connect (s, (struct sockaddr *) &server, strlen (server.sun_path) + 2)
      < 0)
    {
      fprintf (stderr, "%s: ", argv[0]);
      perror ("connect");
      fail (argc, argv);
    }

  /* We use the stream OUT to send our command to the server.  */
  if ((out = fdopen (s, "r+")) == NULL)
    {
      fprintf (stderr, "%s: ", argv[0]);
      perror ("fdopen");
      fail (argc, argv);
    }

  /* We use the stream IN to read the response.
     We used to use just one stream for both output and input
     on the socket, but reversing direction works nonportably:
     on some systems, the output appears as the first input;
     on other systems it does not.  */
  if ((in = fdopen (s, "r+")) == NULL)
    {
      fprintf (stderr, "%s: ", argv[0]);
      perror ("fdopen");
      fail (argc, argv);
    }

#ifdef BSD_SYSTEM
  cwd = getwd (string);
#else
  cwd = getcwd (string, sizeof string);
#endif
  if (cwd == 0)
    {
      /* getwd puts message in STRING if it fails.  */
      fprintf (stderr, "%s: %s (%s)\n", argv[0],
#ifdef BSD_SYSTEM
	       string,
#else
	       "Cannot get current working directory",
#endif
	       strerror (errno));
      fail (argc, argv);
    }

  if (nowait)
    fprintf (out, "-nowait ");

  if (eval)
    fprintf (out, "-eval ");

  if (display)
    fprintf (out, "-display %s ", quote_file_name (display));

  for (i = optind; i < argc; i++)
    {
      if (eval)
	; /* Don't prepend any cwd or anything like that.  */
      else if (*argv[i] == '+')
	{
	  char *p = argv[i] + 1;
	  while (isdigit ((unsigned char) *p) || *p == ':') p++;
	  if (*p != 0)
	    fprintf (out, "%s/", quote_file_name (cwd));
	}
      else if (*argv[i] != '/')
	fprintf (out, "%s/", quote_file_name (cwd));

      fprintf (out, "%s ", quote_file_name (argv[i]));
    }
  fprintf (out, "\n");
  fflush (out);

  /* Maybe wait for an answer.   */
  if (nowait)
    return 0;

  if (!eval)
    {
      printf ("Waiting for Emacs...");
      needlf = 2;
    }
  fflush (stdout);

  /* Now, wait for an answer and print any messages.  */
  while ((str = fgets (string, BUFSIZ, in)))
    {
      if (needlf == 2)
	printf ("\n");
      printf ("%s", str);
      needlf = str[0] == '\0' ? needlf : str[strlen (str) - 1] != '\n';
    }

  if (needlf)
    printf ("\n");
  fflush (stdout);

  return 0;
}

#endif /* HAVE_SOCKETS */

#ifndef HAVE_STRERROR
char *
strerror (errnum)
     int errnum;
{
  extern char *sys_errlist[];
  extern int sys_nerr;

  if (errnum >= 0 && errnum < sys_nerr)
    return sys_errlist[errnum];
  return (char *) "Unknown error";
}

#endif /* ! HAVE_STRERROR */

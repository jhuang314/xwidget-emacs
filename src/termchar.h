/* Flags and parameters describing terminal's characteristics.
   Copyright (C) 1985, 1986, 2003 Free Software Foundation, Inc.

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

/* Each termcap frame points to its own struct tty_output object in the
   output_data.tty field.  The tty_output structure contains the information
   that is specific to terminals. */
struct tty_output
{
  char *name;                   /* The name of the device file or 0 if
                                   stdin/stdout. */
  char *type;                   /* The type of the tty. */
  
  /* Input/output */
  
  FILE *input;                  /* The stream to be used for terminal input. */
  FILE *output;                 /* The stream to be used for terminal output. */
  
  FILE *termscript;             /* If nonzero, send all terminal output
                                   characters to this stream also.  */

  struct emacs_tty *old_tty;    /* The initial tty mode bits */

  int term_initted;             /* 1 if we have been through init_sys_modes. */


  /* Structure for info on cursor positioning.  */

  struct cm *Wcm;

  /* Redisplay. */

  /* XXX GC does not know about this; is this a problem? */
  Lisp_Object top_frame;        /* The topmost frame on this tty. */
  
  /* The previous terminal frame we displayed on this tty.  */
  struct frame *previous_terminal_frame;

  /* Pixel values.
     XXX What are these used for? */
  
  unsigned long background_pixel;
  unsigned long foreground_pixel;

  /* Terminal characteristics. */
  
  int must_write_spaces;	/* Nonzero means spaces in the text must
				   actually be output; can't just skip over
				   some columns to leave them blank.  */
  int fast_clear_end_of_line;   /* Nonzero means terminal has a `ce' string */
  
  int line_ins_del_ok;          /* Terminal can insert and delete lines */
  int char_ins_del_ok;          /* Terminal can insert and delete chars */
  int scroll_region_ok;         /* Terminal supports setting the scroll
                                   window */
  int scroll_region_cost;	/* Cost of setting the scroll window,
                                   measured in characters. */
  int memory_below_frame;	/* Terminal remembers lines scrolled
                                   off bottom */

#if 0  /* These are not used anywhere. */
  /* EMACS_INT baud_rate; */	/* Output speed in baud */
  int min_padding_speed;	/* Speed below which no padding necessary. */
  int dont_calculate_costs;     /* Nonzero means don't bother computing
                                   various cost tables; we won't use them. */
#endif

  /* Strings, numbers and flags taken from the termcap entry.  */

  char *TS_ins_line;		/* "al" */
  char *TS_ins_multi_lines;	/* "AL" (one parameter, # lines to insert) */
  char *TS_bell;                /* "bl" */
  char *TS_clr_to_bottom;       /* "cd" */
  char *TS_clr_line;		/* "ce", clear to end of line */
  char *TS_clr_frame;		/* "cl" */
  char *TS_set_scroll_region;	/* "cs" (2 params, first line and last line) */
  char *TS_set_scroll_region_1; /* "cS" (4 params: total lines,
                                   lines above scroll region, lines below it,
                                   total lines again) */
  char *TS_del_char;		/* "dc" */
  char *TS_del_multi_chars;	/* "DC" (one parameter, # chars to delete) */
  char *TS_del_line;		/* "dl" */
  char *TS_del_multi_lines;	/* "DL" (one parameter, # lines to delete) */
  char *TS_delete_mode;		/* "dm", enter character-delete mode */
  char *TS_end_delete_mode;	/* "ed", leave character-delete mode */
  char *TS_end_insert_mode;	/* "ei", leave character-insert mode */
  char *TS_ins_char;		/* "ic" */
  char *TS_ins_multi_chars;	/* "IC" (one parameter, # chars to insert) */
  char *TS_insert_mode;		/* "im", enter character-insert mode */
  char *TS_pad_inserted_char;	/* "ip".  Just padding, no commands.  */
  char *TS_end_keypad_mode;	/* "ke" */
  char *TS_keypad_mode;		/* "ks" */
  char *TS_pad_char;		/* "pc", char to use as padding */
  char *TS_repeat;		/* "rp" (2 params, # times to repeat
				   and character to be repeated) */
  char *TS_end_standout_mode;	/* "se" */
  char *TS_fwd_scroll;		/* "sf" */
  char *TS_standout_mode;       /* "so" */
  char *TS_rev_scroll;          /* "sr" */
  char *TS_end_termcap_modes;   /* "te" */
  char *TS_termcap_modes;       /* "ti" */
  char *TS_visible_bell;        /* "vb" */
  char *TS_cursor_normal;       /* "ve" */
  char *TS_cursor_visible;      /* "vs" */
  char *TS_cursor_invisible;    /* "vi" */
  char *TS_set_window;          /* "wi" (4 params, start and end of window,
                                   each as vpos and hpos) */

  char *TS_enter_bold_mode;     /* "md" -- turn on bold (extra bright mode).  */
  char *TS_enter_dim_mode;      /* "mh" -- turn on half-bright mode.  */
  char *TS_enter_blink_mode;    /* "mb" -- enter blinking mode.  */
  char *TS_enter_reverse_mode;  /* "mr" -- enter reverse video mode.  */
  char *TS_exit_underline_mode; /* "us" -- start underlining.  */
  char *TS_enter_underline_mode; /* "ue" -- end underlining.  */

  /* "as"/"ae" -- start/end alternate character set.  Not really
     supported, yet.  */
  char *TS_enter_alt_charset_mode;
  char *TS_exit_alt_charset_mode;

  char *TS_exit_attribute_mode; /* "me" -- switch appearances off.  */

  /* Value of the "NC" (no_color_video) capability, or 0 if not present.  */
  int TN_no_color_video;

  int TN_max_colors;            /* "Co" -- number of colors.  */

  /* "pa" -- max. number of color pairs on screen.  Not handled yet.
     Could be a problem if not equal to TN_max_colors * TN_max_colors.  */
  int TN_max_pairs;

  /* "op" -- SVr4 set default pair to its original value.  */
  char *TS_orig_pair;

  /* "AF"/"AB" or "Sf"/"Sb"-- set ANSI or SVr4 foreground/background color.
     1 param, the color index.  */
  char *TS_set_foreground;
  char *TS_set_background;

  int TF_hazeltine;             /* termcap hz flag. */
  int TF_insmode_motion;        /* termcap mi flag: can move while in insert mode. */
  int TF_standout_motion;       /* termcap mi flag: can move while in standout mode. */
  int TF_underscore;            /* termcap ul flag: _ underlines if over-struck on
                                   non-blank position.  Must clear before writing _.  */
  int TF_teleray;               /* termcap xt flag: many weird consequences.
                                   For t1061. */

  int RPov;                     /* # chars to start a TS_repeat */

  int delete_in_insert_mode;    /* delete mode == insert mode */
  
  int se_is_so;                 /* 1 if same string both enters and leaves
                                   standout mode */
  
  int costs_set;                /* Nonzero if costs have been calculated. */
  
  int insert_mode;              /* Nonzero when in insert mode.  */
  int standout_mode;            /* Nonzero when in standout mode.  */



  /* 1 if should obey 0200 bit in input chars as "Meta", 2 if should
     keep 0200 bit in input chars.  0 to ignore the 0200 bit.  */

  int meta_key;

  /* Size of window specified by higher levels.
   This is the number of lines, from the top of frame downwards,
   which can participate in insert-line/delete-line operations.

   Effectively it excludes the bottom frame_lines - specified_window_size
   lines from those operations.  */

  int specified_window;
  
  /* Flag used in tty_show/hide_cursor.  */

  int cursor_hidden;


  struct tty_output *next;
};

extern struct tty_output *tty_list;


#define FRAME_TTY(f) \
  ((f)->output_method == output_termcap \
   ? (f)->output_data.tty : (abort(), (struct tty_output *) 0))
  
#define CURTTY() FRAME_TTY (SELECTED_FRAME())

#define TTY_NAME(t) ((t)->name)
#define TTY_TYPE(t) ((t)->type)

#define TTY_INPUT(t) ((t)->input)
#define TTY_OUTPUT(t) ((t)->output)
#define TTY_TERMSCRIPT(t) ((t)->termscript)

#define TTY_MUST_WRITE_SPACES(t) ((t)->must_write_spaces)
#define TTY_FAST_CLEAR_END_OF_LINE(t) ((t)->fast_clear_end_of_line)
#define TTY_LINE_INS_DEL_OK(t) ((t)->line_ins_del_ok)
#define TTY_CHAR_INS_DEL_OK(t) ((t)->char_ins_del_ok)
#define TTY_SCROLL_REGION_OK(t) ((t)->scroll_region_ok)
#define TTY_SCROLL_REGION_COST(t) ((t)->scroll_region_cost)
#define TTY_MEMORY_BELOW_FRAME(t) ((t)->memory_below_frame)

#if 0
/* These are not used anywhere. */
#define TTY_MIN_PADDING_SPEED(t) ((t)->min_padding_speed)
#define TTY_DONT_CALCULATE_COSTS(t) ((t)->dont_calculate_costs)
#endif

/* arch-tag: bf9f0d49-842b-42fb-9348-ec8759b27193
   (do not change this comment) */

;;; window.el --- GNU Emacs window commands aside from those written in C.

;; Copyright (C) 1985, 1989, 1992, 1993, 1994, 2000
;;  Free Software Foundation, Inc.

;; Maintainer: FSF

;; This file is part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Code:

;;;; Window tree functions.

(defun one-window-p (&optional nomini all-frames)
  "Returns non-nil if the selected window is the only window (in its frame).
Optional arg NOMINI non-nil means don't count the minibuffer
even if it is active.

The optional arg ALL-FRAMES t means count windows on all frames.
If it is `visible', count windows on all visible frames.
ALL-FRAMES nil or omitted means count only the selected frame, 
plus the minibuffer it uses (which may be on another frame).
If ALL-FRAMES is neither nil nor t, count only the selected frame."
  (let ((base-window (selected-window)))
    (if (and nomini (eq base-window (minibuffer-window)))
	(setq base-window (next-window base-window)))
    (eq base-window
	(next-window base-window (if nomini 'arg) all-frames))))

(defun walk-windows (proc &optional minibuf all-frames)
  "Cycle through all visible windows, calling PROC for each one.
PROC is called with a window as argument.

Optional second arg MINIBUF t means count the minibuffer window even
if not active.  MINIBUF nil or omitted means count the minibuffer iff
it is active.  MINIBUF neither t nor nil means not to count the
minibuffer even if it is active.

Several frames may share a single minibuffer; if the minibuffer
counts, all windows on all frames that share that minibuffer count
too.  Therefore, if you are using a separate minibuffer frame
and the minibuffer is active and MINIBUF says it counts,
`walk-windows' includes the windows in the frame from which you
entered the minibuffer, as well as the minibuffer window.

ALL-FRAMES is the optional third argument.
ALL-FRAMES nil or omitted means cycle within the frames as specified above.
ALL-FRAMES = `visible' means include windows on all visible frames.
ALL-FRAMES = 0 means include windows on all visible and iconified frames.
ALL-FRAMES = t means include windows on all frames including invisible frames.
If ALL-FRAMES is a frame, it means include windows on that frame.
Anything else means restrict to the selected frame."
  ;; If we start from the minibuffer window, don't fail to come back to it.
  (if (window-minibuffer-p (selected-window))
      (setq minibuf t))
  (save-selected-window
    (if (framep all-frames)
	(select-window (frame-first-window all-frames)))
    (let* (walk-windows-already-seen
	   (walk-windows-current (selected-window)))
      (while (progn
	       (setq walk-windows-current
		     (next-window walk-windows-current minibuf all-frames))
	       (not (memq walk-windows-current walk-windows-already-seen)))
	(setq walk-windows-already-seen
	      (cons walk-windows-current walk-windows-already-seen))
	(funcall proc walk-windows-current)))))

(defun some-window (predicate &optional minibuf all-frames default)
  "Return a window satisfying PREDICATE.

This function cycles through all visible windows using `walk-windows',
calling PREDICATE on each one.  PREDICATE is called with a window as
argument.  The first window for which PREDICATE returns a non-nil
value is returned.  If no window satisfies PREDICATE, DEFAULT is
returned.

Optional second arg MINIBUF t means count the minibuffer window even
if not active.  MINIBUF nil or omitted means count the minibuffer iff
it is active.  MINIBUF neither t nor nil means not to count the
minibuffer even if it is active.

Several frames may share a single minibuffer; if the minibuffer
counts, all windows on all frames that share that minibuffer count
too.  Therefore, if you are using a separate minibuffer frame
and the minibuffer is active and MINIBUF says it counts,
`walk-windows' includes the windows in the frame from which you
entered the minibuffer, as well as the minibuffer window.

ALL-FRAMES is the optional third argument.
ALL-FRAMES nil or omitted means cycle within the frames as specified above.
ALL-FRAMES = `visible' means include windows on all visible frames.
ALL-FRAMES = 0 means include windows on all visible and iconified frames.
ALL-FRAMES = t means include windows on all frames including invisible frames.
If ALL-FRAMES is a frame, it means include windows on that frame.
Anything else means restrict to the selected frame."
  (catch 'found
    (walk-windows #'(lambda (window) 
		      (when (funcall predicate window)
			(throw 'found window)))
		  minibuf all-frames)
    default))

(defun minibuffer-window-active-p (window)
  "Return t if WINDOW (a minibuffer window) is now active."
  (eq window (active-minibuffer-window)))

(defmacro save-selected-window (&rest body)
  "Execute BODY, then select the window that was selected before BODY."
  (list 'let
	'((save-selected-window-window (selected-window)))
	(list 'unwind-protect
	      (cons 'progn body)
	      (list 'select-window 'save-selected-window-window)))) 

(defun count-windows (&optional minibuf)
   "Returns the number of visible windows.
This counts the windows in the selected frame and (if the minibuffer is
to be counted) its minibuffer frame (if that's not the same frame).
The optional arg MINIBUF non-nil means count the minibuffer
even if it is inactive."
   (let ((count 0))
     (walk-windows (function (lambda (w)
			       (setq count (+ count 1))))
		   minibuf)
     count))

(defun balance-windows ()
  "Makes all visible windows the same height (approximately)."
  (interactive)
  (let ((count -1) levels newsizes size
	;; Don't count the lines that are above the uppermost windows.
	;; (These are the menu bar lines, if any.)
	(mbl (nth 1 (window-edges (frame-first-window (selected-frame))))))
    ;; Find all the different vpos's at which windows start,
    ;; then count them.  But ignore levels that differ by only 1.
    (save-window-excursion
      (let (tops (prev-top -2))
	(walk-windows (function (lambda (w)
				  (setq tops (cons (nth 1 (window-edges w))
						   tops))))
		      'nomini)
	(setq tops (sort tops '<))
	(while tops
	  (if (> (car tops) (1+ prev-top))
	      (setq prev-top (car tops)
		    count (1+ count)))
	  (setq levels (cons (cons (car tops) count) levels))
	  (setq tops (cdr tops)))
	(setq count (1+ count))))
    ;; Subdivide the frame into that many vertical levels.
    (setq size (/ (- (frame-height) mbl) count))
    (walk-windows (function
		   (lambda (w)
		     (select-window w)
		     (let ((newtop (cdr (assq (nth 1 (window-edges))
					      levels)))
			   (newbot (or (cdr (assq (+ (window-height)
						     (nth 1 (window-edges)))
						  levels))
				       count)))
		       (setq newsizes
			     (cons (cons w (* size (- newbot newtop)))
				   newsizes)))))
		  'nomini)
    (walk-windows (function (lambda (w)
			      (select-window w)
			      (let ((newsize (cdr (assq w newsizes))))
				(enlarge-window (- newsize
						   (window-height))))))
		  'nomini)))

;;; I think this should be the default; I think people will prefer it--rms.
(defcustom split-window-keep-point t
  "*If non-nil, split windows keeps the original point in both children.
This is often more convenient for editing.
If nil, adjust point in each of the two windows to minimize redisplay.
This is convenient on slow terminals, but point can move strangely."
  :type 'boolean
  :group 'windows)

(defun split-window-vertically (&optional arg)
  "Split current window into two windows, one above the other.
The uppermost window gets ARG lines and the other gets the rest.
Negative arg means select the size of the lowermost window instead.
With no argument, split equally or close to it.
Both windows display the same buffer now current.

If the variable `split-window-keep-point' is non-nil, both new windows
will get the same value of point as the current window.  This is often
more convenient for editing.

Otherwise, we chose window starts so as to minimize the amount of
redisplay; this is convenient on slow terminals.  The new selected
window is the one that the current value of point appears in.  The
value of point can change if the text around point is hidden by the
new mode line."
  (interactive "P")
  (let ((old-w (selected-window))
	(old-point (point))
	(size (and arg (prefix-numeric-value arg)))
        (window-full-p nil)
	new-w bottom switch moved)
    (and size (< size 0) (setq size (+ (window-height) size)))
    (setq new-w (split-window nil size))
    (or split-window-keep-point
	(progn
	  (save-excursion
	    (set-buffer (window-buffer))
	    (goto-char (window-start))
            (setq moved (vertical-motion (window-height)))
	    (set-window-start new-w (point))
	    (if (> (point) (window-point new-w))
		(set-window-point new-w (point)))
            (and (= moved (window-height))
                 (progn
                   (setq window-full-p t)
                   (vertical-motion -1)))
            (setq bottom (point)))
          (and window-full-p
               (<= bottom (point))
               (set-window-point old-w (1- bottom)))
	  (and window-full-p
               (<= (window-start new-w) old-point)
               (progn
                 (set-window-point new-w old-point)
                 (select-window new-w)))))
    (split-window-save-restore-data new-w old-w)))

;; This is to avoid compiler warnings.
(defvar view-return-to-alist)

(defun split-window-save-restore-data (new-w old-w)
  (save-excursion
    (set-buffer (window-buffer))
    (if view-mode
	(let ((old-info (assq old-w view-return-to-alist)))
	  (setq view-return-to-alist
		(cons (cons new-w (cons (and old-info (car (cdr old-info))) t))
		      view-return-to-alist))))
    new-w))

(defun split-window-horizontally (&optional arg)
  "Split current window into two windows side by side.
This window becomes the leftmost of the two, and gets ARG columns.
Negative arg means select the size of the rightmost window instead.
The argument includes the width of the window's scroll bar; if there
are no scroll bars, it includes the width of the divider column
to the window's right, if any.  No arg means split equally."
  (interactive "P")
  (let ((old-w (selected-window))
	(size (and arg (prefix-numeric-value arg))))
    (and size (< size 0)
	 (setq size (+ (window-width) size)))
    (split-window-save-restore-data (split-window nil size t) old-w)))

(defcustom mode-line-window-height-fudge nil
  "*Fudge factor returned by `mode-line-window-height-fudge' on graphic displays.
If non-nil, it should be the number of lines to add to the sizes of
windows to compensate for the extra height of the mode-line, so it
doesn't't obscure the last line of text.

If nil, an attempt is made to calculate reasonable value.

This is a kluge."
  :type '(choice (const :tag "Guess" nil)
		 (integer :tag "Extra lines" :value 1))
  :group 'windows)

;; List of face attributes that might change a face's height
(defconst height-affecting-face-attributes
  '(:family :height :box :font :inherit))

(defsubst mode-line-window-height-fudge (&optional face)
  "Return a fudge factor to compensate for the extra height of graphic mode-lines.
On a non-graphic display, return 0.

FACE is the face used to display the mode-line; it defaults to `mode-line'.

If the variable `mode-line-window-height-fudge' has a non-nil value, it
is returned.  Otherwise, the `mode-line' face is checked to see if it
contains any attributes that might affect its height; if it does, 1 is
returned, otherwise 0.

\[Because mode-lines on a graphics capable display may have a height
larger than a normal text line, a window who's size is calculated to
exactly show some text, including 1 line for the mode-line, may be
displayed with the last text line obscured by the mode-line.

To work-around this problem, call `mode-line-window-height-fudge', and
add the return value to the requested window size.]

This is a kluge."
  (if (display-graphic-p)
      (or
       ;; Return user-specified value
       mode-line-window-height-fudge
       ;; Try and detect whether mode-line face has any attributes that
       ;; could make it bigger than a default text line, and return a
       ;; fudge factor of 1 if so.
       (let ((attrs height-affecting-face-attributes)
	     (fudge 0))
	 (while attrs
	   (let ((val (face-attribute (or face 'mode-line) (pop attrs))))
	     (unless (or (null val) (eq val 'unspecified))
	       (setq fudge 1 attrs nil))))
	 fudge))
    0))


;;; These functions should eventually be replaced with versions that
;;; really do the job (instead of using the kludgey mode-line face
;;; hacking junk).

(defun window-text-height (&optional window)
  "Return the height in lines of the text display area of WINDOW.
This doesn't include the mode-line (or header-line if any) or any
partial-height lines in the text display area.

Note that the current implementation of this function may sometimes
return an inaccurate value, but attempts to be conservative, by
returning fewer lines than actually exist in the case where the real
value cannot be determined."
  (with-current-buffer (window-buffer window)
    (- (window-height window)
       (if (and (not (window-minibuffer-p window))
		mode-line-format)
	   (1+ (mode-line-window-height-fudge))
	 0)
       (if header-line-format
	   (1+ (mode-line-window-height-fudge 'header-line))
	 0))))

(defun set-window-text-height (window height)
  "Sets the height in lines of the text display area of WINDOW to HEIGHT.
This doesn't include the mode-line (or header-line if any) or any
partial-height lines in the text display area.

If WINDOW is nil, the selected window is used.

Note that the current implementation of this function cannot always set
the height exactly, but attempts to be conservative, by allocating more
lines than are actually needed in the case where some error may be present."
  (let ((delta (- height (window-text-height window))))
    (unless (zerop delta)
      (let ((window-min-height 1))
	(if (and window (not (eq window (selected-window))))
	    (save-selected-window
	      (select-window window)
	      (enlarge-window delta))
	  (enlarge-window delta))))))


(defun enlarge-window-horizontally (arg)
  "Make current window ARG columns wider."
  (interactive "p")
  (enlarge-window arg t))

(defun shrink-window-horizontally (arg)
  "Make current window ARG columns narrower."
  (interactive "p")
  (shrink-window arg t))

(defun window-buffer-height (window)
  "Return the height (in screen lines) of the buffer that WINDOW is displaying."
  (save-excursion
    (set-buffer (window-buffer window))
    (goto-char (point-min))
    (let ((ignore-final-newline
           ;; If buffer ends with a newline, ignore it when counting height
           ;; unless point is after it.
           (and (not (eobp)) (eq ?\n (char-after (1- (point-max)))))))
      (+ 1 (nth 2 (compute-motion (point-min)
                                  '(0 . 0)
                                  (- (point-max) (if ignore-final-newline 1 0))
                                  (cons 0 100000000)
                                  (window-width window)
                                  nil
                                  window))))))

(defun count-screen-lines (&optional beg end count-final-newline window)
  "Return the number of screen lines in the region.
The number of screen lines may be different from the number of actual lines,
due to line breaking, display table, etc.

Optional arguments BEG and END default to `point-min' and `point-max'
respectively.

If region ends with a newline, ignore it unless optinal third argument
COUNT-FINAL-NEWLINE is non-nil.

The optional fourth argument WINDOW specifies the window used for obtaining
parameters such as width, horizontal scrolling, and so on. The default is
to use the selected window's parameters.

Like `vertical-motion', `count-screen-lines' always uses the current buffer,
regardless of which buffer is displayed in WINDOW. This makes possible to use
`count-screen-lines' in any buffer, whether or not it is currently displayed
in some window."
  (unless beg
    (setq beg (point-min)))
  (unless end
    (setq end (point-max)))
  (if (= beg end)
      0
    (save-excursion
      (save-restriction
        (widen)
        (narrow-to-region (min beg end)
                          (if (and (not count-final-newline)
                                   (= ?\n (char-before (max beg end))))
                              (1- (max beg end))
                            (max beg end)))
        (goto-char (point-min))
        (1+ (vertical-motion (buffer-size) window))))))

(defun fit-window-to-buffer (&optional window max-height min-height)
  "Make WINDOW the right size to display its contents exactly.
If the optional argument MAX-HEIGHT is supplied, it is the maximum height
  the window is allowed to be, defaulting to the frame height.
If the optional argument MIN-HEIGHT is supplied, it is the minimum
  height the window is allowed to be, defaulting to `window-min-height'.

The heights in MAX-HEIGHT and MIN-HEIGHT include the mode-line and/or
header-line."
  (interactive)

  (when (null window)
    (setq window (selected-window)))
  (when (null max-height)
    (setq max-height (frame-height (window-frame window))))

  (let* ((window-height
	  ;; The current height of WINDOW
	  (window-height window))
	 (extra
	  ;; The amount by which the text height differs from the window
	  ;; height.
	  (- window-height (window-text-height window)))
	 (text-height
	  ;; The height necessary to show the buffer displayed by WINDOW
	  ;; (`count-screen-lines' always works on the current buffer).
	  (with-current-buffer (window-buffer window)
	    (count-screen-lines)))
	 (delta
	  ;; Calculate how much the window height has to change to show
	  ;; text-height lines, constrained by MIN-HEIGHT and MAX-HEIGHT.
	  (- (max (min (+ text-height extra) max-height)
		  (or min-height window-min-height))
	     window-height))
	 ;; We do our own height checking, so avoid any restrictions due to
	 ;; window-min-height.
	 (window-min-height 1))

    ;; Don't try to redisplay with the cursor at the end
    ;; on its own line--that would force a scroll and spoil things.
    (when (and (eobp) (bolp) (not (bobp)))
      (forward-char -1))

    (unless (zerop delta)
      (if (eq window (selected-window))
	  (enlarge-window delta)
	(save-selected-window
	  (select-window window)
	  (enlarge-window delta))))))

(defun shrink-window-if-larger-than-buffer (&optional window)
  "Shrink the WINDOW to be as small as possible to display its contents.
Do not shrink to less than `window-min-height' lines.
Do nothing if the buffer contains more lines than the present window height,
or if some of the window's contents are scrolled out of view,
or if the window is not the full width of the frame,
or if the window is the only window of its frame."
  (interactive)
  (when (null window)
    (setq window (selected-window)))
  (let* ((frame (window-frame window))
	 (mini (frame-parameter frame 'minibuffer))
	 (edges (window-edges window)))
    (if (and (not (eq window (frame-root-window frame)))
	     (= (window-width) (frame-width))
	     (pos-visible-in-window-p (point-min) window)
	     (not (eq mini 'only))
	     (or (not mini)
		 (< (nth 3 edges) (nth 1 (window-edges mini)))
		 (> (nth 1 edges) (frame-parameter frame 'menu-bar-lines))))
	(fit-window-to-buffer window (window-height window)))))

(defun kill-buffer-and-window ()
  "Kill the current buffer and delete the selected window."
  (interactive)
  (if (yes-or-no-p (format "Kill buffer `%s'? " (buffer-name)))
      (let ((buffer (current-buffer)))
	(delete-window (selected-window))
	(kill-buffer buffer))
    (error "Aborted")))

(defun quit-window (&optional kill window)
  "Quit the current buffer.  Bury it, and maybe delete the selected frame.
\(The frame is deleted if it is contains a dedicated window for the buffer.)
With a prefix argument, kill the buffer instead.

Noninteractively, if KILL is non-nil, then kill the current buffer,
otherwise bury it.

If WINDOW is non-nil, it specifies a window; we delete that window,
and the buffer that is killed or buried is the one in that window."
  (interactive "P")
  (let ((buffer (window-buffer window))
	(frame (window-frame (or window (selected-window))))
	(window-solitary
	 (save-selected-window
	   (if window
	       (select-window window))
	   (one-window-p t)))
	window-handled)

    (save-selected-window
      (if window
	  (select-window window))
      (or (window-minibuffer-p)
	  (window-dedicated-p (selected-window))
	  (switch-to-buffer (other-buffer))))

    ;; Get rid of the frame, if it has just one dedicated window
    ;; and other visible frames exist.
    (and (or (window-minibuffer-p) (window-dedicated-p window))
	 (delq frame (visible-frame-list))
	 window-solitary
	 (if (and (eq default-minibuffer-frame frame)
		  (= 1 (length (minibuffer-frame-list))))
	     (setq window nil)
	   (delete-frame frame)
	   (setq window-handled t)))

    ;; Deal with the buffer.
    (if kill
	(kill-buffer buffer)
      (bury-buffer buffer))

    ;; Maybe get rid of the window.
    (and window (not window-handled) (not window-solitary)
	 (delete-window window))))

(define-key ctl-x-map "2" 'split-window-vertically)
(define-key ctl-x-map "3" 'split-window-horizontally)
(define-key ctl-x-map "}" 'enlarge-window-horizontally)
(define-key ctl-x-map "{" 'shrink-window-horizontally)
(define-key ctl-x-map "-" 'shrink-window-if-larger-than-buffer)
(define-key ctl-x-map "+" 'balance-windows)
(define-key ctl-x-4-map "0" 'kill-buffer-and-window)

;;; windows.el ends here

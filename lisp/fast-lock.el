;;; fast-lock.el --- Automagic text properties caching for fast Font Lock mode.

;; Copyright (C) 1994, 1995, 1996, 1997 Free Software Foundation, Inc.

;; Author: Simon Marshall <simon@gnu.ai.mit.edu>
;; Keywords: faces files
;; Version: 3.12.03

;;; This file is part of GNU Emacs.

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

;;; Commentary:

;; Lazy Lock mode is a Font Lock support mode.
;; It makes visiting a file in Font Lock mode faster by restoring its face text
;; properties from automatically saved associated Font Lock cache files.
;;
;; See caveats and feedback below.
;; See also the lazy-lock package.  (But don't use the two at the same time!)

;; Installation:
;; 
;; Put in your ~/.emacs:
;;
;; (setq font-lock-support-mode 'fast-lock-mode)
;;
;; Start up a new Emacs and use font-lock as usual (except that you can use the
;; so-called "gaudier" fontification regexps on big files without frustration).
;;
;; When you visit a file (which has `font-lock-mode' enabled) that has a
;; corresponding Font Lock cache file associated with it, the Font Lock cache
;; will be loaded from that file instead of being generated by Font Lock code.

;; Caveats:
;;
;; A cache will be saved when visiting a compressed file using crypt++, but not
;; be read.  This is a "feature"/"consequence"/"bug" of crypt++.
;;
;; Version control packages are likely to stamp all over file modification
;; times.  Therefore the act of checking out may invalidate a cache.

;; History:
;;
;; 0.02--1.00:
;; - Changed name from turbo-prop to fast-lock.  Automagic for font-lock only
;; - Made `fast-lock-mode' a minor mode, like G. Dinesh Dutt's fss-mode
;; 1.00--1.01:
;; - Turn on `fast-lock-mode' only if `buffer-file-name' or `interactive-p'
;; - Made `fast-lock-file-name' use `buffer-name' if `buffer-file-name' is nil
;; - Moved save-all conditions to `fast-lock-save-cache'
;; - Added `fast-lock-save-text-properties' to `kill-buffer-hook'
;; 1.01--2.00: complete rewrite---not worth the space to document
;; - Changed structure of text properties cache and threw out file mod checks
;; 2.00--2.01:
;; - Made `condition-case' forms understand `quit'. 
;; - Made `fast-lock' require `font-lock'
;; - Made `fast-lock-cache-name' chase links (from Ben Liblit)
;; 2.01--3.00:
;; - Changed structure of cache to include `font-lock-keywords' (from rms)
;; - Changed `fast-lock-cache-mechanisms' to `fast-lock-cache-directories'
;; - Removed `fast-lock-read-others'
;; - Made `fast-lock-read-cache' ignore cache owner
;; - Made `fast-lock-save-cache-external' create cache directory
;; - Made `fast-lock-save-cache-external' save `font-lock-keywords'
;; - Made `fast-lock-cache-data' check `font-lock-keywords'
;; 3.00--3.01: incorporated port of 2.00 to Lucid, made by Barry Warsaw
;; - Package now provides itself
;; - Lucid: Use `font-lock-any-extents-p' for `font-lock-any-properties-p'
;; - Lucid: Use `list-faces' for `face-list'
;; - Lucid: Added `set-text-properties'
;; - Lucid: Made `turn-on-fast-lock' pass 1 not t to `fast-lock-mode'
;; - Removed test for `fast-lock-mode' from `fast-lock-read-cache'
;; - Lucid: Added Lucid-specific `fast-lock-get-face-properties'
;; 3.01--3.02: now works with Lucid Emacs, thanks to Barry Warsaw
;; - Made `fast-lock-cache-name' map ":" to ";" for OS/2 (from Serganova Vera)
;; - Made `fast-lock-cache-name' use abbreviated file name (from Barry Warsaw)
;; - Lucid: Separated handlers for `error' and `quit' for `condition-case'
;; 3.02--3.03:
;; - Changed `fast-lock-save-cache-external' to `fast-lock-save-cache-data'
;; - Lucid: Added Lucid-specific `fast-lock-set-face-properties'
;; 3.03--3.04:
;; - Corrected `subrp' test of Lucid code
;; - Replaced `font-lock-any-properties-p' with `text-property-not-all'
;; - Lucid: Made `fast-lock-set-face-properties' put `text-prop' on extents
;; - Made `fast-lock-cache-directories' a regexp alist (from Colin Rafferty)
;; - Made `fast-lock-cache-directory' to return a usable cache file directory
;; 3.04--3.05:
;; - Lucid: Fix for XEmacs 19.11 `text-property-not-all'
;; - Replaced `subrp' test of Lucid code with `emacs-version' `string-match'
;; - Made `byte-compile-warnings' omit `unresolved' on compilation
;; - Made `fast-lock-save-cache-data' use a buffer (from Rick Sladkey)
;; - Reverted to old `fast-lock-get-face-properties' (from Rick Sladkey)
;; 3.05--3.06: incorporated hack of 3.03, made by Jonathan Stigelman (Stig)
;; - Reverted to 3.04 version of `fast-lock-get-face-properties'
;; - XEmacs: Removed `list-faces' `defalias'
;; - Made `fast-lock-mode' and `turn-on-fast-lock' succeed `autoload' cookies
;; - Added `fast-lock-submit-bug-report'
;; - Renamed `fast-lock-save-size' to `fast-lock-minimum-size'
;; - Made `fast-lock-save-cache' output a message if no save ever attempted
;; - Made `fast-lock-save-cache-data' output a message if save attempted
;; - Made `fast-lock-cache-data' output a message if load attempted
;; - Made `fast-lock-save-cache-data' do `condition-case' not `unwind-protect'
;; - Made `fast-lock-save-cache' and `fast-lock-read-cache' return nothing
;; - Made `fast-lock-save-cache' check `buffer-modified-p' (Stig)
;; - Added `fast-lock-save-events'
;; - Added `fast-lock-after-save-hook' to `after-save-hook' (Stig)
;; - Added `fast-lock-kill-buffer-hook' to `kill-buffer-hook'
;; - Changed `fast-lock-save-caches' to `fast-lock-kill-emacs-hook'
;; - Added `fast-lock-kill-emacs-hook' to `kill-emacs-hook'
;; - Made `fast-lock-save-cache' check `verify-visited-file-modtime' (Stig)
;; - Made `visited-file-modtime' be the basis of the timestamp (Stig)
;; - Made `fast-lock-save-cache-1' and `fast-lock-cache-data' use/reformat it
;; - Added `fast-lock-cache-filename' to keep track of the cache file name
;; - Added `fast-lock-after-fontify-buffer'
;; - Added `fast-lock-save-faces' list of faces to save (idea from Stig/Tibor)
;; - Made `fast-lock-get-face-properties' functions use it
;; - XEmacs: Made `fast-lock-set-face-properties' do extents the Font Lock way
;; - XEmacs: Removed fix for `text-property-not-all' (19.11 support dropped)
;; - Made `fast-lock-mode' ensure `font-lock-mode' is on
;; - Made `fast-lock-save-cache' do `cdr-safe' not `cdr' (from Dave Foster)
;; - Made `fast-lock-save-cache' do `set-buffer' first (from Dave Foster)
;; - Made `fast-lock-save-cache' loop until saved or quit (from Georg Nikodym)
;; - Made `fast-lock-cache-data' check `buffer-modified-p'
;; - Made `fast-lock-cache-data' do `font-lock-compile-keywords' if necessary
;; - XEmacs: Made `font-lock-compile-keywords' `defalias'
;; 3.06--3.07:
;; - XEmacs: Add `fast-lock-after-fontify-buffer' to the Font Lock hook
;; - Made `fast-lock-cache-name' explain the use of `directory-abbrev-alist'
;; - Made `fast-lock-mode' use `buffer-file-truename' not `buffer-file-name'
;; 3.07--3.08:
;; - Made `fast-lock-read-cache' set `fast-lock-cache-filename'
;; 3.08--3.09:
;; - Made `fast-lock-save-cache' cope if `fast-lock-minimum-size' is an a list
;; - Made `fast-lock-mode' respect the value of `font-lock-inhibit-thing-lock'
;; - Added `fast-lock-after-unfontify-buffer'
;; 3.09--3.10:
;; - Rewrite for Common Lisp macros
;; - Made fast-lock.el barf on a crap 8+3 pseudo-OS (Eli Zaretskii help)
;; - XEmacs: Made `add-minor-mode' succeed `autoload' cookie
;; - XEmacs: Made `fast-lock-save-faces' default to `font-lock-face-list'
;; - Made `fast-lock-save-cache' use `font-lock-value-in-major-mode'
;; - Wrap with `save-buffer-state' (Ray Van Tassle report)
;; - Made `fast-lock-mode' wrap `font-lock-support-mode'
;; 3.10--3.11:
;; - Made `fast-lock-get-face-properties' cope with face lists
;; - Added `fast-lock-verbose'
;; - XEmacs: Add `font-lock-value-in-major-mode' if necessary
;; - Removed `fast-lock-submit-bug-report' and bade farewell
;; 3.11--3.12:
;; - Added Custom support (Hrvoje Niksic help)
;; - Made `save-buffer-state' wrap `inhibit-point-motion-hooks'
;; - Made `fast-lock-cache-data' simplify calls of `font-lock-compile-keywords'
;; 3.12--3.13:
;; - Removed `byte-*' variables from `eval-when-compile' (Erik Naggum hint)
;; - Changed structure of cache to include `font-lock-syntactic-keywords'
;; - Made `fast-lock-save-cache-1' save syntactic fontification data
;; - Made `fast-lock-cache-data' take syntactic fontification data
;; - Added `fast-lock-get-syntactic-properties'
;; - Renamed `fast-lock-set-face-properties' to `fast-lock-add-properties'
;; - Made `fast-lock-add-properties' add syntactic and face fontification data

;;; Code:

(require 'font-lock)

;; Make sure fast-lock.el is supported.
(if (and (eq system-type 'ms-dos) (not (msdos-long-file-names)))
    (error "`fast-lock' was written for long file name systems"))

(eval-when-compile
  ;;
  ;; We don't do this at the top-level as we only use non-autoloaded macros.
  (require 'cl)
  ;;
  ;; We use this to preserve or protect things when modifying text properties.
  (defmacro save-buffer-state (varlist &rest body)
    "Bind variables according to VARLIST and eval BODY restoring buffer state."
    (` (let* ((,@ (append varlist
		   '((modified (buffer-modified-p)) (buffer-undo-list t)
		     (inhibit-read-only t) (inhibit-point-motion-hooks t)
		     before-change-functions after-change-functions
		     deactivate-mark buffer-file-name buffer-file-truename))))
	 (,@ body)
	 (when (and (not modified) (buffer-modified-p))
	   (set-buffer-modified-p nil)))))
  (put 'save-buffer-state 'lisp-indent-function 1)
  ;;
  ;; We use this to verify that a face should be saved.
  (defmacro fast-lock-save-facep (face)
    "Return non-nil if FACE is one of `fast-lock-save-faces'."
    (` (or (null fast-lock-save-faces)
	   (if (symbolp (, face))
	       (memq (, face) fast-lock-save-faces)
	     (let ((faces (, face)))
	       (while (unless (memq (car faces) fast-lock-save-faces)
			(setq faces (cdr faces))))
	       faces)))))
  ;;
  ;; We use this for compatibility with a future Emacs.
  (or (fboundp 'defcustom)
      (defmacro defcustom (symbol value doc &rest args) 
	(` (defvar (, symbol) (, value) (, doc))))))

;(defun fast-lock-submit-bug-report ()
;  "Submit via mail a bug report on fast-lock.el."
;  (interactive)
;  (let ((reporter-prompt-for-summary-p t))
;    (reporter-submit-bug-report "simon@gnu.ai.mit.edu" "fast-lock 3.12.03"
;     '(fast-lock-cache-directories fast-lock-minimum-size
;       fast-lock-save-others fast-lock-save-events fast-lock-save-faces
;       fast-lock-verbose)
;     nil nil
;     (concat "Hi Si.,
;
;I want to report a bug.  I've read the `Bugs' section of `Info' on Emacs, so I
;know how to make a clear and unambiguous report.  To reproduce the bug:
;
;Start a fresh editor via `" invocation-name " -no-init-file -no-site-file'.
;In the `*scratch*' buffer, evaluate:"))))

(defvar fast-lock-mode nil)		; Whether we are turned on.
(defvar fast-lock-cache-timestamp nil)	; For saving/reading.
(defvar fast-lock-cache-filename nil)	; For deleting.

;; User Variables:

(defcustom fast-lock-minimum-size (* 25 1024)
  "*Minimum size of a buffer for cached fontification.
Only buffers more than this can have associated Font Lock cache files saved.
If nil, means cache files are never created.
If a list, each element should be a cons pair of the form (MAJOR-MODE . SIZE),
where MAJOR-MODE is a symbol or t (meaning the default).  For example:
 ((c-mode . 25600) (c++-mode . 25600) (rmail-mode . 1048576))
means that the minimum size is 25K for buffers in C or C++ modes, one megabyte
for buffers in Rmail mode, and size is irrelevant otherwise."
  :type '(choice (const :tag "none" nil)
		 (integer :tag "size")
		 (repeat :menu-tag "mode specific" :tag "mode specific"
			 :value ((t . nil))
			 (cons :tag "Instance"
			       (radio :tag "Mode"
				      (const :tag "all" t)
				      (symbol :tag "name"))
			       (radio :tag "Size"
				      (const :tag "none" nil)
				      (integer :tag "size")))))
  :group 'fast-lock)

(defcustom fast-lock-cache-directories '("." "~/.emacs-flc")
; - `internal', keep each file's Font Lock cache file in the same file.
; - `external', keep each file's Font Lock cache file in the same directory.
  "*Directories in which Font Lock cache files are saved and read.
Each item should be either DIR or a cons pair of the form (REGEXP . DIR) where
DIR is a directory name (relative or absolute) and REGEXP is a regexp.

An attempt will be made to save or read Font Lock cache files using these items
until one succeeds (i.e., until a readable or writable one is found).  If an
item contains REGEXP, DIR is used only if the buffer file name matches REGEXP.
For example:

 (let ((home (expand-file-name (abbreviate-file-name (file-truename \"~/\")))))
   (list (cons (concat \"^\" (regexp-quote home)) \".\") \"~/.emacs-flc\"))
    =>
 ((\"^/your/true/home/directory/\" . \".\") \"~/.emacs-flc\")

would cause a file's current directory to be used if the file is under your
home directory hierarchy, or otherwise the absolute directory `~/.emacs-flc'."
  :type '(repeat (radio (directory :tag "directory")
			(cons :tag "Matching"
			      (regexp :tag "regexp")
			      (directory :tag "directory"))))
  :group 'fast-lock)

(defcustom fast-lock-save-events '(kill-buffer kill-emacs)
  "*Events under which caches will be saved.
Valid events are `save-buffer', `kill-buffer' and `kill-emacs'.
If concurrent editing sessions use the same associated cache file for a file's
buffer, then you should add `save-buffer' to this list."
  :type '(set (const :tag "buffer saving" save-buffer)
	      (const :tag "buffer killing" kill-buffer)
	      (const :tag "emacs killing" kill-emacs))
  :group 'fast-lock)

(defcustom fast-lock-save-others t
  "*If non-nil, save Font Lock cache files irrespective of file owner.
If nil, means only buffer files known to be owned by you can have associated
Font Lock cache files saved.  Ownership may be unknown for networked files."
  :type 'boolean
  :group 'fast-lock)

(defcustom fast-lock-verbose font-lock-verbose
  "*If non-nil, means show status messages for cache processing.
If a number, only buffers greater than this size have processing messages."
  :type '(choice (const :tag "never" nil)
		 (const :tag "always" t)
		 (integer :tag "size"))
  :group 'fast-lock)

(defvar fast-lock-save-faces
  (when (save-match-data (string-match "XEmacs" (emacs-version)))
    ;; XEmacs uses extents for everything, so we have to pick the right ones.
    font-lock-face-list)
  "Faces that will be saved in a Font Lock cache file.
If nil, means information for all faces will be saved.")

;; User Functions:

;;;###autoload
(defun fast-lock-mode (&optional arg)
  "Toggle Fast Lock mode.
With arg, turn Fast Lock mode on if and only if arg is positive and the buffer
is associated with a file.  Enable it automatically in your `~/.emacs' by:

 (setq font-lock-support-mode 'fast-lock-mode)

If Fast Lock mode is enabled, and the current buffer does not contain any text
properties, any associated Font Lock cache is used if its timestamp matches the
buffer's file, and its `font-lock-keywords' match those that you are using.

Font Lock caches may be saved:
- When you save the file's buffer.
- When you kill an unmodified file's buffer.
- When you exit Emacs, for all unmodified or saved buffers.
Depending on the value of `fast-lock-save-events'.
See also the commands `fast-lock-read-cache' and `fast-lock-save-cache'.

Use \\[font-lock-fontify-buffer] to fontify the buffer if the cache is bad.

Various methods of control are provided for the Font Lock cache.  In general,
see variable `fast-lock-cache-directories' and function `fast-lock-cache-name'.
For saving, see variables `fast-lock-minimum-size', `fast-lock-save-events',
`fast-lock-save-others' and `fast-lock-save-faces'."
  (interactive "P")
  ;; Only turn on if we are visiting a file.  We could use `buffer-file-name',
  ;; but many packages temporarily wrap that to nil when doing their own thing.
  (set (make-local-variable 'fast-lock-mode)
       (and buffer-file-truename
	    (not (memq 'fast-lock-mode font-lock-inhibit-thing-lock))
	    (if arg (> (prefix-numeric-value arg) 0) (not fast-lock-mode))))
  (if (and fast-lock-mode (not font-lock-mode))
      ;; Turned on `fast-lock-mode' rather than `font-lock-mode'.
      (let ((font-lock-support-mode 'fast-lock-mode))
	(font-lock-mode t))
    ;; Let's get down to business.
    (set (make-local-variable 'fast-lock-cache-timestamp) nil)
    (set (make-local-variable 'fast-lock-cache-filename) nil)
    (when (and fast-lock-mode (not font-lock-fontified))
      (fast-lock-read-cache))))

(defun fast-lock-read-cache ()
  "Read the Font Lock cache for the current buffer.

The following criteria must be met for a Font Lock cache file to be read:
- Fast Lock mode must be turned on in the buffer.
- The buffer must not be modified.
- The buffer's `font-lock-keywords' must match the cache's.
- The buffer file's timestamp must match the cache's.
- Criteria imposed by `fast-lock-cache-directories'.

See `fast-lock-mode'."
  (interactive)
  (let ((directories fast-lock-cache-directories)
	(modified (buffer-modified-p)) (inhibit-read-only t)
	(fontified font-lock-fontified))
    (set (make-local-variable 'font-lock-fontified) nil)
    ;; Keep trying directories until fontification is turned off.
    (while (and directories (not font-lock-fontified))
      (let ((directory (fast-lock-cache-directory (car directories) nil)))
	(condition-case nil
	    (when directory
	      (setq fast-lock-cache-filename (fast-lock-cache-name directory))
	      (when (file-readable-p fast-lock-cache-filename)
		(load fast-lock-cache-filename t t t)))
	  (error nil) (quit nil))
	(setq directories (cdr directories))))
    ;; Unset `fast-lock-cache-filename', and restore `font-lock-fontified', if
    ;; we don't use a cache.  (Note that `fast-lock-cache-data' sets the value
    ;; of `fast-lock-cache-timestamp'.)
    (set-buffer-modified-p modified)
    (unless font-lock-fontified
      (setq fast-lock-cache-filename nil font-lock-fontified fontified))))

(defun fast-lock-save-cache (&optional buffer)
  "Save the Font Lock cache of BUFFER or the current buffer.

The following criteria must be met for a Font Lock cache file to be saved:
- Fast Lock mode must be turned on in the buffer.
- The event must be one of `fast-lock-save-events'.
- The buffer must be at least `fast-lock-minimum-size' bytes long.
- The buffer file must be owned by you, or `fast-lock-save-others' must be t.
- The buffer must contain at least one `face' text property.
- The buffer must not be modified.
- The buffer file's timestamp must be the same as the file's on disk.
- The on disk file's timestamp must be different than the buffer's cache.
- Criteria imposed by `fast-lock-cache-directories'.

See `fast-lock-mode'."
  (interactive)
  (save-excursion
    (when buffer
      (set-buffer buffer))
    (let ((min-size (font-lock-value-in-major-mode fast-lock-minimum-size))
	  (file-timestamp (visited-file-modtime)) (saved nil))
      (when (and fast-lock-mode
	     ;;
	     ;; "Only save if the buffer matches the file, the file has
	     ;; changed, and it was changed by the current emacs session."
	     ;;
	     ;; Only save if the buffer is not modified,
	     ;; (i.e., so we don't save for something not on disk)
	     (not (buffer-modified-p))
	     ;; and the file's timestamp is the same as the buffer's,
	     ;; (i.e., someone else hasn't written the file in the meantime)
	     (verify-visited-file-modtime (current-buffer))
	     ;; and the file's timestamp is different from the cache's.
	     ;; (i.e., a save has occurred since the cache was read)
	     (not (equal fast-lock-cache-timestamp file-timestamp))
	     ;;
	     ;; Only save if user's restrictions are satisfied.
	     (and min-size (>= (buffer-size) min-size))
	     (or fast-lock-save-others
		 (eq (user-uid) (nth 2 (file-attributes buffer-file-name))))
	     ;;
	     ;; Only save if there are `face' properties to save.
	     (text-property-not-all (point-min) (point-max) 'face nil))
	;;
	;; Try each directory until we manage to save or the user quits.
	(let ((directories fast-lock-cache-directories))
	  (while (and directories (memq saved '(nil error)))
	    (let* ((dir (fast-lock-cache-directory (car directories) t))
		   (file (and dir (fast-lock-cache-name dir))))
	      (when (and file (file-writable-p file))
		(setq saved (fast-lock-save-cache-1 file file-timestamp)))
	      (setq directories (cdr directories)))))))))

;;;###autoload
(defun turn-on-fast-lock ()
  "Unconditionally turn on Fast Lock mode."
  (fast-lock-mode t))

;;; API Functions:

(defun fast-lock-after-fontify-buffer ()
  ;; Delete the Font Lock cache file used to restore fontification, if any.
  (when fast-lock-cache-filename
    (if (file-writable-p fast-lock-cache-filename)
	(delete-file fast-lock-cache-filename)
      (message "File %s font lock cache cannot be deleted" (buffer-name))))
  ;; Flag so that a cache will be saved later even if the file is never saved.
  (setq fast-lock-cache-timestamp nil))

(defalias 'fast-lock-after-unfontify-buffer
  'ignore)

;; Miscellaneous Functions:

(defun fast-lock-save-cache-after-save-file ()
  ;; Do `fast-lock-save-cache' if `save-buffer' is on `fast-lock-save-events'.
  (when (memq 'save-buffer fast-lock-save-events)
    (fast-lock-save-cache)))

(defun fast-lock-save-cache-before-kill-buffer ()
  ;; Do `fast-lock-save-cache' if `kill-buffer' is on `fast-lock-save-events'.
  (when (memq 'kill-buffer fast-lock-save-events)
    (fast-lock-save-cache)))

(defun fast-lock-save-caches-before-kill-emacs ()
  ;; Do `fast-lock-save-cache's if `kill-emacs' is on `fast-lock-save-events'.
  (when (memq 'kill-emacs fast-lock-save-events)
    (mapcar 'fast-lock-save-cache (buffer-list))))

(defun fast-lock-cache-directory (directory create)
  "Return usable directory based on DIRECTORY.
Returns nil if the directory does not exist, or, if CREATE non-nil, cannot be
created.  DIRECTORY may be a string or a cons pair of the form (REGEXP . DIR).
See `fast-lock-cache-directories'."
  (let ((dir
	 (cond ((not buffer-file-name)
		;; Should never be nil, but `crypt++' screws it up.
		nil)
	       ((stringp directory)
		;; Just a directory.
		directory)
	       (t
		;; A directory iff the file name matches the regexp.
		(let ((bufile (expand-file-name buffer-file-truename))
		      (case-fold-search nil))
		  (when (save-match-data (string-match (car directory) bufile))
		    (cdr directory)))))))
    (cond ((not dir)
	   nil)
	  ((file-accessible-directory-p dir)
	   dir)
	  (create
	   (condition-case nil
	       (progn (make-directory dir t) dir)
	     (error nil))))))

;; If you are wondering why we only hash if the directory is not ".", rather
;; than if `file-name-absolute-p', it is because if we just appended ".flc" for
;; relative cache directories (that are not ".") then it is possible that more
;; than one file would have the same cache name in that directory, if the luser
;; made a link from one relative cache directory to another.  (Phew!)
(defun fast-lock-cache-name (directory)
  "Return full cache path name using caching DIRECTORY.
If DIRECTORY is `.', the path is the buffer file name appended with `.flc'.
Otherwise, the path name is constructed from DIRECTORY and the buffer's true
abbreviated file name, with all `/' characters in the name replaced with `#'
characters, and appended with `.flc'.

If the same file has different cache path names when edited on different
machines, e.g., on one machine the cache file name has the prefix `#home',
perhaps due to automount, try putting in your `~/.emacs' something like:

 (setq directory-abbrev-alist (cons '(\"^/home/\" . \"/\") directory-abbrev-alist))

Emacs automagically removes the common `/tmp_mnt' automount prefix by default.

See `fast-lock-cache-directory'."
  (if (string-equal directory ".")
      (concat buffer-file-name ".flc")
    (let* ((bufile (expand-file-name buffer-file-truename))
	   (chars-alist
	    (if (eq system-type 'emx)
		'((?/ . (?#)) (?# . (?# ?#)) (?: . (?\;)) (?\; . (?\; ?\;)))
	      '((?/ . (?#)) (?# . (?# ?#)))))
	   (mapchars
	    (function (lambda (c) (or (cdr (assq c chars-alist)) (list c))))))
      (concat
       (file-name-as-directory (expand-file-name directory))
       (mapconcat 'char-to-string (apply 'append (mapcar mapchars bufile)) "")
       ".flc"))))

;; Font Lock Cache Processing Functions:

;; The version 3 format of the cache is:
;;
;; (fast-lock-cache-data VERSION TIMESTAMP
;;  font-lock-syntactic-keywords SYNTACTIC-PROPERTIES
;;  font-lock-keywords FACE-PROPERTIES)

(defun fast-lock-save-cache-1 (file timestamp)
  ;; Save the FILE with the TIMESTAMP plus fontification data.
  ;; Returns non-nil if a save was attempted to a writable cache file.
  (let ((tpbuf (generate-new-buffer " *fast-lock*"))
	(verbose (if (numberp fast-lock-verbose)
		     (> (buffer-size) fast-lock-verbose)
		   fast-lock-verbose))
	(saved t))
    (if verbose (message "Saving %s font lock cache..." (buffer-name)))
    (condition-case nil
	(save-excursion
	  (print (list 'fast-lock-cache-data 3
		       (list 'quote timestamp)
		       (list 'quote font-lock-syntactic-keywords)
		       (list 'quote (fast-lock-get-syntactic-properties))
		       (list 'quote font-lock-keywords)
		       (list 'quote (fast-lock-get-face-properties)))
		 tpbuf)
	  (set-buffer tpbuf)
	  (write-region (point-min) (point-max) file nil 'quietly)
	  (setq fast-lock-cache-timestamp timestamp
		fast-lock-cache-filename file))
      (error (setq saved 'error)) (quit (setq saved 'quit)))
    (kill-buffer tpbuf)
    (if verbose (message "Saving %s font lock cache...%s" (buffer-name)
			 (cond ((eq saved 'error) "failed")
			       ((eq saved 'quit) "aborted")
			       (t "done"))))
    ;; We return non-nil regardless of whether a failure occurred.
    saved))

(defun fast-lock-cache-data (version timestamp
			     syntactic-keywords syntactic-properties
			     keywords face-properties
			     &rest ignored)
  ;; Find value of syntactic keywords in case it is a symbol.
  (setq font-lock-syntactic-keywords (font-lock-eval-keywords
				      font-lock-syntactic-keywords))
  ;; Compile all keywords in case some are and some aren't.
  (setq font-lock-syntactic-keywords (font-lock-compile-keywords
				      font-lock-syntactic-keywords)
	syntactic-keywords (font-lock-compile-keywords syntactic-keywords)

	font-lock-keywords (font-lock-compile-keywords font-lock-keywords)
	keywords (font-lock-compile-keywords keywords))
  ;; Use the Font Lock cache SYNTACTIC-PROPERTIES and FACE-PROPERTIES if we're
  ;; using cache VERSION format 3, the current buffer's file timestamp matches
  ;; the TIMESTAMP, the current buffer's `font-lock-syntactic-keywords' are the
  ;; same as SYNTACTIC-KEYWORDS, and the current buffer's `font-lock-keywords'
  ;; are the same as KEYWORDS.
  (let ((buf-timestamp (visited-file-modtime))
	(verbose (if (numberp fast-lock-verbose)
		     (> (buffer-size) fast-lock-verbose)
		   fast-lock-verbose))
	(loaded t))
    (if (or (/= version 3)
	    (buffer-modified-p)
	    (not (equal timestamp buf-timestamp))
	    (not (equal syntactic-keywords font-lock-syntactic-keywords))
	    (not (equal keywords font-lock-keywords)))
	(setq loaded nil)
      (if verbose (message "Loading %s font lock cache..." (buffer-name)))
      (condition-case nil
	  (fast-lock-add-properties syntactic-properties face-properties)
	(error (setq loaded 'error)) (quit (setq loaded 'quit)))
      (if verbose (message "Loading %s font lock cache...%s" (buffer-name)
			   (cond ((eq loaded 'error) "failed")
				 ((eq loaded 'quit) "aborted")
				 (t "done")))))
    (setq font-lock-fontified (eq loaded t)
	  fast-lock-cache-timestamp (and (eq loaded t) timestamp))))

;; Text Properties Processing Functions:

;; This is fast, but fails if adjacent characters have different `face' text
;; properties.  Maybe that's why I dropped it in the first place?
;(defun fast-lock-get-face-properties ()
;  "Return a list of `face' text properties in the current buffer.
;Each element of the list is of the form (VALUE START1 END1 START2 END2 ...)
;where VALUE is a `face' property value and STARTx and ENDx are positions."
;  (save-restriction
;    (widen)
;    (let ((start (text-property-not-all (point-min) (point-max) 'face nil))
;	  (limit (point-max)) end properties value cell)
;      (while start
;	(setq end (next-single-property-change start 'face nil limit)
;	      value (get-text-property start 'face))
;	;; Make, or add to existing, list of regions with same `face'.
;	(if (setq cell (assq value properties))
;	    (setcdr cell (cons start (cons end (cdr cell))))
;	  (setq properties (cons (list value start end) properties)))
;	(setq start (next-single-property-change end 'face)))
;      properties)))

;; This is slow, but copes if adjacent characters have different `face' text
;; properties, but fails if they are lists.
;(defun fast-lock-get-face-properties ()
;  "Return a list of `face' text properties in the current buffer.
;Each element of the list is of the form (VALUE START1 END1 START2 END2 ...)
;where VALUE is a `face' property value and STARTx and ENDx are positions.
;Only those `face' VALUEs in `fast-lock-save-faces' are returned."
;  (save-restriction
;    (widen)
;    (let ((faces (or fast-lock-save-faces (face-list))) (limit (point-max))
;	  properties regions face start end)
;      (while faces
;	(setq face (car faces) faces (cdr faces) regions () end (point-min))
;	;; Make a list of start/end regions with `face' property face.
;	(while (setq start (text-property-any end limit 'face face))
;	  (setq end (or (text-property-not-all start limit 'face face) limit)
;		regions (cons start (cons end regions))))
;	;; Add `face' face's regions, if any, to properties.
;	(when regions
;	  (push (cons face regions) properties)))
;      properties)))

(defun fast-lock-get-face-properties ()
  "Return a list of `face' text properties in the current buffer.
Each element of the list is of the form (VALUE START1 END1 START2 END2 ...)
where VALUE is a `face' property value and STARTx and ENDx are positions."
  (save-restriction
    (widen)
    (let ((start (text-property-not-all (point-min) (point-max) 'face nil))
	  end properties value cell)
      (while start
	(setq end (next-single-property-change start 'face nil (point-max))
	      value (get-text-property start 'face))
	;; Make, or add to existing, list of regions with same `face'.
	(cond ((setq cell (assoc value properties))
	       (setcdr cell (cons start (cons end (cdr cell)))))
	      ((fast-lock-save-facep value)
	       (push (list value start end) properties)))
	(setq start (text-property-not-all end (point-max) 'face nil)))
      properties)))

(defun fast-lock-get-syntactic-properties ()
  "Return a list of `syntax-table' text properties in the current buffer.
See `fast-lock-get-face-properties'."
  (save-restriction
    (widen)
    (let ((start (text-property-not-all (point-min) (point-max) 'syntax-table
					nil))
	  end properties value cell)
      (while start
	(setq end (next-single-property-change start 'syntax-table nil
					       (point-max))
	      value (get-text-property start 'syntax-table))
	;; Make, or add to existing, list of regions with same `syntax-table'.
	(if (setq cell (assoc value properties))
	    (setcdr cell (cons start (cons end (cdr cell))))
	  (push (list value start end) properties))
	(setq start (text-property-not-all end (point-max) 'syntax-table nil)))
      properties)))

(defun fast-lock-add-properties (syntactic-properties face-properties)
  "Add `syntax-table' and `face' text properties to the current buffer.
Any existing `syntax-table' and `face' text properties are removed first.
See `fast-lock-get-face-properties'."
  (save-buffer-state (plist regions)
    (save-restriction
      (widen)
      (font-lock-unfontify-region (point-min) (point-max))
      ;;
      ;; Set the `syntax-table' property for each start/end region.
      (while syntactic-properties
	(setq plist (list 'syntax-table (car (car syntactic-properties)))
	      regions (cdr (car syntactic-properties))
	      syntactic-properties (cdr syntactic-properties))
	(while regions
	  (add-text-properties (nth 0 regions) (nth 1 regions) plist)
	  (setq regions (nthcdr 2 regions))))
      ;;
      ;; Set the `face' property for each start/end region.
      (while face-properties
	(setq plist (list 'face (car (car face-properties)))
	      regions (cdr (car face-properties))
	      face-properties (cdr face-properties))
	(while regions
	  (add-text-properties (nth 0 regions) (nth 1 regions) plist)
	  (setq regions (nthcdr 2 regions)))))))

;; Functions for XEmacs:

(when (save-match-data (string-match "XEmacs" (emacs-version)))
  ;;
  ;; It would be better to use XEmacs' `map-extents' over extents with a
  ;; `font-lock' property, but `face' properties are on different extents.
  (defun fast-lock-get-face-properties ()
    "Return a list of `face' text properties in the current buffer.
Each element of the list is of the form (VALUE START1 END1 START2 END2 ...)
where VALUE is a `face' property value and STARTx and ENDx are positions.
Only those `face' VALUEs in `fast-lock-save-faces' are returned."
    (save-restriction
      (widen)
      (let ((properties ()) cell)
	(map-extents
	 (function (lambda (extent ignore)
	    (let ((value (extent-face extent)))
	      ;; We're only interested if it's one of `fast-lock-save-faces'.
	      (when (and value (fast-lock-save-facep value))
		(let ((start (extent-start-position extent))
		      (end (extent-end-position extent)))
		  ;; Make or add to existing list of regions with the same
		  ;; `face' property value.
		  (if (setq cell (assoc value properties))
		      (setcdr cell (cons start (cons end (cdr cell))))
		    (push (list value start end) properties))))
	      ;; Return nil to keep `map-extents' going.
	      nil))))
	properties)))
  ;;
  ;; XEmacs does not support the `syntax-table' text property.
  (defalias 'fast-lock-get-syntactic-properties
    'ignore)
  ;;
  ;; Make extents just like XEmacs' font-lock.el does.
  (defun fast-lock-add-properties (syntactic-properties face-properties)
    "Set `face' text properties in the current buffer.
Any existing `face' text properties are removed first.
See `fast-lock-get-face-properties'."
    (save-restriction
      (widen)
      (font-lock-unfontify-region (point-min) (point-max))
      ;; Set the `face' property, etc., for each start/end region.
      (while face-properties
	(let ((face (car (car face-properties)))
	      (regions (cdr (car face-properties))))
	  (while regions
	    (font-lock-set-face (nth 0 regions) (nth 1 regions) face)
	    (setq regions (nthcdr 2 regions)))
	  (setq face-properties (cdr face-properties))))
      ;; XEmacs does not support the `syntax-table' text property.      
      ))
  ;;
  ;; XEmacs 19.12 font-lock.el's `font-lock-fontify-buffer' runs a hook.
  (add-hook 'font-lock-after-fontify-buffer-hook
	    'fast-lock-after-fontify-buffer))

(unless (boundp 'font-lock-syntactic-keywords)
  (defvar font-lock-syntactic-keywords nil))

(unless (boundp 'font-lock-inhibit-thing-lock)
  (defvar font-lock-inhibit-thing-lock nil))

(unless (fboundp 'font-lock-compile-keywords)
  (defalias 'font-lock-compile-keywords 'identity))

(unless (fboundp 'font-lock-eval-keywords)
  (defun font-lock-eval-keywords (keywords)
    (if (symbolp keywords)
	(font-lock-eval-keywords (if (fboundp keywords)
				     (funcall keywords)
				   (eval keywords)))
      keywords)))

(unless (fboundp 'font-lock-value-in-major-mode)
  (defun font-lock-value-in-major-mode (alist)
    (if (consp alist)
	(cdr (or (assq major-mode alist) (assq t alist)))
      alist)))

;; Install ourselves:

(add-hook 'after-save-hook 'fast-lock-save-cache-after-save-file)
(add-hook 'kill-buffer-hook 'fast-lock-save-cache-before-kill-buffer)
(add-hook 'kill-emacs-hook 'fast-lock-save-caches-before-kill-emacs)

;;;###autoload
(when (fboundp 'add-minor-mode)
  (defvar fast-lock-mode nil)
  (add-minor-mode 'fast-lock-mode nil))
;;;###dont-autoload
(unless (assq 'fast-lock-mode minor-mode-alist)
  (setq minor-mode-alist (append minor-mode-alist '((fast-lock-mode nil)))))

;; Provide ourselves:

(provide 'fast-lock)

;;; fast-lock.el ends here

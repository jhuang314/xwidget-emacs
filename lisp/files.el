;;; files.el --- file input and output commands for Emacs

;; Copyright (C) 1985, 1986, 1987, 1992 Free Software Foundation, Inc.

;; This file is part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 1, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

(defconst delete-auto-save-files t
  "*Non-nil means delete a buffer's auto-save file when the buffer is saved.")

(defconst directory-abbrev-alist
  nil
  "*Alist of abbreviations for file directories.
A list of elements of the form (FROM . TO), each meaning to replace
FROM with TO when it appears in a directory name.  This replacement is
done when setting up the default directory of a newly visited file.
*Every* FROM string should start with `^'.

Use this feature when you have directories which you normally refer to
via absolute symbolic links.  Make TO the name of the link, and FROM
the name it is linked to.")

;;; Turn off backup files on VMS since it has version numbers.
(defconst make-backup-files (not (eq system-type 'vax-vms))
  "*Create a backup of each file when it is saved for the first time.
This can be done by renaming the file or by copying.

Renaming means that Emacs renames the existing file so that it is a
backup file, then writes the buffer into a new file.  Any other names
that the old file had will now refer to the backup file.  The new file
is owned by you and its group is defaulted.

Copying means that Emacs copies the existing file into the backup
file, then writes the buffer on top of the existing file.  Any other
names that the old file had will now refer to the new (edited) file.
The file's owner and group are unchanged.

The choice of renaming or copying is controlled by the variables
`backup-by-copying', `backup-by-copying-when-linked' and
`backup-by-copying-when-mismatch'.")

;; Do this so that local variables based on the file name
;; are not overridden by the major mode.
(defvar backup-inhibited nil
  "Non-nil means don't make a backup file for this buffer.")
(put 'backup-inhibited 'permanent-local t)

(defconst backup-by-copying nil
 "*Non-nil means always use copying to create backup files.
See documentation of variable `make-backup-files'.")

(defconst backup-by-copying-when-linked nil
 "*Non-nil means use copying to create backups for files with multiple names.
This causes the alternate names to refer to the latest version as edited.
This variable is relevant only if `backup-by-copying' is nil.")

(defconst backup-by-copying-when-mismatch nil
  "*Non-nil means create backups by copying if this preserves owner or group.
Renaming may still be used (subject to control of other variables)
when it would not result in changing the owner or group of the file;
that is, for files which are owned by you and whose group matches
the default for a new file created there by you.
This variable is relevant only if `backup-by-copying' is nil.")

(defvar backup-enable-predicate
  '(lambda (name)
     (or (< (length name) 5)
	 (not (string-equal "/tmp/" (substring name 0 5)))))
  "Predicate that looks at a file name and decides whether to make backups.
Called with an absolute file name as argument, it returns t to enable backup.")

(defconst buffer-offer-save nil
  "*Non-nil in a buffer means offer to save the buffer on exit
even if the buffer is not visiting a file.
Automatically local in all buffers.")
(make-variable-buffer-local 'buffer-offer-save)

(defconst file-precious-flag nil
  "*Non-nil means protect against I/O errors while saving files.
Some modes set this non-nil in particular buffers.")

(defvar version-control nil
  "*Control use of version numbers for backup files.
t means make numeric backup versions unconditionally.
nil means make them for files that have some already.
never means do not make them.")

(defvar dired-kept-versions 2
  "*When cleaning directory, number of versions to keep.")

(defvar trim-versions-without-asking nil
  "*If true, deletes excess backup versions silently.
Otherwise asks confirmation.")

(defvar kept-old-versions 2
  "*Number of oldest versions to keep when a new numbered backup is made.")

(defvar kept-new-versions 2
  "*Number of newest versions to keep when a new numbered backup is made.
Includes the new backup.  Must be > 0")

(defconst require-final-newline nil
  "*Value of t says silently ensure a file ends in a newline when it is saved.
Non-nil but not t says ask user whether to add a newline when there isn't one.
nil means don't add newlines.")

(defconst auto-save-default t
  "*Non-nil says by default do auto-saving of every file-visiting buffer.")

(defconst auto-save-visited-file-name nil
  "*Non-nil says auto-save a buffer in the file it is visiting, when practical.
Normally auto-save files are written under other names.")

(defconst save-abbrevs nil
  "*Non-nil means save word abbrevs too when files are saved.
Loading an abbrev file sets this to t.")

(defconst find-file-run-dired t
  "*Non-nil says run dired if find-file is given the name of a directory.")

(put 'find-file-not-found-hooks 'permanent-local t)
(defvar find-file-not-found-hooks nil
  "List of functions to be called for `find-file' on nonexistent file.
These functions are called as soon as the error is detected.
`buffer-file-name' is already set up.
The functions are called in the order given until one of them returns non-nil.")

(put 'find-file-hooks 'permanent-local t)
(defvar find-file-hooks nil
  "List of functions to be called after a buffer is loaded from a file.
The buffer's local variables (if any) will have been processed before the
functions are called.")

(put 'write-file-hooks 'permanent-local t)
(defvar write-file-hooks nil
  "List of functions to be called before writing out a buffer to a file.
If one of them returns non-nil, the file is considered already written
and the rest are not called.
These hooks are considered to pertain to the visited file.
So this list is cleared if you change the visited file name.
See also `write-contents-hooks'.")

(defvar write-contents-hooks nil
  "List of functions to be called before writing out a buffer to a file.
If one of them returns non-nil, the file is considered already written
and the rest are not called.
These hooks are considered to pertain to the buffer's contents,
not to the particular visited file; thus, `set-visited-file-name' does
not clear this variable, but changing the major mode does clear it.
See also `write-file-hooks'.")

(defconst enable-local-variables t
  "*Control use of local-variables lists in files you visit.
The value can be t, nil or something else.
A value of t means local-variables lists are obeyed;
nil means they are ignored; anything else means query.

The command \\[normal-mode] always obeys local-variables lists
and ignores this variable.")

(defconst enable-local-eval nil
  "*Control processing of the \"variable\" `eval' in a file's local variables.
The value can be t, nil or something else.
A value of t means obey `eval' variables;
nil means ignore them; anything else means query.

The command \\[normal-mode] always obeys local-variables lists
and ignores this variable.")

;; Avoid losing in versions where CLASH_DETECTION is disabled.
(or (fboundp 'lock-buffer)
    (fset 'lock-buffer 'ignore))
(or (fboundp 'unlock-buffer)
    (fset 'unlock-buffer 'ignore))

(defun pwd ()
  "Show the current default directory."
  (interactive nil)
  (message "Directory %s" default-directory))

(defun cd (dir)
  "Make DIR become the current buffer's default directory."
  (interactive "DChange default directory: ")
  (setq dir (expand-file-name dir))
  (if (not (eq system-type 'vax-vms))
      (setq dir (file-name-as-directory dir)))
  (if (not (file-directory-p dir))
      (error "%s is not a directory" dir)
    (if (file-executable-p dir)
	(setq default-directory dir)
      (error "Cannot cd to %s:  Permission denied" dir)))
  ;; We used to call pwd at this point.  That's not terribly helpful
  ;; when we're invoking cd interactively, and the new cmushell-based
  ;; shell has its own (better) facilities for this.
)

(defun load-file (file)
  "Load the Lisp file named FILE."
  (interactive "fLoad file: ")
  (load (expand-file-name file) nil nil t))

(defun load-library (library)
  "Load the library named LIBRARY.
This is an interface to the function `load'."
  (interactive "sLoad library: ")
  (load library))

(defun switch-to-buffer-other-window (buffer)
  "Select buffer BUFFER in another window."
  (interactive "BSwitch to buffer in other window: ")
  (let ((pop-up-windows t))
    (pop-to-buffer buffer t)))

(defun switch-to-buffer-other-screen (buffer)
  "Switch to buffer BUFFER in another screen."
  (interactive "BSwitch to buffer in other screen: ")
  (let ((pop-up-screens t))
    (pop-to-buffer buffer)))

(defun find-file (filename)
  "Edit file FILENAME.
Switch to a buffer visiting file FILENAME,
creating one if none already exists."
  (interactive "FFind file: ")
  (switch-to-buffer (find-file-noselect filename)))

(defun find-file-other-window (filename)
  "Edit file FILENAME, in another window.
May create a new window, or reuse an existing one.
See the function `display-buffer'."
  (interactive "FFind file in other window: ")
  (switch-to-buffer-other-window (find-file-noselect filename)))

(defun find-file-other-screen (filename)
  "Edit file FILENAME, in another screen.
May create a new screen, or reuse an existing one.
See the function `display-buffer'."
  (interactive "FFind file in other screen: ")
  (switch-to-buffer-other-screen (find-file-noselect filename)))

(defun find-file-read-only (filename)
  "Edit file FILENAME but don't allow changes.
Like \\[find-file] but marks buffer as read-only.
Use \\[toggle-read-only] to permit editing."
  (interactive "fFind file read-only: ")
  (find-file filename)
  (setq buffer-read-only t))

(defun find-file-read-only-other-window (filename)
  "Edit file FILENAME in another window but don't allow changes.
Like \\[find-file-other-window] but marks buffer as read-only.
Use \\[toggle-read-only] to permit editing."
  (interactive "fFind file read-only other window: ")
  (find-file filename)
  (setq buffer-read-only t))

(defun find-file-read-only-other-screen (filename)
  "Edit file FILENAME in another screen but don't allow changes.
Like \\[find-file-other-screen] but marks buffer as read-only.
Use \\[toggle-read-only] to permit editing."
  (interactive "fFind file read-only other screen: ")
  (find-file-other-screen filename)
  (setq buffer-read-only t))

(defun find-alternate-file (filename)
  "Find file FILENAME, select its buffer, kill previous buffer.
If the current buffer now contains an empty file that you just visited
\(presumably by mistake), use this command to visit the file you really want."
  (interactive
   (let ((file buffer-file-name)
	 (file-name nil)
	 (file-dir nil))
     (and file
	  (setq file-name (file-name-nondirectory file)
		file-dir (file-name-directory file)))
     (list (read-file-name "Find alternate file: " file-dir nil nil file-name))))
  (and (buffer-modified-p)
       ;; (not buffer-read-only)
       (not (yes-or-no-p (format "Buffer %s is modified; kill anyway? "
				 (buffer-name))))
       (error "Aborted"))
  (let ((obuf (current-buffer))
	(ofile buffer-file-name)
	(oname (buffer-name)))
    (rename-buffer " **lose**")
    (setq buffer-file-name nil)
    (unwind-protect
	(progn
	  (unlock-buffer)
	  (find-file filename))
      (cond ((eq obuf (current-buffer))
	     (setq buffer-file-name ofile)
	     (lock-buffer)
	     (rename-buffer oname))))
    (or (eq (current-buffer) obuf)
	(kill-buffer obuf))))

(defun create-file-buffer (filename)
  "Create a suitably named buffer for visiting FILENAME, and return it.
FILENAME (sans directory) is used unchanged if that name is free;
otherwise a string <2> or <3> or ... is appended to get an unused name."
  (let ((lastname (file-name-nondirectory filename)))
    (if (string= lastname "")
	(setq lastname filename))
    (generate-new-buffer lastname)))

(defun generate-new-buffer (name)
  "Create and return a buffer with a name based on NAME.
Choose the buffer's name using generate-new-buffer-name."
  (get-buffer-create (generate-new-buffer-name name)))

(defun abbreviate-file-name (filename)
  "Return a version of FILENAME shortened using directory-abbrev-alist.
This also substitutes \"~\" for the user's home directory.
See \\[describe-variable] directory-abbrev-alist RET for more information."
  (let ((tail directory-abbrev-alist))
    (while tail
      (if (string-match (car (car tail)) filename)
	  (setq filename
		(concat (cdr (car tail)) (substring filename (match-end 0)))))
      (setq tail (cdr tail)))
    (if (string-match (concat "^" (expand-file-name "~")) filename)
	(setq filename
	      (concat "~" (substring filename (match-end 0)))))
    filename))

(defun find-file-noselect (filename &optional nowarn)
  "Read file FILENAME into a buffer and return the buffer.
If a buffer exists visiting FILENAME, return that one, but
verify that the file has not changed since visited or saved.
The buffer is not selected, just returned to the caller."
  (setq filename (expand-file-name filename))
  ;; Get rid of the prefixes added by the automounter.
  (if (and (string-match "^/tmp_mnt/" filename)
	   (file-exists-p (file-name-directory
			   (substring filename (1- (match-end 0))))))
      (setq filename (substring filename (1- (match-end 0)))))
  (setq filename (abbreviate-file-name filename))
  (if (file-directory-p filename)
      (if find-file-run-dired
	  (dired-noselect filename)
	(error "%s is a directory." filename))
    (let ((buf (get-file-buffer filename))
	  error)
      (if buf
	  (or nowarn
	      (verify-visited-file-modtime buf)
	      (cond ((not (file-exists-p filename))
		     (error "File %s no longer exists!" filename))
		    ((yes-or-no-p
		      (format
		       (if (buffer-modified-p buf)
    "File %s changed on disk.  Discard your edits? "
    "File %s changed on disk.  Read the new version? ")
		       (file-name-nondirectory filename)))
		     (save-excursion
		       (set-buffer buf)
		       (revert-buffer t t)))))
	(save-excursion
	  (let* ((link-name (car (file-attributes filename)))
		 (linked-buf (and (stringp link-name)
				  (get-file-buffer link-name))))
	    (if (bufferp linked-buf)
		(message "Symbolic link to file in buffer %s"
			 (buffer-name linked-buf))))
	  (setq buf (create-file-buffer filename))
	  (set-buffer buf)
	  (erase-buffer)
	  (condition-case ()
	      (insert-file-contents filename t)
	    (file-error
	     (setq error t)
	     ;; Run find-file-not-found-hooks until one returns non-nil.
	     (let ((hooks find-file-not-found-hooks))
	       (while (and hooks
			   (not (funcall (car hooks))))
		 (setq hooks (cdr hooks))))))
	  ;; Set buffer's default directory to that of the file.
	  (setq default-directory (file-name-directory filename))
	  ;; Turn off backup files for certain file names.  Since
	  ;; this is a permanent local, the major mode won't eliminate it.
	  (and (not (funcall backup-enable-predicate buffer-file-name))
	       (progn
		 (make-local-variable 'backup-inhibited)
		 (setq backup-inhibited t)))
	  (after-find-file error (not nowarn))))
      buf)))

(defun after-find-file (&optional error warn)
  "Called after finding a file and by the default revert function.
Sets buffer mode, parses local variables.
Optional args ERROR and WARN: ERROR non-nil means there was an
error in reading the file.  WARN non-nil means warn if there
exists an auto-save file more recent than the visited file.
Finishes by calling the functions in `find-file-hooks'."
  (setq buffer-read-only (not (file-writable-p buffer-file-name)))
  (if noninteractive
      nil
    (let* (not-serious
	   (msg
	    (cond ((and error (file-attributes buffer-file-name))
		   (setq buffer-read-only t)
		   "File exists, but is read-protected.")
		  ((not buffer-read-only)
		   (if (and warn
			    (file-newer-than-file-p (make-auto-save-file-name)
						    buffer-file-name))
		       "Auto save file is newer; consider M-x recover-file"
		     (setq not-serious t)
		     (if error "(New file)" nil)))
		  ((not error)
		   (setq not-serious t)
		   "Note: file is write protected")
		  ((file-attributes (directory-file-name default-directory))
		   "File not found and directory write-protected")
		  (t
		   ;; If the directory the buffer is in doesn't exist,
		   ;; offer to create it.  It's better to do this now
		   ;; than when we save the buffer, because we want
		   ;; autosaving to work.
		   (setq buffer-read-only nil)
		   (or (file-exists-p (file-name-directory buffer-file-name))
		       (if (yes-or-no-p
			    (format
			     "The directory containing %s does not exist.  Create? "
			     (abbreviate-file-name buffer-file-name)))
			   (make-directory-path
			    (file-name-directory buffer-file-name))))
		   nil))))
      (if msg
	  (progn
	    (message msg)
	    (or not-serious (sit-for 1 nil t)))))
    (if auto-save-default
	(auto-save-mode t)))
  (normal-mode t)
  (mapcar 'funcall find-file-hooks))

(defun normal-mode (&optional find-file)
  "Choose the major mode for this buffer automatically.
Also sets up any specified local variables of the file.
Uses the visited file name, the -*- line, and the local variables spec.

This function is called automatically from `find-file'.  In that case,
we may set up specified local variables depending on the value of
`enable-local-variables': if it is t, we do; if it is nil, we don't;
otherwise, we query.  `enable-local-variables' is ignored if you
run `normal-mode' explicitly."
  (interactive)
  (or find-file (funcall (or default-major-mode 'fundamental-mode)))
  (condition-case err
      (set-auto-mode)
    (error (message "File mode specification error: %s"
		    (prin1-to-string err))))
  (condition-case err
      (let ((enable-local-variables (or (not find-file)
					enable-local-variables)))
	(hack-local-variables))
    (error (message "File local-variables error: %s"
		    (prin1-to-string err)))))

(defvar auto-mode-alist (mapcar 'purecopy
				'(("\\.text\\'" . text-mode)
				  ("\\.c\\'" . c-mode)
				  ("\\.h\\'" . c-mode)
				  ("\\.tex\\'" . TeX-mode)
				  ("\\.ltx\\'" . LaTeX-mode)
				  ("\\.el\\'" . emacs-lisp-mode)
				  ("\\.mm\\'" . nroff-mode)
				  ("\\.me\\'" . nroff-mode)
				  ("\\.[12345678]\\'" . nroff-mode)
				  ("\\.scm\\'" . scheme-mode)
				  ("\\.l\\'" . lisp-mode)
				  ("\\.lisp\\'" . lisp-mode)
				  ("\\.f\\'" . fortran-mode)
				  ("\\.for\\'" . fortran-mode)
				  ("\\.mss\\'" . scribe-mode)
				  ("\\.pl\\'" . prolog-mode)
				  ("\\.cc\\'" . c++-mode)
				  ("\\.C\\'" . c++-mode)
;;; Less common extensions come here
;;; so more common ones above are found faster.
				  ("\\.s\\'" . asm-mode)
				  ("ChangeLog\\'" . change-log-mode)
				  ("\\$CHANGE_LOG\\$\\.TXT" . change-log-mode)
				  ("\\.TeX\\'" . TeX-mode)
				  ("\\.sty\\'" . LaTeX-mode)
				  ("\\.bbl\\'" . LaTeX-mode)
				  ("\\.bib\\'" . bibtex-mode)
				  ("\\.article\\'" . text-mode)
				  ("\\.letter\\'" . text-mode)
				  ("\\.texinfo\\'" . texinfo-mode)
				  ("\\.lsp\\'" . lisp-mode)
				  ("\\.awk\\'" . awk-mode)
				  ("\\.prolog\\'" . prolog-mode)
				  ;; Mailer puts message to be edited in
				  ;; /tmp/Re.... or Message
				  ("^/tmp/Re" . text-mode)
				  ("/Message[0-9]*\\'" . text-mode)
				  ;; some news reader is reported to use this
				  ("^/tmp/fol/" . text-mode)
				  ("\\.y\\'" . c-mode)
				  ("\\.oak\\'" . scheme-mode)
				  ("\\.scm.[0-9]*\\'" . scheme-mode)
				  ;; .emacs following a directory delimiter
				  ;; in either Unix or VMS syntax.
				  ("[]>:/]\\..*emacs\\'" . emacs-lisp-mode)
				  ("\\.ml\\'" . lisp-mode)))
  "\
Alist of filename patterns vs corresponding major mode functions.
Each element looks like (REGEXP . FUNCTION).
Visiting a file whose name matches REGEXP causes FUNCTION to be called.")

(defun set-auto-mode ()
  "Select major mode appropriate for current buffer.
This checks for a -*- mode tag in the buffer's text, or
compares the filename against the entries in auto-mode-alist.  It does
not check for the \"mode:\" local variable in the Local Variables
section of the file; for that, use `hack-local-variables'.

If enable-local-variables is nil, this function will not check for a
-*- mode tag."
  ;; Look for -*-MODENAME-*- or -*- ... mode: MODENAME; ... -*-
  (let (beg end mode)
    (save-excursion
      (goto-char (point-min))
      (skip-chars-forward " \t\n")
      (if (and enable-local-variables
	       (search-forward "-*-" (save-excursion (end-of-line) (point)) t)
	       (progn
		 (skip-chars-forward " \t")
		 (setq beg (point))
		 (search-forward "-*-"
				 (save-excursion (end-of-line) (point))
				 t))
	       (progn
		 (forward-char -3)
		 (skip-chars-backward " \t")
		 (setq end (point))
		 (goto-char beg)
		 (if (search-forward ":" end t)
		     (progn
		       (goto-char beg)
		       (if (let ((case-fold-search t))
			     (search-forward "mode:" end t))
			   (progn
			     (skip-chars-forward " \t")
			     (setq beg (point))
			     (if (search-forward ";" end t)
				 (forward-char -1)
			       (goto-char end))
			     (skip-chars-backward " \t")
			     (setq mode (buffer-substring beg (point))))))
		   (setq mode (buffer-substring beg end)))))
	  (setq mode (intern (concat (downcase mode) "-mode")))
	(let ((alist auto-mode-alist)
	      (name buffer-file-name))
	  (let ((case-fold-search (eq system-type 'vax-vms)))
	    ;; Remove backup-suffixes from file name.
	    (setq name (file-name-sans-versions name))
	    ;; Find first matching alist entry.
	    (while (and (not mode) alist)
	      (if (string-match (car (car alist)) name)
		  (setq mode (cdr (car alist))))
	      (setq alist (cdr alist)))))))
    (if mode (funcall mode))))

(defun hack-local-variables ()
  "Parse (and bind or evaluate as appropriate) any local variables
for current buffer."
  ;; Look for "Local variables:" line in last page.
  (save-excursion
    (goto-char (point-max))
    (search-backward "\n\^L" (max (- (point-max) 3000) (point-min)) 'move)
    (if (let ((case-fold-search t))
	  (and (search-forward "Local Variables:" nil t)
	       (or (eq enable-local-variables t)
		   (and enable-local-variables
			(save-window-excursion
			  (switch-to-buffer (current-buffer))
			  (save-excursion
			    (beginning-of-line)
			    (set-window-start (selected-window) (point)))
			  (y-or-n-p (format "Set local variables as specified at end of %s? "
					    (file-name-nondirectory buffer-file-name))))))))
	(let ((continue t)
	      prefix prefixlen suffix beg)
	  ;; The prefix is what comes before "local variables:" in its line.
	  ;; The suffix is what comes after "local variables:" in its line.
	  (skip-chars-forward " \t")
	  (or (eolp)
	      (setq suffix (buffer-substring (point)
					     (progn (end-of-line) (point)))))
	  (goto-char (match-beginning 0))
	  (or (bolp)
	      (setq prefix
		    (buffer-substring (point)
				      (progn (beginning-of-line) (point)))))

	  (if prefix (setq prefixlen (length prefix)
			   prefix (regexp-quote prefix)))
	  (if suffix (setq suffix (concat (regexp-quote suffix) "$")))
	  (while continue
	    ;; Look at next local variable spec.
	    (if selective-display (re-search-forward "[\n\C-m]")
	      (forward-line 1))
	    ;; Skip the prefix, if any.
	    (if prefix
		(if (looking-at prefix)
		    (forward-char prefixlen)
		  (error "Local variables entry is missing the prefix")))
	    ;; Find the variable name; strip whitespace.
	    (skip-chars-forward " \t")
	    (setq beg (point))
	    (skip-chars-forward "^:\n")
	    (if (eolp) (error "Missing colon in local variables entry"))
	    (skip-chars-backward " \t")
	    (let* ((str (buffer-substring beg (point)))
		   (var (read str))
		  val)
	      ;; Setting variable named "end" means end of list.
	      (if (string-equal (downcase str) "end")
		  (setq continue nil)
		;; Otherwise read the variable value.
		(skip-chars-forward "^:")
		(forward-char 1)
		(setq val (read (current-buffer)))
		(skip-chars-backward "\n")
		(skip-chars-forward " \t")
		(or (if suffix (looking-at suffix) (eolp))
		    (error "Local variables entry is terminated incorrectly"))
		;; Set the variable.  "Variables" mode and eval are funny.
		(cond ((eq var 'mode)
		       (funcall (intern (concat (downcase (symbol-name val))
						"-mode"))))
		      ((eq var 'eval)
		       (if (and (not (string= (user-login-name) "root"))
				(or (eq enable-local-eval t)
				    (and enable-local-eval
					 (save-window-excursion
					   (switch-to-buffer (current-buffer))
					   (save-excursion
					     (beginning-of-line)
					     (set-window-start (selected-window) (point)))
					   (y-or-n-p (format "Process `eval' local variable in file %s? "
							     (file-name-nondirectory buffer-file-name)))))))
			   (save-excursion (eval val))
			 (message "Ignoring `eval:' in file's local variables")))
		      (t (make-local-variable var)
			 (set var val))))))))))

(defun set-visited-file-name (filename)
  "Change name of file visited in current buffer to FILENAME.
The next time the buffer is saved it will go in the newly specified file.
nil or empty string as argument means make buffer not be visiting any file.
Remember to delete the initial contents of the minibuffer
if you wish to pass an empty string as the argument."
  (interactive "FSet visited file name: ")
  (if filename
      (setq filename
	    (if (string-equal filename "")
		nil
	      (expand-file-name filename))))
  (or (equal filename buffer-file-name)
      (null filename)
      (progn
	(lock-buffer filename)
	(unlock-buffer)))
  (setq buffer-file-name filename)
  (if filename				; make buffer name reflect filename.
      (let ((new-name (file-name-nondirectory buffer-file-name)))
	(if (string= new-name "")
	    (error "Empty file name"))
	(if (eq system-type 'vax-vms)
	    (setq new-name (downcase new-name)))
	(setq default-directory (file-name-directory buffer-file-name))
	(rename-buffer new-name t)))
  (setq buffer-backed-up nil)
  (clear-visited-file-modtime)
  ;; write-file-hooks is normally used for things like ftp-find-file
  ;; that visit things that are not local files as if they were files.
  ;; Changing to visit an ordinary local file instead should flush the hook.
  (kill-local-variable 'write-file-hooks)
  (kill-local-variable 'revert-buffer-function)
  (kill-local-variable 'backup-inhibited)
  ;; Turn off backup files for certain file names.
  ;; Since this is a permanent local, the major mode won't eliminate it.
  (and (not (funcall backup-enable-predicate buffer-file-name))
       (progn
	 (make-local-variable 'backup-inhibited)
	 (setq backup-inhibited t)))
  ;; If auto-save was not already on, turn it on if appropriate.
  (if (not buffer-auto-save-file-name)
      (auto-save-mode (and buffer-file-name auto-save-default)))
  (if buffer-file-name
      (set-buffer-modified-p t)))

(defun write-file (filename)
  "Write current buffer into file FILENAME.
Makes buffer visit that file, and marks it not modified."
;;  (interactive "FWrite file: ")
  (interactive
   (list (if buffer-file-name
	     (read-file-name "Write file: "
				 nil nil nil nil)
	   (read-file-name "Write file: "
			       (cdr (assq 'default-directory
					  (buffer-local-variables)))
			       nil nil (buffer-name)))))
  (or (null filename) (string-equal filename "")
      (set-visited-file-name filename))
  (set-buffer-modified-p t)
  (save-buffer))

(defun backup-buffer ()
  "Make a backup of the disk file visited by the current buffer, if appropriate.
This is normally done before saving the buffer the first time.
If the value is non-nil, it is the result of `file-modes' on the original
file; this means that the caller, after saving the buffer, should change
the modes of the new file to agree with the old modes."
  (if (and make-backup-files (not backup-inhibited)
	   (not buffer-backed-up)
	   (file-exists-p buffer-file-name)
	   (memq (aref (elt (file-attributes buffer-file-name) 8) 0)
		 '(?- ?l)))
      (let ((real-file-name buffer-file-name)
	    backup-info backupname targets setmodes)
	;; If specified name is a symbolic link, chase it to the target.
	;; Thus we make the backups in the directory where the real file is.
	(while (let ((tem (file-symlink-p real-file-name)))
		 (if tem
		     (setq real-file-name
			   (expand-file-name tem
					     (file-name-directory real-file-name))))
		 tem))
	(setq backup-info (find-backup-file-name real-file-name)
	      backupname (car backup-info)
	      targets (cdr backup-info))
;;;     (if (file-directory-p buffer-file-name)
;;;         (error "Cannot save buffer in directory %s" buffer-file-name))
        (condition-case ()
	    (let ((delete-old-versions
		   ;; If have old versions to maybe delete,
		   ;; ask the user to confirm now, before doing anything.
		   ;; But don't actually delete til later.
		   (and targets
			(or trim-versions-without-asking
			    (y-or-n-p (format "Delete excess backup versions of %s? "
					      real-file-name))))))
	      ;; Actually write the back up file.
	      (condition-case ()
		  (if (or file-precious-flag
;			  (file-symlink-p buffer-file-name)
			  backup-by-copying
			  (and backup-by-copying-when-linked
			       (> (file-nlinks real-file-name) 1))
			  (and backup-by-copying-when-mismatch
			       (let ((attr (file-attributes real-file-name)))
				 (or (nth 9 attr)
				     (/= (nth 2 attr) (user-uid))))))
		      (copy-file real-file-name backupname t t)
; rename-file should delete old backup.
;		    (condition-case ()
;			(delete-file backupname)
;		      (file-error nil))
		    (rename-file real-file-name backupname t)
		    (setq setmodes (file-modes backupname)))
		(file-error
		 ;; If trouble writing the backup, write it in ~.
		 (setq backupname (expand-file-name "~/%backup%~"))
		 (message "Cannot write backup file; backing up in ~/%%backup%%~")
		 (sleep-for 1)
		 (copy-file real-file-name backupname t t)))
	      (setq buffer-backed-up t)
	      ;; Now delete the old versions, if desired.
	      (if delete-old-versions
		  (while targets
		    (condition-case ()
			(delete-file (car targets))
		      (file-error nil))
		    (setq targets (cdr targets))))
	      setmodes)
	(file-error nil)))))

(defun file-name-sans-versions (name)
  "Return FILENAME sans backup versions or strings.
This is a separate procedure so your site-init or startup file can
redefine it."
  (substring name 0
             (if (eq system-type 'vax-vms)
		 ;; VMS version number is (a) semicolon, optional
		 ;; sign, zero or more digits or (b) period, option
		 ;; sign, zero or more digits, provided this is the
		 ;; second period encountered outside of the
		 ;; device/directory part of the file name.
                 (or (string-match ";[---+]?[0-9]*\\'" name)
                     (if (string-match "\\.[^]>:]*\\(\\.[---+]?[0-9]*\\)\\'"
                                       name)
                         (match-beginning 1))
                     (length name))
               (or (string-match "\\.~[0-9]+~\\'" name)
                   (string-match "~\\'" name)
                   (length name)))))

(defun make-backup-file-name (file)
  "Create the non-numeric backup file name for FILE.
This is a separate function so you can redefine it for customization."
  (concat file "~"))

(defun backup-file-name-p (file)
  "Return non-nil if FILE is a backup file name (numeric or not).
This is a separate function so you can redefine it for customization.
You may need to redefine `file-name-sans-versions' as well."
  (string-match "~$" file))

;; I believe there is no need to alter this behavior for VMS;
;; since backup files are not made on VMS, it should not get called.
(defun find-backup-file-name (fn)
  "Find a file name for a backup file, and suggestions for deletions.
Value is a list whose car is the name for the backup file
 and whose cdr is a list of old versions to consider deleting now."
  (if (eq version-control 'never)
      (list (make-backup-file-name fn))
    (let* ((base-versions (concat (file-name-nondirectory fn) ".~"))
	   (bv-length (length base-versions))
	   (possibilities (file-name-all-completions
			   base-versions
			   (file-name-directory fn)))
	   (versions (sort (mapcar 'backup-extract-version possibilities)
			   '<))
	   (high-water-mark (apply 'max 0 versions))
	   (deserve-versions-p
	    (or version-control
		(> high-water-mark 0)))
	   (number-to-delete (- (length versions)
				kept-old-versions kept-new-versions -1)))
      (if (not deserve-versions-p)
	  (list (make-backup-file-name fn))
	(cons (concat fn ".~" (int-to-string (1+ high-water-mark)) "~")
	      (if (> number-to-delete 0)
		  (mapcar (function (lambda (n)
				      (concat fn ".~" (int-to-string n) "~")))
			  (let ((v (nthcdr kept-old-versions versions)))
			    (rplacd (nthcdr (1- number-to-delete) v) ())
			    v))))))))

(defun backup-extract-version (fn)
  (if (and (string-match "[0-9]+~$" fn bv-length)
	   (= (match-beginning 0) bv-length))
      (string-to-int (substring fn bv-length -1))
      0))

(defun file-nlinks (filename)
  "Return number of names file FILENAME has."
  (car (cdr (file-attributes filename))))

(defun save-buffer (&optional args)
  "Save current buffer in visited file if modified.  Versions described below.
By default, makes the previous version into a backup file
 if previously requested or if this is the first save.
With 1 or 3 \\[universal-argument]'s, marks this version
 to become a backup when the next save is done.
With 2 or 3 \\[universal-argument]'s,
 unconditionally makes the previous version into a backup file.
With argument of 0, never makes the previous version into a backup file.

If a file's name is FOO, the names of its numbered backup versions are
 FOO.~i~ for various integers i.  A non-numbered backup file is called FOO~.
Numeric backups (rather than FOO~) will be made if value of
 `version-control' is not the atom `never' and either there are already
 numeric versions of the file being backed up, or `version-control' is
 non-nil.
We don't want excessive versions piling up, so there are variables
 `kept-old-versions', which tells Emacs how many oldest versions to keep,
 and `kept-new-versions', which tells how many newest versions to keep.
 Defaults are 2 old versions and 2 new.
`dired-kept-versions' controls dired's clean-directory (.) command.
If `trim-versions-without-asking' is nil, system will query user
 before trimming versions.  Otherwise it does it silently."
  (interactive "p")
  (let ((modp (buffer-modified-p))
	(large (> (buffer-size) 50000))
	(make-backup-files (and make-backup-files (not (eq args 0)))))
    (and modp (memq args '(16 64)) (setq buffer-backed-up nil))
    (if (and modp large) (message "Saving file %s..." (buffer-file-name)))
    (basic-save-buffer)
    (and modp (memq args '(4 64)) (setq buffer-backed-up nil))))

(defun delete-auto-save-file-if-necessary (&optional force)
  "Delete auto-save file for current buffer if `delete-auto-save-files' is t.
Normally delete only if the file was written by this Emacs since
the last real save, but optional arg FORCE non-nil means delete anyway."
  (and buffer-auto-save-file-name delete-auto-save-files
       (not (string= buffer-file-name buffer-auto-save-file-name))
       (or force (recent-auto-save-p))
       (progn
	 (condition-case ()
	     (delete-file buffer-auto-save-file-name)
	   (file-error nil))
	 (set-buffer-auto-saved))))

(defun basic-save-buffer ()
  "Save the current buffer in its visited file, if it has been modified."
  (interactive)
  (if (buffer-modified-p)
      (let ((recent-save (recent-auto-save-p))
	    setmodes tempsetmodes)
	;; On VMS, rename file and buffer to get rid of version number.
	(if (and (eq system-type 'vax-vms)
		 (not (string= buffer-file-name
			       (file-name-sans-versions buffer-file-name))))
	    (let (buffer-new-name)
	      ;; Strip VMS version number before save.
	      (setq buffer-file-name
		    (file-name-sans-versions buffer-file-name))
	      ;; Construct a (unique) buffer name to correspond.
	      (let ((buf (create-file-buffer (downcase buffer-file-name))))
		(setq buffer-new-name (buffer-name buf))
		(kill-buffer buf))
	      (rename-buffer buffer-new-name)))
	;; If buffer has no file name, ask user for one.
	(or buffer-file-name
	    (progn
	      (setq buffer-file-name
		    (expand-file-name (read-file-name "File to save in: ") nil)
		    default-directory (file-name-directory buffer-file-name))
	      (auto-save-mode auto-save-default)))
	(or (verify-visited-file-modtime (current-buffer))
	    (not (file-exists-p buffer-file-name))
	    (yes-or-no-p
	     (format "%s has changed since visited or saved.  Save anyway? "
		     (file-name-nondirectory buffer-file-name)))
	    (error "Save not confirmed"))
	(save-restriction
	  (widen)
	  (and (> (point-max) 1)
	       (/= (char-after (1- (point-max))) ?\n)
	       (or (eq require-final-newline t)
		   (and require-final-newline
			(y-or-n-p
			 (format "Buffer %s does not end in newline.  Add one? "
				 (buffer-name)))))
	       (save-excursion
		 (goto-char (point-max))
		 (insert ?\n)))
	  (let ((hooks (append write-contents-hooks write-file-hooks))
		(done nil))
	    (while (and hooks
			(not (setq done (funcall (car hooks)))))
	      (setq hooks (cdr hooks)))
	    ;; If a hook returned t, file is already "written".
	    (cond ((not done)
		   (if (not (file-writable-p buffer-file-name))
		       (let ((dir (file-name-directory buffer-file-name)))
			 (if (not (file-directory-p dir))
			     (error "%s is not a directory" dir)
			   (if (not (file-exists-p buffer-file-name))
			       (error "Directory %s write-protected" dir)
			     (if (yes-or-no-p
				  (format "File %s is write-protected; try to save anyway? "
					  (file-name-nondirectory
					   buffer-file-name)))
				 (setq tempsetmodes t)
			       (error "Attempt to save to a file which you aren't allowed to write"))))))
		   (or buffer-backed-up
		       (setq setmodes (backup-buffer)))
		   (if file-precious-flag
		       ;; If file is precious, rename it away before
		       ;; overwriting it.
		       (let ((rename t)
			     realname tempname temp)
			 ;; Chase symlinks; rename the ultimate actual file.
			 (setq realname buffer-file-name)
			 (while (setq temp (file-symlink-p realname))
			   (setq realname temp))
			 (setq tempname (concat realname "#"))
			 (condition-case ()
			     (progn (rename-file realname tempname t)
				    (setq setmodes (file-modes tempname)))
			   (file-error (setq rename nil tempname nil)))
			 (if (file-directory-p realname)
			     (error "%s is a directory" realname))
			 (unwind-protect
			     (progn (clear-visited-file-modtime)
				    (write-region (point-min) (point-max)
						  realname nil t)
				    (setq rename nil))
			   ;; If rename is still t, writing failed.
			   ;; So rename the old file back to original name,
			   (if rename
			       (progn
				 (rename-file tempname realname t)
				 (clear-visited-file-modtime))
			     ;; Otherwise we don't need the original file,
			     ;; so flush it, if we still have it.
			     ;; If rename failed due to name length restriction
			     ;; then TEMPNAME is now nil.
			     (if tempname
				 (condition-case ()
				     (delete-file tempname)
				   (error nil))))))
		     ;; If file not writable, see if we can make it writable
		     ;; temporarily while we write it.
		     ;; But no need to do so if we have just backed it up
		     ;; (setmodes is set) because that says we're superseding.
		     (cond ((and tempsetmodes (not setmodes))
			    ;; Change the mode back, after writing.
			    (setq setmodes (file-modes buffer-file-name))
			    (set-file-modes buffer-file-name 511)))
		     (write-region (point-min) (point-max)
				   buffer-file-name nil t)))))
	  (if setmodes
	      (condition-case ()
		   (set-file-modes buffer-file-name setmodes)
		(error nil))))
	;; If the auto-save file was recent before this command,
	;; delete it now.
	(delete-auto-save-file-if-necessary recent-save)
	(run-hooks 'after-save-hooks))
    (message "(No changes need to be saved)")))

(defun save-some-buffers (&optional arg exiting)
  "Save some modified file-visiting buffers.  Asks user about each one.
Optional argument (the prefix) non-nil means save all with no questions.
Optional second argument EXITING means ask about certain non-file buffers
 as well as about file buffers."
  (interactive "P")
  (save-excursion
    (if (zerop (map-y-or-n-p
		(function
		 (lambda (buffer)
		   (and (buffer-modified-p buffer)
			(or
			 (buffer-file-name buffer)
			 (and exiting
			      (progn
				(set-buffer buffer)
				(and buffer-offer-save (> (buffer-size) 0)))))
			(if arg
			    t
			  (if (buffer-file-name buffer)
			      (format "Save file %s? "
				      (buffer-file-name buffer))
			    (format "Save buffer %s? "
				    (buffer-name buffer)))))))
		(function
		 (lambda (buffer)
		   (set-buffer buffer)
		   (save-buffer)))
		(buffer-list)
		'("buffer" "buffers" "save")))
	(message "(No files need saving)"))))

(defun not-modified (&optional arg)
  "Mark current buffer as unmodified, not needing to be saved.
With prefix arg, mark buffer as modified, so \\[save-buffer] will save."
  (interactive "P")
  (message (if arg "Modification-flag set"
	       "Modification-flag cleared"))
  (set-buffer-modified-p arg))

(defun toggle-read-only (&optional arg)
  "Change whether this buffer is visiting its file read-only.
With arg, set read-only iff arg is positive."
  (interactive "P")
  (setq buffer-read-only
	(if (null arg)
            (not buffer-read-only)
            (> (prefix-numeric-value arg) 0)))
  ;; Force mode-line redisplay
  (set-buffer-modified-p (buffer-modified-p)))

(defun insert-file (filename)
  "Insert contents of file FILENAME into buffer after point.
Set mark after the inserted text.

This function is meant for the user to run interactively.
Don't call it from programs!  Use `insert-file-contents' instead.
\(Its calling sequence is different; see its documentation)."
  (interactive "fInsert file: ")
  (let ((tem (insert-file-contents filename)))
    (push-mark (+ (point) (car (cdr tem))))))

(defun append-to-file (start end filename)
  "Append the contents of the region to the end of file FILENAME.
When called from a function, expects three arguments,
START, END and FILENAME.  START and END are buffer positions
saying what text to write."
  (interactive "r\nFAppend to file: ")
  (write-region start end filename t))

(defun file-newest-backup (filename)
  "Return most recent backup file for FILENAME or nil if no backups exist."
  (let* ((filename (expand-file-name filename))
	 (file (file-name-nondirectory filename))
	 (dir  (file-name-directory    filename))
	 (comp (file-name-all-completions file dir))
	 newest)
    (while comp
      (setq file (concat dir (car comp))
	    comp (cdr comp))
      (if (and (backup-file-name-p file)
	       (or (null newest) (file-newer-than-file-p file newest)))
	  (setq newest file)))
    newest))

(defun rename-uniquely ()
  "Rename current buffer to a similar name not already taken.
This function is useful for creating multiple shell process buffers
or multiple mail buffers, etc."
  (interactive)
  (let* ((new-buf (generate-new-buffer (buffer-name)))
	 (name (buffer-name new-buf)))
    (kill-buffer new-buf)
    (rename-buffer name)
    (set-buffer-modified-p (buffer-modified-p)))) ; force mode line update

(defun make-directory-path (path)
  "Create all the directories along path that don't exist yet."
  (interactive "Fdirectory path to create: ")
  (let ((path (directory-file-name (expand-file-name path)))
	create-list)
    (while (not (file-exists-p path))
      (setq create-list (cons path create-list)	    
	    path (directory-file-name (file-name-directory path))))
    (while create-list
      (make-directory (car create-list))
      (setq create-list (cdr create-list)))))


(put 'revert-buffer-function 'permanent-local t)
(defvar revert-buffer-function nil
  "Function to use to revert this buffer, or nil to do the default.")

(put 'revert-buffer-insert-file-contents-function 'permanent-local t)
(defvar revert-buffer-insert-file-contents-function nil
  "Function to use to insert contents when reverting this buffer.
Gets two args, first the nominal file name to use,
and second, t if reading the auto-save file.")

(defun revert-buffer (&optional check-auto noconfirm)
  "Replace the buffer text with the text of the visited file on disk.
This undoes all changes since the file was visited or saved.
With a prefix argument, offer to revert from latest auto-save file, if
that is more recent than the visited file.
When called from lisp, this is the first argument, CHECK-AUTO; it is optional.
Optional second argument NOCONFIRM means don't ask for confirmation at all.

If the value of `revert-buffer-function' is non-nil, it is called to
do the work."
  (interactive "P")
  (if revert-buffer-function
      (funcall revert-buffer-function (not check-auto) noconfirm)
    (let* ((opoint (point))
	   (auto-save-p (and check-auto (recent-auto-save-p)
			     buffer-auto-save-file-name
			     (file-readable-p buffer-auto-save-file-name)
			     (y-or-n-p
   "Buffer has been auto-saved recently.  Revert from auto-save file? ")))
	   (file-name (if auto-save-p
			  buffer-auto-save-file-name
			buffer-file-name)))
      (cond ((null file-name)
	     (error "Buffer does not seem to be associated with any file"))
	    ((or noconfirm
		 (yes-or-no-p (format "Revert buffer from file %s? "
				      file-name)))
	     ;; If file was backed up but has changed since,
	     ;; we shd make another backup.
	     (and (not auto-save-p)
		  (not (verify-visited-file-modtime (current-buffer)))
		  (setq buffer-backed-up nil))
	     ;; Get rid of all undo records for this buffer.
	     (or (eq buffer-undo-list t)
		 (setq buffer-undo-list nil))
	     (let ((buffer-read-only nil)
		   ;; Don't make undo records for the reversion.
		   (buffer-undo-list t))
	       (if revert-buffer-insert-file-contents-function
		   (funcall revert-buffer-insert-file-contents-function
			    file-name auto-save-p)
		 (if (not (file-exists-p file-name))
		     (error "File %s no longer exists!" file-name))
		 ;; Bind buffer-file-name to nil
		 ;; so that we don't try to lock the file.
		 (let ((buffer-file-name nil))
		   (or auto-save-p
		       (unlock-buffer))
		   (erase-buffer))
		 (insert-file-contents file-name (not auto-save-p))))
	     (goto-char (min opoint (point-max)))
	     (after-find-file nil)
	     t)))))

(defun recover-file (file)
  "Visit file FILE, but get contents from its last auto-save file."
  (interactive
   (let ((prompt-file buffer-file-name)
	 (file-name nil)
	 (file-dir nil))
     (and prompt-file
	  (setq file-name (file-name-nondirectory prompt-file)
		file-dir (file-name-directory prompt-file)))
     (list (read-file-name "Recover file: "
			       file-dir nil nil file-name))))
  (setq file (expand-file-name file))
  (if (auto-save-file-name-p file) (error "%s is an auto-save file" file))
  (let ((file-name (let ((buffer-file-name file))
		     (make-auto-save-file-name))))
    (cond ((not (file-newer-than-file-p file-name file))
	   (error "Auto-save file %s not current" file-name))
	  ((save-window-excursion
	     (if (not (eq system-type 'vax-vms))
		 (with-output-to-temp-buffer "*Directory*"
		   (buffer-disable-undo standard-output)
		   (call-process "ls" nil standard-output nil
				 "-l" file file-name)))
	     (yes-or-no-p (format "Recover auto save file %s? " file-name)))
	   (switch-to-buffer (find-file-noselect file t))
	   (let ((buffer-read-only nil))
	     (erase-buffer)
	     (insert-file-contents file-name nil))
	   (after-find-file nil))
	  (t (error "Recover-file cancelled.")))))

(defun kill-some-buffers ()
  "For each buffer, ask whether to kill it."
  (interactive)
  (let ((list (buffer-list)))
    (while list
      (let* ((buffer (car list))
	     (name (buffer-name buffer)))
	(and (not (string-equal name ""))
	     (/= (aref name 0) ? )
	     (yes-or-no-p
	      (format "Buffer %s %s.  Kill? "
		      name
		      (if (buffer-modified-p buffer)
			  "HAS BEEN EDITED" "is unmodified")))
	     (kill-buffer buffer)))
      (setq list (cdr list)))))

(defun auto-save-mode (arg)
  "Toggle auto-saving of contents of current buffer.
With ARG, turn auto-saving on if positive, else off."
  (interactive "P")
  (setq buffer-auto-save-file-name
        (and (if (null arg)
		 (not buffer-auto-save-file-name)
	       (or (eq arg t) (listp arg) (and (integerp arg) (> arg 0))))
	     (if (and buffer-file-name auto-save-visited-file-name
		      (not buffer-read-only))
		 buffer-file-name
	       (make-auto-save-file-name))))
  (if (interactive-p)
      (message "Auto-save %s (in this buffer)"
	       (if buffer-auto-save-file-name "on" "off")))
  buffer-auto-save-file-name)

(defun rename-auto-save-file ()
  "Adjust current buffer's auto save file name for current conditions.
Also rename any existing auto save file, if it was made in this session."
  (let ((osave buffer-auto-save-file-name))
    (setq buffer-auto-save-file-name
	  (make-auto-save-file-name))
    (if (and osave buffer-auto-save-file-name
	     (not (string= buffer-auto-save-file-name buffer-file-name))
	     (not (string= buffer-auto-save-file-name osave))
	     (file-exists-p osave)
	     (recent-auto-save-p))
	(rename-file osave buffer-auto-save-file-name t))))

(defun make-auto-save-file-name ()
  "Return file name to use for auto-saves of current buffer.
Does not consider `auto-save-visited-file-name' as that variable is checked
before calling this function.  You can redefine this for customization.
See also `auto-save-file-name-p'."
  (if buffer-file-name
      (concat (file-name-directory buffer-file-name)
	      "#"
	      (file-name-nondirectory buffer-file-name)
	      "#")
    ;; For non-file bfr, use bfr name and Emacs pid.
    (expand-file-name (format "#%s#%s#" (buffer-name) (make-temp-name "")))))

(defun auto-save-file-name-p (filename)
  "Return non-nil if FILENAME can be yielded by `make-auto-save-file-name'.
FILENAME should lack slashes.  You can redefine this for customization."
  (string-match "^#.*#$" filename))

(defconst list-directory-brief-switches
  (if (eq system-type 'vax-vms) "" "-CF")
  "*Switches for list-directory to pass to `ls' for brief listing,")

(defconst list-directory-verbose-switches
  (if (eq system-type 'vax-vms)
      "/PROTECTION/SIZE/DATE/OWNER/WIDTH=(OWNER:10)"
    "-l")
  "*Switches for list-directory to pass to `ls' for verbose listing,")

(defun list-directory (dirname &optional verbose)
  "Display a list of files in or matching DIRNAME, a la `ls'.
DIRNAME is globbed by the shell if necessary.
Prefix arg (second arg if noninteractive) means supply -l switch to `ls'.
Actions controlled by variables `list-directory-brief-switches'
and `list-directory-verbose-switches'."
  (interactive (let ((pfx current-prefix-arg))
		 (list (read-file-name (if pfx "List directory (verbose): "
					 "List directory (brief): ")
				       nil default-directory nil)
		       pfx)))
  (let ((switches (if verbose list-directory-verbose-switches
		    list-directory-brief-switches)))
    (or dirname (setq dirname default-directory))
    (setq dirname (expand-file-name dirname))
    (with-output-to-temp-buffer "*Directory*"
      (buffer-disable-undo standard-output)
      (princ "Directory ")
      (princ dirname)
      (terpri)
      (if (eq system-type 'vax-vms)
	  (vms-read-directory dirname switches standard-output)
	(if (file-directory-p dirname)
	    (save-excursion
	      (set-buffer "*Directory*")
	      (call-process "ls" nil standard-output nil switches
			    (setq default-directory
				  (file-name-as-directory dirname))))
	  (let ((default-directory (file-name-directory dirname)))
	    (if (file-exists-p default-directory)
		(call-process shell-file-name nil standard-output nil
			      "-c" (concat "exec ls "
					   switches " "
					   (file-name-nondirectory dirname)))
	      (princ "No such directory: ")
	      (princ dirname)
	      (terpri))))))))

(defun save-buffers-kill-emacs (&optional arg)
  "Offer to save each buffer, then kill this Emacs process.
With prefix arg, silently save all file-visiting buffers, then kill."
  (interactive "P")
  (save-some-buffers arg t)
  (and (or (not (memq t (mapcar (function
				  (lambda (buf) (and (buffer-file-name buf)
						     (buffer-modified-p buf))))
				(buffer-list))))
	   (yes-or-no-p "Modified buffers exist; exit anyway? "))
       (or (not (fboundp 'process-list))
	   ;; process-list is not defined on VMS.
	   (let ((processes (process-list))
		 active)
	     (while processes
	       (and (memq (process-status (car processes)) '(run stop))
		    (let ((val (process-kill-without-query (car processes))))
		      (process-kill-without-query (car processes) val)
		      val)
		    (setq active t))
	       (setq processes (cdr processes)))
	     (or (not active)
		 (yes-or-no-p "Active processes exist; kill them and exit anyway? "))))
       (kill-emacs)))

(define-key ctl-x-map "\C-f" 'find-file)
(define-key ctl-x-map "\C-q" 'toggle-read-only)
(define-key ctl-x-map "\C-r" 'find-file-read-only)
(define-key ctl-x-map "\C-v" 'find-alternate-file)
(define-key ctl-x-map "\C-s" 'save-buffer)
(define-key ctl-x-map "s" 'save-some-buffers)
(define-key ctl-x-map "\C-w" 'write-file)
(define-key ctl-x-map "i" 'insert-file)
(define-key esc-map "~" 'not-modified)
(define-key ctl-x-map "\C-d" 'list-directory)
(define-key ctl-x-map "\C-c" 'save-buffers-kill-emacs)

(define-key ctl-x-4-map "f" 'find-file-other-window)
(define-key ctl-x-4-map "r" 'find-file-read-only-other-window)
(define-key ctl-x-4-map "\C-f" 'find-file-other-window)
(define-key ctl-x-4-map "b" 'switch-to-buffer-other-window)
(define-key ctl-x-4-map "o" 'display-buffer)

(define-key ctl-x-5-map "b" 'switch-to-buffer-other-screen)
(define-key ctl-x-5-map "f" 'find-file-other-screen)
(define-key ctl-x-5-map "\C-f" 'find-file-other-screen)
(define-key ctl-x-5-map "r" 'find-file-read-only-other-screen)

;;; files.el ends here

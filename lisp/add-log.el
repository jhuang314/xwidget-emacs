;;; add-log.el --- change log maintenance commands for Emacs

;; Copyright (C) 1985, 1986, 1988, 1993, 1994 Free Software Foundation, Inc.

;; Keywords: maint

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
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

;; This facility is documented in the Emacs Manual.

;;; Code:

(defvar change-log-default-name nil
  "*Name of a change log file for \\[add-change-log-entry].")

(defvar add-log-current-defun-function nil
  "\
*If non-nil, function to guess name of current function from surrounding text.
\\[add-change-log-entry] calls this function (if nil, `add-log-current-defun'
instead) with no arguments.  It returns a string or nil if it cannot guess.")

;; This MUST not be autoloaded, since user-login-name
;; cannot be known at Emacs dump time.
(defvar add-log-full-name (user-full-name)
  "*Full name of user, for inclusion in ChangeLog daily headers.
This defaults to the value returned by the `user-full-name' function.")

;; This MUST not be autoloaded, since user-login-name
;; cannot be known at Emacs dump time.
(defvar add-log-mailing-address user-mail-address
  "*Electronic mail address of user, for inclusion in ChangeLog daily headers.
This defaults to the value of `user-mail-address'.")

(defun change-log-name ()
  (or change-log-default-name
      (if (eq system-type 'vax-vms) 
	  "$CHANGE_LOG$.TXT" 
	(if (eq system-type 'ms-dos)
	    "changelo"
	  "ChangeLog"))))

;;;###autoload
(defun prompt-for-change-log-name ()
  "Prompt for a change log name."
  (let ((default (change-log-name)))
    (expand-file-name
     (read-file-name (format "Log file (default %s): " default)
		     nil default))))

;;;###autoload
(defun find-change-log (&optional file-name)
  "Find a change log file for \\[add-change-log-entry] and return the name.

Optional arg FILE-NAME specifies the file to use.
If FILE-NAME is nil, use the value of `change-log-default-name' if non-nil.
Otherwise, search in the current directory and its successive parents
for a file named `ChangeLog' (or whatever we use on this operating system).

Once a file is found, `change-log-default-name' is set locally in the
current buffer to the complete file name."
  ;; If user specified a file name or if this buffer knows which one to use,
  ;; just use that.
  (or file-name
      (setq file-name change-log-default-name)
      (progn
	;; Chase links in the source file
	;; and use the change log in the dir where it points.
	(setq file-name (or (and buffer-file-name
				 (file-name-directory
				  (file-chase-links buffer-file-name)))
			    default-directory))
	(if (file-directory-p file-name)
	    (setq file-name (expand-file-name (change-log-name) file-name)))
	;; Chase links before visiting the file.
	;; This makes it easier to use a single change log file
	;; for several related directories.
	(setq file-name (file-chase-links file-name))
	(setq file-name (expand-file-name file-name))
	;; Move up in the dir hierarchy till we find a change log file.
	(let ((file1 file-name)
	      parent-dir)
	  (while (and (not (or (get-file-buffer file1) (file-exists-p file1)))
		      (progn (setq parent-dir
				   (file-name-directory
				    (directory-file-name
				     (file-name-directory file1))))
			     ;; Give up if we are already at the root dir.
			     (not (string= (file-name-directory file1)
					   parent-dir))))
	    ;; Move up to the parent dir and try again.
	    (setq file1 (expand-file-name 
			 (file-name-nondirectory (change-log-name))
			 parent-dir)))
	  ;; If we found a change log in a parent, use that.
	  (if (or (get-file-buffer file1) (file-exists-p file1))
	      (setq file-name file1)))))
  ;; Make a local variable in this buffer so we needn't search again.
  (set (make-local-variable 'change-log-default-name) file-name)
  file-name)

;;;###autoload
(defun add-change-log-entry (&optional whoami file-name other-window new-entry)
  "Find change log file and add an entry for today.
Optional arg (interactive prefix) non-nil means prompt for user name and site.
Second arg is file name of change log.  If nil, uses `change-log-default-name'.
Third arg OTHER-WINDOW non-nil means visit in other window.
Fourth arg NEW-ENTRY non-nil means always create a new entry at the front;
never append to an existing entry."
  (interactive (list current-prefix-arg
		     (prompt-for-change-log-name)))
  (if whoami
      (progn
	(setq add-log-full-name (read-input "Full name: " add-log-full-name))
	 ;; Note that some sites have room and phone number fields in
	 ;; full name which look silly when inserted.  Rather than do
	 ;; anything about that here, let user give prefix argument so that
	 ;; s/he can edit the full name field in prompter if s/he wants.
	(setq add-log-mailing-address
	      (read-input "Mailing address: " add-log-mailing-address))))
  (let ((defun (funcall (or add-log-current-defun-function
			    'add-log-current-defun)))
	paragraph-end entry)

    (setq file-name (find-change-log file-name))

    ;; Set ENTRY to the file name to use in the new entry.
    (and buffer-file-name
	 ;; Never want to add a change log entry for the ChangeLog file itself.
	 (not (string= buffer-file-name file-name))
	 (setq entry (if (string-match
			  (concat "^" (regexp-quote (file-name-directory
						     file-name)))
			  buffer-file-name)
			 (substring buffer-file-name (match-end 0))
		       (file-name-nondirectory buffer-file-name))))

    (if (and other-window (not (equal file-name buffer-file-name)))
	(find-file-other-window file-name)
      (find-file file-name))
    (or (eq major-mode 'change-log-mode)
	(change-log-mode))
    (undo-boundary)
    (goto-char (point-min))
    (if (looking-at (concat (regexp-quote (substring (current-time-string)
						     0 10))
			    ".* " (regexp-quote add-log-full-name)
			    "  (" (regexp-quote add-log-mailing-address)))
	(forward-line 1)
      (insert (current-time-string)
	      "  " add-log-full-name
	      "  (" add-log-mailing-address ")\n\n"))

    ;; Search only within the first paragraph.
    (if (looking-at "\n*[^\n* \t]")
	(skip-chars-forward "\n")
      (forward-paragraph 1))
    (setq paragraph-end (point))
    (goto-char (point-min))

    ;; Now insert the new line for this entry.
    (cond ((re-search-forward "^\\s *\\*\\s *$" paragraph-end t)
	   ;; Put this file name into the existing empty entry.
	   (if entry
	       (insert entry)))
	  ((and (not new-entry)
		(re-search-forward
		 (concat (regexp-quote (concat "* " entry))
			 ;; Don't accept `foo.bar' when
			 ;; looking for `foo':
			 "\\(\\s \\|[(),:]\\)")
		 paragraph-end t))
	   ;; Add to the existing entry for the same file.
	   (re-search-forward "^\\s *$\\|^\\s \\*")
	   (beginning-of-line)
	   (while (and (not (eobp)) (looking-at "^\\s *$"))
	     (delete-region (point) (save-excursion (forward-line 1) (point))))
	   (insert "\n\n")
	   (forward-line -2)
	   (indent-relative-maybe))
	  (t
	   ;; Make a new entry.
	   (forward-line 1)
	   (while (looking-at "\\sW")
	     (forward-line 1))
	   (while (and (not (eobp)) (looking-at "^\\s *$"))
	     (delete-region (point) (save-excursion (forward-line 1) (point))))
	   (insert "\n\n\n")
	   (forward-line -2)
	   (indent-to left-margin)
	   (insert "* " (or entry ""))))
    ;; Now insert the function name, if we have one.
    ;; Point is at the entry for this file,
    ;; either at the end of the line or at the first blank line.
    (if defun
	(progn
	  ;; Make it easy to get rid of the function name.
	  (undo-boundary)
	  (insert (if (save-excursion
			(beginning-of-line 1)
			(looking-at "\\s *$")) 
		      ""
		    " ")
		  "(" defun "): "))
      ;; No function name, so put in a colon unless we have just a star.
      (if (not (save-excursion
		 (beginning-of-line 1)
		 (looking-at "\\s *\\(\\*\\s *\\)?$")))
	  (insert ": ")))))

;;;###autoload
(defun add-change-log-entry-other-window (&optional whoami file-name)
  "Find change log file in other window and add an entry for today.
Optional arg (interactive prefix) non-nil means prompt for user name and site.
Second arg is file name of change log.  \
If nil, uses `change-log-default-name'."
  (interactive (if current-prefix-arg
		   (list current-prefix-arg
			 (prompt-for-change-log-name))))
  (add-change-log-entry whoami file-name t))
;;;###autoload (define-key ctl-x-4-map "a" 'add-change-log-entry-other-window)

;;;###autoload
(defun change-log-mode ()
  "Major mode for editing change logs; like Indented Text Mode.
Prevents numeric backups and sets `left-margin' to 8 and `fill-column' to 74.
New log entries are usually made with \\[add-change-log-entry] or \\[add-change-log-entry-other-window].
Each entry behaves as a paragraph, and the entries for one day as a page.
Runs `change-log-mode-hook'."
  (interactive)
  (kill-all-local-variables)
  (indented-text-mode)
  (setq major-mode 'change-log-mode
	mode-name "Change Log"
	left-margin 8
	fill-column 74)
  (use-local-map change-log-mode-map)
  ;; Let each entry behave as one paragraph:
  (set (make-local-variable 'paragraph-start) "^\\s *$\\|^\f")
  (set (make-local-variable 'paragraph-separate) "^\\s *$\\|^\f\\|^\\sw")
  ;; Let all entries for one day behave as one page.
  ;; Match null string on the date-line so that the date-line
  ;; is grouped with what follows.
  (set (make-local-variable 'page-delimiter) "^\\<\\|^\f")
  (set (make-local-variable 'version-control) 'never)
  (set (make-local-variable 'adaptive-fill-regexp) "\\s *")
  (run-hooks 'change-log-mode-hook))

(defvar change-log-mode-map nil
  "Keymap for Change Log major mode.")
(if change-log-mode-map
    nil
  (setq change-log-mode-map (make-sparse-keymap))
  (define-key change-log-mode-map "\M-q" 'change-log-fill-paragraph))

;; It might be nice to have a general feature to replace this.  The idea I
;; have is a variable giving a regexp matching text which should not be
;; moved from bol by filling.  change-log-mode would set this to "^\\s *\\s(".
;; But I don't feel up to implementing that today.
(defun change-log-fill-paragraph (&optional justify)
  "Fill the paragraph, but preserve open parentheses at beginning of lines.
Prefix arg means justify as well."
  (interactive "P")
  (let ((paragraph-separate (concat paragraph-separate "\\|^\\s *\\s("))
	(paragraph-start (concat paragraph-start "\\|^\\s *\\s(")))
    (fill-paragraph justify)))

(defvar add-log-current-defun-header-regexp
  "^\\([A-Z][A-Z_ ]*[A-Z_]\\|[-_a-zA-Z]+\\)[ \t]*[:=]"
  "*Heuristic regexp used by `add-log-current-defun' for unknown major modes.")

;;;###autoload
(defun add-log-current-defun ()
  "Return name of function definition point is in, or nil.

Understands C, Lisp, LaTeX (\"functions\" are chapters, sections, ...),
Texinfo (@node titles), and Fortran.

Other modes are handled by a heuristic that looks in the 10K before
point for uppercase headings starting in the first column or
identifiers followed by `:' or `=', see variable
`add-log-current-defun-header-regexp'.

Has a preference of looking backwards."
  (condition-case nil
      (save-excursion
	(let ((location (point)))
	  (cond ((memq major-mode '(emacs-lisp-mode lisp-mode scheme-mode))
		 ;; If we are now precisely a the beginning of a defun,
		 ;; make sure beginning-of-defun finds that one
		 ;; rather than the previous one.
		 (or (eobp) (forward-char 1))
		 (beginning-of-defun)
		 ;; Make sure we are really inside the defun found, not after it.
		 (if (and (progn (end-of-defun)
				 (< location (point)))
			  (progn (forward-sexp -1)
				 (>= location (point))))
		     (progn
		       (if (looking-at "\\s(")
			   (forward-char 1))
		       (forward-sexp 1)
		       (skip-chars-forward " ")
		       (buffer-substring (point)
					 (progn (forward-sexp 1) (point))))))
		((and (memq major-mode '(c-mode c++-mode c++-c-mode))
		      (save-excursion (beginning-of-line)
				      ;; Use eq instead of = here to avoid
				      ;; error when at bob and char-after
				      ;; returns nil.
				      (while (eq (char-after (- (point) 2)) ?\\)
					(forward-line -1))
				      (looking-at "[ \t]*#[ \t]*define[ \t]")))
		 ;; Handle a C macro definition.
		 (beginning-of-line)
		 (while (eq (char-after (- (point) 2)) ?\\) ;not =; note above
		   (forward-line -1))
		 (search-forward "define")
		 (skip-chars-forward " \t")
		 (buffer-substring (point)
				   (progn (forward-sexp 1) (point))))
		((memq major-mode '(c-mode c++-mode c++-c-mode))
		 (beginning-of-line)
		 ;; See if we are in the beginning part of a function,
		 ;; before the open brace.  If so, advance forward.
		 (while (not (looking-at "{\\|\\(\\s *$\\)"))
		   (forward-line 1))
		 (or (eobp)
		     (forward-char 1))
		 (beginning-of-defun)
		 (if (progn (end-of-defun)
			    (< location (point)))
		     (progn
		       (backward-sexp 1)
		       (let (beg tem)

			 (forward-line -1)
			 ;; Skip back over typedefs of arglist.
			 (while (and (not (bobp))
				     (looking-at "[ \t\n]"))
			   (forward-line -1))
			 ;; See if this is using the DEFUN macro used in Emacs,
			 ;; or the DEFUN macro used by the C library.
			 (if (condition-case nil
				 (and (save-excursion
					(forward-line 1)
					(backward-sexp 1)
					(beginning-of-line)
					(setq tem (point))
					(looking-at "DEFUN\\b"))
				      (>= location tem))
			       (error nil))
			     (progn
			       (goto-char tem)
			       (down-list 1)
			       (if (= (char-after (point)) ?\")
				   (progn
				     (forward-sexp 1)
				     (skip-chars-forward " ,")))
			       (buffer-substring (point)
						 (progn (forward-sexp 1) (point))))
			   ;; Ordinary C function syntax.
			   (setq beg (point))
			   (if (condition-case nil
				   ;; Protect against "Unbalanced parens" error.
				   (progn
				     (down-list 1) ; into arglist
				     (backward-up-list 1)
				     (skip-chars-backward " \t")
				     t)
				 (error nil))
			       ;; Verify initial pos was after
			       ;; real start of function.
			       (if (and (save-excursion
					  (goto-char beg)
					  ;; For this purpose, include the line
					  ;; that has the decl keywords.  This
					  ;; may also include some of the
					  ;; comments before the function.
					  (while (and (not (bobp))
						      (save-excursion
							(forward-line -1)
							(looking-at "[^\n\f]")))
					    (forward-line -1))
					  (>= location (point)))
					;; Consistency check: going down and up
					;; shouldn't take us back before BEG.
					(> (point) beg))
				   (buffer-substring (point)
						     (progn (backward-sexp 1)
							    (point))))))))))
		((memq major-mode
		       '(TeX-mode plain-TeX-mode LaTeX-mode;; tex-mode.el
				  plain-tex-mode latex-mode;; cmutex.el
				  ))
		 (if (re-search-backward
		      "\\\\\\(sub\\)*\\(section\\|paragraph\\|chapter\\)" nil t)
		     (progn
		       (goto-char (match-beginning 0))
		       (buffer-substring (1+ (point));; without initial backslash
					 (progn
					   (end-of-line)
					   (point))))))
		((eq major-mode 'texinfo-mode)
		 (if (re-search-backward "^@node[ \t]+\\([^,]+\\)," nil t)
		     (buffer-substring (match-beginning 1)
				       (match-end 1))))
                ((eq major-mode 'fortran-mode)
                 ;; must be inside function body for this to work
                 (beginning-of-fortran-subprogram)
                 (let ((case-fold-search t)) ; case-insensitive
                   ;; search for fortran subprogram start
                   (if (re-search-forward
			 "^[ \t]*\\(program\\|subroutine\\|function\
\\|[ \ta-z0-9*]*[ \t]+function\\)"
			 nil t)
                       (progn
                         ;; move to EOL or before first left paren
                         (if (re-search-forward "[(\n]" nil t)
			     (progn (forward-char -1)
				    (skip-chars-backward " \t"))
			   (end-of-line))
			 ;; Use the name preceding that.
                         (buffer-substring (point)
                                           (progn (forward-sexp -1)
                                                  (point)))))))
		(t
		 ;; If all else fails, try heuristics
		 (let (case-fold-search)
		   (end-of-line)
		   (if (re-search-backward add-log-current-defun-header-regexp
					   (- (point) 10000)
					   t)
		       (buffer-substring (match-beginning 1)
					 (match-end 1))))))))
    (error nil)))


(provide 'add-log)

;;; add-log.el ends here

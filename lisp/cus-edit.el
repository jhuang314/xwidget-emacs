;;; cus-edit.el --- Tools for customization Emacs.
;;
;; Copyright (C) 1996, 1997 Free Software Foundation, Inc.
;;
;; Author: Per Abrahamsen <abraham@dina.kvl.dk>
;; Keywords: help, faces
;; Version: 1.9901
;; X-URL: http://www.dina.kvl.dk/~abraham/custom/

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

;;; Commentary:
;;
;; This file implements the code to create and edit customize buffers.
;; 
;; See `custom.el'.

;;; Code:

(require 'cus-face)
(require 'cus-start)
(require 'wid-edit)
(require 'easymenu)
(eval-when-compile (require 'cl))

(condition-case nil
    (require 'cus-load)
  (error nil))

(define-widget-keywords :custom-prefixes :custom-menu :custom-show
  :custom-magic :custom-state :custom-level :custom-form
  :custom-set :custom-save :custom-reset-current :custom-reset-saved 
  :custom-reset-standard)

(put 'custom-define-hook 'custom-type 'hook)
(put 'custom-define-hook 'standard-value '(nil))
(custom-add-to-group 'customize 'custom-define-hook 'custom-variable)

;;; Customization Groups.

(defgroup emacs nil
  "Customization of the One True Editor."
  :link '(custom-manual "(emacs)Top"))

;; Most of these groups are stolen from `finder.el',
(defgroup editing nil
  "Basic text editing facilities."
  :group 'emacs)

(defgroup abbrev nil
  "Abbreviation handling, typing shortcuts, macros."
  :tag "Abbreviations"
  :group 'editing)

(defgroup matching nil
  "Various sorts of searching and matching."
  :group 'editing)

(defgroup emulations nil
  "Emulations of other editors."
  :group 'editing)

(defgroup mouse nil
  "Mouse support."
  :group 'editing)

(defgroup outlines nil
  "Support for hierarchical outlining."
  :group 'editing)

(defgroup external nil
  "Interfacing to external utilities."
  :group 'emacs)

(defgroup bib nil
  "Code related to the `bib' bibliography processor."
  :tag "Bibliography"
  :group 'external)

(defgroup processes nil
  "Process, subshell, compilation, and job control support."
  :group 'external
  :group 'development)

(defgroup programming nil
  "Support for programming in other languages."
  :group 'emacs)

(defgroup languages nil
  "Specialized modes for editing programming languages."
  :group 'programming)

(defgroup lisp nil
  "Lisp support, including Emacs Lisp."
  :group 'languages
  :group 'development)

(defgroup c nil
  "Support for the C language and related languages."
  :group 'languages)

(defgroup tools nil
  "Programming tools."
  :group 'programming)

(defgroup oop nil
  "Support for object-oriented programming."
  :group 'programming)

(defgroup applications nil
  "Applications written in Emacs."
  :group 'emacs)

(defgroup calendar nil
  "Calendar and time management support."
  :group 'applications)

(defgroup mail nil
  "Modes for electronic-mail handling."
  :group 'applications)

(defgroup news nil
  "Support for netnews reading and posting."
  :group 'applications)

(defgroup games nil
  "Games, jokes and amusements."
  :group 'applications)

(defgroup development nil
  "Support for further development of Emacs."
  :group 'emacs)

(defgroup docs nil
  "Support for Emacs documentation."
  :group 'development)

(defgroup extensions nil
  "Emacs Lisp language extensions."
  :group 'development)

(defgroup internal nil
  "Code for Emacs internals, build process, defaults."
  :group 'development)

(defgroup maint nil
  "Maintenance aids for the Emacs development group."
  :tag "Maintenance"
  :group 'development)

(defgroup environment nil
  "Fitting Emacs with its environment."
  :group 'emacs)

(defgroup comm nil
  "Communications, networking, remote access to files."
  :tag "Communication"
  :group 'environment)

(defgroup hardware nil
  "Support for interfacing with exotic hardware."
  :group 'environment)

(defgroup terminals nil
  "Support for terminal types."
  :group 'environment)

(defgroup unix nil
  "Front-ends/assistants for, or emulators of, UNIX features."
  :group 'environment)

(defgroup vms nil
  "Support code for vms."
  :group 'environment)

(defgroup i18n nil
  "Internationalization and alternate character-set support."
  :group 'environment
  :group 'editing)

(defgroup x nil
  "The X Window system."
  :group 'environment)

(defgroup frames nil
  "Support for Emacs frames and window systems."
  :group 'environment)

(defgroup data nil
  "Support editing files of data."
  :group 'emacs)

(defgroup wp nil
  "Word processing."
  :group 'emacs)

(defgroup tex nil
  "Code related to the TeX formatter."
  :group 'wp)

(defgroup faces nil
  "Support for multiple fonts."
  :group 'emacs)

(defgroup hypermedia nil
  "Support for links between text or other media types."
  :group 'emacs)

(defgroup help nil
  "Support for on-line help systems."
  :group 'emacs)

(defgroup local nil
  "Code local to your site."
  :group 'emacs)

(defgroup customize '((widgets custom-group))
  "Customization of the Customization support."
  :link '(custom-manual "(custom)Top")
  :link '(url-link :tag "Development Page" 
		   "http://www.dina.kvl.dk/~abraham/custom/")
  :prefix "custom-"
  :group 'help)

(defgroup custom-faces nil
  "Faces used by customize."
  :group 'customize
  :group 'faces)

(defgroup abbrev-mode nil
  "Word abbreviations mode."
  :group 'abbrev)

(defgroup alloc nil
  "Storage allocation and gc for GNU Emacs Lisp interpreter."
  :tag "Storage Allocation"
  :group 'internal)

(defgroup undo nil
  "Undoing changes in buffers."
  :group 'editing)

(defgroup modeline nil
  "Content of the modeline."
  :group 'environment)

(defgroup fill nil
  "Indenting and filling text."
  :group 'editing)

(defgroup editing-basics nil
  "Most basic editing facilities."
  :group 'editing)

(defgroup display nil
  "How characters are displayed in buffers."
  :group 'environment)

(defgroup execute nil
  "Executing external commands."
  :group 'processes)

(defgroup installation nil
  "The Emacs installation."
  :group 'environment)

(defgroup dired nil
  "Directory editing."
  :group 'environment)

(defgroup limits nil
  "Internal Emacs limits."
  :group 'internal)

(defgroup debug nil
  "Debugging Emacs itself."
  :group 'development)

(defgroup minibuffer nil
  "Controling the behaviour of the minibuffer."
  :group 'environment)

(defgroup keyboard nil
  "Input from the keyboard."
  :group 'environment)

(defgroup mouse nil
  "Input from the mouse."
  :group 'environment)

(defgroup menu nil
  "Input from the menus."
  :group 'environment)

(defgroup auto-save nil
  "Preventing accidential loss of data."
  :group 'data)

(defgroup processes-basics nil
  "Basic stuff dealing with processes."
  :group 'processes)

(defgroup mule nil
  "MULE Emacs internationalization."
  :group 'i18n)

(defgroup windows nil
  "Windows within a frame."
  :group 'environment)

;;; Utilities.

(defun custom-quote (sexp)
  "Quote SEXP iff it is not self quoting."
  (if (or (memq sexp '(t nil))
	  (and (symbolp sexp)
	       (eq (aref (symbol-name sexp) 0) ?:))
	  (and (listp sexp)
	       (memq (car sexp) '(lambda)))
	  (stringp sexp)
	  (numberp sexp)
	  (and (fboundp 'characterp)
	       (characterp sexp)))
      sexp
    (list 'quote sexp)))

(defun custom-split-regexp-maybe (regexp)
  "If REGEXP is a string, split it to a list at `\\|'.
You can get the original back with from the result with: 
  (mapconcat 'identity result \"\\|\")

IF REGEXP is not a string, return it unchanged."
  (if (stringp regexp)
      (let ((start 0)
	    all)
	(while (string-match "\\\\|" regexp start)
	  (setq all (cons (substring regexp start (match-beginning 0)) all)
		start (match-end 0)))
	(nreverse (cons (substring regexp start) all)))
    regexp))

(defun custom-variable-prompt ()
  ;; Code stolen from `help.el'.
  "Prompt for a variable, defaulting to the variable at point.
Return a list suitable for use in `interactive'."
   (let ((v (variable-at-point))
	 (enable-recursive-minibuffers t)
	 val)
     (setq val (completing-read 
		(if v
		    (format "Customize variable: (default %s) " v)
		  "Customize variable: ")
		obarray (lambda (symbol)
			  (and (boundp symbol)
			       (or (get symbol 'custom-type)
				   (user-variable-p symbol))))))
     (list (if (equal val "")
	       v (intern val)))))

(defun custom-menu-filter (menu widget)
  "Convert MENU to the form used by `widget-choose'.
MENU should be in the same format as `custom-variable-menu'.
WIDGET is the widget to apply the filter entries of MENU on."
  (let ((result nil)
	current name action filter)
    (while menu 
      (setq current (car menu)
	    name (nth 0 current)
	    action (nth 1 current)
	    filter (nth 2 current)
	    menu (cdr menu))
      (if (or (null filter) (funcall filter widget))
	  (push (cons name action) result)
	(push name result)))
    (nreverse result)))

;;; Unlispify.

(defvar custom-prefix-list nil
  "List of prefixes that should be ignored by `custom-unlispify'")

(defcustom custom-unlispify-menu-entries t
  "Display menu entries as words instead of symbols if non nil."
  :group 'customize
  :type 'boolean)

(defun custom-unlispify-menu-entry (symbol &optional no-suffix)
  "Convert symbol into a menu entry."
  (cond ((not custom-unlispify-menu-entries)
	 (symbol-name symbol))
	((get symbol 'custom-tag)
	 (if no-suffix
	     (get symbol 'custom-tag)
	   (concat (get symbol 'custom-tag) "...")))
	(t
	 (save-excursion
	   (set-buffer (get-buffer-create " *Custom-Work*"))
	   (erase-buffer)
	   (princ symbol (current-buffer))
	   (goto-char (point-min))
	   (when (and (eq (get symbol 'custom-type) 'boolean)
		      (re-search-forward "-p\\'" nil t))
	     (replace-match "" t t)
	     (goto-char (point-min)))
	   (let ((prefixes custom-prefix-list)
		 prefix)
	     (while prefixes
	       (setq prefix (car prefixes))
	       (if (search-forward prefix (+ (point) (length prefix)) t)
		   (progn 
		     (setq prefixes nil)
		     (delete-region (point-min) (point)))
		 (setq prefixes (cdr prefixes)))))
	   (subst-char-in-region (point-min) (point-max) ?- ?\  t)
	   (capitalize-region (point-min) (point-max))
	   (unless no-suffix 
	     (goto-char (point-max))
	     (insert "..."))
	   (buffer-string)))))

(defcustom custom-unlispify-tag-names t
  "Display tag names as words instead of symbols if non nil."
  :group 'customize
  :type 'boolean)

(defun custom-unlispify-tag-name (symbol)
  "Convert symbol into a menu entry."
  (let ((custom-unlispify-menu-entries custom-unlispify-tag-names))
    (custom-unlispify-menu-entry symbol t)))

(defun custom-prefix-add (symbol prefixes)
  ;; Addd SYMBOL to list of ignored PREFIXES.
  (cons (or (get symbol 'custom-prefix)
	    (concat (symbol-name symbol) "-"))
	prefixes))

;;; Guess.

(defcustom custom-guess-name-alist
  '(("-p\\'" boolean)
    ("-hook\\'" hook)
    ("-face\\'" face)
    ("-file\\'" file)
    ("-function\\'" function)
    ("-functions\\'" (repeat function))
    ("-list\\'" (repeat sexp))
    ("-alist\\'" (repeat (cons sexp sexp))))
  "Alist of (MATCH TYPE).

MATCH should be a regexp matching the name of a symbol, and TYPE should 
be a widget suitable for editing the value of that symbol.  The TYPE
of the first entry where MATCH matches the name of the symbol will be
used. 

This is used for guessing the type of variables not declared with
customize."
  :type '(repeat (group (regexp :tag "Match") (sexp :tag "Type")))
  :group 'customize)

(defcustom custom-guess-doc-alist
  '(("\\`\\*?Non-nil " boolean))
  "Alist of (MATCH TYPE).

MATCH should be a regexp matching a documentation string, and TYPE
should be a widget suitable for editing the value of a variable with
that documentation string.  The TYPE of the first entry where MATCH
matches the name of the symbol will be used.

This is used for guessing the type of variables not declared with
customize."
  :type '(repeat (group (regexp :tag "Match") (sexp :tag "Type")))
  :group 'customize)

(defun custom-guess-type (symbol)
  "Guess a widget suitable for editing the value of SYMBOL.
This is done by matching SYMBOL with `custom-guess-name-alist' and 
if that fails, the doc string with `custom-guess-doc-alist'."
  (let ((name (symbol-name symbol))
	(names custom-guess-name-alist)
	current found)
    (while names
      (setq current (car names)
	    names (cdr names))
      (when (string-match (nth 0 current) name)
	(setq found (nth 1 current)
	      names nil)))
    (unless found
      (let ((doc (documentation-property symbol 'variable-documentation))
	    (docs custom-guess-doc-alist))
	(when doc 
	  (while docs
	    (setq current (car docs)
		  docs (cdr docs))
	    (when (string-match (nth 0 current) doc)
	      (setq found (nth 1 current)
		    docs nil))))))
    found))

;;; Sorting.

(defcustom custom-buffer-sort-predicate 'custom-buffer-sort-alphabetically
  "Function used for sorting group members in buffers.
The value should be useful as a predicate for `sort'.  
The list to be sorted is the value of the groups `custom-group' property."
  :type '(radio (function-item custom-buffer-sort-alphabetically)
		(function :tag "Other"))
  :group 'customize)

(defun custom-buffer-sort-alphabetically (a b)
  "Return t iff is A should be before B.
A and B should be members of a `custom-group' property. 
The members are sorted alphabetically, except that all groups are
sorted after all non-groups."
  (cond ((and (eq (nth 1 a) 'custom-group) 
	      (not (eq (nth 1 b) 'custom-group)))
	 nil)
	((and (eq (nth 1 b) 'custom-group) 
	      (not (eq (nth 1 a) 'custom-group)))
	 t)
	(t
	 (string-lessp (symbol-name (nth 0 a)) (symbol-name (nth 0 b))))))

(defcustom custom-menu-sort-predicate 'custom-menu-sort-alphabetically
  "Function used for sorting group members in menus.
The value should be useful as a predicate for `sort'.  
The list to be sorted is the value of the groups `custom-group' property."
  :type '(radio (function-item custom-menu-sort-alphabetically)
		(function :tag "Other"))
  :group 'customize)

(defun custom-menu-sort-alphabetically (a b)
  "Return t iff is A should be before B.
A and B should be members of a `custom-group' property. 
The members are sorted alphabetically, except that all groups are
sorted before all non-groups."
  (cond ((and (eq (nth 1 a) 'custom-group) 
	      (not (eq (nth 1 b) 'custom-group)))
	 t)
	((and (eq (nth 1 b) 'custom-group) 
	      (not (eq (nth 1 a) 'custom-group)))
	 nil)
	(t
	 (string-lessp (symbol-name (nth 0 a)) (symbol-name (nth 0 b))))))

;;; Custom Mode Commands.

(defvar custom-options nil
  "Customization widgets in the current buffer.")

(defun custom-set ()
  "Set changes in all modified options."
  (interactive)
  (let ((children custom-options))
    (mapcar (lambda (child)
	      (when (eq (widget-get child :custom-state) 'modified)
		(widget-apply child :custom-set)))
	    children)))

(defun custom-save ()
  "Set all modified group members and save them."
  (interactive)
  (let ((children custom-options))
    (mapcar (lambda (child)
	      (when (memq (widget-get child :custom-state) '(modified set))
		(widget-apply child :custom-save)))
	    children))
  (custom-save-all))

(defvar custom-reset-menu 
  '(("Current" . custom-reset-current)
    ("Saved" . custom-reset-saved)
    ("Standard Settings" . custom-reset-standard))
  "Alist of actions for the `Reset' button.
The key is a string containing the name of the action, the value is a
lisp function taking the widget as an element which will be called
when the action is chosen.")

(defun custom-reset (event)
  "Select item from reset menu."
  (let* ((completion-ignore-case t)
	 (answer (widget-choose "Reset to"
				custom-reset-menu
				event)))
    (if answer
	(funcall answer))))

(defun custom-reset-current ()
  "Reset all modified group members to their current value."
  (interactive)
  (let ((children custom-options))
    (mapcar (lambda (child)
	      (when (eq (widget-get child :custom-state) 'modified)
		(widget-apply child :custom-reset-current)))
	    children)))

(defun custom-reset-saved ()
  "Reset all modified or set group members to their saved value."
  (interactive)
  (let ((children custom-options))
    (mapcar (lambda (child)
	      (when (eq (widget-get child :custom-state) 'modified)
		(widget-apply child :custom-reset-current)))
	    children)))

(defun custom-reset-standard ()
  "Reset all modified, set, or saved group members to their standard settings."
  (interactive)
  (let ((children custom-options))
    (mapcar (lambda (child)
	      (when (eq (widget-get child :custom-state) 'modified)
		(widget-apply child :custom-reset-current)))
	    children)))

;;; The Customize Commands

(defun custom-prompt-variable (prompt-var prompt-val)
  "Prompt for a variable and a value and return them as a list.
PROMPT-VAR is the prompt for the variable, and PROMPT-VAL is the
prompt for the value.  The %s escape in PROMPT-VAL is replaced with
the name of the variable.

If the variable has a `variable-interactive' property, that is used as if
it were the arg to `interactive' (which see) to interactively read the value.

If the variable has a `custom-type' property, it must be a widget and the
`:prompt-value' property of that widget will be used for reading the value."
  (let* ((var (read-variable prompt-var))
	 (minibuffer-help-form '(describe-variable var)))
    (list var
	  (let ((prop (get var 'variable-interactive))
		(type (get var 'custom-type))
		(prompt (format prompt-val var)))
	    (unless (listp type)
	      (setq type (list type)))
	    (cond (prop
		   ;; Use VAR's `variable-interactive' property
		   ;; as an interactive spec for prompting.
		   (call-interactively (list 'lambda '(arg)
					     (list 'interactive prop)
					     'arg)))
		  (type
		   (widget-prompt-value type
					prompt
					(if (boundp var)
					    (symbol-value var))
					(not (boundp var))))
		  (t
		   (eval-minibuffer prompt)))))))

;;;###autoload
(defun custom-set-value (var val)
  "Set VARIABLE to VALUE.  VALUE is a Lisp object.

If VARIABLE has a `variable-interactive' property, that is used as if
it were the arg to `interactive' (which see) to interactively read the value.

If VARIABLE has a `custom-type' property, it must be a widget and the
`:prompt-value' property of that widget will be used for reading the value." 
  (interactive (custom-prompt-variable "Set variable: "
				       "Set %s to value: "))
   
  (set var val))

;;;###autoload
(defun custom-set-variable (var val)
  "Set the default for VARIABLE to VALUE.  VALUE is a Lisp object.

If VARIABLE has a `custom-set' property, that is used for setting
VARIABLE, otherwise `set-default' is used.

The `customized-value' property of the VARIABLE will be set to a list
with a quoted VALUE as its sole list member.

If VARIABLE has a `variable-interactive' property, that is used as if
it were the arg to `interactive' (which see) to interactively read the value.

If VARIABLE has a `custom-type' property, it must be a widget and the
`:prompt-value' property of that widget will be used for reading the value. " 
  (interactive (custom-prompt-variable "Set variable: "
				       "Set customized value for %s to: "))
  (funcall (or (get var 'custom-set) 'set-default) var val)
  (put var 'customized-value (list (custom-quote val))))

;;;###autoload
(defun customize ()
  "Select a customization buffer which you can use to set user options.
User options are structured into \"groups\".
Initially the top-level group `Emacs' and its immediate subgroups
are shown; the contents of those subgroups are initially hidden."
  (interactive)
  (customize-group 'emacs))

;;;###autoload
(defun customize-group (group)
  "Customize GROUP, which must be a customization group."
  (interactive (list (completing-read "Customize group: (default emacs) "
				      obarray 
				      (lambda (symbol)
					(get symbol 'custom-group))
				      t)))

  (when (stringp group)
    (if (string-equal "" group)
	(setq group 'emacs)
      (setq group (intern group))))
  (custom-buffer-create (list (list group 'custom-group))
			(format "*Customize Group: %s*"
				(custom-unlispify-tag-name group))))

;;;###autoload
(defun customize-group-other-window (symbol)
  "Customize SYMBOL, which must be a customization group."
  (interactive (list (completing-read "Customize group: (default emacs) "
				      obarray 
				      (lambda (symbol)
					(get symbol 'custom-group))
				      t)))

  (when (stringp symbol)
    (if (string-equal "" symbol)
	(setq symbol 'emacs)
      (setq symbol (intern symbol))))
  (custom-buffer-create-other-window
   (list (list symbol 'custom-group))
   (format "*Customize Group: %s*" (custom-unlispify-tag-name symbol))))

;;;###autoload
(defun customize-variable (symbol)
  "Customize SYMBOL, which must be a variable."
  (interactive (custom-variable-prompt))
  (custom-buffer-create (list (list symbol 'custom-variable))
			(format "*Customize Variable: %s*"
				(custom-unlispify-tag-name symbol))))

;;;###autoload
(defun customize-variable-other-window (symbol)
  "Customize SYMBOL, which must be a variable.
Show the buffer in another window, but don't select it."
  (interactive (custom-variable-prompt))
  (custom-buffer-create-other-window
   (list (list symbol 'custom-variable))
   (format "*Customize Variable: %s*" (custom-unlispify-tag-name symbol))))

;;;###autoload
(defun customize-face (&optional symbol)
  "Customize SYMBOL, which should be a face name or nil.
If SYMBOL is nil, customize all faces."
  (interactive (list (completing-read "Customize face: (default all) " 
				      obarray 'custom-facep)))
  (if (or (null symbol) (and (stringp symbol) (zerop (length symbol))))
      (let ((found nil))
	(message "Looking for faces...")
	(mapcar (lambda (symbol)
		  (setq found (cons (list symbol 'custom-face) found)))
		(nreverse (mapcar 'intern 
				  (sort (mapcar 'symbol-name (face-list))
					'string<))))
			
	(custom-buffer-create found "*Customize Faces*"))
    (if (stringp symbol)
	(setq symbol (intern symbol)))
    (unless (symbolp symbol)
      (error "Should be a symbol %S" symbol))
    (custom-buffer-create (list (list symbol 'custom-face))
			  (format "*Customize Face: %s*"
				  (custom-unlispify-tag-name symbol)))))

;;;###autoload
(defun customize-face-other-window (&optional symbol)
  "Show customization buffer for FACE in other window."
  (interactive (list (completing-read "Customize face: " 
				      obarray 'custom-facep)))
  (if (or (null symbol) (and (stringp symbol) (zerop (length symbol))))
      ()
    (if (stringp symbol)
	(setq symbol (intern symbol)))
    (unless (symbolp symbol)
      (error "Should be a symbol %S" symbol))
    (custom-buffer-create-other-window 
     (list (list symbol 'custom-face))
     (format "*Customize Face: %s*" (custom-unlispify-tag-name symbol)))))

;;;###autoload
(defun customize-customized ()
  "Customize all user options set since the last save in this session."
  (interactive)
  (let ((found nil))
    (mapatoms (lambda (symbol)
		(and (get symbol 'customized-face)
		     (custom-facep symbol)
		     (setq found (cons (list symbol 'custom-face) found)))
		(and (get symbol 'customized-value)
		     (boundp symbol)
		     (setq found
			   (cons (list symbol 'custom-variable) found)))))
    (if found 
	(custom-buffer-create found "*Customize Customized*")
      (error "No customized user options"))))

;;;###autoload
(defun customize-saved ()
  "Customize all already saved user options."
  (interactive)
  (let ((found nil))
    (mapatoms (lambda (symbol)
		(and (get symbol 'saved-face)
		     (custom-facep symbol)
		     (setq found (cons (list symbol 'custom-face) found)))
		(and (get symbol 'saved-value)
		     (boundp symbol)
		     (setq found
			   (cons (list symbol 'custom-variable) found)))))
    (if found 
	(custom-buffer-create found "*Customize Saved*")
      (error "No saved user options"))))

;;;###autoload
(defun customize-apropos (regexp &optional all)
  "Customize all user options matching REGEXP.
If ALL (e.g., started with a prefix key), include options which are not
user-settable."
  (interactive "sCustomize regexp: \nP")
  (let ((found nil))
    (mapatoms (lambda (symbol)
		(when (string-match regexp (symbol-name symbol))
		  (when (get symbol 'custom-group)
		    (setq found (cons (list symbol 'custom-group) found)))
		  (when (custom-facep symbol)
		    (setq found (cons (list symbol 'custom-face) found)))
		  (when (and (boundp symbol)
			     (or (get symbol 'saved-value)
				 (get symbol 'standard-value)
				 (if all
				     (get symbol 'variable-documentation)
				   (user-variable-p symbol))))
		    (setq found
			  (cons (list symbol 'custom-variable) found))))))
    (if found 
	(custom-buffer-create found "*Customize Apropos*")
      (error "No matches"))))

;;; Buffer.

;;;###autoload
(defun custom-buffer-create (options &optional name)
  "Create a buffer containing OPTIONS.
Optional NAME is the name of the buffer.
OPTIONS should be an alist of the form ((SYMBOL WIDGET)...), where
SYMBOL is a customization option, and WIDGET is a widget for editing
that option."
  (unless name (setq name "*Customization*"))
  (kill-buffer (get-buffer-create name))
  (switch-to-buffer (get-buffer-create name))
  (custom-buffer-create-internal options))

;;;###autoload
(defun custom-buffer-create-other-window (options &optional name)
  "Create a buffer containing OPTIONS.
Optional NAME is the name of the buffer.
OPTIONS should be an alist of the form ((SYMBOL WIDGET)...), where
SYMBOL is a customization option, and WIDGET is a widget for editing
that option."
  (unless name (setq name "*Customization*"))
  (kill-buffer (get-buffer-create name))
  (let ((window (selected-window)))
    (switch-to-buffer-other-window (get-buffer-create name))
    (custom-buffer-create-internal options)
    (select-window window)))
  

(defun custom-buffer-create-internal (options)
  (message "Creating customization buffer...")
  (custom-mode)
  (widget-insert "This is a customization buffer.
Push RET or click mouse-2 on the word ")
  ;; (put-text-property 1 2 'start-open nil)
  (widget-create 'info-link 
		 :tag "help"
		 :help-echo "Read the online help."
		 "(emacs)Easy Customization")
  (widget-insert " for more information.\n\n")
  (message "Creating customization buttons...")
  (widget-create 'push-button
		 :tag "Set"
		 :help-echo "Set all modifications for this session."
		 :action (lambda (widget &optional event)
			   (custom-set)))
  (widget-insert " ")
  (widget-create 'push-button
		 :tag "Save"
		 :help-echo "\
Make the modifications default for future sessions."
		 :action (lambda (widget &optional event)
			   (custom-save)))
  (widget-insert " ")
  (widget-create 'push-button
		 :tag "Reset"
		 :help-echo "Undo all modifications."
		 :action (lambda (widget &optional event)
			   (custom-reset event)))
  (widget-insert " ")
  (widget-create 'push-button
		 :tag "Done"
		 :help-echo "Bury the buffer."
		 :action (lambda (widget &optional event)
			   (bury-buffer)))
  (widget-insert "\n\n")
  (message "Creating customization items...")
  (setq custom-options 
	(if (= (length options) 1)
	    (mapcar (lambda (entry)
		      (widget-create (nth 1 entry)
				     :custom-state 'unknown
				     :tag (custom-unlispify-tag-name
					   (nth 0 entry))
				     :value (nth 0 entry)))
		    options)
	  (let ((count 0)
		(length (length options)))
	    (mapcar (lambda (entry)
			(prog2
			    (message "Creating customization items %2d%%..."
				     (/ (* 100.0 count) length))
			    (widget-create (nth 1 entry)
					 :tag (custom-unlispify-tag-name
					       (nth 0 entry))
					 :value (nth 0 entry))
			  (setq count (1+ count))
			  (unless (eq (preceding-char) ?\n)
			    (widget-insert "\n"))
			  (widget-insert "\n")))
		      options))))
  (unless (eq (preceding-char) ?\n)
    (widget-insert "\n"))
  (message "Creating customization magic...")
  (mapcar 'custom-magic-reset custom-options)
  (message "Creating customization setup...")
  (widget-setup)
  (goto-char (point-min))
  (when (fboundp 'map-extents)  
    ;; This horrible kludge should make bob and eob read-only in XEmacs.
    (map-extents (lambda (extent &rest junk)
		   (set-extent-property extent 'start-closed t))
		 nil (point-min) (1+ (point-min)))
    (map-extents (lambda (extent &rest junk)
		   (set-extent-property extent 'end-closed t))
		 nil (1- (point-max)) (point-max)))
  (message "Creating customization buffer...done"))

;;; Modification of Basic Widgets.
;;
;; We add extra properties to the basic widgets needed here.  This is
;; fine, as long as we are careful to stay within out own namespace.
;;
;; We want simple widgets to be displayed by default, but complex
;; widgets to be hidden.

(widget-put (get 'item 'widget-type) :custom-show t)
(widget-put (get 'editable-field 'widget-type)
	    :custom-show (lambda (widget value)
			   (let ((pp (pp-to-string value)))
			     (cond ((string-match "\n" pp)
				    nil)
				   ((> (length pp) 40)
				    nil)
				   (t t)))))
(widget-put (get 'menu-choice 'widget-type) :custom-show t)

;;; The `custom-manual' Widget.

(define-widget 'custom-manual 'info-link
  "Link to the manual entry for this customization option."
  :help-echo "Read the manual entry for this option."
  :tag "Manual")

;;; The `custom-magic' Widget.

(defface custom-invalid-face '((((class color))
				(:foreground "yellow" :background "red"))
			       (t
				(:bold t :italic t :underline t)))
  "Face used when the customize item is invalid.")

(defface custom-rogue-face '((((class color))
			      (:foreground "pink" :background "black"))
			     (t
			      (:underline t)))
  "Face used when the customize item is not defined for customization.")

(defface custom-modified-face '((((class color)) 
				 (:foreground "white" :background "blue"))
				(t
				 (:italic t :bold)))
  "Face used when the customize item has been modified.")

(defface custom-set-face '((((class color)) 
				(:foreground "blue" :background "white"))
			       (t
				(:italic t)))
  "Face used when the customize item has been set.")

(defface custom-changed-face '((((class color)) 
				(:foreground "white" :background "blue"))
			       (t
				(:italic t)))
  "Face used when the customize item has been changed.")

(defface custom-saved-face '((t (:underline t)))
  "Face used when the customize item has been saved.")

(defconst custom-magic-alist '((nil "#" underline "\
uninitialized, you should not see this.")
			       (unknown "?" italic "\
unknown, you should not see this.")
			       (hidden "-" default "\
hidden, invoke the dots above to show." "\
group now hidden, invoke the dots above to show contents.")
			       (invalid "x" custom-invalid-face "\
the value displayed for this item is invalid and cannot be set.")
			       (modified "*" custom-modified-face "\
you have edited the item, and can now set it." "\
you have edited something in this group, and can now set it.")
			       (set "+" custom-set-face "\
you have set this item, but not saved it." "\
something in this group has been set, but not yet saved.")
			       (changed ":" custom-changed-face "\
this item has been changed outside customize." "\
something in this group has been changed outside customize.")
			       (saved "!" custom-saved-face "\
this item has been set and saved." "\
something in this group has been set and saved.")
			       (rogue "@" custom-rogue-face "\
this item has not been changed with customize." "\
something in this group is not prepared for customization.")
			       (standard " " nil "\
this item is unchanged from its standard setting." "\
the visible members of this group are all at standard settings."))
  "Alist of customize option states.
Each entry is of the form (STATE MAGIC FACE ITEM-DESC [ GROUP-DESC ]), where 

STATE is one of the following symbols:

`nil'
   For internal use, should never occur.
`unknown'
   For internal use, should never occur.
`hidden'
   This item is not being displayed. 
`invalid'
   This item is modified, but has an invalid form.
`modified'
   This item is modified, and has a valid form.
`set'
   This item has been set but not saved.
`changed'
   The current value of this item has been changed temporarily.
`saved'
   This item is marked for saving.
`rogue'
   This item has no customization information.
`standard'
   This item is unchanged from the standard setting.

MAGIC is a string used to present that state.

FACE is a face used to present the state.

ITEM-DESC is a string describing the state for options.

GROUP-DESC is a string describing the state for groups.  If this is
left out, ITEM-DESC will be used.

The list should be sorted most significant first.")

(defcustom custom-magic-show 'long
  "If non-nil, show textual description of the state.
If non-nil and not the symbol `long', only show first word."
  :type '(choice (const :tag "no" nil)
		 (const short)
		 (const long))
  :group 'customize)

(defcustom custom-magic-show-hidden nil
  "If non-nil, also show long state description of hidden options."
  :type 'boolean
  :group 'customize)

(defcustom custom-magic-show-button nil
  "Show a magic button indicating the state of each customization option."
  :type 'boolean
  :group 'customize)

(define-widget 'custom-magic 'default
  "Show and manipulate state for a customization option."
  :format "%v"
  :action 'widget-parent-action
  :notify 'ignore
  :value-get 'ignore
  :value-create 'custom-magic-value-create
  :value-delete 'widget-children-value-delete)

(defun widget-magic-mouse-down-action (widget &optional event)
  ;; Non-nil unless hidden.
  (not (eq (widget-get (widget-get (widget-get widget :parent) :parent) 
		       :custom-state)
	   'hidden)))

(defun custom-magic-value-create (widget)
  ;; Create compact status report for WIDGET.
  (let* ((parent (widget-get widget :parent))
	 (state (widget-get parent :custom-state))
	 (hidden (eq state 'hidden))
	 (entry (assq state custom-magic-alist))
	 (magic (nth 1 entry))
	 (face (nth 2 entry))
	 (text (or (and (eq (widget-type parent) 'custom-group)
			(nth 4 entry))
		   (nth 3 entry)))
	 (lisp (eq (widget-get parent :custom-form) 'lisp))
	 children)
    (when (and custom-magic-show
	       (or custom-magic-show-hidden (not hidden)))
      (insert "   ")
      (push (widget-create-child-and-convert 
	     widget 'choice-item 
	     :help-echo "\
Change the state of this item."
	     :format (if hidden "%t" "%[%t%]")
	     :button-prefix 'widget-push-button-prefix
	     :button-suffix 'widget-push-button-suffix
	     :mouse-down-action 'widget-magic-mouse-down-action
	     :tag "State")
	    children)
      (insert ": ")
      (if (eq custom-magic-show 'long)
	  (insert text)
	(insert (symbol-name state)))
      (when lisp 
	(insert " (lisp)"))
      (insert "\n"))
    (when custom-magic-show-button
      (when custom-magic-show
	(let ((indent (widget-get parent :indent)))
	  (when indent
	    (insert-char ?  indent))))
      (push (widget-create-child-and-convert 
	     widget 'choice-item 
	     :mouse-down-action 'widget-magic-mouse-down-action
	     :button-face face
	     :button-prefix ""
	     :button-suffix ""
	     :help-echo "Change the state."
	     :format (if hidden "%t" "%[%t%]")
	     :tag (if lisp 
		      (concat "(" magic ")")
		    (concat "[" magic "]")))
	    children)
      (insert " "))
    (widget-put widget :children children)))

(defun custom-magic-reset (widget)
  "Redraw the :custom-magic property of WIDGET."
  (let ((magic (widget-get widget :custom-magic)))
    (widget-value-set magic (widget-value magic))))

;;; The `custom' Widget.

(define-widget 'custom 'default
  "Customize a user option."
  :convert-widget 'custom-convert-widget
  :format-handler 'custom-format-handler
  :notify 'custom-notify
  :custom-level 1
  :custom-state 'hidden
  :documentation-property 'widget-subclass-responsibility
  :value-create 'widget-subclass-responsibility
  :value-delete 'widget-children-value-delete
  :value-get 'widget-value-value-get
  :validate 'widget-children-validate
  :match (lambda (widget value) (symbolp value)))

(defun custom-convert-widget (widget)
  ;; Initialize :value and :tag from :args in WIDGET.
  (let ((args (widget-get widget :args)))
    (when args 
      (widget-put widget :value (widget-apply widget
					      :value-to-internal (car args)))
      (widget-put widget :tag (custom-unlispify-tag-name (car args)))
      (widget-put widget :args nil)))
  widget)

(defun custom-format-handler (widget escape)
  ;; We recognize extra escape sequences.
  (let* ((buttons (widget-get widget :buttons))
	 (state (widget-get widget :custom-state))
	 (level (widget-get widget :custom-level)))
    (cond ((eq escape ?l)
	   (when level 
	     (if (eq state 'hidden)
		 (insert-char ?- (* 2 level))
	       (insert "/" (make-string (1- (* 2 level)) ?-)))))
	  ((eq escape ?e)
	   (when (and level (not (eq state 'hidden)))
	     (insert "\n\\" (make-string (1- (* 2 level)) ?-) " "
		     (widget-get widget :tag) " group end ")
	     (insert (make-string (- 75 (current-column)) ?-) "/\n")))
	  ((eq escape ?-)
	   (when level 
	     (if (eq state 'hidden)
		 (insert-char ?- (- 77 (current-column)))		 
	       (insert (make-string (- 76 (current-column)) ?-) "\\"))))
	  ((eq escape ?L)
	   (push (widget-create-child-and-convert
		  widget 'visibility
		  :action 'custom-toggle-parent
		  (not (eq state 'hidden)))
		 buttons))
	  ((eq escape ?m)
	   (and (eq (preceding-char) ?\n)
		(widget-get widget :indent)
		(insert-char ?  (widget-get widget :indent)))
	   (let ((magic (widget-create-child-and-convert
			 widget 'custom-magic nil)))
	     (widget-put widget :custom-magic magic)
	     (push magic buttons)
	     (widget-put widget :buttons buttons)))
	  ((eq escape ?a)
	   (unless (eq state 'hidden)
	     (let* ((symbol (widget-get widget :value))
		    (links (get symbol 'custom-links))
		    (many (> (length links) 2)))
	       (when links
		 (and (eq (preceding-char) ?\n)
		      (widget-get widget :indent)
		      (insert-char ?  (widget-get widget :indent)))
		 (insert "See also ")
		 (while links
		   (push (widget-create-child-and-convert widget (car links))
			 buttons)
		   (setq links (cdr links))
		   (cond ((null links)
			  (insert ".\n"))
			 ((null (cdr links))
			  (if many
			      (insert ", and ")
			    (insert " and ")))
			 (t 
			  (insert ", "))))
		 (widget-put widget :buttons buttons)))))
	  (t 
	   (widget-default-format-handler widget escape)))))

(defun custom-notify (widget &rest args)
  "Keep track of changes."
  (unless (memq (widget-get widget :custom-state) '(nil unknown hidden))
    (widget-put widget :custom-state 'modified))
  (let ((buffer-undo-list t))
    (custom-magic-reset widget))
  (apply 'widget-default-notify widget args))

(defun custom-redraw (widget)
  "Redraw WIDGET with current settings."
  (let ((line (count-lines (point-min) (point)))
	(column (current-column))
	(pos (point))
	(from (marker-position (widget-get widget :from)))
	(to (marker-position (widget-get widget :to))))
    (save-excursion
      (widget-value-set widget (widget-value widget))
      (custom-redraw-magic widget))
    (when (and (>= pos from) (<= pos to))
      (condition-case nil
	  (progn 
	    (if (> column 0)
		(goto-line line)
	      (goto-line (1+ line)))
	    (move-to-column column))
	(error nil)))))

(defun custom-redraw-magic (widget)
  "Redraw WIDGET state with current settings."
  (while widget 
    (let ((magic (widget-get widget :custom-magic)))
      (unless magic 
	(debug))
      (widget-value-set magic (widget-value magic))
      (when (setq widget (widget-get widget :group))
	(custom-group-state-update widget))))
  (widget-setup))

(defun custom-show (widget value)
  "Non-nil if WIDGET should be shown with VALUE by default."
  (let ((show (widget-get widget :custom-show)))
    (cond ((null show)
	   nil)
	  ((eq t show)
	   t)
	  (t
	   (funcall show widget value)))))

(defvar custom-load-recursion nil
  "Hack to avoid recursive dependencies.")

(defun custom-load-symbol (symbol)
  "Load all dependencies for SYMBOL."
  (unless custom-load-recursion
    (let ((custom-load-recursion t) 
	  (loads (get symbol 'custom-loads))
	  load)
      (while loads
	(setq load (car loads)
	      loads (cdr loads))
	(cond ((symbolp load)
	       (condition-case nil
		   (require load)
		 (error nil)))
	      ;; Don't reload a file already loaded.
	      ((assoc (locate-library load) load-history))
	      (t
	       (condition-case nil
		   ;; Without this, we would load cus-edit recursively.
		   ;; We are still loading it when we call this,
		   ;; and it is not in load-history yet.
		   (or (equal load "cus-edit")
		       (load-library load))
		 (error nil))))))))

(defun custom-load-widget (widget)
  "Load all dependencies for WIDGET."
  (custom-load-symbol (widget-value widget)))

(defun custom-toggle-hide (widget)
  "Toggle visibility of WIDGET."
  (let ((state (widget-get widget :custom-state)))
    (cond ((memq state '(invalid modified))
	   (error "There are unset changes"))
	  ((eq state 'hidden)
	   (widget-put widget :custom-state 'unknown))
	  (t 
	   (widget-put widget :documentation-shown nil)
	   (widget-put widget :custom-state 'hidden)))
    (custom-redraw widget)))

(defun custom-toggle-parent (widget &rest ignore)
  "Toggle visibility of parent to WIDGET."
  (custom-toggle-hide (widget-get widget :parent)))

;;; The `custom-variable' Widget.

(defface custom-variable-sample-face '((t (:underline t)))
  "Face used for unpushable variable tags."
  :group 'custom-faces)

(defface custom-variable-button-face '((t (:underline t :bold t)))
  "Face used for pushable variable tags."
  :group 'custom-faces)

(define-widget 'custom-variable 'custom
  "Customize variable."
  :format "%v%m%h%a"
  :help-echo "Set or reset this variable."
  :documentation-property 'variable-documentation
  :custom-state nil
  :custom-menu 'custom-variable-menu-create
  :custom-form 'edit
  :value-create 'custom-variable-value-create
  :action 'custom-variable-action
  :custom-set 'custom-variable-set
  :custom-save 'custom-variable-save
  :custom-reset-current 'custom-redraw
  :custom-reset-saved 'custom-variable-reset-saved
  :custom-reset-standard 'custom-variable-reset-standard)

(defun custom-variable-type (symbol)
  "Return a widget suitable for editing the value of SYMBOL.
If SYMBOL has a `custom-type' property, use that.  
Otherwise, look up symbol in `custom-guess-type-alist'."
  (let* ((type (or (get symbol 'custom-type)
		   (and (not (get symbol 'standard-value))
			(custom-guess-type symbol))
		   'sexp))
	 (options (get symbol 'custom-options))
	 (tmp (if (listp type)
		  (copy-sequence type)
		(list type))))
    (when options
      (widget-put tmp :options options))
    tmp))

(defun custom-variable-value-create (widget)
  "Here is where you edit the variables value."
  (custom-load-widget widget)
  (let* ((buttons (widget-get widget :buttons))
	 (children (widget-get widget :children))
	 (form (widget-get widget :custom-form))
	 (state (widget-get widget :custom-state))
	 (symbol (widget-get widget :value))
	 (tag (widget-get widget :tag))
	 (type (custom-variable-type symbol))
	 (conv (widget-convert type))
	 (get (or (get symbol 'custom-get) 'default-value))
	 (value (if (default-boundp symbol)
		    (funcall get symbol)
		  (widget-get conv :value))))
    ;; If the widget is new, the child determine whether it is hidden.
    (cond (state)
	  ((custom-show type value)
	   (setq state 'unknown))
	  (t
	   (setq state 'hidden)))
    ;; If we don't know the state, see if we need to edit it in lisp form.
    (when (eq state 'unknown)
      (unless (widget-apply conv :match value)
	;; (widget-apply (widget-convert type) :match value)
	(setq form 'lisp)))
    ;; Now we can create the child widget.
    (cond ((eq state 'hidden)
	   ;; Indicate hidden value.
	   (push (widget-create-child-and-convert 
		  widget 'item
		  :format "%{%t%}: "
		  :sample-face 'custom-variable-sample-face
		  :tag tag
		  :parent widget)
		 buttons)
	   (push (widget-create-child-and-convert 
		  widget 'visibility
		  :action 'custom-toggle-parent
		  nil)
		 buttons))
	  ((eq form 'lisp)
	   ;; In lisp mode edit the saved value when possible.
	   (let* ((value (cond ((get symbol 'saved-value)
				(car (get symbol 'saved-value)))
			       ((get symbol 'standard-value)
				(car (get symbol 'standard-value)))
			       ((default-boundp symbol)
				(custom-quote (funcall get symbol)))
			       (t
				(custom-quote (widget-get conv :value))))))
	     (insert (symbol-name symbol) ": ")
	     (push (widget-create-child-and-convert 
		  widget 'visibility
		  :action 'custom-toggle-parent
		  t)
		 buttons)
	     (insert " ")
	     (push (widget-create-child-and-convert 
		    widget 'sexp 
		    :button-face 'custom-variable-button-face
		    :format "%v"
		    :tag (symbol-name symbol)
		    :parent widget
		    :value value)
		   children)))
	  (t
	   ;; Edit mode.
	   (let* ((format (widget-get type :format))
		  tag-format value-format)
	     (unless (string-match ":" format)
	       (error "Bad format."))
	     (setq tag-format (substring format 0 (match-end 0)))
	     (setq value-format (substring format (match-end 0)))
	     (push (widget-create-child-and-convert
		    widget 'item 
		    :format tag-format
		    :action 'custom-tag-action
		    :mouse-down-action 'custom-tag-mouse-down-action
		    :button-face 'custom-variable-button-face
		    :sample-face 'custom-variable-sample-face
		    tag)
		   buttons)
	     (insert " ")
	     (push (widget-create-child-and-convert 
		  widget 'visibility
		  :action 'custom-toggle-parent
		  t)
		 buttons)	     
	     (push (widget-create-child-and-convert
		    widget type 
		    :format value-format
		    :value value)
		   children))))
    ;; Now update the state.
    (unless (eq (preceding-char) ?\n)
      (widget-insert "\n"))
    (if (eq state 'hidden)
	(widget-put widget :custom-state state)
      (custom-variable-state-set widget))
    (widget-put widget :custom-form form)	     
    (widget-put widget :buttons buttons)
    (widget-put widget :children children)))

(defun custom-tag-action (widget &rest args)
  "Pass :action to first child of WIDGET's parent."
  (apply 'widget-apply (car (widget-get (widget-get widget :parent) :children))
	 :action args))

(defun custom-tag-mouse-down-action (widget &rest args)
  "Pass :mouse-down-action to first child of WIDGET's parent."
  (apply 'widget-apply (car (widget-get (widget-get widget :parent) :children))
	 :mouse-down-action args))

(defun custom-variable-state-set (widget)
  "Set the state of WIDGET."
  (let* ((symbol (widget-value widget))
	 (get (or (get symbol 'custom-get) 'default-value))
	 (value (if (default-boundp symbol)
		    (funcall get symbol)
		  (widget-get widget :value)))
	 tmp
	 (state (cond ((setq tmp (get symbol 'customized-value))
		       (if (condition-case nil
			       (equal value (eval (car tmp)))
			     (error nil))
			   'set
			 'changed))
		      ((setq tmp (get symbol 'saved-value))
		       (if (condition-case nil
			       (equal value (eval (car tmp)))
			     (error nil))
			   'saved
			 'changed))
		      ((setq tmp (get symbol 'standard-value))
		       (if (condition-case nil
			       (equal value (eval (car tmp)))
			     (error nil))
			   'standard
			 'changed))
		      (t 'rogue))))
    (widget-put widget :custom-state state)))

(defvar custom-variable-menu 
  '(("Edit" custom-variable-edit 
     (lambda (widget)
       (not (eq (widget-get widget :custom-form) 'edit))))
    ("Edit Lisp" custom-variable-edit-lisp
     (lambda (widget)
       (not (eq (widget-get widget :custom-form) 'lisp))))
    ("Set" custom-variable-set
     (lambda (widget)
       (eq (widget-get widget :custom-state) 'modified)))
    ("Save" custom-variable-save
     (lambda (widget)
       (memq (widget-get widget :custom-state) '(modified set changed rogue))))
    ("Reset to Current" custom-redraw
     (lambda (widget)
       (and (default-boundp (widget-value widget))
	    (memq (widget-get widget :custom-state) '(modified changed)))))
    ("Reset to Saved" custom-variable-reset-saved
     (lambda (widget)
       (and (get (widget-value widget) 'saved-value)
	    (memq (widget-get widget :custom-state)
		  '(modified set changed rogue)))))
    ("Reset to Standard Settings" custom-variable-reset-standard
     (lambda (widget)
       (and (get (widget-value widget) 'standard-value)
	    (memq (widget-get widget :custom-state)
		  '(modified set changed saved rogue))))))
  "Alist of actions for the `custom-variable' widget.
Each entry has the form (NAME ACTION FILTER) where NAME is the name of
the menu entry, ACTION is the function to call on the widget when the
menu is selected, and FILTER is a predicate which takes a `custom-variable'
widget as an argument, and returns non-nil if ACTION is valid on that
widget. If FILTER is nil, ACTION is always valid.")

(defun custom-variable-action (widget &optional event)
  "Show the menu for `custom-variable' WIDGET.
Optional EVENT is the location for the menu."
  (if (eq (widget-get widget :custom-state) 'hidden)
      (custom-toggle-hide widget)
    (unless (eq (widget-get widget :custom-state) 'modified)
      (custom-variable-state-set widget))
    (custom-redraw-magic widget)
    (let* ((completion-ignore-case t)
	   (answer (widget-choose (concat "Operation on "
					  (custom-unlispify-tag-name
					   (widget-get widget :value)))
				  (custom-menu-filter custom-variable-menu
						      widget)
				  event)))
      (if answer
	  (funcall answer widget)))))

(defun custom-variable-edit (widget)
  "Edit value of WIDGET."
  (widget-put widget :custom-state 'unknown)
  (widget-put widget :custom-form 'edit)
  (custom-redraw widget))

(defun custom-variable-edit-lisp (widget)
  "Edit the lisp representation of the value of WIDGET."
  (widget-put widget :custom-state 'unknown)
  (widget-put widget :custom-form 'lisp)
  (custom-redraw widget))

(defun custom-variable-set (widget)
  "Set the current value for the variable being edited by WIDGET."
  (let* ((form (widget-get widget :custom-form))
	 (state (widget-get widget :custom-state))
	 (child (car (widget-get widget :children)))
	 (symbol (widget-value widget))
	 (set (or (get symbol 'custom-set) 'set-default))
	  val)
    (cond ((eq state 'hidden)
	   (error "Cannot set hidden variable."))
	  ((setq val (widget-apply child :validate))
	   (goto-char (widget-get val :from))
	   (error "%s" (widget-get val :error)))
	  ((eq form 'lisp)
	   (funcall set symbol (eval (setq val (widget-value child))))
	   (put symbol 'customized-value (list val)))
	  (t
	   (funcall set symbol (setq val (widget-value child)))
	   (put symbol 'customized-value (list (custom-quote val)))))
    (custom-variable-state-set widget)
    (custom-redraw-magic widget)))

(defun custom-variable-save (widget)
  "Set the default value for the variable being edited by WIDGET."
  (let* ((form (widget-get widget :custom-form))
	 (state (widget-get widget :custom-state))
	 (child (car (widget-get widget :children)))
	 (symbol (widget-value widget))
	 (set (or (get symbol 'custom-set) 'set-default))
	 val)
    (cond ((eq state 'hidden)
	   (error "Cannot set hidden variable."))
	  ((setq val (widget-apply child :validate))
	   (goto-char (widget-get val :from))
	   (error "%s" (widget-get val :error)))
	  ((eq form 'lisp)
	   (put symbol 'saved-value (list (widget-value child)))
	   (funcall set symbol (eval (widget-value child))))
	  (t
	   (put symbol
		'saved-value (list (custom-quote (widget-value
						  child))))
	   (funcall set symbol (widget-value child))))
    (put symbol 'customized-value nil)
    (custom-save-all)
    (custom-variable-state-set widget)
    (custom-redraw-magic widget)))

(defun custom-variable-reset-saved (widget)
  "Restore the saved value for the variable being edited by WIDGET."
  (let* ((symbol (widget-value widget))
	 (set (or (get symbol 'custom-set) 'set-default)))
    (if (get symbol 'saved-value)
	(condition-case nil
	    (funcall set symbol (eval (car (get symbol 'saved-value))))
	  (error nil))
      (error "No saved value for %s" symbol))
    (put symbol 'customized-value nil)
    (widget-put widget :custom-state 'unknown)
    (custom-redraw widget)))

(defun custom-variable-reset-standard (widget)
  "Restore the standard setting for the variable being edited by WIDGET."
  (let* ((symbol (widget-value widget))
	 (set (or (get symbol 'custom-set) 'set-default)))
    (if (get symbol 'standard-value)
	(funcall set symbol (eval (car (get symbol 'standard-value))))
      (error "No standard setting known for %S" symbol))
    (put symbol 'customized-value nil)
    (when (get symbol 'saved-value)
      (put symbol 'saved-value nil)
      (custom-save-all))
    (widget-put widget :custom-state 'unknown)
    (custom-redraw widget)))

;;; The `custom-face-edit' Widget.

(define-widget 'custom-face-edit 'checklist
  "Edit face attributes."
  :format "%t: %v"
  :tag "Attributes"
  :extra-offset 12
  :button-args '(:help-echo "Control whether this attribute have any effect.")
  :args (mapcar (lambda (att)
		  (list 'group 
			:inline t
			:sibling-args (widget-get (nth 1 att) :sibling-args)
			(list 'const :format "" :value (nth 0 att)) 
			(nth 1 att)))
		custom-face-attributes))

;;; The `custom-display' Widget.

(define-widget 'custom-display 'menu-choice
  "Select a display type."
  :tag "Display"
  :value t
  :help-echo "Specify frames where the face attributes should be used."
  :args '((const :tag "all" t)
	  (checklist
	   :offset 0
	   :extra-offset 9
	   :args ((group :sibling-args (:help-echo "\
Only match the specified window systems.")
			 (const :format "Type: "
				type)
			 (checklist :inline t
				    :offset 0
				    (const :format "X "
					   :sibling-args (:help-echo "\
The X11 Window System.")
					   x)
				    (const :format "PM "
					   :sibling-args (:help-echo "\
OS/2 Presentation Manager.")
					   pm)
				    (const :format "Win32 "
					   :sibling-args (:help-echo "\
Windows NT/95/97.")
					   win32)
				    (const :format "DOS "
					   :sibling-args (:help-echo "\
Plain MS-DOS.")
					   pc)
				    (const :format "TTY%n"
					   :sibling-args (:help-echo "\
Plain text terminals.")
					   tty)))
		  (group :sibling-args (:help-echo "\
Only match the frames with the specified color support.")
			 (const :format "Class: "
				class)
			 (checklist :inline t
				    :offset 0
				    (const :format "Color "
					   :sibling-args (:help-echo "\
Match color frames.")
					   color)
				    (const :format "Grayscale "
					   :sibling-args (:help-echo "\
Match grayscale frames.")
					   grayscale)
				    (const :format "Monochrome%n"
					   :sibling-args (:help-echo "\
Match frames with no color support.")
					   mono)))
		  (group :sibling-args (:help-echo "\
Only match frames with the specified intensity.")
			 (const :format "\
Background brightness: "
				background)
			 (checklist :inline t
				    :offset 0
				    (const :format "Light "
					   :sibling-args (:help-echo "\
Match frames with light backgrounds.")
					   light)
				    (const :format "Dark\n"
					   :sibling-args (:help-echo "\
Match frames with dark backgrounds.")
					   dark)))))))

;;; The `custom-face' Widget.

(defface custom-face-tag-face '((t (:underline t)))
  "Face used for face tags."
  :group 'custom-faces)

(define-widget 'custom-face 'custom
  "Customize face."
  :format "%{%t%}: %s %L\n%m%h%a%v"
  :format-handler 'custom-face-format-handler
  :sample-face 'custom-face-tag-face
  :help-echo "Set or reset this face."
  :documentation-property '(lambda (face)
			     (face-doc-string face))
  :value-create 'custom-face-value-create
  :action 'custom-face-action
  :custom-form 'selected
  :custom-set 'custom-face-set
  :custom-save 'custom-face-save
  :custom-reset-current 'custom-redraw
  :custom-reset-saved 'custom-face-reset-saved
  :custom-reset-standard 'custom-face-reset-standard
  :custom-menu 'custom-face-menu-create)

(defun custom-face-format-handler (widget escape)
  ;; We recognize extra escape sequences.
  (let (child
	(symbol (widget-get widget :value)))
    (cond ((eq escape ?s)
	   (and (string-match "XEmacs" emacs-version)
		;; XEmacs cannot display initialized faces.
		(not (custom-facep symbol))
		(copy-face 'custom-face-empty symbol))
	   (setq child (widget-create-child-and-convert 
			widget 'item
			:format "(%{%t%})"
			:sample-face symbol
			:tag "sample")))
	  (t 
	   (custom-format-handler widget escape)))
    (when child
      (widget-put widget
		  :buttons (cons child (widget-get widget :buttons))))))

(define-widget 'custom-face-all 'editable-list 
  "An editable list of display specifications and attributes."
  :entry-format "%i %d %v"
  :insert-button-args '(:help-echo "Insert new display specification here.")
  :append-button-args '(:help-echo "Append new display specification here.")
  :delete-button-args '(:help-echo "Delete this display specification.")
  :args '((group :format "%v" custom-display custom-face-edit)))

(defconst custom-face-all (widget-convert 'custom-face-all)
  "Converted version of the `custom-face-all' widget.")

(define-widget 'custom-display-unselected 'item
  "A display specification that doesn't match the selected display."
  :match 'custom-display-unselected-match)

(defun custom-display-unselected-match (widget value)
  "Non-nil if VALUE is an unselected display specification."
  (not (face-spec-set-match-display value (selected-frame))))

(define-widget 'custom-face-selected 'group 
  "Edit the attributes of the selected display in a face specification."
  :args '((repeat :format ""
		  :inline t
		  (group custom-display-unselected sexp))
	  (group (sexp :format "") custom-face-edit)
	  (repeat :format ""
		  :inline t
		  sexp)))

(defconst custom-face-selected (widget-convert 'custom-face-selected)
  "Converted version of the `custom-face-selected' widget.")

(defun custom-face-value-create (widget)
  ;; Create a list of the display specifications.
  (unless (eq (preceding-char) ?\n)
    (insert "\n"))
  (when (not (eq (widget-get widget :custom-state) 'hidden))
    (message "Creating face editor...")
    (custom-load-widget widget)
    (let* ((symbol (widget-value widget))
	   (spec (or (get symbol 'saved-face)
		     (get symbol 'face-defface-spec)
		     ;; Attempt to construct it.
		     (list (list t (custom-face-attributes-get 
				    symbol (selected-frame))))))
	   (form (widget-get widget :custom-form))
	   (indent (widget-get widget :indent))
	   (edit (widget-create-child-and-convert
		  widget
		  (cond ((and (eq form 'selected)
			      (widget-apply custom-face-selected :match spec))
			 (when indent (insert-char ?\  indent))
			 'custom-face-selected)
			((and (not (eq form 'lisp))
			      (widget-apply custom-face-all :match spec))
			 'custom-face-all)
			(t 
			 (when indent (insert-char ?\  indent))
			 'sexp))
		  :value spec)))
      (custom-face-state-set widget)
      (widget-put widget :children (list edit)))
    (message "Creating face editor...done")))

(defvar custom-face-menu 
  '(("Edit Selected" custom-face-edit-selected
     (lambda (widget)
       (not (eq (widget-get widget :custom-form) 'selected))))
    ("Edit All" custom-face-edit-all
     (lambda (widget)
       (not (eq (widget-get widget :custom-form) 'all))))
    ("Edit Lisp" custom-face-edit-lisp
     (lambda (widget)
       (not (eq (widget-get widget :custom-form) 'lisp))))
    ("Set" custom-face-set)
    ("Save" custom-face-save)
    ("Reset to Saved" custom-face-reset-saved
     (lambda (widget)
       (get (widget-value widget) 'saved-face)))
    ("Reset to Standard Setting" custom-face-reset-standard
     (lambda (widget)
       (get (widget-value widget) 'face-defface-spec))))
  "Alist of actions for the `custom-face' widget.
Each entry has the form (NAME ACTION FILTER) where NAME is the name of
the menu entry, ACTION is the function to call on the widget when the
menu is selected, and FILTER is a predicate which takes a `custom-face'
widget as an argument, and returns non-nil if ACTION is valid on that
widget. If FILTER is nil, ACTION is always valid.")

(defun custom-face-edit-selected (widget)
  "Edit selected attributes of the value of WIDGET."
  (widget-put widget :custom-state 'unknown)
  (widget-put widget :custom-form 'selected)
  (custom-redraw widget))

(defun custom-face-edit-all (widget)
  "Edit all attributes of the value of WIDGET."
  (widget-put widget :custom-state 'unknown)
  (widget-put widget :custom-form 'all)
  (custom-redraw widget))

(defun custom-face-edit-lisp (widget)
  "Edit the lisp representation of the value of WIDGET."
  (widget-put widget :custom-state 'unknown)
  (widget-put widget :custom-form 'lisp)
  (custom-redraw widget))

(defun custom-face-state-set (widget)
  "Set the state of WIDGET."
  (let ((symbol (widget-value widget)))
    (widget-put widget :custom-state (cond ((get symbol 'customized-face)
					    'set)
					   ((get symbol 'saved-face)
					    'saved)
					   ((get symbol 'face-defface-spec)
					    'standard)
					   (t 
					    'rogue)))))

(defun custom-face-action (widget &optional event)
  "Show the menu for `custom-face' WIDGET.
Optional EVENT is the location for the menu."
  (if (eq (widget-get widget :custom-state) 'hidden)
      (custom-toggle-hide widget)
    (let* ((completion-ignore-case t)
	   (symbol (widget-get widget :value))
	   (answer (widget-choose (concat "Operation on "
					  (custom-unlispify-tag-name symbol))
				  (custom-menu-filter custom-face-menu
						      widget)
				  event)))
      (if answer
	  (funcall answer widget)))))

(defun custom-face-set (widget)
  "Make the face attributes in WIDGET take effect."
  (let* ((symbol (widget-value widget))
	 (child (car (widget-get widget :children)))
	 (value (widget-value child)))
    (put symbol 'customized-face value)
    (face-spec-set symbol value)
    (custom-face-state-set widget)
    (custom-redraw-magic widget)))

(defun custom-face-save (widget)
  "Make the face attributes in WIDGET default."
  (let* ((symbol (widget-value widget))
	 (child (car (widget-get widget :children)))
	 (value (widget-value child)))
    (face-spec-set symbol value)
    (put symbol 'saved-face value)
    (put symbol 'customized-face nil)
    (custom-face-state-set widget)
    (custom-redraw-magic widget)))

(defun custom-face-reset-saved (widget)
  "Restore WIDGET to the face's default attributes."
  (let* ((symbol (widget-value widget))
	 (child (car (widget-get widget :children)))
	 (value (get symbol 'saved-face)))
    (unless value
      (error "No saved value for this face"))
    (put symbol 'customized-face nil)
    (face-spec-set symbol value)
    (widget-value-set child value)
    (custom-face-state-set widget)
    (custom-redraw-magic widget)))

(defun custom-face-reset-standard (widget)
  "Restore WIDGET to the face's standard settings."
  (let* ((symbol (widget-value widget))
	 (child (car (widget-get widget :children)))
	 (value (get symbol 'face-defface-spec)))
    (unless value
      (error "No standard setting for this face"))
    (put symbol 'customized-face nil)
    (when (get symbol 'saved-face)
      (put symbol 'saved-face nil)
      (custom-save-all))
    (face-spec-set symbol value)
    (widget-value-set child value)
    (custom-face-state-set widget)
    (custom-redraw-magic widget)))

;;; The `face' Widget.

(define-widget 'face 'default
  "Select and customize a face."
  :convert-widget 'widget-value-convert-widget
  :format "%[%t%]: %v"
  :tag "Face"
  :value 'default
  :value-create 'widget-face-value-create
  :value-delete 'widget-face-value-delete
  :value-get 'widget-value-value-get
  :validate 'widget-children-validate
  :action 'widget-face-action
  :match '(lambda (widget value) (symbolp value)))

(defun widget-face-value-create (widget)
  ;; Create a `custom-face' child.
  (let* ((symbol (widget-value widget))
	 (child (widget-create-child-and-convert
		 widget 'custom-face
		 :format "%t %s %L\n%m%h%v"
		 :custom-level nil
		 :value symbol)))
    (custom-magic-reset child)
    (setq custom-options (cons child custom-options))
    (widget-put widget :children (list child))))

(defun widget-face-value-delete (widget)
  ;; Remove the child from the options.
  (let ((child (car (widget-get widget :children))))
    (setq custom-options (delq child custom-options))
    (widget-children-value-delete widget)))

(defvar face-history nil
  "History of entered face names.")

(defun widget-face-action (widget &optional event)
  "Prompt for a face."
  (let ((answer (completing-read "Face: "
				 (mapcar (lambda (face)
					   (list (symbol-name face)))
					 (face-list))
				 nil nil nil				 
				 'face-history)))
    (unless (zerop (length answer))
      (widget-value-set widget (intern answer))
      (widget-apply widget :notify widget event)
      (widget-setup))))

;;; The `hook' Widget.

(define-widget 'hook 'list
  "A emacs lisp hook"
  :convert-widget 'custom-hook-convert-widget
  :tag "Hook")

(defun custom-hook-convert-widget (widget)
  ;; Handle `:custom-options'.
  (let* ((options (widget-get widget :options))
	 (other `(editable-list :inline t 
				:entry-format "%i %d%v"
				(function :format " %v")))
	 (args (if options
		   (list `(checklist :inline t
				     ,@(mapcar (lambda (entry)
						 `(function-item ,entry))
					       options))
			 other)
		 (list other))))
    (widget-put widget :args args)
    widget))

;;; The `custom-group' Widget.

(defcustom custom-group-tag-faces '(custom-group-tag-face-1)
  ;; In XEmacs, this ought to play games with font size.
  "Face used for group tags.
The first member is used for level 1 groups, the second for level 2,
and so forth.  The remaining group tags are shown with
`custom-group-tag-face'."
  :type '(repeat face)
  :group 'custom-faces)

(defface custom-group-tag-face-1 '((((class color)
				     (background dark))
				    (:foreground "pink" :underline t))
				   (((class color)
				     (background light))
				    (:foreground "red" :underline t))
				   (t (:underline t)))
  "Face used for group tags.")

(defface custom-group-tag-face '((((class color)
				   (background dark))
				  (:foreground "light blue" :underline t))
				 (((class color)
				   (background light))
				  (:foreground "blue" :underline t))
				 (t (:underline t)))
  "Face used for low level group tags."
  :group 'custom-faces)

(define-widget 'custom-group 'custom
  "Customize group."
  :format "%l %{%t%} group: %L %-\n%m%h%a%v%e"
  :sample-face-get 'custom-group-sample-face-get
  :documentation-property 'group-documentation
  :help-echo "Set or reset all members of this group."
  :value-create 'custom-group-value-create
  :action 'custom-group-action
  :custom-set 'custom-group-set
  :custom-save 'custom-group-save
  :custom-reset-current 'custom-group-reset-current
  :custom-reset-saved 'custom-group-reset-saved
  :custom-reset-standard 'custom-group-reset-standard
  :custom-menu 'custom-group-menu-create)

(defun custom-group-sample-face-get (widget)
  ;; Use :sample-face.
  (or (nth (1- (widget-get widget :custom-level)) custom-group-tag-faces)
      'custom-group-tag-face))

(defun custom-group-value-create (widget)
  (let ((state (widget-get widget :custom-state)))
    (unless (eq state 'hidden)
      (message "Creating group...")
      (custom-load-widget widget)
      (let* ((level (widget-get widget :custom-level))
	     (symbol (widget-value widget))
	     (members (sort (get symbol 'custom-group) 
			    custom-buffer-sort-predicate))
	     (prefixes (widget-get widget :custom-prefixes))
	     (custom-prefix-list (custom-prefix-add symbol prefixes))
	     (length (length members))
	     (count 0)
	     (children (mapcar (lambda (entry)
				 (widget-insert "\n")
				 (message "Creating group members... %2d%%"
					  (/ (* 100.0 count) length))
				 (setq count (1+ count))
				 (prog1
				     (widget-create-child-and-convert
				      widget (nth 1 entry)
				      :group widget
				      :tag (custom-unlispify-tag-name
					    (nth 0 entry))
				      :custom-prefixes custom-prefix-list
				      :custom-level (1+ level)
				      :value (nth 0 entry))
				   (unless (eq (preceding-char) ?\n)
				     (widget-insert "\n"))))
			       members)))
	(put symbol 'custom-group members)
	(message "Creating group magic...")
	(mapcar 'custom-magic-reset children)
	(message "Creating group state...")
	(widget-put widget :children children)
	(custom-group-state-update widget)
	(message "Creating group... done")))))

(defvar custom-group-menu 
  '(("Set" custom-group-set
     (lambda (widget)
       (eq (widget-get widget :custom-state) 'modified)))
    ("Save" custom-group-save
     (lambda (widget)
       (memq (widget-get widget :custom-state) '(modified set))))
    ("Reset to Current" custom-group-reset-current
     (lambda (widget)
       (memq (widget-get widget :custom-state) '(modified))))
    ("Reset to Saved" custom-group-reset-saved
     (lambda (widget)
       (memq (widget-get widget :custom-state) '(modified set))))
    ("Reset to standard setting" custom-group-reset-standard
     (lambda (widget)
       (memq (widget-get widget :custom-state) '(modified set saved)))))
  "Alist of actions for the `custom-group' widget.
Each entry has the form (NAME ACTION FILTER) where NAME is the name of
the menu entry, ACTION is the function to call on the widget when the
menu is selected, and FILTER is a predicate which takes a `custom-group'
widget as an argument, and returns non-nil if ACTION is valid on that
widget. If FILTER is nil, ACTION is always valid.")

(defun custom-group-action (widget &optional event)
  "Show the menu for `custom-group' WIDGET.
Optional EVENT is the location for the menu."
  (if (eq (widget-get widget :custom-state) 'hidden)
      (custom-toggle-hide widget)
    (let* ((completion-ignore-case t)
	   (answer (widget-choose (concat "Operation on "
					  (custom-unlispify-tag-name
					   (widget-get widget :value)))
				  (custom-menu-filter custom-group-menu
						      widget)
				  event)))
      (if answer
	  (funcall answer widget)))))

(defun custom-group-set (widget)
  "Set changes in all modified group members."
  (let ((children (widget-get widget :children)))
    (mapcar (lambda (child)
	      (when (eq (widget-get child :custom-state) 'modified)
		(widget-apply child :custom-set)))
	    children )))

(defun custom-group-save (widget)
  "Save all modified group members."
  (let ((children (widget-get widget :children)))
    (mapcar (lambda (child)
	      (when (memq (widget-get child :custom-state) '(modified set))
		(widget-apply child :custom-save)))
	    children )))

(defun custom-group-reset-current (widget)
  "Reset all modified group members."
  (let ((children (widget-get widget :children)))
    (mapcar (lambda (child)
	      (when (eq (widget-get child :custom-state) 'modified)
		(widget-apply child :custom-reset-current)))
	    children )))

(defun custom-group-reset-saved (widget)
  "Reset all modified or set group members."
  (let ((children (widget-get widget :children)))
    (mapcar (lambda (child)
	      (when (memq (widget-get child :custom-state) '(modified set))
		(widget-apply child :custom-reset-saved)))
	    children )))

(defun custom-group-reset-standard (widget)
  "Reset all modified, set, or saved group members."
  (let ((children (widget-get widget :children)))
    (mapcar (lambda (child)
	      (when (memq (widget-get child :custom-state)
			  '(modified set saved))
		(widget-apply child :custom-reset-standard)))
	    children )))

(defun custom-group-state-update (widget)
  "Update magic."
  (unless (eq (widget-get widget :custom-state) 'hidden)
    (let* ((children (widget-get widget :children))
	   (states (mapcar (lambda (child)
			     (widget-get child :custom-state))
			   children))
	   (magics custom-magic-alist)
	   (found 'standard))
      (while magics
	(let ((magic (car (car magics))))
	  (if (and (not (eq magic 'hidden))
		   (memq magic states))
	      (setq found magic
		    magics nil)
	    (setq magics (cdr magics)))))
      (widget-put widget :custom-state found)))
  (custom-magic-reset widget))

;;; The `custom-save-all' Function.

(defcustom custom-file "~/.emacs"
  "File used for storing customization information.
If you change this from the default \"~/.emacs\" you need to
explicitly load that file for the settings to take effect."
  :type 'file
  :group 'customize)

(defun custom-save-delete (symbol)
  "Delete the call to SYMBOL form `custom-file'.
Leave point at the location of the call, or after the last expression."
  (set-buffer (find-file-noselect custom-file))
  (goto-char (point-min))
  (catch 'found
    (while t
      (let ((sexp (condition-case nil
		      (read (current-buffer))
		    (end-of-file (throw 'found nil)))))
	(when (and (listp sexp)
		   (eq (car sexp) symbol))
	  (delete-region (save-excursion
			   (backward-sexp)
			   (point))
			 (point))
	  (throw 'found nil))))))

(defun custom-save-variables ()
  "Save all customized variables in `custom-file'."
  (save-excursion
    (custom-save-delete 'custom-set-variables)
    (let ((standard-output (current-buffer)))
      (unless (bolp)
	(princ "\n"))
      (princ "(custom-set-variables")
      (mapatoms (lambda (symbol)
		  (let ((value (get symbol 'saved-value))
			(requests (get symbol 'custom-requests))
			(now (not (or (get symbol 'standard-value)
				      (and (not (boundp symbol))
					   (not (get symbol 'force-value)))))))
		    (when value
		      (princ "\n '(")
		      (princ symbol)
		      (princ " ")
		      (prin1 (car value))
		      (cond (requests
			     (if now
				 (princ " t ")
			       (princ " nil "))
			     (prin1 requests)
			     (princ ")"))
			    (now
			     (princ " t)"))
			    (t
			     (princ ")")))))))
      (princ ")")
      (unless (looking-at "\n")
	(princ "\n")))))

(defun custom-save-faces ()
  "Save all customized faces in `custom-file'."
  (save-excursion
    (custom-save-delete 'custom-set-faces)
    (let ((standard-output (current-buffer)))
      (unless (bolp)
	(princ "\n"))
      (princ "(custom-set-faces")
      (let ((value (get 'default 'saved-face)))
	;; The default face must be first, since it affects the others.
	(when value
	  (princ "\n '(default ")
	  (prin1 value)
	  (if (or (get 'default 'face-defface-spec)
		  (and (not (custom-facep 'default))
		       (not (get 'default 'force-face))))
	      (princ ")")
	    (princ " t)"))))
      (mapatoms (lambda (symbol)
		  (let ((value (get symbol 'saved-face)))
		    (when (and (not (eq symbol 'default))
			       ;; Don't print default face here.
			       value)
		      (princ "\n '(")
		      (princ symbol)
		      (princ " ")
		      (prin1 value)
		      (if (or (get symbol 'face-defface-spec)
			      (and (not (custom-facep symbol))
				   (not (get symbol 'force-face))))
			  (princ ")")
			(princ " t)"))))))
      (princ ")")
      (unless (looking-at "\n")
	(princ "\n")))))

;;;###autoload
(defun custom-save-customized ()
  "Save all user options which have been set in this session."
  (interactive)
  (mapatoms (lambda (symbol)
	      (let ((face (get symbol 'customized-face))
		    (value (get symbol 'customized-value)))
		(when face 
		  (put symbol 'saved-face face)
		  (put symbol 'customized-face nil))
		(when value 
		  (put symbol 'saved-value value)
		  (put symbol 'customized-value nil)))))
  ;; We really should update all custom buffers here.
  (custom-save-all))

;;;###autoload
(defun custom-save-all ()
  "Save all customizations in `custom-file'."
  (custom-save-variables)
  (custom-save-faces)
  (save-excursion
    (set-buffer (find-file-noselect custom-file))
    (save-buffer)))

;;; The Customize Menu.

;;; Menu support

(unless (string-match "XEmacs" emacs-version)
  (defconst custom-help-menu '("Customize"
			       ["Update menu..." custom-menu-update t]
			       ["Group..." customize-group t]
			       ["Variable..." customize-variable t]
			       ["Face..." customize-face t]
			       ["Saved..." customize-saved t]
			       ["Set..." customize-customized t]
			       ["Apropos..." customize-apropos t])
    ;; This menu should be identical to the one defined in `menu-bar.el'. 
    "Customize menu")

  (defun custom-menu-reset ()
    "Reset customize menu."
    (remove-hook 'custom-define-hook 'custom-menu-reset)
    (define-key global-map [menu-bar help-menu customize-menu]
      (cons (car custom-help-menu)
	    (easy-menu-create-keymaps (car custom-help-menu)
				      (cdr custom-help-menu)))))

  (defun custom-menu-update (event)
    "Update customize menu."
    (interactive "e")
    (add-hook 'custom-define-hook 'custom-menu-reset)
    (let* ((emacs (widget-apply '(custom-group) :custom-menu 'emacs))
	   (menu `(,(car custom-help-menu)
		   ,emacs
		   ,@(cdr (cdr custom-help-menu)))))
      (let ((map (easy-menu-create-keymaps (car menu) (cdr menu))))
	(define-key global-map [menu-bar help-menu customize-menu]
	  (cons (car menu) map))))))

(defcustom custom-menu-nesting 2
  "Maximum nesting in custom menus."
  :type 'integer
  :group 'customize)

(defun custom-face-menu-create (widget symbol)
  "Ignoring WIDGET, create a menu entry for customization face SYMBOL."
  (vector (custom-unlispify-menu-entry symbol)
	  `(customize-face ',symbol)
	  t))

(defun custom-variable-menu-create (widget symbol)
  "Ignoring WIDGET, create a menu entry for customization variable SYMBOL."
  (let ((type (get symbol 'custom-type)))
    (unless (listp type)
      (setq type (list type)))
    (if (and type (widget-get type :custom-menu))
	(widget-apply type :custom-menu symbol)
      (vector (custom-unlispify-menu-entry symbol)
	      `(customize-variable ',symbol)
	      t))))

;; Add checkboxes to boolean variable entries.
(widget-put (get 'boolean 'widget-type)
	    :custom-menu (lambda (widget symbol)
			   (vector (custom-unlispify-menu-entry symbol)
				   `(customize-variable ',symbol)
				   ':style 'toggle
				   ':selected symbol)))

(if (string-match "XEmacs" emacs-version)
    ;; XEmacs can create menus dynamically.
    (defun custom-group-menu-create (widget symbol)
      "Ignoring WIDGET, create a menu entry for customization group SYMBOL."
      `( ,(custom-unlispify-menu-entry symbol t)
	 :filter (lambda (&rest junk)
		   (cdr (custom-menu-create ',symbol)))))
  ;; But emacs can't.
  (defun custom-group-menu-create (widget symbol)
    "Ignoring WIDGET, create a menu entry for customization group SYMBOL."
    ;; Limit the nesting.
    (let ((custom-menu-nesting (1- custom-menu-nesting)))
      (custom-menu-create symbol))))

;;;###autoload
(defun custom-menu-create (symbol)
  "Create menu for customization group SYMBOL.
The menu is in a format applicable to `easy-menu-define'."
  (let* ((item (vector (custom-unlispify-menu-entry symbol)
		       `(customize-group ',symbol)
		       t)))
    (if (and (or (not (boundp 'custom-menu-nesting))
		 (>= custom-menu-nesting 0))
	     (< (length (get symbol 'custom-group)) widget-menu-max-size))
	(let ((custom-prefix-list (custom-prefix-add symbol
						     custom-prefix-list))
	      (members (sort (get symbol 'custom-group)
			     custom-menu-sort-predicate)))
	  (put symbol 'custom-group members)
	  (custom-load-symbol symbol)
	  `(,(custom-unlispify-menu-entry symbol t)
	    ,item
	    "--"
	    ,@(mapcar (lambda (entry)
			(widget-apply (if (listp (nth 1 entry))
					  (nth 1 entry)
					(list (nth 1 entry)))
				      :custom-menu (nth 0 entry)))
		      members)))
      item)))

;;;###autoload
(defun customize-menu-create (symbol &optional name)
  "Return a customize menu for customization group SYMBOL.
If optional NAME is given, use that as the name of the menu. 
Otherwise the menu will be named `Customize'.
The format is suitable for use with `easy-menu-define'."
  (unless name
    (setq name "Customize"))
  (if (string-match "XEmacs" emacs-version)
      ;; We can delay it under XEmacs.
      `(,name
	:filter (lambda (&rest junk)
		  (cdr (custom-menu-create ',symbol))))
    ;; But we must create it now under Emacs.
    (cons name (cdr (custom-menu-create symbol)))))

;;; The Custom Mode.

(defvar custom-mode-map nil
  "Keymap for `custom-mode'.")
  
(unless custom-mode-map
  (setq custom-mode-map (make-sparse-keymap))
  (set-keymap-parent custom-mode-map widget-keymap)
  (define-key custom-mode-map "q" 'bury-buffer))

(easy-menu-define custom-mode-customize-menu 
    custom-mode-map
  "Menu used to customize customization buffers."
  (customize-menu-create 'customize))

(easy-menu-define custom-mode-menu 
    custom-mode-map
  "Menu used in customization buffers."
  `("Custom"
    ["Set" custom-set t]
    ["Save" custom-save t]
    ["Reset to Current" custom-reset-current t]
    ["Reset to Saved" custom-reset-saved t]
    ["Reset to Standard Settings" custom-reset-standard t]
    ["Info" (Info-goto-node "(custom)The Customization Buffer") t]))

(defcustom custom-mode-hook nil
  "Hook called when entering custom-mode."
  :type 'hook
  :group 'customize)

(defun custom-mode ()
  "Major mode for editing customization buffers.

The following commands are available:

Move to next button or editable field.     \\[widget-forward]
Move to previous button or editable field. \\[widget-backward]
Invoke button under the mouse pointer.     \\[widget-button-click]
Invoke button under point.		   \\[widget-button-press]
Set all modifications.			   \\[custom-set]
Make all modifications default.		   \\[custom-save]
Reset all modified options. 		   \\[custom-reset-current]
Reset all modified or set options.	   \\[custom-reset-saved]
Reset all options.			   \\[custom-reset-standard]

Entry to this mode calls the value of `custom-mode-hook'
if that value is non-nil."
  (kill-all-local-variables)
  (setq major-mode 'custom-mode
	mode-name "Custom")
  (use-local-map custom-mode-map)
  (easy-menu-add custom-mode-customize-menu)
  (easy-menu-add custom-mode-menu)
  (make-local-variable 'custom-options)
  (run-hooks 'custom-mode-hook))

;;; The End.

(provide 'cus-edit)

;; cus-edit.el ends here

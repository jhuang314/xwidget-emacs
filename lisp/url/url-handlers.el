;;; url-handlers.el --- file-name-handler stuff for URL loading

;; Copyright (c) 1996, 1997, 1998, 1999, 2004  Free Software Foundation, Inc.

;; Keywords: comm, data, processes, hypermedia

;; This file is part of GNU Emacs.
;;
;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;;; Code:

;; (require 'url)
(eval-when-compile (require 'url-parse))
;; (require 'url-util)
(eval-when-compile (require 'mm-decode))
;; (require 'mailcap)
;; The following functions in the byte compiler's warnings are known not
;; to cause any real problem for the following reasons:
;; - mm-save-part-to-file, mm-destroy-parts: always used
;;   after mm-dissect-buffer and defined in the same file.
;; The following are autoloaded instead of `require'd to avoid eagerly
;; loading all of URL when turning on url-handler-mode in the .emacs.
(autoload 'url-retrieve-synchronously "url" "Retrieve url synchronously.")
(autoload 'url-expand-file-name "url-expand" "Convert url to a fully specified url, and canonicalize it.")
(autoload 'mm-dissect-buffer "mm-decode" "Dissect the current buffer and return a list of MIME handles.")
(autoload 'url-scheme-get-property "url-methods" "Get property of a URL SCHEME.")

(eval-when-compile
  (require 'cl))

;; Implementation status
;; ---------------------
;; Function				Status
;; ------------------------------------------------------------
;; add-name-to-file			Needs DAV Bindings
;; copy-file				Broken (assumes 1st item is URL)
;; delete-directory			Finished (DAV)
;; delete-file				Finished (DAV)
;; diff-latest-backup-file
;; directory-file-name			unnecessary (what about VMS)?
;; directory-files			Finished (DAV)
;; dired-call-process
;; dired-compress-file
;; dired-uncache
;; expand-file-name			Finished
;; file-accessible-directory-p
;; file-attributes			Finished, better with DAV
;; file-directory-p			Needs DAV, finished
;; file-executable-p			Finished
;; file-exists-p			Finished
;; file-local-copy
;; file-modes
;; file-name-all-completions		Finished (DAV)
;; file-name-as-directory
;; file-name-completion			Finished (DAV)
;; file-name-directory
;; file-name-nondirectory
;; file-name-sans-versions		why?
;; file-newer-than-file-p
;; file-ownership-preserved-p		No way to know
;; file-readable-p			Finished
;; file-regular-p			!directory_p
;; file-symlink-p			Needs DAV bindings
;; file-truename			Needs DAV bindings
;; file-writable-p			Check for LOCK?
;; find-backup-file-name		why?
;; get-file-buffer			why?
;; insert-directory			Use DAV
;; insert-file-contents			Finished
;; load
;; make-directory			Finished (DAV)
;; make-symbolic-link			Needs DAV bindings
;; rename-file				Finished (DAV)
;; set-file-modes			Use mod_dav specific executable flag?
;; set-visited-file-modtime		Impossible?
;; shell-command			Impossible?
;; unhandled-file-name-directory
;; vc-registered			Finished (DAV)
;; verify-visited-file-modtime
;; write-region

(defvar url-handler-regexp
  "\\`\\(https?\\|ftp\\|file\\|nfs\\)://"
  "*A regular expression for matching  URLs handled by file-name-handler-alist.
Some valid URL protocols just do not make sense to visit interactively
\(about, data, info, irc, mailto, etc\).  This regular expression
avoids conflicts with local files that look like URLs \(Gnus is
particularly bad at this\).")

;;;###autoload
(define-minor-mode url-handler-mode
  "Use URL to handle URL-like file names."
  :global t
  (if (not (boundp 'file-name-handler-alist))
      ;; Can't be turned ON anyway.
      (setq url-handler-mode nil)
    ;; Remove old entry, if any.
    (setq file-name-handler-alist
	  (delq (rassq 'url-file-handler file-name-handler-alist)
		file-name-handler-alist))
    (if url-handler-mode
	(push (cons url-handler-regexp 'url-file-handler)
	      file-name-handler-alist))))

(defun url-run-real-handler (operation args)
  (let ((inhibit-file-name-handlers (cons 'url-file-handler
					  (if (eq operation inhibit-file-name-operation)
					      inhibit-file-name-handlers)))
	(inhibit-file-name-operation operation))
    (apply operation args)))

(defun url-file-handler (operation &rest args)
  "Function called from the `file-name-handler-alist' routines.
OPERATION is what needs to be done (`file-exists-p', etc).  ARGS are
the arguments that would have been passed to OPERATION."
  (let ((fn (or (get operation 'url-file-handlers)
		(intern-soft (format "url-%s" operation))))
	(val nil)
	(hooked nil))
    (if (and fn (fboundp fn))
	(setq hooked t
	      val (apply fn args))
      (setq hooked nil
	    val (url-run-real-handler operation args)))
    (url-debug 'handlers "%s %S%S => %S" (if hooked "Hooked" "Real")
	       operation args val)
    val))

(defun url-file-handler-identity (&rest args)
  ;; Identity function
  (car args))

;; These are operations that we can fully support
(put 'file-readable-p 'url-file-handlers 'url-file-exists-p)
(put 'substitute-in-file-name 'url-file-handlers 'url-file-handler-identity)
(put 'file-name-absolute-p 'url-file-handlers (lambda (&rest ignored) t))
(put 'expand-file-name 'url-file-handlers 'url-handler-expand-file-name)

;; These are operations that we do not support yet (DAV!!!)
(put 'file-writable-p 'url-file-handlers 'ignore)
(put 'file-symlink-p 'url-file-handlers 'ignore)

(defun url-handler-expand-file-name (file &optional base)
  (if (file-name-absolute-p file)
      (expand-file-name file "/")
    (url-expand-file-name file base)))

;; The actual implementation
;;;###autoload
(defun url-copy-file (url newname &optional ok-if-already-exists keep-time)
  "Copy URL to NEWNAME.  Both args must be strings.
Signals a `file-already-exists' error if file NEWNAME already exists,
unless a third argument OK-IF-ALREADY-EXISTS is supplied and non-nil.
A number as third arg means request confirmation if NEWNAME already exists.
This is what happens in interactive use with M-x.
Fourth arg KEEP-TIME non-nil means give the new file the same
last-modified time as the old one.  (This works on only some systems.)
A prefix arg makes KEEP-TIME non-nil."
  (if (and (file-exists-p newname)
	   (not ok-if-already-exists))
      (error "Opening output file: File already exists, %s" newname))
  (let ((buffer (url-retrieve-synchronously url))
	(handle nil))
    (if (not buffer)
	(error "Opening input file: No such file or directory, %s" url))
    (with-current-buffer buffer
      (setq handle (mm-dissect-buffer t)))
    (mm-save-part-to-file handle newname)
    (kill-buffer buffer)
    (mm-destroy-parts handle)))

;;;###autoload
(defun url-file-local-copy (url &rest ignored)
  "Copy URL into a temporary file on this machine.
Returns the name of the local copy, or nil, if FILE is directly
accessible."
  (let ((filename (make-temp-name "url")))
    (url-copy-file url filename)
    filename))

;;;###autoload
(defun url-insert-file-contents (url &optional visit beg end replace)
  (let ((buffer (url-retrieve-synchronously url))
	(handle nil)
	(data nil))
    (if (not buffer)
	(error "Opening input file: No such file or directory, %s" url))
    (if visit (setq buffer-file-name url))
    (with-current-buffer buffer
      (setq handle (mm-dissect-buffer t))
      (set-buffer (mm-handle-buffer handle))
      (setq data (if beg (buffer-substring beg end)
		   (buffer-string))))
    (kill-buffer buffer)
    (mm-destroy-parts handle)
    (if replace (delete-region (point-min) (point-max)))
    (save-excursion
      (let ((start (point)))
	(insert data)
	;; FIXME: for text/plain data, we sometimes receive a `charset'
	;; annotation which we could use as a hint of the locale in use
	;; at the remote site.  Not sure how/if that should be done.  --Stef
	(decode-coding-inserted-region
	 start (point) url visit beg end replace)))
    (list url (length data))))

(defun url-file-name-completion (url directory)
  (error "Unimplemented"))

(defun url-file-name-all-completions (file directory)
  (error "Unimplemented"))

;; All other handlers map onto their respective backends.
(defmacro url-handlers-create-wrapper (method args)
  `(defun ,(intern (format "url-%s" method)) ,args
     ,(format "URL file-name-handler wrapper for `%s' call.\n---\n%s" method
              (or (documentation method t) "No original documentation."))
     (setq url (url-generic-parse-url url))
     (when (url-type url)
       (funcall (url-scheme-get-property (url-type url) (quote ,method))
                ,@(remove '&rest (remove '&optional args))))))

(url-handlers-create-wrapper file-exists-p (url))
(url-handlers-create-wrapper file-attributes (url &optional id-format))
(url-handlers-create-wrapper file-symlink-p (url))
(url-handlers-create-wrapper file-writable-p (url))
(url-handlers-create-wrapper file-directory-p (url))
(url-handlers-create-wrapper file-executable-p (url))

(if (featurep 'xemacs)
    (progn
      ;; XEmacs specific prototypes
      (url-handlers-create-wrapper
       directory-files (url &optional full match nosort files-only))
      (url-handlers-create-wrapper
       file-truename (url &optional default)))
  ;; Emacs specific prototypes
  (url-handlers-create-wrapper
   directory-files (url &optional full match nosort))
  (url-handlers-create-wrapper
   file-truename (url &optional counter prev-dirs)))

(add-hook 'find-file-hook 'url-handlers-set-buffer-mode)

(defun url-handlers-set-buffer-mode ()
  "Set correct modes for the current buffer if visiting a remote file."
  (and (stringp buffer-file-name)
       (string-match url-handler-regexp buffer-file-name)
       (auto-save-mode 0)))

(provide 'url-handlers)

;; arch-tag: 7300b99c-cc83-42ff-9147-79b2723c62ac
;;; url-handlers.el ends here

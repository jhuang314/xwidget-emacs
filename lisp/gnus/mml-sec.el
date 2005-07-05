;;; mml-sec.el --- A package with security functions for MML documents
;; Copyright (C) 2000, 2001, 2002, 2003, 2004 Free Software Foundation, Inc.

;; Author: Simon Josefsson <simon@josefsson.org>

;; This file is part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;;; Code:

(require 'mml-smime)
(eval-when-compile (require 'cl))
(autoload 'mml2015-sign "mml2015")
(autoload 'mml2015-encrypt "mml2015")
(autoload 'mml1991-sign "mml1991")
(autoload 'mml1991-encrypt "mml1991")
(autoload 'message-goto-body "message")
(autoload 'mml-insert-tag "mml")

(defvar mml-sign-alist
  '(("smime"     mml-smime-sign-buffer     mml-smime-sign-query)
    ("pgp"       mml-pgp-sign-buffer       list)
    ("pgpauto"   mml-pgpauto-sign-buffer  list)
    ("pgpmime"   mml-pgpmime-sign-buffer   list))
  "Alist of MIME signer functions.")

(defcustom mml-default-sign-method "pgpmime"
  "Default sign method.
The string must have an entry in `mml-sign-alist'."
  :version "22.1"
  :type '(choice (const "smime")
		 (const "pgp")
		 (const "pgpauto")
		 (const "pgpmime")
		 string)
  :group 'message)

(defvar mml-encrypt-alist
  '(("smime"     mml-smime-encrypt-buffer     mml-smime-encrypt-query)
    ("pgp"       mml-pgp-encrypt-buffer       list)
    ("pgpauto"   mml-pgpauto-sign-buffer  list)
    ("pgpmime"   mml-pgpmime-encrypt-buffer   list))
  "Alist of MIME encryption functions.")

(defcustom mml-default-encrypt-method "pgpmime"
  "Default encryption method.
The string must have an entry in `mml-encrypt-alist'."
  :version "22.1"
  :type '(choice (const "smime")
		 (const "pgp")
		 (const "pgpauto")
		 (const "pgpmime")
		 string)
  :group 'message)

(defcustom mml-signencrypt-style-alist
  '(("smime"   separate)
    ("pgp"     combined)
    ("pgpauto" combined)
    ("pgpmime" combined))
  "Alist specifying if `signencrypt' results in two separate operations or not.
The first entry indicates the MML security type, valid entries include
the strings \"smime\", \"pgp\", and \"pgpmime\".  The second entry is
a symbol `separate' or `combined' where `separate' means that MML signs
and encrypt messages in a two step process, and `combined' means that MML
signs and encrypt the message in one step.

Note that the output generated by using a `combined' mode is NOT
understood by all PGP implementations, in particular PGP version
2 does not support it!  See Info node `(message)Security' for
details."
  :version "22.1"
  :group 'message
  :type '(repeat (list (choice (const :tag "S/MIME" "smime")
			       (const :tag "PGP" "pgp")
			       (const :tag "PGP/MIME" "pgpmime")
			       (string :tag "User defined"))
		       (choice (const :tag "Separate" separate)
			       (const :tag "Combined" combined)))))

;;; Configuration/helper functions

(defun mml-signencrypt-style (method &optional style)
  "Function for setting/getting the signencrypt-style used.  Takes two
arguments, the method (e.g. \"pgp\") and optionally the mode
\(e.g. combined).  If the mode is omitted, the current value is returned.

For example, if you prefer to use combined sign & encrypt with
smime, putting the following in your Gnus startup file will
enable that behavior:

\(mml-set-signencrypt-style \"smime\" combined)

You can also customize or set `mml-signencrypt-style-alist' instead."
  (let ((style-item (assoc method mml-signencrypt-style-alist)))
    (if style-item
	(if (or (eq style 'separate)
		(eq style 'combined))
	    ;; valid style setting?
	    (setf (second style-item) style)
	  ;; otherwise, just return the current value
	  (second style-item))
      (message "Warning, attempt to set invalid signencrypt style"))))

;;; Security functions

(defun mml-smime-sign-buffer (cont)
  (or (mml-smime-sign cont)
      (error "Signing failed... inspect message logs for errors")))

(defun mml-smime-encrypt-buffer (cont &optional sign)
  (when sign
    (message "Combined sign and encrypt S/MIME not support yet")
    (sit-for 1))
  (or (mml-smime-encrypt cont)
      (error "Encryption failed... inspect message logs for errors")))

(defun mml-pgp-sign-buffer (cont)
  (or (mml1991-sign cont)
      (error "Signing failed... inspect message logs for errors")))

(defun mml-pgp-encrypt-buffer (cont &optional sign)
  (or (mml1991-encrypt cont sign)
      (error "Encryption failed... inspect message logs for errors")))

(defun mml-pgpmime-sign-buffer (cont)
  (or (mml2015-sign cont)
      (error "Signing failed... inspect message logs for errors")))

(defun mml-pgpmime-encrypt-buffer (cont &optional sign)
  (or (mml2015-encrypt cont sign)
      (error "Encryption failed... inspect message logs for errors")))

(defun mml-pgpauto-sign-buffer (cont)
  (message-goto-body)
  (or (if (re-search-backward "Content-Type: *multipart/.*" nil t) ; there must be a better way...
	  (mml2015-sign cont)
	(mml1991-sign cont))
      (error "Encryption failed... inspect message logs for errors")))

(defun mml-pgpauto-encrypt-buffer (cont &optional sign)
  (message-goto-body)
  (or (if (re-search-backward "Content-Type: *multipart/.*" nil t) ; there must be a better way...
	  (mml2015-encrypt cont sign)
	(mml1991-encrypt cont sign))
      (error "Encryption failed... inspect message logs for errors")))

(defun mml-secure-part (method &optional sign)
  (save-excursion
    (let ((tags (funcall (nth 2 (assoc method (if sign mml-sign-alist
						mml-encrypt-alist))))))
      (cond ((re-search-backward
	      "<#\\(multipart\\|part\\|external\\|mml\\)" nil t)
	     (goto-char (match-end 0))
	     (insert (if sign " sign=" " encrypt=") method)
	     (while tags
	       (let ((key (pop tags))
		     (value (pop tags)))
		 (when value
		   ;; Quote VALUE if it contains suspicious characters.
		   (when (string-match "[\"'\\~/*;() \t\n]" value)
		     (setq value (prin1-to-string value)))
		   (insert (format " %s=%s" key value))))))
	    ((or (re-search-backward
		  (concat "^" (regexp-quote mail-header-separator) "\n") nil t)
		 (re-search-forward
		  (concat "^" (regexp-quote mail-header-separator) "\n") nil t))
	     (goto-char (match-end 0))
	     (apply 'mml-insert-tag 'part (cons (if sign 'sign 'encrypt)
						(cons method tags))))
	    (t (error "The message is corrupted. No mail header separator"))))))

(defun mml-secure-sign-pgp ()
  "Add MML tags to PGP sign this MML part."
  (interactive)
  (mml-secure-part "pgp" 'sign))

(defun mml-secure-sign-pgpauto ()
  "Add MML tags to PGP-auto sign this MML part."
  (interactive)
  (mml-secure-part "pgpauto" 'sign))

(defun mml-secure-sign-pgpmime ()
  "Add MML tags to PGP/MIME sign this MML part."
  (interactive)
  (mml-secure-part "pgpmime" 'sign))

(defun mml-secure-sign-smime ()
  "Add MML tags to S/MIME sign this MML part."
  (interactive)
  (mml-secure-part "smime" 'sign))

(defun mml-secure-encrypt-pgp ()
  "Add MML tags to PGP encrypt this MML part."
  (interactive)
  (mml-secure-part "pgp"))

(defun mml-secure-encrypt-pgpmime ()
  "Add MML tags to PGP/MIME encrypt this MML part."
  (interactive)
  (mml-secure-part "pgpmime"))

(defun mml-secure-encrypt-smime ()
  "Add MML tags to S/MIME encrypt this MML part."
  (interactive)
  (mml-secure-part "smime"))

;; defuns that add the proper <#secure ...> tag to the top of the message body
(defun mml-secure-message (method &optional modesym)
  (let ((mode (prin1-to-string modesym))
	insert-loc)
    (mml-unsecure-message)
    (save-excursion
      (goto-char (point-min))
      (cond ((re-search-forward
	      (concat "^" (regexp-quote mail-header-separator) "\n") nil t)
	     (goto-char (setq insert-loc (match-end 0)))
	     (unless (looking-at "<#secure")
	       (mml-insert-tag
		'secure 'method method 'mode mode)))
	    (t (error
		"The message is corrupted. No mail header separator"))))
    (when (eql insert-loc (point))
      (forward-line 1))))

(defun mml-unsecure-message ()
  "Remove security related MML tags from message."
  (interactive)
  (save-excursion
    (goto-char (point-max))
    (when (re-search-backward "^<#secure.*>\n" nil t)
      (delete-region (match-beginning 0) (match-end 0)))))

(defun mml-secure-message-sign-smime ()
  "Add MML tag to encrypt/sign the entire message."
  (interactive)
  (mml-secure-message "smime" 'sign))

(defun mml-secure-message-sign-pgp ()
  "Add MML tag to encrypt/sign the entire message."
  (interactive)
  (mml-secure-message "pgp" 'sign))

(defun mml-secure-message-sign-pgpmime ()
  "Add MML tag to encrypt/sign the entire message."
  (interactive)
  (mml-secure-message "pgpmime" 'sign))

(defun mml-secure-message-sign-pgpauto ()
  "Add MML tag to encrypt/sign the entire message."
  (interactive)
  (mml-secure-message "pgpauto" 'sign))

(defun mml-secure-message-encrypt-smime (&optional dontsign)
  "Add MML tag to encrypt and sign the entire message.
If called with a prefix argument, only encrypt (do NOT sign)."
  (interactive "P")
  (mml-secure-message "smime" (if dontsign 'encrypt 'signencrypt)))

(defun mml-secure-message-encrypt-pgp (&optional dontsign)
  "Add MML tag to encrypt and sign the entire message.
If called with a prefix argument, only encrypt (do NOT sign)."
  (interactive "P")
  (mml-secure-message "pgp" (if dontsign 'encrypt 'signencrypt)))

(defun mml-secure-message-encrypt-pgpmime (&optional dontsign)
  "Add MML tag to encrypt and sign the entire message.
If called with a prefix argument, only encrypt (do NOT sign)."
  (interactive "P")
  (mml-secure-message "pgpmime" (if dontsign 'encrypt 'signencrypt)))

(defun mml-secure-message-encrypt-pgpauto (&optional dontsign)
  "Add MML tag to encrypt and sign the entire message.
If called with a prefix argument, only encrypt (do NOT sign)."
  (interactive "P")
  (mml-secure-message "pgpauto" (if dontsign 'encrypt 'signencrypt)))

(provide 'mml-sec)

;;; arch-tag: 111c56e7-df5e-4287-87d7-93ed2911ec6c
;;; mml-sec.el ends here

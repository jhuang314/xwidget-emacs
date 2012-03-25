;;; gnus-sieve.el --- Utilities to manage sieve scripts for Gnus

;; Copyright (C) 2001-2012 Free Software Foundation, Inc.

;; Author: NAGY Andras <nagya@inf.elte.hu>,
;;	Simon Josefsson <simon@josefsson.org>

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Gnus glue to generate complete Sieve scripts from Gnus Group
;; Parameters with "if" test predicates.

;;; Code:

(require 'gnus)
(require 'gnus-sum)
(require 'format-spec)
(autoload 'sieve-mode "sieve-mode")
(eval-when-compile
  (require 'sieve))

;; Variables

(defgroup gnus-sieve nil
  "Manage sieve scripts in Gnus."
  :group 'gnus)

(defcustom gnus-sieve-file "~/.sieve"
  "Path to your Sieve script."
  :type 'file
  :group 'gnus-sieve)

(defcustom gnus-sieve-region-start "\n## Begin Gnus Sieve Script\n"
  "Line indicating the start of the autogenerated region in
your Sieve script."
  :type 'string
  :group 'gnus-sieve)

(defcustom gnus-sieve-region-end "\n## End Gnus Sieve Script\n"
  "Line indicating the end of the autogenerated region in
your Sieve script."
  :type 'string
  :group 'gnus-sieve)

(defcustom gnus-sieve-select-method nil
  "Which select method we generate the Sieve script for.

For example: \"nnimap:mailbox\""
  :group 'gnus-sieve)

(defcustom gnus-sieve-crosspost t
  "Whether the generated Sieve script should do crossposting."
  :type 'boolean
  :group 'gnus-sieve)

(defcustom gnus-sieve-update-shell-command "echo put %f | sieveshell %s"
  "Shell command to execute after updating your Sieve script.  The following
formatting characters are recognized:

%f    Script's file name (gnus-sieve-file)
%s    Server name (from gnus-sieve-select-method)"
  :type 'string
  :group 'gnus-sieve)

;;;###autoload
(defun gnus-sieve-update ()
  "Update the Sieve script in gnus-sieve-file, by replacing the region
between gnus-sieve-region-start and gnus-sieve-region-end with
\(gnus-sieve-script gnus-sieve-select-method gnus-sieve-crosspost\), then
execute gnus-sieve-update-shell-command.
See the documentation for these variables and functions for details."
  (interactive)
  (gnus-sieve-generate)
  (save-buffer)
  (shell-command
   (format-spec gnus-sieve-update-shell-command
		(format-spec-make ?f gnus-sieve-file
				  ?s (or (cadr (gnus-server-get-method
						nil gnus-sieve-select-method))
					 "")))))

;;;###autoload
(defun gnus-sieve-generate ()
  "Generate the Sieve script in gnus-sieve-file, by replacing the region
between gnus-sieve-region-start and gnus-sieve-region-end with
\(gnus-sieve-script gnus-sieve-select-method gnus-sieve-crosspost\).
See the documentation for these variables and functions for details."
  (interactive)
  (require 'sieve)
  (find-file gnus-sieve-file)
  (goto-char (point-min))
  (if (re-search-forward (regexp-quote gnus-sieve-region-start) nil t)
      (delete-region (match-beginning 0)
		     (or (re-search-forward (regexp-quote
					     gnus-sieve-region-end) nil t)
			 (point)))
    (insert sieve-template))
  (insert gnus-sieve-region-start
	  (gnus-sieve-script gnus-sieve-select-method gnus-sieve-crosspost)
	  gnus-sieve-region-end))

(defun gnus-sieve-guess-rule-for-article ()
  "Guess a sieve rule based on RFC822 article in buffer.
Return nil if no rule could be guessed."
  (when (message-fetch-field "sender")
    `(sieve address "sender" ,(message-fetch-field "sender"))))

;;;###autoload
(defun gnus-sieve-article-add-rule ()
  (interactive)
  (gnus-summary-select-article nil 'force)
  (with-current-buffer gnus-original-article-buffer
    (let ((rule (gnus-sieve-guess-rule-for-article))
	  (info (gnus-get-info gnus-newsgroup-name)))
      (if (null rule)
	  (error "Could not guess rule for article")
	(gnus-info-set-params info (cons rule (gnus-info-params info)))
	(message "Added rule in group %s for article: %s" gnus-newsgroup-name
		 rule)))))

;; Internals

;; FIXME: do proper quoting of " etc
(defun gnus-sieve-string-list (list)
  "Convert an elisp string list to a Sieve string list.

For example:
\(gnus-sieve-string-list '(\"to\" \"cc\"))
  => \"[\\\"to\\\", \\\"cc\\\"]\"
"
  (concat "[\"" (mapconcat 'identity list "\", \"") "\"]"))

(defun gnus-sieve-test-list (list)
  "Convert an elisp test list to a Sieve test list.

For example:
\(gnus-sieve-test-list '((address \"sender\" \"boss@company.com\") (size :over 4K)))
  => \"(address \\\"sender\\\" \\\"boss@company.com\\\", size :over 4K)\""
  (concat "(" (mapconcat 'gnus-sieve-test list ", ") ")"))

;; FIXME: do proper quoting
(defun gnus-sieve-test-token (token)
  "Convert an elisp test token to a Sieve test token.

For example:
\(gnus-sieve-test-token 'address)
  => \"address\"

\(gnus-sieve-test-token \"sender\")
  => \"\\\"sender\\\"\"

\(gnus-sieve-test-token '(\"to\" \"cc\"))
  => \"[\\\"to\\\", \\\"cc\\\"]\""
  (cond
   ((symbolp token)            ;; Keyword
    (symbol-name token))

   ((stringp token)            ;; String
    (concat "\"" token "\""))

   ((and (listp token)         ;; String list
	 (stringp (car token)))
    (gnus-sieve-string-list token))

   ((and (listp token)         ;; Test list
	 (listp (car token)))
    (gnus-sieve-test-list token))))

(defun gnus-sieve-test (test)
  "Convert an elisp test to a Sieve test.

For example:
\(gnus-sieve-test '(address \"sender\" \"sieve-admin@extundo.com\"))
  => \"address \\\"sender\\\" \\\"sieve-admin@extundo.com\\\"\"

\(gnus-sieve-test '(anyof ((header :contains (\"to\" \"cc\") \"my@address.com\")
			  (size :over 100K))))
  => \"anyof (header :contains [\\\"to\\\", \\\"cc\\\"] \\\"my@address.com\\\",
	     size :over 100K)\""
  (mapconcat 'gnus-sieve-test-token test " "))

(defun gnus-sieve-script (&optional method crosspost)
  "Generate a Sieve script based on groups with select method METHOD
\(or all groups if nil\).  Only groups having a `sieve' parameter are
considered.  This parameter should contain an elisp test
\(see the documentation of gnus-sieve-test for details\).  For each
such group, a Sieve IF control structure is generated, having the
test as the condition and { fileinto \"group.name\"; } as the body.

If CROSSPOST is nil, each conditional body contains a \"stop\" command
which stops execution after a match is found.

For example: If the INBOX.list.sieve group has the

  (sieve address \"sender\" \"sieve-admin@extundo.com\")

group parameter, (gnus-sieve-script) results in:

  if address \"sender\" \"sieve-admin@extundo.com\" {
          fileinto \"INBOX.list.sieve\";
  }

This is returned as a string."
  (let* ((newsrc (cdr gnus-newsrc-alist))
	 script)
    (dolist (info newsrc)
      (when (or (not method)
		(gnus-server-equal method (gnus-info-method info)))
	(let* ((group (gnus-info-group info))
	       (spec (gnus-group-find-parameter group 'sieve t)))
	  (when spec
	    (push (concat "if " (gnus-sieve-test spec) " {\n"
			  "\tfileinto \"" (gnus-group-real-name group) "\";\n"
			  (if crosspost
			      ""
			    "\tstop;\n")
			  "}")
		  script)))))
    (mapconcat 'identity script "\n")))

(provide 'gnus-sieve)

;;; gnus-sieve.el ends here

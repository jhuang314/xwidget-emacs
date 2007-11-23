;;; rng-parse.el --- parse an XML file and validate it against a schema

;; Copyright (C) 2003 Free Software Foundation, Inc.

;; Author: James Clark
;; Keywords: XML, RelaxNG

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.

;; You should have received a copy of the GNU General Public
;; License along with this program; if not, write to the Free
;; Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
;; MA 02111-1307 USA

;;; Commentary:

;; This combines the validation machinery in rng-match.el with the
;; parser in nxml-parse.el by using the `nxml-validate-function' hook.

;;; Code:

(require 'nxml-parse)
(require 'rng-match)
(require 'rng-dt)

(defvar rng-parse-prev-was-start-tag nil)

(defun rng-parse-validate-file (schema file)
  "Parse and validate the XML document in FILE and return it as a list.
The returned list has the same form as that returned by
`nxml-parse-file'.  SCHEMA is a list representing the schema to use
for validation, such as returned by the function `rng-c-load-schema'.
If the XML document is invalid with respect to schema, an error will
be signaled in the same way as when it is not well-formed."
  (save-excursion
    (set-buffer (nxml-parse-find-file file))
    (unwind-protect
	(let ((nxml-parse-file-name file)
	      (nxml-validate-function 'rng-parse-do-validate)
	      (rng-dt-namespace-context-getter '(nxml-ns-get-context))
	      rng-parse-prev-was-start-tag)
	  ;; We don't simply call nxml-parse-file, because
	  ;; we want to do rng-match-with-schema in the same
	  ;; buffer in which we will call the other rng-match-* functions.
	  (rng-match-with-schema schema
	    (nxml-parse-instance)))
      (kill-buffer nil))))

(defun rng-parse-do-validate (text start-tag)
  (cond ((and (let ((tem rng-parse-prev-was-start-tag))
		(setq rng-parse-prev-was-start-tag (and start-tag t))
		tem)
	      (not start-tag)
	      (rng-match-text-typed-p))
	 (unless (rng-match-element-value (or text ""))
	   (cons "Invalid data" (and text 'text))))
	((and text
	      (not (rng-blank-p text))
	      (not (rng-match-mixed-text)))
	 (cons "Text not allowed" 'text))
	((not start-tag)
	 (unless (rng-match-end-tag)
	   (cons "Missing elements" nil)))
	((not (rng-match-start-tag-open
	       (rng-parse-to-match-name (car start-tag))))
	 (cons "Element not allowed" nil))
	(t
	 (let ((atts (cadr start-tag))
	       (i 0)
	       att err)
	   (while (and atts (not err))
	     (setq att (car atts))
	     (when (not (and (consp (car att))
			     (eq (caar att) nxml-xmlns-namespace-uri)))
	       (setq err
		     (cond ((not (rng-match-attribute-name
				  (rng-parse-to-match-name (car att))))
			    (cons "Attribute not allowed"
				  (cons 'attribute-name i)))
			   ((not (rng-match-attribute-value (cdr att)))
			    (cons "Invalid attribute value"
				  (cons 'attribute-value i))))))
	     (setq atts (cdr atts))
	     (setq i (1+ i)))
	   (or err
	       (unless (rng-match-start-tag-close)
		 (cons "Missing attributes" 'tag-close)))))))

(defun rng-parse-to-match-name (name)
  (if (consp name)
      name
    (cons nil name)))

(provide 'rng-parse)

;; arch-tag: 8f14f533-b687-4dc0-9cd7-617ead856981
;;; rng-parse.el ends here

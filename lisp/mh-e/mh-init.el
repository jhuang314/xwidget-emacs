;;; mh-init.el --- MH-E initialization

;; Copyright (C) 2003, 2004, 2005, 2006 Free Software Foundation, Inc.

;; Author: Peter S. Galbraith <psg@debian.org>
;; Maintainer: Bill Wohler <wohler@newt.com>
;; Keywords: mail
;; See: mh-e.el

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
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Sets up the MH variant (currently nmh, MH, or GNU mailutils).
;;
;; Users may customize `mh-variant' to switch between available variants.
;; Available MH variants are returned by the function `mh-variants'.
;; Developers may check which variant is currently in use with the
;; variable `mh-variant-in-use' or the function `mh-variant-p'.
;;
;; Also contains code that is used at load or initialization time only.

;;; Change Log:

;;; Code:

(eval-when-compile (require 'mh-acros))
(mh-require-cl)
(require 'mh-buffers)
(require 'mh-utils)

(defvar mh-sys-path
  '("/usr/local/nmh/bin"                ; nmh default
    "/usr/local/bin/mh/"
    "/usr/local/mh/"
    "/usr/bin/mh/"                      ; Ultrix 4.2, Linux
    "/usr/new/mh/"                      ; Ultrix < 4.2
    "/usr/contrib/mh/bin/"              ; BSDI
    "/usr/pkg/bin/"                     ; NetBSD
    "/usr/local/bin/"
    "/usr/local/bin/mu-mh/"             ; GNU mailutils - default
    "/usr/bin/mu-mh/")                  ; GNU mailutils - packaged
  "List of directories to search for variants of the MH variant.
The list `exec-path' is searched in addition to this list.
There's no need for users to modify this list. Instead add extra
directories to the customizable variable `mh-path'.")

;; Set for local environment:
;; mh-progs and mh-lib used to be set in paths.el, which tried to
;; figure out at build time which of several possible directories MH
;; was installed into.  But if you installed MH after building Emacs,
;; this would almost certainly be wrong, so now we do it at run time.

(defvar mh-progs nil
  "Directory containing MH commands, such as inc, repl, and rmm.")

(defvar mh-lib nil
  "Directory containing the MH library.
This directory contains, among other things, the components file.")

(defvar mh-lib-progs nil
  "Directory containing MH helper programs.
This directory contains, among other things, the mhl program.")

(defvar mh-flists-present-flag nil
  "Non-nil means that we have \"flists\".")

;;;###autoload
(put 'mh-progs 'risky-local-variable t)
;;;###autoload
(put 'mh-lib 'risky-local-variable t)
;;;###autoload
(put 'mh-lib-progs 'risky-local-variable t)

(defvar mh-variants nil
  "List describing known MH variants.
Do not access this variable directly as it may not have yet been initialized.
Use the function `mh-variants' instead.")

;;;###mh-autoload
(defun mh-variants ()
  "Return a list of installed variants of MH on the system.
This function looks for MH in `mh-sys-path', `mh-path' and
`exec-path'. The format of the list of variants that is returned
is described by the variable `mh-variants'."
  (if mh-variants
      mh-variants
    (let ((list-unique))
      ;; Make a unique list of directories, keeping the given order.
      ;; We don't want the same MH variant to be listed multiple times.
      (loop for dir in (append mh-path mh-sys-path exec-path) do
            (setq dir (file-chase-links (directory-file-name dir)))
            (add-to-list 'list-unique dir))
      (loop for dir in (nreverse list-unique) do
            (when (and dir (file-directory-p dir) (file-readable-p dir))
              (let ((variant (mh-variant-info dir)))
                (if variant
                    (add-to-list 'mh-variants variant)))))
      mh-variants)))

(defun mh-variant-info (dir)
  "Return MH variant found in DIR, or nil if none present."
  (save-excursion
    (let ((tmp-buffer (get-buffer-create mh-temp-buffer)))
      (set-buffer tmp-buffer)
      (cond
       ((mh-variant-mh-info dir))
       ((mh-variant-nmh-info dir))
       ((mh-variant-mu-mh-info dir))))))

(defun mh-variant-mh-info (dir)
  "Return info for MH variant in DIR assuming a temporary buffer is setup."
  ;; MH does not have the -version option.
  ;; Its version number is included in the output of "-help" as:
  ;;
  ;; version: MH 6.8.4 #2[UCI] (burrito) of Fri Jan 15 20:01:39 EST 1999
  ;; options: [ATHENA] [BIND] [DUMB] [LIBLOCKFILE] [LOCALE] [MAILGROUP] [MHE]
  ;;          [MHRC] [MIME] [MORE='"/usr/bin/sensible-pager"'] [NLINK_HACK]
  ;;          [NORUSERPASS] [OVERHEAD] [POP] [POPSERVICE='"pop-3"'] [RENAME]
  ;;          [RFC1342] [RPATHS] [RPOP] [SENDMTS] [SMTP] [SOCKETS]
  ;;          [SPRINTFTYPE=int] [SVR4] [SYS5] [SYS5DIR] [TERMINFO]
  ;;          [TYPESIG=void] [UNISTD] [UTK] [VSPRINTF]
  (let ((mhparam (expand-file-name "mhparam" dir)))
    (when (mh-file-command-p mhparam)
      (erase-buffer)
      (call-process mhparam nil '(t nil) nil "-help")
      (goto-char (point-min))
      (when (search-forward-regexp "version: MH \\(\\S +\\)" nil t)
        (let ((version (format "MH %s" (match-string 1))))
          (erase-buffer)
          (call-process mhparam nil '(t nil) nil "libdir")
          (goto-char (point-min))
          (when (search-forward-regexp "^.*$" nil t)
            (let ((libdir (match-string 0)))
              `(,version
                (variant        mh)
                (mh-lib-progs   ,libdir)
                (mh-lib         ,libdir)
                (mh-progs       ,dir)
                (flists         nil)))))))))

(defun mh-variant-mu-mh-info (dir)
  "Return info for GNU mailutils variant in DIR.
This assumes that a temporary buffer is setup."
  ;; 'mhparam -version' output:
  ;; mhparam (GNU mailutils 0.3.2)
  (let ((mhparam (expand-file-name "mhparam" dir)))
    (when (mh-file-command-p mhparam)
      (erase-buffer)
      (call-process mhparam nil '(t nil) nil "-version")
      (goto-char (point-min))
      (when (search-forward-regexp "mhparam (\\(GNU [Mm]ailutils \\S +\\))"
                                   nil t)
        (let ((version (match-string 1))
              (mh-progs dir))
          `(,version
            (variant        mu-mh)
            (mh-lib-progs   ,(mh-profile-component "libdir"))
            (mh-lib         ,(mh-profile-component "etcdir"))
            (mh-progs       ,dir)
            (flists         ,(file-exists-p
                              (expand-file-name "flists" dir)))))))))

(defun mh-variant-nmh-info (dir)
  "Return info for nmh variant in DIR assuming a temporary buffer is setup."
  ;; `mhparam -version' outputs:
  ;; mhparam -- nmh-1.1-RC1 [compiled on chaak at Fri Jun 20 11:03:28 PDT 2003]
  (let ((mhparam (expand-file-name "mhparam" dir)))
    (when (mh-file-command-p mhparam)
      (erase-buffer)
      (call-process mhparam nil '(t nil) nil "-version")
      (goto-char (point-min))
      (when (search-forward-regexp "mhparam -- nmh-\\(\\S +\\)" nil t)
        (let ((version (format "nmh %s" (match-string 1)))
              (mh-progs dir))
          `(,version
            (variant        nmh)
            (mh-lib-progs   ,(mh-profile-component "libdir"))
            (mh-lib         ,(mh-profile-component "etcdir"))
            (mh-progs       ,dir)
            (flists         ,(file-exists-p
                              (expand-file-name "flists" dir)))))))))

(defun mh-file-command-p (file)
  "Return t if file FILE is the name of a executable regular file."
  (and (file-regular-p file) (file-executable-p file)))

(defvar mh-variant-in-use nil
  "The MH variant currently in use; a string with variant and version number.
This differs from `mh-variant' when the latter is set to
\"autodetect\".")

;;;###mh-autoload
(defun mh-variant-set (variant)
  "Set the MH variant to VARIANT.
Sets `mh-progs', `mh-lib', `mh-lib-progs' and
`mh-flists-present-flag'.
If the VARIANT is \"autodetect\", then first try nmh, then MH and
finally GNU mailutils."
  (interactive
   (list (completing-read
          "MH variant: "
          (mapcar (lambda (x) (list (car x))) (mh-variants))
          nil t)))
  (let ((valid-list (mapcar (lambda (x) (car x)) (mh-variants))))
    (cond
     ((eq variant 'none))
     ((eq variant 'autodetect)
      (cond
       ((mh-variant-set-variant 'nmh)
        (message "%s installed as MH variant" mh-variant-in-use))
       ((mh-variant-set-variant 'mh)
        (message "%s installed as MH variant" mh-variant-in-use))
       ((mh-variant-set-variant 'mu-mh)
        (message "%s installed as MH variant" mh-variant-in-use))
       (t
        (message "No MH variant found on the system"))))
     ((member variant valid-list)
      (when (not (mh-variant-set-variant variant))
        (message "Warning: %s variant not found. Autodetecting..." variant)
        (mh-variant-set 'autodetect)))
     (t
      (message "Unknown variant; use %s"
               (mapconcat '(lambda (x) (format "%s" (car x)))
                          (mh-variants) " or "))))))

(defun mh-variant-set-variant (variant)
  "Setup the system variables for the MH variant named VARIANT.
If VARIANT is a string, use that key in the alist returned by the
function `mh-variants'.
If VARIANT is a symbol, select the first entry that matches that
variant."
  (cond
   ((stringp variant)                   ;e.g. "nmh 1.1-RC1"
    (when (assoc variant (mh-variants))
      (let* ((alist (cdr (assoc variant (mh-variants))))
             (lib-progs (cadr (assoc 'mh-lib-progs alist)))
             (lib       (cadr (assoc 'mh-lib       alist)))
             (progs     (cadr (assoc 'mh-progs     alist)))
             (flists    (cadr (assoc 'flists       alist))))
        ;;(set-default mh-variant variant)
        (setq mh-x-mailer-string     nil
              mh-flists-present-flag flists
              mh-lib-progs           lib-progs
              mh-lib                 lib
              mh-progs               progs
              mh-variant-in-use      variant))))
   ((symbolp variant)                   ;e.g. 'nmh (pick the first match)
    (loop for variant-list in (mh-variants)
          when (eq variant (cadr (assoc 'variant (cdr variant-list))))
          return (let* ((version   (car variant-list))
                        (alist (cdr variant-list))
                        (lib-progs (cadr (assoc 'mh-lib-progs alist)))
                        (lib       (cadr (assoc 'mh-lib       alist)))
                        (progs     (cadr (assoc 'mh-progs     alist)))
                        (flists    (cadr (assoc 'flists       alist))))
                   ;;(set-default mh-variant flavor)
                   (setq mh-x-mailer-string     nil
                         mh-flists-present-flag flists
                         mh-lib-progs           lib-progs
                         mh-lib                 lib
                         mh-progs               progs
                         mh-variant-in-use      version)
                   t)))))

;;;###mh-autoload
(defun mh-variant-p (&rest variants)
  "Return t if variant is any of VARIANTS.
Currently known variants are 'MH, 'nmh, and 'mu-mh."
  (let ((variant-in-use
         (cadr (assoc 'variant (assoc mh-variant-in-use (mh-variants))))))
    (not (null (member variant-in-use variants)))))



;;; Read MH Profile

(defvar mh-find-path-run nil
  "Non-nil if `mh-find-path' has been run already.
Do not access this variable; `mh-find-path' already uses it to
avoid running more than once.")

(defun mh-find-path ()
  "Set variables from user's MH profile.

This function sets `mh-user-path' from your \"Path:\" MH profile
component (but defaults to \"Mail\" if one isn't present),
`mh-draft-folder' from \"Draft-Folder:\", `mh-unseen-seq' from
\"Unseen-Sequence:\", `mh-previous-seq' from
\"Previous-Sequence:\", and `mh-inbox' from \"Inbox:\" (defaults
to \"+inbox\").

The hook `mh-find-path-hook' is run after these variables have
been set. This hook can be used the change the value of these
variables if you need to run with different values between MH and
MH-E."
  (unless mh-find-path-run
    ;; Sanity checks.
    (if (and (getenv "MH")
             (not (file-readable-p (getenv "MH"))))
        (error "MH environment variable contains unreadable file %s"
               (getenv "MH")))
    (if (null (mh-variants))
        (error "Install MH and run install-mh before running MH-E"))
    (let ((profile "~/.mh_profile"))
      (if (not (file-readable-p profile))
          (error "Run install-mh before running MH-E")))
    ;; Read MH profile.
    (setq mh-user-path (mh-profile-component "Path"))
    (if (not mh-user-path)
        (setq mh-user-path "Mail"))
    (setq mh-user-path
          (file-name-as-directory
           (expand-file-name mh-user-path (expand-file-name "~"))))
    (unless mh-x-image-cache-directory
      (setq mh-x-image-cache-directory
            (expand-file-name ".mhe-x-image-cache" mh-user-path)))
    (setq mh-draft-folder (mh-profile-component "Draft-Folder"))
    (if mh-draft-folder
        (progn
          (if (not (mh-folder-name-p mh-draft-folder))
              (setq mh-draft-folder (format "+%s" mh-draft-folder)))
          (if (not (file-exists-p (mh-expand-file-name mh-draft-folder)))
              (error
               "Draft folder \"%s\" not found; create it and try again"
               (mh-expand-file-name mh-draft-folder)))))
    (setq mh-inbox (mh-profile-component "Inbox"))
    (cond ((not mh-inbox)
           (setq mh-inbox "+inbox"))
          ((not (mh-folder-name-p mh-inbox))
           (setq mh-inbox (format "+%s" mh-inbox))))
    (setq mh-unseen-seq (mh-profile-component "Unseen-Sequence"))
    (if mh-unseen-seq
        (setq mh-unseen-seq (intern mh-unseen-seq))
      (setq mh-unseen-seq 'unseen))     ;old MH default?
    (setq mh-previous-seq (mh-profile-component "Previous-Sequence"))
    (if mh-previous-seq
        (setq mh-previous-seq (intern mh-previous-seq)))
    (run-hooks 'mh-find-path-hook)
    (mh-collect-folder-names)
    (setq mh-find-path-run t)))



;; Shush compiler.
(eval-when-compile (defvar image-load-path))

(defvar mh-image-load-path-called-flag nil)

;;;###mh-autoload
(defun mh-image-load-path ()
  "Ensure that the MH-E images are accessible by `find-image'.
Images for MH-E are found in ../../etc/images relative to the
files in \"lisp/mh-e\". If `image-load-path' exists (since Emacs
22), then the images directory is added to it if isn't already
there. Otherwise, the images directory is added to the
`load-path' if it isn't already there."
  (unless mh-image-load-path-called-flag
    (let (mh-library-name mh-image-load-path)
      ;; First, find mh-e in the load-path.
      (setq mh-library-name (locate-library "mh-e"))
      (if (not mh-library-name)
        (error "Can not find MH-E in load-path"))
      (setq mh-image-load-path
            (expand-file-name (concat (file-name-directory mh-library-name)
                                      "../../etc/images")))
      (if (not (file-exists-p mh-image-load-path))
          (error "Can not find image directory %s" mh-image-load-path))
      (if (boundp 'image-load-path)
          (add-to-list 'image-load-path mh-image-load-path)
        (add-to-list 'load-path mh-image-load-path)))
    (setq mh-image-load-path-called-flag t)))



;;; Support routines for mh-customize.el

(defvar mh-min-colors-defined-flag (and (not mh-xemacs-flag)
                                        (>= emacs-major-version 22))
  "Non-nil means defface supports min-colors display requirement.")

(defun mh-defface-compat (spec)
  "Convert SPEC for defface if necessary to run on older platforms.
Modifies SPEC in place and returns it. See `defface' for the spec definition.

When `mh-min-colors-defined-flag' is nil, this function finds
display entries with \"min-colors\" requirements and either
removes the \"min-colors\" requirement or strips the display
entirely if the display does not support the number of specified
colors."
  (if mh-min-colors-defined-flag
      spec
    (let ((cells (display-color-cells))
          new-spec)
      ;; Remove entries with min-colors, or delete them if we have fewer colors
      ;; than they specify.
      (loop for entry in (reverse spec) do
            (let ((requirement (if (eq (car entry) t)
                                   nil
                                 (assoc 'min-colors (car entry)))))
              (if requirement
                  (when (>= cells (nth 1 requirement))
                    (setq new-spec (cons (cons (delq requirement (car entry))
                                               (cdr entry))
                                         new-spec)))
                (setq new-spec (cons entry new-spec)))))
      new-spec)))

(provide 'mh-init)

;; Local Variables:
;; indent-tabs-mode: nil
;; sentence-end-double-space: nil
;; End:

;; arch-tag: e8372aeb-d803-42b1-9c95-3c93ad22f63c
;;; mh-init.el ends here

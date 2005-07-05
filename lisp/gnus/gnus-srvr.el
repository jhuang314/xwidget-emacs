;;; gnus-srvr.el --- virtual server support for Gnus
;; Copyright (C) 1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003,
;; 2004, 2005
;;        Free Software Foundation, Inc.

;; Author: Lars Magne Ingebrigtsen <larsi@gnus.org>
;; Keywords: news

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

;;; Code:

(eval-when-compile (require 'cl))

(require 'gnus)
(require 'gnus-spec)
(require 'gnus-group)
(require 'gnus-int)
(require 'gnus-range)

(defcustom gnus-server-mode-hook nil
  "Hook run in `gnus-server-mode' buffers."
  :group 'gnus-server
  :type 'hook)

(defcustom gnus-server-exit-hook nil
  "Hook run when exiting the server buffer."
  :group 'gnus-server
  :type 'hook)

(defcustom gnus-server-line-format "     {%(%h:%w%)} %s%a\n"
  "Format of server lines.
It works along the same lines as a normal formatting string,
with some simple extensions.

The following specs are understood:

%h backend
%n name
%w address
%s status
%a agent covered

General format specifiers can also be used.
See Info node `(gnus)Formatting Variables'."
  :link '(custom-manual "(gnus)Formatting Variables")
  :group 'gnus-server-visual
  :type 'string)

(defcustom gnus-server-mode-line-format "Gnus: %%b"
  "The format specification for the server mode line."
  :group 'gnus-server-visual
  :type 'string)

(defcustom gnus-server-browse-in-group-buffer nil
  "Whether server browsing should take place in the group buffer.
If nil, a faster, but more primitive, buffer is used instead."
  :version "22.1"
  :group 'gnus-server-visual
  :type 'boolean)

;;; Internal variables.

(defvar gnus-inserted-opened-servers nil)

(defvar gnus-server-line-format-alist
  `((?h gnus-tmp-how ?s)
    (?n gnus-tmp-name ?s)
    (?w gnus-tmp-where ?s)
    (?s gnus-tmp-status ?s)
    (?a gnus-tmp-agent ?s)))

(defvar gnus-server-mode-line-format-alist
  `((?S gnus-tmp-news-server ?s)
    (?M gnus-tmp-news-method ?s)
    (?u gnus-tmp-user-defined ?s)))

(defvar gnus-server-line-format-spec nil)
(defvar gnus-server-mode-line-format-spec nil)
(defvar gnus-server-killed-servers nil)

(defvar gnus-server-mode-map)

(defvar gnus-server-menu-hook nil
  "*Hook run after the creation of the server mode menu.")

(defun gnus-server-make-menu-bar ()
  (gnus-turn-off-edit-menu 'server)
  (unless (boundp 'gnus-server-server-menu)
    (easy-menu-define
     gnus-server-server-menu gnus-server-mode-map ""
     '("Server"
       ["Add..." gnus-server-add-server t]
       ["Browse" gnus-server-read-server t]
       ["Scan" gnus-server-scan-server t]
       ["List" gnus-server-list-servers t]
       ["Kill" gnus-server-kill-server t]
       ["Yank" gnus-server-yank-server t]
       ["Copy" gnus-server-copy-server t]
       ["Edit" gnus-server-edit-server t]
       ["Regenerate" gnus-server-regenerate-server t]
       ["Exit" gnus-server-exit t]))

    (easy-menu-define
     gnus-server-connections-menu gnus-server-mode-map ""
     '("Connections"
       ["Open" gnus-server-open-server t]
       ["Close" gnus-server-close-server t]
       ["Offline" gnus-server-offline-server t]
       ["Deny" gnus-server-deny-server t]
       "---"
       ["Open All" gnus-server-open-all-servers t]
       ["Close All" gnus-server-close-all-servers t]
       ["Reset All" gnus-server-remove-denials t]))

    (gnus-run-hooks 'gnus-server-menu-hook)))

(defvar gnus-server-mode-map nil)
(put 'gnus-server-mode 'mode-class 'special)

(unless gnus-server-mode-map
  (setq gnus-server-mode-map (make-sparse-keymap))
  (suppress-keymap gnus-server-mode-map)

  (gnus-define-keys gnus-server-mode-map
    " " gnus-server-read-server-in-server-buffer
    "\r" gnus-server-read-server
    gnus-mouse-2 gnus-server-pick-server
    "q" gnus-server-exit
    "l" gnus-server-list-servers
    "k" gnus-server-kill-server
    "y" gnus-server-yank-server
    "c" gnus-server-copy-server
    "a" gnus-server-add-server
    "e" gnus-server-edit-server
    "s" gnus-server-scan-server

    "O" gnus-server-open-server
    "\M-o" gnus-server-open-all-servers
    "C" gnus-server-close-server
    "\M-c" gnus-server-close-all-servers
    "D" gnus-server-deny-server
    "L" gnus-server-offline-server
    "R" gnus-server-remove-denials

    "n" next-line
    "p" previous-line

    "g" gnus-server-regenerate-server

    "\C-c\C-i" gnus-info-find-node
    "\C-c\C-b" gnus-bug))

(defface gnus-server-agent
  '((((class color) (background light)) (:foreground "PaleTurquoise" :bold t))
    (((class color) (background dark)) (:foreground "PaleTurquoise" :bold t))
    (t (:bold t)))
  "Face used for displaying AGENTIZED servers"
  :group 'gnus-server-visual)
;; backward-compatibility alias
(put 'gnus-server-agent-face 'face-alias 'gnus-server-agent)

(defface gnus-server-opened
  '((((class color) (background light)) (:foreground "Green3" :bold t))
    (((class color) (background dark)) (:foreground "Green1" :bold t))
    (t (:bold t)))
  "Face used for displaying OPENED servers"
  :group 'gnus-server-visual)
;; backward-compatibility alias
(put 'gnus-server-opened-face 'face-alias 'gnus-server-opened)

(defface gnus-server-closed
  '((((class color) (background light)) (:foreground "Steel Blue" :italic t))
    (((class color) (background dark))
     (:foreground "Light Steel Blue" :italic t))
    (t (:italic t)))
  "Face used for displaying CLOSED servers"
  :group 'gnus-server-visual)
;; backward-compatibility alias
(put 'gnus-server-closed-face 'face-alias 'gnus-server-closed)

(defface gnus-server-denied
  '((((class color) (background light)) (:foreground "Red" :bold t))
    (((class color) (background dark)) (:foreground "Pink" :bold t))
    (t (:inverse-video t :bold t)))
  "Face used for displaying DENIED servers"
  :group 'gnus-server-visual)
;; backward-compatibility alias
(put 'gnus-server-denied-face 'face-alias 'gnus-server-denied)

(defface gnus-server-offline
  '((((class color) (background light)) (:foreground "Orange" :bold t))
    (((class color) (background dark)) (:foreground "Yellow" :bold t))
    (t (:inverse-video t :bold t)))
  "Face used for displaying OFFLINE servers"
  :group 'gnus-server-visual)
;; backward-compatibility alias
(put 'gnus-server-offline-face 'face-alias 'gnus-server-offline)

(defcustom gnus-server-agent-face 'gnus-server-agent
  "Face name to use on AGENTIZED servers."
  :version "22.1"
  :group 'gnus-server-visual
  :type 'face)

(defcustom gnus-server-opened-face 'gnus-server-opened
  "Face name to use on OPENED servers."
  :version "22.1"
  :group 'gnus-server-visual
  :type 'face)

(defcustom gnus-server-closed-face 'gnus-server-closed
  "Face name to use on CLOSED servers."
  :version "22.1"
  :group 'gnus-server-visual
  :type 'face)

(defcustom gnus-server-denied-face 'gnus-server-denied
  "Face name to use on DENIED servers."
  :version "22.1"
  :group 'gnus-server-visual
  :type 'face)

(defcustom gnus-server-offline-face 'gnus-server-offline
  "Face name to use on OFFLINE servers."
  :version "22.1"
  :group 'gnus-server-visual
  :type 'face)

(defvar gnus-server-font-lock-keywords
  (list
   '("(\\(agent\\))" 1 gnus-server-agent-face)
   '("(\\(opened\\))" 1 gnus-server-opened-face)
   '("(\\(closed\\))" 1 gnus-server-closed-face)
   '("(\\(offline\\))" 1 gnus-server-offline-face)
   '("(\\(denied\\))" 1 gnus-server-denied-face)))

(defun gnus-server-mode ()
  "Major mode for listing and editing servers.

All normal editing commands are switched off.
\\<gnus-server-mode-map>
For more in-depth information on this mode, read the manual
\(`\\[gnus-info-find-node]').

The following commands are available:

\\{gnus-server-mode-map}"
  (interactive)
  (when (gnus-visual-p 'server-menu 'menu)
    (gnus-server-make-menu-bar))
  (kill-all-local-variables)
  (gnus-simplify-mode-line)
  (setq major-mode 'gnus-server-mode)
  (setq mode-name "Server")
  (gnus-set-default-directory)
  (setq mode-line-process nil)
  (use-local-map gnus-server-mode-map)
  (buffer-disable-undo)
  (setq truncate-lines t)
  (setq buffer-read-only t)
  (if (featurep 'xemacs)
      (put 'gnus-server-mode 'font-lock-defaults '(gnus-server-font-lock-keywords t))
    (set (make-local-variable 'font-lock-defaults)
	 '(gnus-server-font-lock-keywords t)))
  (gnus-run-mode-hooks 'gnus-server-mode-hook))

(defun gnus-server-insert-server-line (gnus-tmp-name method)
  (let* ((gnus-tmp-how (car method))
	 (gnus-tmp-where (nth 1 method))
	 (elem (assoc method gnus-opened-servers))
	 (gnus-tmp-status
	  (cond
	   ((eq (nth 1 elem) 'denied) "(denied)")
	   ((eq (nth 1 elem) 'offline) "(offline)")
	   (t
	    (condition-case nil
		(if (or (gnus-server-opened method)
			(eq (nth 1 elem) 'ok))
		    "(opened)"
		  "(closed)")
	      ((error) "(error)")))))
	 (gnus-tmp-agent (if (and gnus-agent
				  (gnus-agent-method-p method))
			     " (agent)"
			   "")))
    (beginning-of-line)
    (gnus-add-text-properties
     (point)
     (prog1 (1+ (point))
       ;; Insert the text.
       (eval gnus-server-line-format-spec))
     (list 'gnus-server (intern gnus-tmp-name)
           'gnus-named-server (intern (gnus-method-to-server method))))))

(defun gnus-enter-server-buffer ()
  "Set up the server buffer."
  (gnus-server-setup-buffer)
  (gnus-configure-windows 'server)
  (gnus-server-prepare))

(defun gnus-server-setup-buffer ()
  "Initialize the server buffer."
  (unless (get-buffer gnus-server-buffer)
    (save-excursion
      (set-buffer (gnus-get-buffer-create gnus-server-buffer))
      (gnus-server-mode)
      (when gnus-carpal
	(gnus-carpal-setup-buffer 'server)))))

(defun gnus-server-prepare ()
  (gnus-set-format 'server-mode)
  (gnus-set-format 'server t)
  (let ((alist gnus-server-alist)
	(buffer-read-only nil)
	(opened gnus-opened-servers)
	done server op-ser)
    (erase-buffer)
    (setq gnus-inserted-opened-servers nil)
    ;; First we do the real list of servers.
    (while alist
      (unless (member (cdar alist) done)
	(push (cdar alist) done)
	(setq server (pop alist))
	(when (and server (car server) (cdr server))
	  (gnus-server-insert-server-line (car server) (cdr server))))
      (when (member (cdar alist) done)
	(pop alist)))
    ;; Then we insert the list of servers that have been opened in
    ;; this session.
    (while opened
      (when (and (not (member (caar opened) done))
		 ;; Just ignore ephemeral servers.
		 (not (member (caar opened) gnus-ephemeral-servers)))
	(push (caar opened) done)
	(gnus-server-insert-server-line
	 (setq op-ser (format "%s:%s" (caaar opened) (nth 1 (caar opened))))
	 (caar opened))
	(push (list op-ser (caar opened)) gnus-inserted-opened-servers))
      (setq opened (cdr opened))))
  (goto-char (point-min))
  (gnus-server-position-point))

(defun gnus-server-server-name ()
  (let ((server (get-text-property (gnus-point-at-bol) 'gnus-server)))
    (and server (symbol-name server))))

(defun gnus-server-named-server ()
  "Returns a server name that matches one of the names returned by
gnus-method-to-server."
  (let ((server (get-text-property (gnus-point-at-bol) 'gnus-named-server)))
    (and server (symbol-name server))))

(defalias 'gnus-server-position-point 'gnus-goto-colon)

(defconst gnus-server-edit-buffer "*Gnus edit server*")

(defun gnus-server-update-server (server)
  (save-excursion
    (set-buffer gnus-server-buffer)
    (let* ((buffer-read-only nil)
	   (entry (assoc server gnus-server-alist))
	   (oentry (assoc (gnus-server-to-method server)
			  gnus-opened-servers)))
      (when entry
	(gnus-dribble-enter
	 (concat "(gnus-server-set-info \"" server "\" '"
		 (gnus-prin1-to-string (cdr entry)) ")\n")))
      (when (or entry oentry)
	;; Buffer may be narrowed.
	(save-restriction
	  (widen)
	  (when (gnus-server-goto-server server)
	    (gnus-delete-line))
	  (if entry
	      (gnus-server-insert-server-line (car entry) (cdr entry))
	    (gnus-server-insert-server-line
	     (format "%s:%s" (caar oentry) (nth 1 (car oentry)))
	     (car oentry)))
	  (gnus-server-position-point))))))

(defun gnus-server-set-info (server info)
  ;; Enter a select method into the virtual server alist.
  (when (and server info)
    (gnus-dribble-enter
     (concat "(gnus-server-set-info \"" server "\" '"
	     (gnus-prin1-to-string info) ")"))
    (let* ((server (nth 1 info))
	   (entry (assoc server gnus-server-alist))
	   (cached (assoc server gnus-server-method-cache)))
      (if cached
	  (setq gnus-server-method-cache
		(delq cached gnus-server-method-cache)))
      (if entry (setcdr entry info)
	(setq gnus-server-alist
	      (nconc gnus-server-alist (list (cons server info))))))))

;;; Interactive server functions.

(defun gnus-server-kill-server (server)
  "Kill the server on the current line."
  (interactive (list (gnus-server-server-name)))
  (unless (gnus-server-goto-server server)
    (if server (error "No such server: %s" server)
      (error "No server on the current line")))
  (unless (assoc server gnus-server-alist)
    (error "Read-only server %s" server))
  (gnus-dribble-touch)
  (let ((buffer-read-only nil))
    (gnus-delete-line))
  (push (assoc server gnus-server-alist) gnus-server-killed-servers)
  (setq gnus-server-alist (delq (car gnus-server-killed-servers)
				gnus-server-alist))
  (let ((groups (gnus-groups-from-server server)))
    (when (and groups
	       (gnus-yes-or-no-p
		(format "Kill all %s groups from this server? "
			(length groups))))
      (dolist (group groups)
	(setq gnus-newsrc-alist
	      (delq (assoc group gnus-newsrc-alist)
		    gnus-newsrc-alist))
	(when gnus-group-change-level-function
	  (funcall gnus-group-change-level-function
		   group gnus-level-killed 3)))))
  (gnus-server-position-point))

(defun gnus-server-yank-server ()
  "Yank the previously killed server."
  (interactive)
  (unless gnus-server-killed-servers
    (error "No killed servers to be yanked"))
  (let ((alist gnus-server-alist)
	(server (gnus-server-server-name))
	(killed (car gnus-server-killed-servers)))
    (if (not server)
	(setq gnus-server-alist (nconc gnus-server-alist (list killed)))
      (if (string= server (caar gnus-server-alist))
	  (push killed gnus-server-alist)
	(while (and (cdr alist)
		    (not (string= server (caadr alist))))
	  (setq alist (cdr alist)))
	(if alist
	    (setcdr alist (cons killed (cdr alist)))
	  (setq gnus-server-alist (list killed)))))
    (gnus-server-update-server (car killed))
    (setq gnus-server-killed-servers (cdr gnus-server-killed-servers))
    (gnus-server-position-point)))

(defun gnus-server-exit ()
  "Return to the group buffer."
  (interactive)
  (gnus-run-hooks 'gnus-server-exit-hook)
  (gnus-kill-buffer (current-buffer))
  (gnus-configure-windows 'group t))

(defun gnus-server-list-servers ()
  "List all available servers."
  (interactive)
  (let ((cur (gnus-server-server-name)))
    (gnus-server-prepare)
    (if cur (gnus-server-goto-server cur)
      (goto-char (point-max))
      (forward-line -1))
    (gnus-server-position-point)))

(defun gnus-server-set-status (method status)
  "Make METHOD have STATUS."
  (let ((entry (assoc method gnus-opened-servers)))
    (if entry
	(setcar (cdr entry) status)
      (push (list method status) gnus-opened-servers))))

(defun gnus-opened-servers-remove (method)
  "Remove METHOD from the list of opened servers."
  (setq gnus-opened-servers (delq (assoc method gnus-opened-servers)
				  gnus-opened-servers)))

(defun gnus-server-open-server (server)
  "Force an open of SERVER."
  (interactive (list (gnus-server-server-name)))
  (let ((method (gnus-server-to-method server)))
    (unless method
      (error "No such server: %s" server))
    (gnus-server-set-status method 'ok)
    (prog1
	(or (gnus-open-server method)
	    (progn (message "Couldn't open %s" server) nil))
      (gnus-server-update-server server)
      (gnus-server-position-point))))

(defun gnus-server-open-all-servers ()
  "Open all servers."
  (interactive)
  (let ((servers gnus-inserted-opened-servers))
    (while servers
      (gnus-server-open-server (car (pop servers))))))

(defun gnus-server-close-server (server)
  "Close SERVER."
  (interactive (list (gnus-server-server-name)))
  (let ((method (gnus-server-to-method server)))
    (unless method
      (error "No such server: %s" server))
    (gnus-server-set-status method 'closed)
    (prog1
	(gnus-close-server method)
      (gnus-server-update-server server)
      (gnus-server-position-point))))

(defun gnus-server-offline-server (server)
  "Set SERVER to offline."
  (interactive (list (gnus-server-server-name)))
  (let ((method (gnus-server-to-method server)))
    (unless method
      (error "No such server: %s" server))
    (prog1
	(gnus-close-server method)
      (gnus-server-set-status method 'offline)
      (gnus-server-update-server server)
      (gnus-server-position-point))))

(defun gnus-server-close-all-servers ()
  "Close all servers."
  (interactive)
  (dolist (server gnus-inserted-opened-servers)
    (gnus-server-close-server (car server))))

(defun gnus-server-deny-server (server)
  "Make sure SERVER will never be attempted opened."
  (interactive (list (gnus-server-server-name)))
  (let ((method (gnus-server-to-method server)))
    (unless method
      (error "No such server: %s" server))
    (gnus-server-set-status method 'denied))
  (gnus-server-update-server server)
  (gnus-server-position-point)
  t)

(defun gnus-server-remove-denials ()
  "Make all denied servers into closed servers."
  (interactive)
  (dolist (server gnus-opened-servers)
    (when (eq (nth 1 server) 'denied)
      (setcar (nthcdr 1 server) 'closed)))
  (gnus-server-list-servers))

(defun gnus-server-copy-server (from to)
  (interactive
   (list
    (or (gnus-server-server-name)
	(error "No server on the current line"))
    (read-string "Copy to: ")))
  (unless from
    (error "No server on current line"))
  (unless (and to (not (string= to "")))
    (error "No name to copy to"))
  (when (assoc to gnus-server-alist)
    (error "%s already exists" to))
  (unless (gnus-server-to-method from)
    (error "%s: no such server" from))
  (let ((to-entry (cons from (gnus-copy-sequence
			      (gnus-server-to-method from)))))
    (setcar to-entry to)
    (setcar (nthcdr 2 to-entry) to)
    (push to-entry gnus-server-killed-servers)
    (gnus-server-yank-server)))

(defun gnus-server-add-server (how where)
  (interactive
   (list (intern (completing-read "Server method: "
				  gnus-valid-select-methods nil t))
	 (read-string "Server name: ")))
  (when (assq where gnus-server-alist)
    (error "Server with that name already defined"))
  (push (list where how where) gnus-server-killed-servers)
  (gnus-server-yank-server))

(defun gnus-server-goto-server (server)
  "Jump to a server line."
  (interactive
   (list (completing-read "Goto server: " gnus-server-alist nil t)))
  (let ((to (text-property-any (point-min) (point-max)
			       'gnus-server (intern server))))
    (when to
      (goto-char to)
      (gnus-server-position-point))))

(defun gnus-server-edit-server (server)
  "Edit the server on the current line."
  (interactive (list (gnus-server-server-name)))
  (unless server
    (error "No server on current line"))
  (unless (assoc server gnus-server-alist)
    (error "This server can't be edited"))
  (let ((info (cdr (assoc server gnus-server-alist))))
    (gnus-close-server info)
    (gnus-edit-form
     info "Editing the server."
     `(lambda (form)
	(gnus-server-set-info ,server form)
	(gnus-server-list-servers)
	(gnus-server-position-point)))))

(defun gnus-server-scan-server (server)
  "Request a scan from the current server."
  (interactive (list (gnus-server-server-name)))
  (let ((method (gnus-server-to-method server)))
    (if (not (gnus-get-function method 'request-scan))
	(error "Server %s can't scan" (car method))
      (gnus-message 3 "Scanning %s..." server)
      (gnus-request-scan nil method)
      (gnus-message 3 "Scanning %s...done" server))))

(defun gnus-server-read-server-in-server-buffer (server)
  "Browse a server in server buffer."
  (interactive (list (gnus-server-server-name)))
  (let (gnus-server-browse-in-group-buffer)
    (gnus-server-read-server server)))

(defun gnus-server-read-server (server)
  "Browse a server."
  (interactive (list (gnus-server-server-name)))
  (let ((buf (current-buffer)))
    (prog1
	(gnus-browse-foreign-server server buf)
      (save-excursion
	(set-buffer buf)
	(gnus-server-update-server (gnus-server-server-name))
	(gnus-server-position-point)))))

(defun gnus-server-pick-server (e)
  (interactive "e")
  (mouse-set-point e)
  (gnus-server-read-server (gnus-server-server-name)))


;;;
;;; Browse Server Mode
;;;

(defvar gnus-browse-menu-hook nil
  "*Hook run after the creation of the browse mode menu.")

(defvar gnus-browse-mode-hook nil)
(defvar gnus-browse-mode-map nil)
(put 'gnus-browse-mode 'mode-class 'special)

(unless gnus-browse-mode-map
  (setq gnus-browse-mode-map (make-keymap))
  (suppress-keymap gnus-browse-mode-map)

  (gnus-define-keys
      gnus-browse-mode-map
    " " gnus-browse-read-group
    "=" gnus-browse-select-group
    "n" gnus-browse-next-group
    "p" gnus-browse-prev-group
    "\177" gnus-browse-prev-group
    [delete] gnus-browse-prev-group
    "N" gnus-browse-next-group
    "P" gnus-browse-prev-group
    "\M-n" gnus-browse-next-group
    "\M-p" gnus-browse-prev-group
    "\r" gnus-browse-select-group
    "u" gnus-browse-unsubscribe-current-group
    "l" gnus-browse-exit
    "L" gnus-browse-exit
    "q" gnus-browse-exit
    "Q" gnus-browse-exit
    "d" gnus-browse-describe-group
    "\C-c\C-c" gnus-browse-exit
    "?" gnus-browse-describe-briefly

    "\C-c\C-i" gnus-info-find-node
    "\C-c\C-b" gnus-bug))

(defun gnus-browse-make-menu-bar ()
  (gnus-turn-off-edit-menu 'browse)
  (unless (boundp 'gnus-browse-menu)
    (easy-menu-define
     gnus-browse-menu gnus-browse-mode-map ""
     '("Browse"
       ["Subscribe" gnus-browse-unsubscribe-current-group t]
       ["Read" gnus-browse-read-group t]
       ["Select" gnus-browse-select-group t]
       ["Describe" gnus-browse-describe-group t]
       ["Next" gnus-browse-next-group t]
       ["Prev" gnus-browse-prev-group t]
       ["Exit" gnus-browse-exit t]))
    (gnus-run-hooks 'gnus-browse-menu-hook)))

(defvar gnus-browse-current-method nil)
(defvar gnus-browse-return-buffer nil)

(defvar gnus-browse-buffer "*Gnus Browse Server*")

(defun gnus-browse-foreign-server (server &optional return-buffer)
  "Browse the server SERVER."
  (setq gnus-browse-current-method (gnus-server-to-method server))
  (setq gnus-browse-return-buffer return-buffer)
  (let* ((method gnus-browse-current-method)
	 (orig-select-method gnus-select-method)
	 (gnus-select-method method)
	 groups group)
    (gnus-message 5 "Connecting to %s..." (nth 1 method))
    (cond
     ((not (gnus-check-server method))
      (gnus-message
       1 "Unable to contact server %s: %s" (nth 1 method)
       (gnus-status-message method))
      nil)
     ((not
       (prog2
	   (gnus-message 6 "Reading active file...")
	   (gnus-request-list method)
	 (gnus-message 6 "Reading active file...done")))
      (gnus-message
       1 "Couldn't request list: %s" (gnus-status-message method))
      nil)
     (t
      (with-current-buffer nntp-server-buffer
	(let ((cur (current-buffer)))
	  (goto-char (point-min))
	  (unless (string= gnus-ignored-newsgroups "")
	    (delete-matching-lines gnus-ignored-newsgroups))
	  ;; We treat NNTP as a special case to avoid problems with
	  ;; garbage group names like `"foo' that appear in some badly
	  ;; managed active files. -jh.
	  (if (eq (car method) 'nntp)
	      (while (not (eobp))
		(ignore-errors
		  (push (cons
			 (buffer-substring
			  (point)
			  (progn
			    (skip-chars-forward "^ \t")
			    (point)))
			 (let ((last (read cur)))
			   (cons (read cur) last)))
			groups))
		(forward-line))
	    (while (not (eobp))
	      (ignore-errors
		(push (cons
		       (if (eq (char-after) ?\")
			   (read cur)
			 (let ((p (point)) (name ""))
			   (skip-chars-forward "^ \t\\\\")
			   (setq name (buffer-substring p (point)))
			   (while (eq (char-after) ?\\)
			     (setq p (1+ (point)))
			     (forward-char 2)
			     (skip-chars-forward "^ \t\\\\")
			     (setq name (concat name (buffer-substring
						      p (point)))))
			   name))
		       (let ((last (read cur)))
			 (cons (read cur) last)))
		      groups))
	      (forward-line)))))
      (setq groups (sort groups
			 (lambda (l1 l2)
			   (string< (car l1) (car l2)))))
      (if gnus-server-browse-in-group-buffer
	  (let* ((gnus-select-method orig-select-method)
		 (gnus-group-listed-groups
		  (mapcar (lambda (group)
			    (let ((name
				   (gnus-group-prefixed-name
				    (car group) method)))
			      (gnus-set-active name (cdr group))
			      name))
			  groups)))
	    (gnus-configure-windows 'group)
	    (funcall gnus-group-prepare-function
		     gnus-level-killed 'ignore 1 'ignore))
	(gnus-get-buffer-create gnus-browse-buffer)
	(when gnus-carpal
	  (gnus-carpal-setup-buffer 'browse))
	(gnus-configure-windows 'browse)
	(buffer-disable-undo)
	(let ((buffer-read-only nil))
	  (erase-buffer))
	(gnus-browse-mode)
	(setq mode-line-buffer-identification
	      (list
	       (format
		"Gnus: %%b {%s:%s}" (car method) (cadr method))))
	(let ((buffer-read-only nil)
	      name
	      (prefix (let ((gnus-select-method orig-select-method))
			(gnus-group-prefixed-name "" method))))
	  (while (setq group (pop groups))
	    (gnus-add-text-properties
	     (point)
	     (prog1 (1+ (point))
	       (insert
		(format "%c%7d: %s\n"
			(let ((level (gnus-group-level
				      (concat prefix (setq name (car group))))))
			      (cond
			       ((<= level gnus-level-subscribed) ? )
			       ((<= level gnus-level-unsubscribed) ?U)
			       ((= level gnus-level-zombie) ?Z)
			       (t ?K)))
			(max 0 (- (1+ (cddr group)) (cadr group)))
			(mm-decode-coding-string
			 name
			 (inline (gnus-group-name-charset method name))))))
	     (list 'gnus-group name))))
	(switch-to-buffer (current-buffer)))
      (goto-char (point-min))
      (gnus-group-position-point)
      (gnus-message 5 "Connecting to %s...done" (nth 1 method))
      t))))

(defun gnus-browse-mode ()
  "Major mode for browsing a foreign server.

All normal editing commands are switched off.

\\<gnus-browse-mode-map>
The only things you can do in this buffer is

1) `\\[gnus-browse-unsubscribe-current-group]' to subscribe to a group.
The group will be inserted into the group buffer upon exit from this
buffer.

2) `\\[gnus-browse-read-group]' to read a group ephemerally.

3) `\\[gnus-browse-exit]' to return to the group buffer."
  (interactive)
  (kill-all-local-variables)
  (when (gnus-visual-p 'browse-menu 'menu)
    (gnus-browse-make-menu-bar))
  (gnus-simplify-mode-line)
  (setq major-mode 'gnus-browse-mode)
  (setq mode-name "Browse Server")
  (setq mode-line-process nil)
  (use-local-map gnus-browse-mode-map)
  (buffer-disable-undo)
  (setq truncate-lines t)
  (gnus-set-default-directory)
  (setq buffer-read-only t)
  (gnus-run-mode-hooks 'gnus-browse-mode-hook))

(defun gnus-browse-read-group (&optional no-article number)
  "Enter the group at the current line.
If NUMBER, fetch this number of articles."
  (interactive "P")
  (let ((group (gnus-browse-group-name)))
    (if (or (not (gnus-get-info group))
	    (gnus-ephemeral-group-p group))
	(unless (gnus-group-read-ephemeral-group
		 group gnus-browse-current-method nil
		 (cons (current-buffer) 'browse)
		 nil nil nil number)
	  (error "Couldn't enter %s" group))
      (unless (gnus-group-read-group nil no-article group)
	(error "Couldn't enter %s" group)))))

(defun gnus-browse-select-group (&optional number)
  "Select the current group.
If NUMBER, fetch this number of articles."
  (interactive "P")
  (gnus-browse-read-group 'no number))

(defun gnus-browse-next-group (n)
  "Go to the next group."
  (interactive "p")
  (prog1
      (forward-line n)
    (gnus-group-position-point)))

(defun gnus-browse-prev-group (n)
  "Go to the next group."
  (interactive "p")
  (gnus-browse-next-group (- n)))

(defun gnus-browse-unsubscribe-current-group (arg)
  "(Un)subscribe to the next ARG groups."
  (interactive "p")
  (when (eobp)
    (error "No group at current line"))
  (let ((ward (if (< arg 0) -1 1))
	(arg (abs arg)))
    (while (and (> arg 0)
		(not (eobp))
		(gnus-browse-unsubscribe-group)
		(zerop (gnus-browse-next-group ward)))
      (decf arg))
    (gnus-group-position-point)
    (when (/= 0 arg)
      (gnus-message 7 "No more newsgroups"))
    arg))

(defun gnus-browse-group-name ()
  (save-excursion
    (beginning-of-line)
    (let ((name (get-text-property (point) 'gnus-group)))
      (when (re-search-forward ": \\(.*\\)$" (gnus-point-at-eol) t)
	(concat (gnus-method-to-server-name gnus-browse-current-method) ":"
		(or name
		    (match-string-no-properties 1)))))))

(defun gnus-browse-describe-group (group)
  "Describe the current group."
  (interactive (list (gnus-browse-group-name)))
  (gnus-group-describe-group nil group))

(defun gnus-browse-unsubscribe-group ()
  "Toggle subscription of the current group in the browse buffer."
  (let ((sub nil)
	(buffer-read-only nil)
	group)
    (save-excursion
      (beginning-of-line)
      ;; If this group it killed, then we want to subscribe it.
      (unless (eq (char-after) ? )
	(setq sub t))
      (setq group (gnus-browse-group-name))
      (when (gnus-server-equal gnus-browse-current-method "native")
	(setq group (gnus-group-real-name group)))
      (if sub
	  (progn
	    ;; Make sure the group has been properly removed before we
	    ;; subscribe to it.
	    (gnus-kill-ephemeral-group group)
	    (gnus-group-change-level
	     (list t group gnus-level-default-subscribed
		   nil nil (if (gnus-server-equal
				gnus-browse-current-method "native")
			       nil
			     (gnus-method-simplify
			      gnus-browse-current-method)))
	     gnus-level-default-subscribed (gnus-group-level group)
	     (and (car (nth 1 gnus-newsrc-alist))
		  (gnus-gethash (car (nth 1 gnus-newsrc-alist))
				gnus-newsrc-hashtb))
	     t)
	    (delete-char 1)
	    (insert ? ))
	(gnus-group-change-level
	 group gnus-level-unsubscribed gnus-level-default-subscribed)
	(delete-char 1)
	(insert ?U)))
    t))

(defun gnus-browse-exit ()
  "Quit browsing and return to the group buffer."
  (interactive)
  (when (eq major-mode 'gnus-browse-mode)
    (gnus-kill-buffer (current-buffer)))
  ;; Insert the newly subscribed groups in the group buffer.
  (save-excursion
    (set-buffer gnus-group-buffer)
    (gnus-group-list-groups nil))
  (if gnus-browse-return-buffer
      (gnus-configure-windows 'server 'force)
    (gnus-configure-windows 'group 'force)))

(defun gnus-browse-describe-briefly ()
  "Give a one line description of the group mode commands."
  (interactive)
  (gnus-message 6
		(substitute-command-keys "\\<gnus-browse-mode-map>\\[gnus-group-next-group]:Forward  \\[gnus-group-prev-group]:Backward  \\[gnus-browse-exit]:Exit  \\[gnus-info-find-node]:Run Info  \\[gnus-browse-describe-briefly]:This help")))

(defun gnus-server-regenerate-server ()
  "Issue a command to the server to regenerate all its data structures."
  (interactive)
  (let ((server (gnus-server-server-name)))
    (unless server
      (error "No server on the current line"))
    (condition-case ()
	(gnus-get-function (gnus-server-to-method server)
			   'request-regenerate)
      (error
	(error "This backend doesn't support regeneration")))
    (gnus-message 5 "Requesting regeneration of %s..." server)
    (unless (gnus-open-server server)
      (error "Couldn't open server"))
    (if (gnus-request-regenerate server)
	(gnus-message 5 "Requesting regeneration of %s...done" server)
      (gnus-message 5 "Couldn't regenerate %s" server))))

(provide 'gnus-srvr)

;;; arch-tag: c0117f64-27ca-475d-9406-8da6854c7a25
;;; gnus-srvr.el ends here

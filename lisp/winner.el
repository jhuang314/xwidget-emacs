;;; winner.el --- Restore old window configurations

;; Copyright (C) 1997, 1998 Free Software Foundation. Inc.

;; Author: Ivar Rummelhoff <ivarru@math.uio.no>
;; Created: 27 Feb 1997
;; Time-stamp: <1998-08-21 19:51:02 ivarr>
;; Keywords: convenience frames

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

;; Winner mode is a global minor mode that records the changes in the
;; window configuration (i.e. how the frames are partitioned into
;; windows) so that the changes can be "undone" using the command
;; `winner-undo'.  By default this one is bound to the key sequence
;; ctrl-x left.  If you change your mind (while undoing), you can
;; press ctrl-x right (calling `winner-redo').  Even though it uses
;; some features of Emacs20.3, winner.el should also work with
;; Emacs19.34 and XEmacs20, provided that the installed version of
;; custom is not obsolete.

;; Winner mode was improved august 1998.

;;; Code:

(eval-when-compile
  (require 'cl))

(eval-when-compile
  (cond
   ((eq (aref (emacs-version) 0) ?X)
    (defmacro winner-active-region ()
      '(region-active-p))
    (defsetf winner-active-region () (store)
      `(if ,store (zmacs-activate-region)
	 (zmacs-deactivate-region))))
   (t (defmacro winner-active-region ()
	'mark-active)
      (defsetf winner-active-region () (store)
	`(setq mark-active ,store)))) )

(require 'ring)

(when (fboundp 'defgroup)
  (defgroup winner nil
    "Restoring window configurations."
    :group 'windows))

(unless (fboundp 'defcustom)
  (defmacro defcustom (symbol &optional initvalue docs &rest rest)
    (list 'defvar symbol initvalue docs)))


;;;###autoload
(defcustom winner-mode nil
  "Toggle winner-mode.
Setting this variable directly does not take effect;
use either \\[customize] or the function `winner-mode'."
  :set #'(lambda (symbol value)
	   (winner-mode (or value 0)))
  :initialize 'custom-initialize-default
  :type    'boolean
  :group   'winner
  :require 'winner)

(defcustom winner-dont-bind-my-keys nil
  "If non-nil: Do not use `winner-mode-map' in Winner mode."
  :type  'boolean
  :group 'winner)

(defcustom winner-ring-size 200
  "Maximum number of stored window configurations per frame."
  :type  'integer
  :group 'winner)




;;;; Saving old configurations (internal variables and subroutines)

;; This variable is updated with the current window configuration
;; after every command, so that when command make changes in the
;; window configuration, the last configuration can be saved.
(defvar winner-currents nil)

;; The current configuration (+ the buffers involved).
(defsubst winner-conf ()
  (list (current-window-configuration)
	(loop for w being the windows
	      unless (window-minibuffer-p w)
	      collect (window-buffer w)) ))
;;	(if winner-testvar (incf winner-testvar) ; For debugging purposes
;;	  (setq winner-testvar 0))))

;; Save current configuration.
;; (Called by `winner-save-old-configurations' below).
(defun winner-remember ()
  (let ((entry (assq (selected-frame) winner-currents)))
    (if entry (setcdr entry (winner-conf))
      (push (cons (selected-frame) (winner-conf))
	    winner-currents))))

;; Consult `winner-currents'.
(defun winner-configuration (&optional frame)
  (or (cdr (assq (or frame (selected-frame)) winner-currents))
      (letf (((selected-frame) frame))
	(winner-conf))))



;; This variable contains the window cofiguration rings.
;; The key in this alist is the frame.
(defvar winner-ring-alist nil)

;; Find the right ring.  If it does not exist, create one.
(defsubst winner-ring (frame)
  (or (cdr (assq frame winner-ring-alist))
      (progn
	(let ((ring (make-ring winner-ring-size)))
	  (ring-insert ring (winner-configuration frame))
	  (push (cons frame ring) winner-ring-alist)
	  ring))))

;; If the same command is called several times in a row,
;; we only save one window configuration.
(defvar winner-last-command nil)

;; Frames affected by the previous command.
(defvar winner-last-frames nil)

;; Save the current window configuration, if it has changed.
;; Then return frame, else return nil.
(defun winner-insert-if-new (frame)
  (unless (or (memq frame winner-last-frames)
	      (eq this-command 'winner-redo))
    (let ((conf (winner-configuration frame))
	  (ring (winner-ring frame)))
      (when (and (not (ring-empty-p ring))
		 (winner-equal conf (ring-ref ring 0)))
	(ring-remove ring 0))
      (ring-insert ring conf)
      (push frame winner-last-frames)
      frame)))

;; Frames affected by the current command.
(defvar winner-modified-list nil)

;; Called whenever the window configuration changes
;; (a `window-configuration-change-hook').
(defun winner-change-fun ()
  (unless (memq (selected-frame) winner-modified-list)
    (push (selected-frame) winner-modified-list)))


;; For Emacs20 (a `post-command-hook').
(defun winner-save-old-configurations ()
  (unless (eq this-command winner-last-command)
    (setq winner-last-frames nil)
    (setq winner-last-command this-command))
  (dolist (frame winner-modified-list)
    (winner-insert-if-new frame))
  (setq winner-modified-list nil)
  ;;  (ir-trace ; For debugging purposes
  ;;   "%S"
  ;;   (loop with ring = (winner-ring (selected-frame))
  ;;	 for i from 0 to (1- (ring-length ring))
  ;;	 collect (caddr (ring-ref ring i))))
  (winner-remember))

;; For compatibility with other emacsen
;; and called by `winner-undo' before "undoing".
(defun winner-save-unconditionally ()
  (unless (eq this-command winner-last-command)
    (setq winner-last-frames nil)
    (setq winner-last-command this-command))
  (winner-insert-if-new (selected-frame))
  (winner-remember))




;;;; Restoring configurations

;; Works almost as `set-window-configuration',
;; but doesn't change the contents or the size of the minibuffer.
(defun winner-set-conf (winconf)
  (let ((miniwin (minibuffer-window))
	(minisel (window-minibuffer-p (selected-window))))
    (let ((minibuf   (window-buffer miniwin))
	  (minipoint (window-point  miniwin))
	  (minisize  (window-height miniwin)))
      (set-window-configuration winconf)
      (setf (window-buffer miniwin) minibuf
	    (window-point  miniwin) minipoint)
      (when (/= minisize (window-height miniwin)) 
	(letf (((selected-window) miniwin) )
	  ;; Clumsy due to cl-macs-limitation
	  (setf (window-height) minisize)))
      (cond
       (minisel (select-window miniwin))
       ((window-minibuffer-p (selected-window))
	(other-window 1))))))


(defvar winner-point-alist nil)
;; `set-window-configuration' restores old points and marks.  This is
;; not what we want, so we make a list of the "real" (i.e. new) points
;; and marks before undoing window configurations.
;;
;; Format of entries: (buffer (mark . mark-active) (window . point) ..)

(defun winner-make-point-alist ()
  (letf (((current-buffer)))
    (loop with alist
	  with entry 
	  for win being the windows
	  do (cond
	      ((window-minibuffer-p win))
	      ((setq entry (assq win alist)) 
	       ;; Update existing entry
	       (push (cons win (window-point win))
		     (cddr entry)))
	      (t;; Else create new entry
	       (push (list (set-buffer (window-buffer win))
			   (cons (mark t) (winner-active-region))
			   (cons win (window-point win)))
		     alist)))
	  finally return alist)))


(defun winner-get-point (buf win)
  ;; Consult (and possibly extend) `winner-point-alist'.
  (when (buffer-name buf)
    (let ((entry (assq buf winner-point-alist)))
      (cond
       (entry
	(or (cdr (assq win (cddr entry)))
	    (cdr (assq nil (cddr entry)))
	    (letf (((current-buffer) buf))
	      (push (cons nil (point)) (cddr entry))
	      (point))))
       (t (letf (((current-buffer) buf))
	    (push (list buf
			(cons (mark t) (winner-active-region))
			(cons nil (point)))
		  winner-point-alist)
	    (point)))))))

;; Make sure point doesn't end up in the minibuffer and
;; delete windows displaying dead buffers.  Return nil
;; if and only if all the windows should have been deleted.
;; Do not move neither points nor marks.
(defun winner-set (conf)
  (let* ((buffers nil)
	 (origpoints
	  (loop for buf in (cadr conf)
		for pos = (winner-get-point buf nil)
		if (and pos (not (memq buf buffers)))
		do (push buf buffers)
		collect pos)))
    (winner-set-conf (car conf))
    (let (xwins) ; These windows should be deleted
      (loop for win being the windows
	    unless (window-minibuffer-p win)
	    do (if (pop origpoints)
		   (setf (window-point win)
			 ;; Restore point
			 (winner-get-point
			  (window-buffer win)
			  win))
		 (push win xwins))) ; delete this window
      ;; Restore mark
      (letf (((current-buffer)))
	(loop for buf in buffers 
	      for entry = (cadr (assq buf winner-point-alist))
	      do (progn (set-buffer buf)
			(set-mark (car entry))
			(setf (winner-active-region) (cdr entry)))))
      ;; Delete windows, whose buffers are dead.
      ;; Return t if this is still a possible configuration.
      (or (null xwins)
	  (progn (mapcar 'delete-window (cdr xwins))
		 (if (one-window-p t)
		     nil  ; No windows left
		   (progn (delete-window (car xwins))
			  t)))))))



;;;; Winner mode  (a minor mode)

(defcustom winner-mode-hook nil
  "Functions to run whenever Winner mode is turned on."
  :type 'hook
  :group 'winner)

(defcustom winner-mode-leave-hook nil
  "Functions to run whenever Winner mode is turned off."
  :type 'hook
  :group 'winner)

(defvar winner-mode-map nil "Keymap for Winner mode.")

;; Is `window-configuration-change-hook' working?
(defun winner-hook-installed-p ()
  (save-window-excursion
    (let ((winner-var nil)
	  (window-configuration-change-hook
	   '((lambda () (setq winner-var t)))))
      (split-window)
      winner-var)))


;;;###autoload
(defun winner-mode (&optional arg)
  "Toggle Winner mode.
With arg, turn Winner mode on if and only if arg is positive."
  (interactive "P")
  (let ((on-p (if arg (> (prefix-numeric-value arg) 0)
		(not winner-mode))))
    (cond
     ;; Turn mode on
     (on-p 
      (setq winner-mode t)
      (cond
       ((winner-hook-installed-p)
	(add-hook 'window-configuration-change-hook 'winner-change-fun)
	(add-hook 'post-command-hook 'winner-save-old-configurations))
       (t (add-hook 'post-command-hook 'winner-save-unconditionally)))
      (setq winner-modified-list (frame-list))
      (winner-save-old-configurations)
      (run-hooks 'winner-mode-hook))
     ;; Turn mode off
     (winner-mode
      (setq winner-mode nil)
      (remove-hook 'window-configuration-change-hook 'winner-change-fun)
      (remove-hook 'post-command-hook 'winner-save-old-configurations)
      (remove-hook 'post-command-hook 'winner-save-unconditionally)
      (run-hooks 'winner-mode-leave-hook)))
    (force-mode-line-update)))

;; Inspired by undo (simple.el)

(defvar winner-undo-frame nil)

(defvar winner-pending-undo-ring nil
  "The ring currently used by winner undo.")
(defvar winner-undo-counter nil)
(defvar winner-undone-data  nil) ; There confs have been passed.

(defun winner-undo ()
  "Switch back to an earlier window configuration saved by Winner mode.
In other words, \"undo\" changes in window configuration."
  (interactive)
  (cond
   ((not winner-mode) (error "Winner mode is turned off"))
   (t (unless (and (eq last-command 'winner-undo)
 		   (eq winner-undo-frame (selected-frame)))
	(winner-save-unconditionally)	; current configuration->stack
 	(setq winner-undo-frame (selected-frame))
 	(setq winner-point-alist (winner-make-point-alist))
 	(setq winner-pending-undo-ring (winner-ring (selected-frame)))
 	(setq winner-undo-counter 0)
 	(setq winner-undone-data (list (winner-win-data))))
      (incf winner-undo-counter)	; starting at 1
      (when (and (winner-undo-this)
 		 (not (window-minibuffer-p (selected-window))))
 	(message "Winner undo (%d / %d)"
 		 winner-undo-counter
 		 (1- (ring-length winner-pending-undo-ring)))))))
 
(defun winner-win-data () 
  ;; Essential properties of the windows in the selected frame.
  (loop for win being the windows
 	unless (window-minibuffer-p win)
 	collect (list (window-buffer win)
 		      (window-width  win)
 		      (window-height win))))
 

(defun winner-undo-this ()		; The heart of winner undo.
  (loop 
   (cond
    ((>= winner-undo-counter (ring-length winner-pending-undo-ring))
     (message "No further window configuration undo information")
     (return nil))
 
    ((and				; If possible configuration
      (winner-set (ring-ref winner-pending-undo-ring
 			    winner-undo-counter))
      ;; .. and new configuration
      (let ((data (winner-win-data)))
 	(and (not (member data winner-undone-data))
 	     (push data winner-undone-data))))
     (return t))			; .. then everything is all right.
    (t					; Else; discharge it and try another one.
     (ring-remove winner-pending-undo-ring winner-undo-counter)))))
 

(defun winner-redo ()			; If you change your mind.
  "Restore a more recent window configuration saved by Winner mode."
  (interactive)
  (cond
   ((eq last-command 'winner-undo)
    (winner-set
     (ring-remove winner-pending-undo-ring 0))
    (unless (eq (selected-window) (minibuffer-window))
      (message "Winner undid undo")))
   (t (error "Previous command was not a winner-undo"))))

;;; To be evaluated when the package is loaded:

(if (fboundp 'compare-window-configurations)
    (defalias 'winner-equal 'compare-window-configurations)
  (defalias 'winner-equal 'equal))

(unless winner-mode-map
  (setq winner-mode-map (make-sparse-keymap))
  (define-key winner-mode-map [(control x) left] 'winner-undo)
  (define-key winner-mode-map [(control x) right] 'winner-redo))

(unless (or (assq 'winner-mode minor-mode-map-alist)
	    winner-dont-bind-my-keys)
  (push (cons 'winner-mode winner-mode-map)
	minor-mode-map-alist))

(unless (assq 'winner-mode minor-mode-alist)
  (push '(winner-mode " Win") minor-mode-alist))

(provide 'winner)

;;; winner.el ends here

;;; vc-dispatcher.el -- generic command-dispatcher facility.

;; Copyright (C) 2008
;;   Free Software Foundation, Inc.

;; Author:     FSF (see below for full credits)
;; Maintainer: Eric S. Raymond <esr@thyrsus.com>
;; Keywords: tools

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

;;; Credits:

;; Designed and implemented by Eric S. Raymond, originally as part of VC mode.
;; Stefan Monnier and Dan Nicolaescu contributed substantial work on the
;; vc-dir front end.

;;; Commentary:

;; Goals:
;;
;; There is a class of front-ending problems that Emacs might be used
;; to address that involves selecting sets of files, or possibly
;; directories, and passing the selection set to slave commands.  The
;; prototypical example, from which this code is derived, is talking
;; to version-control systems.
;;
;; vc-dispatcher.el is written to decouple the UI issues in such front
;; ends from their application-specific logic.  It also provides a
;; service layer for running the slave commands either synchronously
;; or asynchronously and managing the message/error logs from the
;; command runs.
;;
;; Similar UI problems can be expected to come up in applications
;; areas other than VCSes; IDEs and document search are two obvious ones.
;; This mode is intended to ensure that the Emacs interfaces for all such
;; beasts are consistent and carefully designed.  But even if nothing
;; but VC ever uses it, getting the layer separation right will be
;; a valuable thing.

;; Dispatcher's universe:
;;
;; The universe consists of the file tree rooted at the current
;; directory.  The dispatcher's upper layer deduces some subset
;; of the file tree from the state of the currently visited buffer
;; and returns that subset, presumably to a client mode.
;;
;; The user may be looking at either of two different views; a buffer
;; visiting a file, or a directory buffer generated by vc-dispatcher.
;;
;; The lower layer of this mode runs commands in subprocesses, either
;; synchronously or asynchronously.  Commands may be launched in one
;; of two ways: they may be run immediately, or the calling mode can
;; create a closure associated with a text-entry buffer, to be
;; executed when the user types C-c to ship the buffer contents.  In
;; either case the command messages and error (if any) will remain
;; available in a status buffer.

;; Special behavior of dispatcher directory buffers:
;;
;; In dispatcher directory buffers, facilities to perform basic
;; navigation and selection operations are provided by keymap and menu
;; entries that dispatcher sets up itself, so they'll be uniform
;; across all dispatcher-using client modes.  Client modes are
;; expected to append to these to provide mode-specific bindings.
;;
;; The standard map associates a 'state' slot (that the client mode
;; may set) with each directory entry.  The dispatcher knows nothing
;; about the semantics of individual states, but mark and unmark commands
;; treat all entries with the same state as the currently selected one as
;; a unit.

;; The interface:
;;
;; The main interface to the lower level is vc-do-command.  This launches a
;; command, synchronously or asynchronously, making the output available
;; in a command log buffer.  Two other functions, (vc-start-annotation) and
;; (vc-finish-logentry), allow you to associate a command closure with an
;; annotation buffer so that when the user confirms the comment the closure
;; is run (with the comment as part of its context).
;;
;; The interface to the upper level has the two main entry points (vc-dir)
;; and (vc-dispatcher-selection-set) and a couple of convenience functions.
;; (vc-dir) sets up a dispatcher browsing buffer; (vc-dispatcher-selection-set)
;; returns a selection set of files, either the marked files in a browsing
;; buffer or the singleton set consisting of the file visited by the current
;; buffer (when that is appropriate).  It also does what is needed to ensure
;; that on-disk files and the contents of their visiting Emacs buffers
;; coincide.
;;
;; When the client mode adds a local mode-line-hook to a buffer, it
;; will be called with the buffer file name as argument whenever the
;; dispatcher resynchs the buffer.

;; To do:
;;
;; - log buffers need font-locking.
;;

;; General customization
(defcustom vc-logentry-check-hook nil
  "Normal hook run by `vc-finish-logentry'.
Use this to impose your own rules on the entry in addition to any the
dispatcher client mode imposes itself."
  :type 'hook
  :group 'vc)

(defcustom vc-delete-logbuf-window t
  "If non-nil, delete the log buffer and window after each logical action.
If nil, bury that buffer instead.
This is most useful if you have multiple windows on a frame and would like to
preserve the setting."
  :type 'boolean
  :group 'vc)

(defcustom vc-command-messages nil
  "If non-nil, display run messages from back-end commands."
  :type 'boolean
  :group 'vc)

(defcustom vc-suppress-confirm nil
  "If non-nil, treat user as expert; suppress yes-no prompts on some things."
  :type 'boolean
  :group 'vc)

;; Variables the user doesn't need to know about.

(defvar vc-log-operation nil)
(defvar vc-log-after-operation-hook nil)
(defvar vc-log-fileset)
(defvar vc-log-extra)

;; In a log entry buffer, this is a local variable
;; that points to the buffer for which it was made
;; (either a file, or a directory buffer).
(defvar vc-parent-buffer nil)
(put 'vc-parent-buffer 'permanent-local t)
(defvar vc-parent-buffer-name nil)
(put 'vc-parent-buffer-name 'permanent-local t)

;; Common command execution logic

(defun vc-process-filter (p s)
  "An alternative output filter for async process P.
One difference with the default filter is that this inserts S after markers.
Another is that undo information is not kept."
  (let ((buffer (process-buffer p)))
    (when (buffer-live-p buffer)
      (with-current-buffer buffer
        (save-excursion
          (let ((buffer-undo-list t)
                (inhibit-read-only t))
            (goto-char (process-mark p))
            (insert s)
            (set-marker (process-mark p) (point))))))))

(defun vc-setup-buffer (buf)
  "Prepare BUF for executing a slave command and make it current."
  (let ((camefrom (current-buffer))
	(olddir default-directory))
    (set-buffer (get-buffer-create buf))
    (kill-all-local-variables)
    (set (make-local-variable 'vc-parent-buffer) camefrom)
    (set (make-local-variable 'vc-parent-buffer-name)
	 (concat " from " (buffer-name camefrom)))
    (setq default-directory olddir)
    (let ((buffer-undo-list t)
          (inhibit-read-only t))
      (erase-buffer))))

(defvar vc-sentinel-movepoint)          ;Dynamically scoped.

(defun vc-process-sentinel (p s)
  (let ((previous (process-get p 'vc-previous-sentinel))
        (buf (process-buffer p)))
    ;; Impatient users sometime kill "slow" buffers; check liveness
    ;; to avoid "error in process sentinel: Selecting deleted buffer".
    (when (buffer-live-p buf)
      (when previous (funcall previous p s))
      (with-current-buffer buf
        (setq mode-line-process
              (let ((status (process-status p)))
                ;; Leave mode-line uncluttered, normally.
                (unless (eq 'exit status)
                  (format " (%s)" status))))
        (let (vc-sentinel-movepoint)
          ;; Normally, we want async code such as sentinels to not move point.
          (save-excursion
            (goto-char (process-mark p))
            (let ((cmds (process-get p 'vc-sentinel-commands)))
              (process-put p 'vc-sentinel-commands nil)
              (dolist (cmd cmds)
                ;; Each sentinel may move point and the next one should be run
                ;; at that new point.  We could get the same result by having
                ;; each sentinel read&set process-mark, but since `cmd' needs
                ;; to work both for async and sync processes, this would be
                ;; difficult to achieve.
                (vc-exec-after cmd))))
          ;; But sometimes the sentinels really want to move point.
          (when vc-sentinel-movepoint
	    (let ((win (get-buffer-window (current-buffer) 0)))
	      (if (not win)
		  (goto-char vc-sentinel-movepoint)
		(with-selected-window win
		  (goto-char vc-sentinel-movepoint))))))))))

(defun vc-set-mode-line-busy-indicator ()
  (setq mode-line-process
	(concat " " (propertize "[waiting...]"
                                'face 'mode-line-emphasis
                                'help-echo
                                "A command is in progress in this buffer"))))

(defun vc-exec-after (code)
  "Eval CODE when the current buffer's process is done.
If the current buffer has no process, just evaluate CODE.
Else, add CODE to the process' sentinel."
  (let ((proc (get-buffer-process (current-buffer))))
    (cond
     ;; If there's no background process, just execute the code.
     ;; We used to explicitly call delete-process on exited processes,
     ;; but this led to timing problems causing process output to be
     ;; lost.  Terminated processes get deleted automatically
     ;; anyway. -- cyd
     ((or (null proc) (eq (process-status proc) 'exit))
      ;; Make sure we've read the process's output before going further.
      (when proc (accept-process-output proc))
      (eval code))
     ;; If a process is running, add CODE to the sentinel
     ((eq (process-status proc) 'run)
      (vc-set-mode-line-busy-indicator)
      (let ((previous (process-sentinel proc)))
        (unless (eq previous 'vc-process-sentinel)
          (process-put proc 'vc-previous-sentinel previous))
        (set-process-sentinel proc 'vc-process-sentinel))
      (process-put proc 'vc-sentinel-commands
                   ;; We keep the code fragments in the order given
                   ;; so that vc-diff-finish's message shows up in
                   ;; the presence of non-nil vc-command-messages.
                   (append (process-get proc 'vc-sentinel-commands)
                           (list code))))
     (t (error "Unexpected process state"))))
  nil)

(defvar vc-post-command-functions nil
  "Hook run at the end of `vc-do-command'.
Each function is called inside the buffer in which the command was run
and is passed 3 arguments: the COMMAND, the FILES and the FLAGS.")

(defvar w32-quote-process-args)

(defun vc-delistify (filelist)
  "Smash a FILELIST into a file list string suitable for info messages."
  ;; FIXME what about file names with spaces?
  (if (not filelist) "."  (mapconcat 'identity filelist " ")))

;;;###autoload
(defun vc-do-command (buffer okstatus command file-or-list &rest flags)
  "Execute a slave command, notifying user and checking for errors.
Output from COMMAND goes to BUFFER, or the current buffer if
BUFFER is t.  If the destination buffer is not already current,
set it up properly and erase it.  The command is considered
successful if its exit status does not exceed OKSTATUS (if
OKSTATUS is nil, that means to ignore error status, if it is
`async', that means not to wait for termination of the
subprocess; if it is t it means to ignore all execution errors).
FILE-OR-LIST is the name of a working file; it may be a list of
files or be nil (to execute commands that don't expect a file
name or set of files).  If an optional list of FLAGS is present,
that is inserted into the command line before the filename."
  ;; FIXME: file-relative-name can return a bogus result because
  ;; it doesn't look at the actual file-system to see if symlinks
  ;; come into play.
  (let* ((files
	  (mapcar (lambda (f) (file-relative-name (expand-file-name f)))
		  (if (listp file-or-list) file-or-list (list file-or-list))))
	 (full-command
	  ;; What we're doing here is preparing a version of the command
	  ;; for display in a debug-progress message.  If it's fewer than
	  ;; 20 characters display the entire command (without trailing
	  ;; newline).  Otherwise display the first 20 followed by an ellipsis.
	  (concat (if (string= (substring command -1) "\n")
		      (substring command 0 -1)
		    command)
		  " "
		  (vc-delistify (mapcar (lambda (s) (if (> (length s) 20) (concat (substring s 0 2) "...")  s)) flags))
		  " " (vc-delistify files))))
    (save-current-buffer
      (unless (or (eq buffer t)
		  (and (stringp buffer)
		       (string= (buffer-name) buffer))
		  (eq buffer (current-buffer)))
	(vc-setup-buffer buffer))
      ;; If there's some previous async process still running, just kill it.
      (let ((oldproc (get-buffer-process (current-buffer))))
        ;; If we wanted to wait for oldproc to finish before doing
        ;; something, we'd have used vc-eval-after.
        ;; Use `delete-process' rather than `kill-process' because we don't
        ;; want any of its output to appear from now on.
        (if oldproc (delete-process oldproc)))
      (let ((squeezed (remq nil flags))
	    (inhibit-read-only t)
	    (status 0))
	(when files
	  (setq squeezed (nconc squeezed files)))
	(let ((exec-path (append vc-path exec-path))
	      ;; Add vc-path to PATH for the execution of this command.
	      (process-environment
	       (cons (concat "PATH=" (getenv "PATH")
			     path-separator
			     (mapconcat 'identity vc-path path-separator))
		     process-environment))
	      (w32-quote-process-args t))
	  (when (and (eq okstatus 'async) (file-remote-p default-directory))
	    ;; start-process does not support remote execution
	    (setq okstatus nil))
	  (if (eq okstatus 'async)
	      ;; Run asynchronously.
	      (let ((proc
		     (let ((process-connection-type nil))
		       (apply 'start-file-process command (current-buffer)
                              command squeezed))))
		(if vc-command-messages
		    (message "Running %s in background..." full-command))
		;;(set-process-sentinel proc (lambda (p msg) (delete-process p)))
		(set-process-filter proc 'vc-process-filter)
		(vc-exec-after
		 `(if vc-command-messages
		      (message "Running %s in background... done" ',full-command))))
	    ;; Run synchronously
	    (when vc-command-messages
	      (message "Running %s in foreground..." full-command))
	    (let ((buffer-undo-list t))
	      (setq status (apply 'process-file command nil t nil squeezed)))
	    (when (and (not (eq t okstatus))
		       (or (not (integerp status))
			   (and okstatus (< okstatus status))))
              (unless (eq ?\s (aref (buffer-name (current-buffer)) 0))
                (pop-to-buffer (current-buffer))
                (goto-char (point-min))
                (shrink-window-if-larger-than-buffer))
	      (error "Running %s...FAILED (%s)" full-command
		     (if (integerp status) (format "status %d" status) status))))
	  ;; We're done.  But don't emit a status message if running
	  ;; asynchronously, it would just mislead.
	  (if (and vc-command-messages (not (eq okstatus 'async)))
	      (message "Running %s...OK = %d" full-command status)))
	(vc-exec-after
	 `(run-hook-with-args 'vc-post-command-functions
			      ',command ',file-or-list ',flags))
	status))))

;; These functions are used to ensure that the view the user sees is up to date
;; even if the dispatcher client mode has messed with file contents (as in,
;; for example, VCS keyword expansion).

(declare-function view-mode-exit "view" (&optional return-to-alist exit-action all-win))

(defun vc-position-context (posn)
  "Save a bit of the text around POSN in the current buffer.
Used to help us find the corresponding position again later
if markers are destroyed or corrupted."
  ;; A lot of this was shamelessly lifted from Sebastian Kremer's
  ;; rcs.el mode.
  (list posn
	(buffer-size)
	(buffer-substring posn
			  (min (point-max) (+ posn 100)))))

(defun vc-find-position-by-context (context)
  "Return the position of CONTEXT in the current buffer.
If CONTEXT cannot be found, return nil."
  (let ((context-string (nth 2 context)))
    (if (equal "" context-string)
	(point-max)
      (save-excursion
	(let ((diff (- (nth 1 context) (buffer-size))))
	  (when (< diff 0) (setq diff (- diff)))
	  (goto-char (nth 0 context))
	  (if (or (search-forward context-string nil t)
		  ;; Can't use search-backward since the match may continue
		  ;; after point.
		  (progn (goto-char (- (point) diff (length context-string)))
			 ;; goto-char doesn't signal an error at
			 ;; beginning of buffer like backward-char would
			 (search-forward context-string nil t)))
	      ;; to beginning of OSTRING
	      (- (point) (length context-string))))))))

(defun vc-context-matches-p (posn context)
  "Return t if POSN matches CONTEXT, nil otherwise."
  (let* ((context-string (nth 2 context))
	 (len (length context-string))
	 (end (+ posn len)))
    (if (> end (1+ (buffer-size)))
	nil
      (string= context-string (buffer-substring posn end)))))

(defun vc-buffer-context ()
  "Return a list (POINT-CONTEXT MARK-CONTEXT REPARSE).
Used by `vc-restore-buffer-context' to later restore the context."
  (let ((point-context (vc-position-context (point)))
	;; Use mark-marker to avoid confusion in transient-mark-mode.
	(mark-context (when (eq (marker-buffer (mark-marker)) (current-buffer))
			 (vc-position-context (mark-marker))))
	;; Make the right thing happen in transient-mark-mode.
	(mark-active nil))
    (list point-context mark-context nil)))

(defun vc-restore-buffer-context (context)
  "Restore point/mark, and reparse any affected compilation buffers.
CONTEXT is that which `vc-buffer-context' returns."
  (let ((point-context (nth 0 context))
	(mark-context (nth 1 context)))
    ;; if necessary, restore point and mark
    (if (not (vc-context-matches-p (point) point-context))
	(let ((new-point (vc-find-position-by-context point-context)))
	  (when new-point (goto-char new-point))))
    (and mark-active
         mark-context
         (not (vc-context-matches-p (mark) mark-context))
         (let ((new-mark (vc-find-position-by-context mark-context)))
           (when new-mark (set-mark new-mark))))))

(defun vc-revert-buffer-internal (&optional arg no-confirm)
  "Revert buffer, keeping point and mark where user expects them.
Try to be clever in the face of changes due to expanded version-control
key words.  This is important for typeahead to work as expected.
ARG and NO-CONFIRM are passed on to `revert-buffer'."
  (interactive "P")
  (widen)
  (let ((context (vc-buffer-context)))
    ;; Use save-excursion here, because it may be able to restore point
    ;; and mark properly even in cases where vc-restore-buffer-context
    ;; would fail.  However, save-excursion might also get it wrong --
    ;; in this case, vc-restore-buffer-context gives it a second try.
    (save-excursion
      ;; t means don't call normal-mode;
      ;; that's to preserve various minor modes.
      (revert-buffer arg no-confirm t))
    (vc-restore-buffer-context context)))

(defun vc-resynch-window (file &optional keep noquery)
  "If FILE is in the current buffer, either revert or unvisit it.
The choice between revert (to see expanded keywords) and unvisit
depends on KEEP.  NOQUERY if non-nil inhibits confirmation for
reverting.  NOQUERY should be t *only* if it is known the only
difference between the buffer and the file is due to
modifications by the dispatcher client code, rather than user
editing!"
  (and (string= buffer-file-name file)
       (if keep
	   (progn
	     (vc-revert-buffer-internal t noquery)
             ;; TODO: Adjusting view mode might no longer be necessary
             ;; after RMS change to files.el of 1999-08-08.  Investigate
             ;; this when we install the new VC.
             (and view-read-only
                  (if (file-writable-p file)
                      (and view-mode
                           (let ((view-old-buffer-read-only nil))
                             (view-mode-exit)))
                    (and (not view-mode)
                         (not (eq (get major-mode 'mode-class) 'special))
                         (view-mode-enter))))
	     (run-hook-with-args 'mode-line-hook buffer-file-name))
	 (kill-buffer (current-buffer)))))

(declare-function vc-dir-resynch-file "vc-dir" (&optional fname))

(defun vc-resynch-buffer (file &optional keep noquery)
  "If FILE is currently visited, resynch its buffer."
  (if (string= buffer-file-name file)
      (vc-resynch-window file keep noquery)
    (let ((buffer (get-file-buffer file)))
      (when buffer
	(with-current-buffer buffer
	  (vc-resynch-window file keep noquery)))))
  ;; Try to avoid unnecessary work, a *vc-dir* buffer is only present
  ;; if this is true.
  (when (memq 'vc-dir-resynch-file after-save-hook)
    (vc-dir-resynch-file file)))

(defun vc-buffer-sync (&optional not-urgent)
  "Make sure the current buffer and its working file are in sync.
NOT-URGENT means it is ok to continue if the user says not to save."
  (when (buffer-modified-p)
    (if (or vc-suppress-confirm
	    (y-or-n-p (format "Buffer %s modified; save it? " (buffer-name))))
	(save-buffer)
      (unless not-urgent
	(error "Aborted")))))

;; Command closures

;; Set up key bindings for use while editing log messages

(defun vc-log-edit (fileset)
  "Set up `log-edit' for use on FILE."
  (setq default-directory
	(with-current-buffer vc-parent-buffer default-directory))
  (log-edit 'vc-finish-logentry
	    nil
	    `((log-edit-listfun . (lambda () ',fileset))
	      (log-edit-diff-function . (lambda () (vc-diff nil)))))
  (set (make-local-variable 'vc-log-fileset) fileset)
  (make-local-variable 'vc-log-extra)
  (set-buffer-modified-p nil)
  (setq buffer-file-name nil))

(defun vc-start-logentry (files extra comment initial-contents msg logbuf action &optional after-hook)
  "Accept a comment for an operation on FILES with extra data EXTRA.
If COMMENT is nil, pop up a LOGBUF buffer, emit MSG, and set the
action on close to ACTION.  If COMMENT is a string and
INITIAL-CONTENTS is non-nil, then COMMENT is used as the initial
contents of the log entry buffer.  If COMMENT is a string and
INITIAL-CONTENTS is nil, do action immediately as if the user had
entered COMMENT.  If COMMENT is t, also do action immediately with an
empty comment.  Remember the file's buffer in `vc-parent-buffer'
\(current one if no file).  AFTER-HOOK specifies the local value
for `vc-log-after-operation-hook'."
  (let ((parent
         (if (vc-dispatcher-browsing)
             ;; If we are called from a directory browser, the parent buffer is
             ;; the current buffer.
             (current-buffer)
           (if (and files (equal (length files) 1))
               (get-file-buffer (car files))
             (current-buffer)))))
    (if (and comment (not initial-contents))
	(set-buffer (get-buffer-create logbuf))
      (pop-to-buffer (get-buffer-create logbuf)))
    (set (make-local-variable 'vc-parent-buffer) parent)
    (set (make-local-variable 'vc-parent-buffer-name)
	 (concat " from " (buffer-name vc-parent-buffer)))
    (vc-log-edit files)
    (make-local-variable 'vc-log-after-operation-hook)
    (when after-hook
      (setq vc-log-after-operation-hook after-hook))
    (setq vc-log-operation action)
    (setq vc-log-extra extra)
    (when comment
      (erase-buffer)
      (when (stringp comment) (insert comment)))
    (if (or (not comment) initial-contents)
	(message "%s  Type C-c C-c when done" msg)
      (vc-finish-logentry (eq comment t)))))

(declare-function vc-dir-move-to-goal-column "vc-dir" ())

(defun vc-finish-logentry (&optional nocomment)
  "Complete the operation implied by the current log entry.
Use the contents of the current buffer as a check-in or registration
comment.  If the optional arg NOCOMMENT is non-nil, then don't check
the buffer contents as a comment."
  (interactive)
  ;; Check and record the comment, if any.
  (unless nocomment
    (run-hooks 'vc-logentry-check-hook))
  ;; Sync parent buffer in case the user modified it while editing the comment.
  ;; But not if it is a vc-dir buffer.
  (with-current-buffer vc-parent-buffer
    (or (vc-dispatcher-browsing) (vc-buffer-sync)))
  (unless vc-log-operation
    (error "No log operation is pending"))
  ;; save the parameters held in buffer-local variables
  (let ((logbuf (current-buffer))
	(log-operation vc-log-operation)
	(log-fileset vc-log-fileset)
	(log-extra vc-log-extra)
	(log-entry (buffer-string))
	(after-hook vc-log-after-operation-hook)
	(tmp-vc-parent-buffer vc-parent-buffer))
    (pop-to-buffer vc-parent-buffer)
    ;; OK, do it to it
    (save-excursion
      (funcall log-operation
	       log-fileset
	       log-extra
	       log-entry))
    ;; Remove checkin window (after the checkin so that if that fails
    ;; we don't zap the log buffer and the typing therein).
    ;; -- IMO this should be replaced with quit-window
    (cond ((and logbuf vc-delete-logbuf-window)
	   (delete-windows-on logbuf (selected-frame))
	   ;; Kill buffer and delete any other dedicated windows/frames.
	   (kill-buffer logbuf))
	  (logbuf (pop-to-buffer logbuf)
		  (bury-buffer)
		  (pop-to-buffer tmp-vc-parent-buffer)))
    ;; Now make sure we see the expanded headers
    (when log-fileset
      (mapc
       (lambda (file) (vc-resynch-buffer file vc-keep-workfiles t))
       log-fileset))
    (when (vc-dispatcher-browsing)
      (vc-dir-move-to-goal-column))
    (run-hooks after-hook 'vc-finish-logentry-hook)))

(defun vc-dispatcher-browsing ()
  "Are we in a directory browser buffer?"
  (derived-mode-p 'vc-dir-mode))

;; These are unused.
;; (defun vc-dispatcher-in-fileset-p (fileset)
;;   (let ((member nil))
;;     (while (and (not member) fileset)
;;       (let ((elem (pop fileset)))
;;         (if (if (file-directory-p elem)
;;                 (eq t (compare-strings buffer-file-name nil (length elem)
;;                                        elem nil nil))
;;               (eq (current-buffer) (get-file-buffer elem)))
;;             (setq member t))))
;;     member))

;; (defun vc-dispatcher-selection-set (&optional observer)
;;   "Deduce a set of files to which to apply an operation.  Return a cons
;; cell (SELECTION . FILESET), where SELECTION is what the user chose
;; and FILES is the flist with any directories replaced by the listed files
;; within them.

;; If we're in a directory display, the fileset is the list of marked files (if
;; there is one) else the file on the current line.  If not in a directory
;; display, but the current buffer visits a file, the fileset is a singleton
;; containing that file.  Otherwise, throw an error."
;;   (let ((selection
;;          (cond
;;           ;; Browsing with vc-dir
;;           ((vc-dispatcher-browsing)
;; 	   ;; If no files are marked, temporarily mark current file
;; 	   ;; and choose on that basis (so we get subordinate files)
;; 	   (if (not (vc-dir-marked-files))
;; 		 (prog2
;; 		   (vc-dir-mark-file)
;; 		   (cons (vc-dir-marked-files) (vc-dir-marked-only-files))
;; 		   (vc-dir-unmark-all-files t))
;; 	     (cons (vc-dir-marked-files) (vc-dir-marked-only-files))))
;;           ;; Visiting an eligible file
;;           ((buffer-file-name)
;;            (cons (list buffer-file-name) (list buffer-file-name)))
;;           ;; No eligible file -- if there's a parent buffer, deduce from there
;;           ((and vc-parent-buffer (or (buffer-file-name vc-parent-buffer)
;;                                      (with-current-buffer vc-parent-buffer
;;                                        (vc-dispatcher-browsing))))
;;            (with-current-buffer vc-parent-buffer
;;              (vc-dispatcher-selection-set)))
;;           ;; No good set here, throw error
;;           (t (error "No fileset is available here")))))
;;     ;; We assume, in order to avoid unpleasant surprises to the user,
;;     ;; that a fileset is not in good shape to be handed to the user if the
;;     ;; buffers visiting the fileset don't match the on-disk contents.
;;     (unless observer
;;       (save-some-buffers
;;        nil (lambda () (vc-dispatcher-in-fileset-p (cdr selection)))))
;;     selection))

(provide 'vc-dispatcher)

;; arch-tag: 7d08b17f-5470-4799-914b-bfb9fcf6a246
;;; vc-dispatcher.el ends here

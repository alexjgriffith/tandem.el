;;; tandem.el --- Client for Tandem  -*- lexical-binding: t -*-

;; Copyright (C) 2018 Alexander Giffith
;; Author: Alexander Griffith <griffitaj@gmail.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.4"))
;; Homepage: https://github.com/alexjgriffith/tandem.el

;; This file is not part of GNU Emacs.

;; This file is part of tandem.el.

;; tandem.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; tandem.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with tandem.el.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(defvar tandem-local-change-message nil)

(make-variable-buffer-local tandem-local-change-message)

(defun column-number-at-pos (&optional pos)
  "Return  buffer column number at position POS.
If POS is nil, use current buffer location.
Counting starts at (point-min), so the value refers
to the contents of the accessible portion of the buffer."
  (let ((opoint (or pos (point))))
    (save-excursion
      (goto-char opoint)
      (current-column))))

(defun tandem-agent-report-local-write (start end text)
  "Format a local write for the tandem agent.
START is a cons list first member row second member column.
END has the same structure as START.
TEXT is a string."
  `((start . ((row . ,(car start)) (column . ,(cdr start))))
    (end . ((row . ,(car end)) (column . ,(cdr end))))
    (text . ,text)))

(defun tandem-before-change-hook (start end)
  "Prepare a local write for tandem if change occures to a buffer.
START is the start position of the change. END is the ending
position of the change. If there is a change `tandem-local-change-message'
is set to that value, otherwise it is set to nil."
  (let ((end-pos `(,(- (line-number-at-pos end) 1)
                   . ,(column-number-at-pos end)))
        (start-pos `(,(- (line-number-at-pos start) 1)
                     . ,(column-number-at-pos start))))
      (setq tandem-local-change-message
            (when (not (equal end-pos start-pos))
              (tandem-agent-report-local-write start-pos end-pos "")))))

(defun tandem-after-change-hook (start end length)
  "Send a local write patch to tandem after each change to the buffer."
  (let* ((end-pos `(,(- (line-number-at-pos end) 1)
                    . ,(column-number-at-pos end)))
         (start-pos `(,(- (line-number-at-pos start) 1)
                      . ,(column-number-at-pos start)))
         (str (if (and (> length 0) tandem-local-change-message)
                  tandem-local-change-message
                (tandem-agent-report-local-write
                 start-pos end-pos
                 (buffer-substring-no-properties start end)))))
    (setq tandem-local-change-message nil)
    str))

(defun tandem-track-inputs ()
  (interactive)
  (make-local-variable 'after-change-functions)
  (make-local-variable 'before-change-functions)
  (add-hook 'before-change-functions 'tandem-before-change-hook t t)
  (add-hook 'after-change-functions 'tandem-after-change-hook t t))

(defun tandem-message-user-changed-editor-text (contents)
  "Create object to notify tandem agent that user has changed buffer text."
  `("user-changed-editor-text" . ((contents . ,contents))))

(defun tandem-message-check-document-sync (contents)
  "Create object to request tandem agent to compare buffer and crdt."
  `("check-document-sync" . ((contents .  ,contents))))

(defun tandem-message-check-apply-text (contents)
  "Create object to hold input from agent if there needs to be a buffer change."
  `("check-apply-text" . ((contents . ,contents))))

(defun tandem-message-connect-to (host port)
  "Create object to send to the agent to request connection to another agent."
  `("connect-to" . ((host . ,host) (port . ,port))))

(defun tandem-message-write-request (seq)
  "Create object to hold request sent by agent concerning crdt update in buffer."
  `("write-request" . ((seq . ,seq))))

(defun tandem-message-write-request-ack (seq)
  "Create object to hold response to agent's write request."
  `("write-request-ack" . ((seq . ,seq))))

(defun tandem-message-new-patches (patch-list)
  "Create object to hold new patches that were made by the user in buffer."
    `("new-patches" . ((patch_list . ,patch-list))))

(defun tandem-message-apply-patches (patch-list)
  "Create object to hold a vector of new patches to be applied to buffer."
  `("apply-patches" . ((patch_list . ,patch-list))))

(defun tandem-message-host-session ()
  "Create object for host initiation request."
  `("host-session" . (())))

(defun tandem-message-join-session (session-id)
  "Create object to hold info for users request to join session."
  `("join-session" . ((session_id . ,session-id))))

(defun tandem-message-session-info (session-id)
  "Create object to hold info for users current session."
  `("session-info" . ((session_id . ,session-id))))

(defun tandem-message-serialize (message)
  "Serialize MESSAGE for transmision to agent."
  (json-encode-alist
   `((type . ,(car message))
     (payload . ,(cdr message))
     (version . 1))))

(defun tandem-message-deserialize (json)
  "Deserialize JSON recieved from agent."
  (let ((ess (json-read-from-string json)))
    (cons (cdr (assoc 'type ess))
          (cdr (assoc 'payload ess)))))

(provide 'tandem)
;;; tandem.el ends here

;;; org-global-insert-link.el --- 
;; 
;; Filename: org-global-insert-link.el
;; Description: Use Org Mode's ability to capture links in other modes.
;; Author: Neil Smithline
;; Maintainer: Neil Smithline
;; Copyright (C) 2012, Neil Smithline, all rights reserved.;; Created: Sat Apr 14 18:40:50 2012 (-0400)
;; Version: 0.1
;; Last-Updated: 14 April 2012
;;           By: Neil Smithline
;;     Update #: 0
;; URL: 
;; Keywords: org-mode, org, links, urls
;; Compatibility: Any modern Emacs and Org Mode.
;; 
;; Features that might be required by this library:
;;
;;   org
;;   org-capture
;;   org-protocol
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Commentary: 
;; The `org-insert-mode-link-global' function extends `org-mode's
;; ability to insert and format captured links in non-`org-mode'
;; buffers.
;;
;; The formatting of the link is dependent on the major-mode of the
;; buffer. For example, it will insert HTML-style links in when in
;; `html-mode' or `nxhtml-mode'.
;;
;; The modes that are supported can be modified by changing the
;; variable `init-org-insert-mode-link-mappings'.
;;
;; URLs can be captured via a variety of means including features
;; provided by `org-capture' and `org-protocol'
;; 
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Change Log:
;; 
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Code:
(require 'defhook)

(defun org-convert-link-to-html (url description)
  ;; To use `org-html-make-link' we must split URL into path and
  ;; protocol without messing up the match-data for
  ;; `org-insert-mode-link-global'.
  (save-match-data
    (string-match "\\([^:]+\\):\\(.+\\)" url)
    (let ((protocol       (match-string 1 url))
          (path           (match-string 2 url)))
      (org-html-make-link nil                   ; no opt-plist needed
                          protocol
                          path
                          nil                   ; no fragment needed
                          description
                          "target=\"_blank\""   ; other tag attributes
                          nil))))               ; don't inline images

(defun org-convert-link-to-text (url description)
  (format "%s (see %s)" description url))

(defun org-convert-link-to-elisp (url description)
  (format "%s (see URL `%s')" description url))

(defun org-convert-link-to-org (url description)
  (org-make-link-string url description))

;; For debugging: (setq org-insert-mode-link-mappings nil)
(defvar org-insert-mode-link-mappings nil
  "Assoc list of mappings to use for `org-insert-mode-link-global'.
The `car' of each item should be a mode name that matches the
value of the variable `major-mode'. The `cdr' should be a handler
function that will properly format the link for the major mode.

The handler function will be passed two arguments. The first
argument is a string that is the target URL of the link. The
second argument is a string description of the url. The
description is appropriate to display to the user.")

(defhook init-org-insert-mode-link-mappings (emacs-startup-hook)
  (add-to-list 'org-insert-mode-link-mappings
               (list 'org-mode       #'org-convert-link-to-org))
  (add-to-list 'org-insert-mode-link-mappings
               (list 'emacs-lisp-mode #'org-convert-link-to-elisp))
  (add-to-list 'org-insert-mode-link-mappings
               (list 'html-mode      #'org-convert-link-to-html))
  (add-to-list 'org-insert-mode-link-mappings
               (list 'nxhtml-mode    #'org-convert-link-to-html))
  (add-to-list 'org-insert-mode-link-mappings
               (list 'text-mode      #'org-convert-link-to-text)))

(defun org-insert-mode-link-global ()
  "Like `org-insert-link-global' with formatting for other modes.
It may be helpful to bind this function to a global keymapping.
For example, putting:
    (global-set-key \"\\C-cl\" #'org-insert-mode-link-global)
in your `user-init-filewill' will bind this to \"Control-C L\".

The set of supported modes is stored in the variable
`org-insert-mode-link-mappings'."
  (interactive)
  (org-insert-link-global)
  (let ((bounds             (org-in-regexp org-bracket-link-regexp))
        (conversion-fn      (cadr (assoc major-mode
                                         org-insert-mode-link-mappings))))
    (when (and bounds conversion-fn)
      (assert (functionp conversion-fn) t)
      ;; I seem to lose the match data set by `org-in-regexp' so I
      ;; just repeat the search. This is easy and fast as
      ;; `org-in-regexp' has given me the start of the regexp.
      (save-excursion
        (goto-char (car bounds))
        (assert (looking-at org-bracket-link-analytic-regexp) t)
        ;; Now pull the path components out.
        (let ((url          (concat (match-string-no-properties 2)
                                    ":"
                                    (match-string-no-properties 3)))
              (description  (match-string-no-properties 5)))
          ;; And coll the conversion function to replace the newly
          ;; inserted link
          (replace-match (funcall conversion-fn url description)
                         'fixedcase 'literal))))))

(provide 'org-global-insert-link)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org-global-insert-link.el ends here

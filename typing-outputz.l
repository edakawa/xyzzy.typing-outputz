;;; -*- Mode: Lisp -*-

;;; $Id: typing-outputz.l,v 1.2 2018/09/08 15:33:13 hajime Exp $

;;; typing-outputz --- Outputz.com typing mode for xyzzy.

;; Author: Hajime EDAKAWA <hajime.edakawa@gmail.com>
;; License: Public Domain
;; Last Update: May 2010

;; This file is part of xyzzy.

;;; Commentary:

;; This is Minor mode for http://outputz.com/ that is to send typing count number.
;; In this typing-outputz, sends to http://outputz.com/ in format "xyzzy://MODE-NAME/COUNT-LINE/BUFFER-NAME".
;;     MODE-NAME   --- Buffer mode name.
;;     COUNT-LINE  --- Number of newline.
;;     BUFFER-NAME --- Buffer name.

;;; Requirement:

;; xml-http-request

;;; Installation:

;; 1. Please move typing-outputz.l to your site-lisp directory.
;; 2. Please add following expression to your .xyzzy file.
;;     (require "typing-outputz")
;;     (use-package :typing-outputz)
;;     (setq *typing-outputz-key* "•œŠˆ‚ÌŽô•¶")
;;     (add-hook '*find-file-hooks*
;;               'typing-outputz-mode)
;; 3. End.

;; If you don't install xml-http-request, please download from following URL.
;;     http://miyamuko.s56.xrea.com/xyzzy/xml-http-request/intro.htm

;;; Acknowledgement:

;; hayamiz
;;     Made typing-outputz idea first.
;; miyamuko
;;     Taught mistake.
;;     Suggestion on typing-outputz-post.

;;; Code:

(provide "typing-outputz")

(defpackage "typing-outputz"
  (:use "lisp" "editor"))

(in-package "typing-outputz")

(require "xml-http-request")
(use-package :xml-http-request)

(export '(*typing-outputz-key*
	  typing-outputz-mode))

(defvar *typing-outputz-key* nil)

(defvar-local *typing-outputz-mode* nil)
(defvar-local *typing-outputz-count-char* 0)
(defvar-local *typing-outputz-count-line* 0)
(defvar-local *typing-outputz-total-line-number* nil)

(defun typing-outputz-mode (&optional (arg nil sv))
  (interactive "p")
  (ed::toggle-mode '*typing-outputz-mode* arg sv)
  (dolist (x '((*post-command-hook* . typing-outputz-count-up)
	       (*after-save-buffer-hook* . typing-outputz-post)))
    (if *typing-outputz-mode*
	(add-hook (car x) (cdr x))
      (delete-hook (car x) (cdr x))))
  (update-mode-line t))

(defun typing-outputz-count-up ()
  (unless *typing-outputz-total-line-number*
    (setq *typing-outputz-total-line-number* (buffer-lines)))
  (when *typing-outputz-mode*
    (when (eq *this-command* 'self-insert-command)
      (setq *typing-outputz-count-char* (1+ *typing-outputz-count-char*)))
    (let ((n (buffer-lines)))
      (cond ((> n *typing-outputz-total-line-number*)
	     (setq *typing-outputz-count-line* (+ *typing-outputz-count-line* (- n *typing-outputz-total-line-number*))
		   *typing-outputz-total-line-number* n))
	    ((< n *typing-outputz-total-line-number*)
	     (setq *typing-outputz-total-line-number* n))))))

(defun typing-outputz-post ()
  (flet ((escape-uri (str)
	   (si:www-url-encode (substitute-string str " " "-"))))
    (when (and *typing-outputz-mode*
	       (or (not (zerop *typing-outputz-count-char*))
		   (not (zerop *typing-outputz-count-line*))))
      (unwind-protect
	  (xhr-post-async "http://outputz.com/api/post"
			  `(:key  ,*typing-outputz-key*
			    :uri  ,(format nil "xyzzy://~A/~D/~A" (escape-uri mode-name) *typing-outputz-count-line* (escape-uri (buffer-name (selected-buffer))))
			    :size ,(+ *typing-outputz-count-char* *typing-outputz-count-line*))
			  :encoding *encoding-utf8n*
			  :onsuccess #'(lambda (res) (message "Sending Outputz...done"))
			  :onfailure #'(lambda (res) (msgbox "Error: Typing Outputz: ~A" (xhr-status-text res))))
	(setq *typing-outputz-count-char* 0
	      *typing-outputz-count-line* 0)))))

(pushnew '(*typing-outputz-mode* . "TypingOutputz") *minor-mode-alist* :key #'car)

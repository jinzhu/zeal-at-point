;;; zeal-at-point.el --- Search the word at point with Zeal

;; Copyright (C) 2013 Jinzhu
;; Author:  Jinzhu <wosmvp@gmail.com>
;; Created: 29 Nov 2013
;; Version: 0.0.3
;; URL: https://github.com/jinzhu/zeal-at-point
;;
;; This file is NOT part of GNU Emacs.
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy of
;; this software and associated documentation files (the "Software"), to deal in
;; the Software without restriction, including without limitation the rights to
;; use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is furnished to do
;; so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.
;;
;; Commentary:
;;
;; Add the following to your .emacs:
;;
;;   (require 'zeal-at-point)
;;   (global-set-key "\C-cd" 'zeal-at-point)
;;
;; Run `zeal-at-point' to search the word at point, then Zeal is
;; launched and search the word. To edit the search term first,
;; use C-u to set the prefix argument for `zeal-at-point'.
;;
;; Run `zeal-at-point-set-docset' to set docset for current buffer
;;
;; Zeal queries can be narrowed down with a docset prefix.  You can
;; customize the relations between docsets and major modes.
;;
;;   (add-to-list 'zeal-at-point-mode-alist '(perl-mode . "perl"))
;;
;; Additionally, the buffer-local variable `zeal-at-point-docset' can
;; be set in a specific mode hook (or file/directory local variables)
;; to programmatically override the guessed docset.  For example:
;;
;;   (add-hook 'rinari-minor-mode-hook
;;             (lambda () (setq zeal-at-point-docset "rails")))
;;
;;
;; Thanks dash-at-point.el (https://github.com/stanaka/dash-at-point), I copied lots of code from it!
;;

;;; Code:

(defgroup zeal-at-point nil
  "Searching in Zeal for text at point"
  :group 'external)

(defvar zeal-at-point-zeal-version
  (when (executable-find "zeal")
    (let ((output (with-temp-buffer
                    (call-process "zeal" nil t nil "--version")
                    (buffer-string))))
      (when (string-match "Zeal \\([[:digit:]\\.]+\\)" output)
        (match-string 1 output))))
  "The version of zeal installed on the system.")

(defcustom zeal-at-point-mode-alist
  `((actionscript-mode . "actionscript")
    (arduino-mode . "arduino")
    (c++-mode . "cpp")
    (c-mode . "c")
    (clojure-mode . "clojure")
    (coffee-mode . "coffee")
    (lisp-mode . "lisp")
    (cperl-mode . "perl")
    (css-mode . "css")
    (elixir-mode . "elixir")
    (emacs-lisp-mode . ,(if (and zeal-at-point-zeal-version
                                 (version< zeal-at-point-zeal-version "0.3.0"))
                            "emacs lisp"
                          "elisp"))
    (enh-ruby-mode . "ruby")
    (erlang-mode . "erlang")
    (gfm-mode . "markdown")
    (go-mode . "go")
    (groovy-mode . "groovy")
    (haskell-mode . "haskell")
    (html-mode . "html")
    (java-mode . "java")
    (js2-mode . "javascript")
    (js3-mode . "nodejs")
    (less-css-mode . "less")
    (lua-mode . "lua")
    (markdown-mode . "markdown")
    (objc-mode . "iphoneos")
    (perl-mode . "perl")
    (php-mode . "php")
    (processing-mode . "processing")
    (puppet-mode . "puppet")
    (python-mode . "python3")
    (ruby-mode . "ruby")
    (rust-mode . "rust")
    (sass-mode . "sass")
    (scala-mode . "scala")
    (tcl-mode . "tcl")
    (vim-mode . "vim"))
  "Alist which maps major modes to Zeal docset tags.
Each entry is of the form (MAJOR-MODE . DOCSET-TAG) where
MAJOR-MODE is a symbol and DOCSET-TAG is a corresponding tag
for one or more docsets in Zeal."
  :type '(repeat (cons (symbol :tag "Major mode name")
                       (or (string :tag "Docset tag")
                           (repeat (string :tag "Docset tags")))))
  :group 'zeal-at-point)

(defvar zeal-at-point-docsets (mapcar
                               (lambda (element)
                                 (cdr element))
                               zeal-at-point-mode-alist)
  "Variable used to store all known Zeal docsets. The default value
is a collection of all the values from `zeal-at-point-mode-alist'.

Setting or appending this variable can be used to add completion
options to `zeal-at-point-docset'.")

(defvar zeal-at-point-docset nil
  "Variable used to specify the docset for the current buffer.
Users can set this to override the default guess made using
`zeal-at-point-mode-alist', allowing the docset to be determined
programatically.

For example, Ruby on Rails programmers might add an \"allruby\"
tag to the Rails, Ruby and Rubygems docsets in Zeal, and then add
code to `rinari-minor-mode-hook' or `ruby-on-rails-mode-hook'
which sets this variable to \"allruby\" so that Zeal will search
the combined docset.")
(make-variable-buffer-local 'zeal-at-point-docset)

(defvar zeal-at-point--docset-history nil)

(unless (fboundp 'setq-local)
  (defmacro setq-local (var val)
    `(set (make-local-variable ',var) ,val)))

(defun zeal-at-point-get-docset ()
  "Guess which docset suit to the current major mode."
  (or zeal-at-point-docset (cdr (assoc major-mode zeal-at-point-mode-alist))))

(defun zeal-at-point-maybe-add-docset (search-string)
  "Prefix SEARCH-STRING with the guessed docset, if any."
  (let ((docset (zeal-at-point-get-docset)))
    (if (version<= "0.2.1" zeal-at-point-zeal-version)
        (let ((docsets (if (listp docset)
                           (mapconcat #'identity docset ",")
                         docset)))
          (format "dash-plugin://keys=%s&query=%s" docsets search-string))
      (concat (when docset
                (concat docset ":"))
              search-string))))

(defun zeal-at-point-run-search (search)
  (if (executable-find "zeal")
      (if (version< "0.2.0" zeal-at-point-zeal-version)
          (start-process "Zeal" nil "zeal" search)
        (start-process "Zeal" nil "zeal" "--query" search))
    (message "Zeal is not found. Please install it from http://zealdocs.org")))

;;;###autoload
(defun zeal-at-point (&optional edit-search)
  "Search for the word at point in Zeal."
  (interactive "P")
  (let* ((thing (if mark-active (buffer-substring (region-beginning) (region-end)) (thing-at-point 'symbol)))
         (search (zeal-at-point-maybe-add-docset thing)))
    (zeal-at-point-run-search
     (if (or edit-search (null thing))
         (read-string "Zeal search: " search)
       search))))

(defun zeal-at-point--docset-candidates ()
  (mapcar 'cdr zeal-at-point-mode-alist))

(defun zeal-at-point--set-docset-prompt ()
  (let ((default-docset (zeal-at-point-get-docset)))
    (format "Zeal docset%s: " (if default-docset
                                  (format "[Default: %s]" default-docset)
                                ""))))

(defun zeal-at-point-read-docset ()
  (let ((docset (completing-read (zeal-at-point--set-docset-prompt)
                                 (zeal-at-point--docset-candidates) nil nil nil
                                 'zeal-at-point--docset-history (zeal-at-point-get-docset))))
    (if (string-match-p "," docset)
        (split-string docset ",")
      docset)))

;;;###autoload
(defun zeal-at-point-set-docset ()
  "Set current buffer's docset."
  (interactive)
  (let ((minibuffer-local-completion-map
         (copy-keymap minibuffer-local-completion-map)))
    (define-key minibuffer-local-completion-map (kbd "SPC") nil)
    (setq-local zeal-at-point-docset (zeal-at-point-read-docset))))

;;;###autoload
(defun zeal-at-point-search (&optional edit-search)
  "Prompt and search in zeal."
  (interactive "P")
  (let ((search (zeal-at-point-maybe-add-docset "")))
    (zeal-at-point-run-search
     (read-string "Zeal search: " search))))

(provide 'zeal-at-point)

;;; zeal-at-point.el ends here

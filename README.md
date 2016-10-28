# Zeal At Point

Search the word at point with Zeal

[Zeal](http://zealdocs.org/) is a simple offline API documentation browser inspired by Dash (OS X app), available for Linux and Windows.

## Installation

The recommended way to install is via [MELPA](http://melpa.milkbox.net/) or Marmalade

## Usage

Run `zeal-at-point` to search the word at point (or string in region), then Zeal is launched and search the word.
Use prefix argument `C-u` to edit the search string first.

There is no default keymap defined, but you could setup your own binding like this:

```lisp
(global-set-key "\C-cd" 'zeal-at-point)
```


Zeal queries can be narrowed down with a docset prefix. You can customize the relations between docsets and major modes.

```lisp
(add-to-list 'zeal-at-point-mode-alist '(perl-mode . "perl"))

;; Use multiple docsets
(add-to-list 'zeal-at-point-mode-alist '(python-mode . ("python" "django")))
```

Additionally, the buffer-local variable `zeal-at-point-docset` can be set in a specific mode hook (or file/directory local variables) to programmatically override the guessed docset. For example:

```lisp
(add-hook 'rinari-minor-mode-hook
   (lambda () (setq zeal-at-point-docset "rails")))

;; Use multiple docsets
(add-hook 'python-mode-hook
   (lambda () (setq zeal-at-point-docset '("python" "django"))))
```

You are also possible to set docset for current buffer with `zeal-at-point-set-docset`

## Thanks

* [Shinji Tanaka](https://github.com/stanaka), Creater of [dash-at-point.el](https://github.com/stanaka/dash-at-point), I copied lots of codes from it!
* [Syohei YOSHIDA](https://github.com/syohex), Contributed lots of pull requests

## Copyright

Copyright (C) 2013 Jinzhu

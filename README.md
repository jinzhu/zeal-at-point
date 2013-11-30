# Zeal At Point

Search the word at point with Zeal

[Zeal](http://zealdocs.org/) is a simple offline API documentation browser inspired by Dash (OS X app), available for Linux and Windows.

## Installation

The recommended way to install is via [MELPA](http://melpa.milkbox.net/) or Marmalade

## Usage

```lisp
(global-set-key "\C-cd" 'zeal-at-point)
```

Run `zeal-at-point` to search the word at point (or string in region), then Zeal is launched and search the word.
Use prefix argument `C-u` to edit the search string first.

Zeal queries can be narrowed down with a docset prefix. You can customize the relations between docsets and major modes.

```lisp
(add-to-list 'zeal-at-point-mode-alist '(perl-mode . "perl"))
```

Additionally, the buffer-local variable `zeal-at-point-docset` can be set in a specific mode hook (or file/directory local variables) to programmatically override the guessed docset. For example:

```lisp
(add-hook 'rinari-minor-mode-hook
   (lambda () (setq zeal-at-point-docset "rails")))
```

Thanks [dash-at-point.el](https://github.com/stanaka/dash-at-point), I copied lots of codes from it!

## Copyright

Copyright (C) 2013 Jinzhu

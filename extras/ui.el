;; -*- lexical-binding: t; -*-

;;; ░█▀▀░█▄█░█▀█░█▀▀░█▀▀░░░█▀▄░█▀▀░█▀▀░█▀█░█░░░▀█▀░▀█▀░█░█
;;; ░█▀▀░█░█░█▀█░█░░░▀▀█░░░█▀▄░█▀▀░█░█░█░█░█░░░░█░░░█░░█▀█
;;; ░▀▀▀░▀░▀░▀░▀░▀▀▀░▀▀▀░░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░░▀░░▀░▀
;;;
;;; Frames, windows and buffers, oh my!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Basic/native settings
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setopt
 inhibit-splash-screen t
 use-short-answers t)

;; Time and load averages in modeline; not required.
(setopt display-time-default-load-average nil)

;; Move through windows with Shift-<arrow keys>
(windmove-default-keybindings 'shift) ; You can use other modifiers here

(defun regolith/windmove-no-error (orig-fun &rest args)
  "Suppress errors from windmove-do-window-select, so that if you try to move in a direction where there is no window, it doesn't throw an error."
  (condition-case nil
      (apply orig-fun args)
    (error nil)))

;; Suppress the error message
(advice-add 'windmove-do-window-select :around
            #'regolith/windmove-no-error)

;; Try to stop compilation error, etc. windows from splitting.
(setopt
 split-width-threshold nil
 split-height-threshold nil)

;; Fallback rule for all buffers: reuse existing windows, no new splits
(setopt display-buffer-base-action
        '((display-buffer-reuse-mode-window
           display-buffer-use-some-window)
          (inhibit-same-window . nil)))

;; Specific exceptions
(setopt display-buffer-alist
        `(
          (,(rx (or "*compilation*" "*Warnings*"))
           (display-buffer-below-selected)
           ;; To make it take up the entire bottom of the frame, use this instead of the above line:
           ;; (display-buffer-in-side-window)
           ;; (side . bottom)
           (window-height . 0.1)
           (preserve-size . (nil . t))
           (dedicated . t))))

;; But I do want two split windows side-by-side if possible
(defun regolith/split-window-right-if-wide-enough ()
  "Split the window vertically if the frame is wide enough and there is only one window."
  (when (and (>= (frame-width) 160)        ; Is the screen wide enough?
             (= (length (window-list)) 1)) ; Ensure it hasn't been split yet
    (split-window-right)))

(add-hook 'window-setup-hook
          'regolith/split-window-right-if-wide-enough)

;; Make right-click do something sensible
(when (display-graphic-p)
  (context-menu-mode))

;; When doing Page-Up/Page-Down, preserve the cursor's position on the screen.
(setq scroll-preserve-screen-position t)

;; Mode line information
(setopt line-number-mode t)                        ; Show current line in modeline
(setopt column-number-mode t)                      ; Show column as well

(setopt x-underline-at-descent-line nil)           ; Prettier underlines
(setopt switch-to-buffer-obey-display-actions t)   ; Make switching buffers more consistent

(setopt size-indication-mode t)
(setopt use-dialog-box nil) ;; Ask me in the minibuffer instead

(setopt
 show-trailing-whitespace nil      ; By default, don't underline trailing spaces
 indicate-buffer-boundaries 'left  ; Show buffer top and bottom in the margin
 indicate-empty-lines t)           ; Show empty lines in the margin

;; Enable horizontal scrolling
(setopt mouse-wheel-tilt-scroll t)
(setopt mouse-wheel-flip-direction t)

;; Don't accidentally close windows by clicking on the mode-line
(define-key global-map [mode-line mouse-2] nil)
(define-key global-map [mode-line mouse-3] 'minions-minor-modes-menu)

;; Misc. UI tweaks
(blink-cursor-mode -1)                                ; Steady cursor
(pixel-scroll-precision-mode)                         ; Smooth scrolling

;; For terminal users, make the mouse more useful
(unless (display-graphic-p)
  (xterm-mouse-mode 1))

;; Display line numbers in programming mode
(setopt display-line-numbers-width 3)           ; Set a minimum width

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Tab-bar configuration
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Show the tab-bar as soon as tab-bar functions are invoked
(setopt tab-bar-show 1)

;; Add the time to the tab-bar, if visible
;; (add-to-list 'tab-bar-format 'tab-bar-format-align-right 'append)
;; (add-to-list 'tab-bar-format 'tab-bar-format-global 'append)

;; not sure I'll use the tab-bar, but might as well keep this here in case I do.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Theme
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package emacs
  :config
  ;; Customised colour palette to make it less harsh (but not using
  ;; the -tinted variant as I don't like the blue)
  ;;
  ;; Doing this as a "good enough" theme without needing more packages.
  ;;
  ;; If updating bg-main an dfg-main, also update the
  ;; default-frame-alist in early-init.el to avoid flashes of color on
  ;; startup.
  (setq modus-themes-common-palette-overrides
	      '((bg-main "#242424")                  ; Matte dark charcoal gray canvas
          (bg-dim  "#1c1c1c")                  ; Deeper charcoal framing boundaries
          (bg-line-number-active "#333333")    ; Highlighted line block
          (fg-main "#dedede")                  ; Off-white reading text
          (fg-dim  "#9e9e9e")))                ; Soft gravel gray for comments/sub-text

  (load-theme 'modus-vivendi t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Other
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Not sure I quite like this; having a bit of padding around the
;; buffer is nice but I don't like the extra space it adds around the
;; fringe, between buffers, and the mode line representation.
;;
;; It also breaks moody below
;; (use-package spacious-padding
;;   :ensure t
;;   :config
;;   (spacious-padding-mode 1))

;; This is normally used to hide minor modes in the modeline, but
;; sleek-modeline already does that, so I just use it to get the
;; right-click menu on the modeline.
(use-package minions
  :ensure t
  :functions
  minions-minor-modes-menu
  :config
  ;; Avoid issues with string-match being called on non-strings, which
  ;; results in errors (typically to do with markdown mode for some
  ;; reason).
  (advice-add 'minions-minor-modes-menu :around
              (lambda (orig-fun &rest args)
                (cl-letf* ((old-sm (symbol-function 'string-match))
                           ((symbol-function 'string-match)
                            (lambda (regexp string &rest rest-args)
                              (when (stringp string)
                                (apply old-sm regexp string rest-args)))))
                  (apply orig-fun args)))))

;; Using the default Symbol font.  Not doing it on Windows as we don't
;; have the font installed there.
;;
;; Technically we can use nerd-icons in the terminal as well and not
;; require display-graphic-p, but in the rare case I'm using terminal
;; Emacs I probably want it as light as possible, so don't load it
;; there.
(use-package nerd-icons
  :ensure t
  :if (and (display-graphic-p) (system-type-is-gnu)))

;; TODO: can we somehow use the extension mechanism to use minions here still?
;;
;; Also look into why the major mode name seems rather boring/plain
;; and doesn't have the extra stuff (e.g. /l that Emacs Lisp mode has)
;; that the default mode line shows.
;;
;; Help on hover keeps talking about the legacy mouse behaviour, which
;; I've disabled above...
(use-package sleek-modeline
  :ensure t
  :if (display-graphic-p)
  :custom
  (sleek-modeline-size 'medium)
  (sleek-modeline-suppress-default-mouse nil) ;; Use Emacs mouse menus
  :config
  (sleek-modeline-mode 1))

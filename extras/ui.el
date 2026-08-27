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

;; Make prompts shorter and easier to answer
(defalias 'yes-or-no-p 'y-or-n-p)

(setopt inhibit-splash-screen t)

;; Time and load averages in modeline; not required.
(setopt display-time-default-load-average nil)

;; Move through windows with Shift-<arrow keys>
(windmove-default-keybindings 'shift) ; You can use other modifiers here

;; Suppress the error message
(advice-add 'windmove-do-window-select :around
  (lambda (orig-fun &rest args)
    (condition-case nil
        (apply orig-fun args)
      (error nil))))

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
(add-hook 'window-setup-hook
          (lambda ()
            (when (and (>= (frame-width) 160)        ; Is the screen wide enough?
                       (= (length (window-list)) 1)) ; Ensure it hasn't been split yet
              (split-window-right))))

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

;; Misc. UI tweaks
(blink-cursor-mode -1)                                ; Steady cursor
(pixel-scroll-precision-mode)                         ; Smooth scrolling

;; For terminal users, make the mouse more useful
(xterm-mouse-mode 1)

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
  (setq modus-themes-common-palette-overrides
	      '((bg-main "#242424")                  ; Matte dark charcoal gray canvas
          (bg-dim  "#1c1c1c")                  ; Deeper charcoal framing boundaries
          (bg-line-number-active "#333333")    ; Highlighted line block
          (fg-main "#dedede")                  ; Off-white reading text
          (fg-dim  "#9e9e9e")))                ; Soft gravel gray for comments/sub-text

  (load-theme 'modus-vivendi t))          ; maybe requires version 30

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

(use-package moody
  :ensure t
  :if (display-graphic-p)
  :config
  (moody-replace-vc-mode)
  (moody-replace-mode-line-front-space)
  (moody-replace-mode-line-buffer-identification))

;; Hide minor modes in the mode line, but show them in a pop-up menu
;; when you click on the mode line.
(use-package minions
  :ensure t
  :custom
  (minions-mode-line-delimiters '("[" . "]"))
  (minions-mode-line-lighter " 🗠")
  ;; Make the minions mode line face bold by customising the minions-mode-line-face variable
  (minions-mode-line-face '(:weight bold))

  :config
  (minions-mode 1))

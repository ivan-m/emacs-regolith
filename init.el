;;;
;;;  ██████████                                               ███████████                              ████   ███   █████    █████
;;; ░░███░░░░░█                                              ░░███░░░░░███                            ░░███  ░░░   ░░███    ░░███
;;;  ░███  █ ░  █████████████    ██████    ██████   █████     ░███    ░███   ██████   ███████  ██████  ░███  ████  ███████   ░███████
;;;  ░██████   ░░███░░███░░███  ░░░░░███  ███░░███ ███░░      ░██████████   ███░░███ ███░░███ ███░░███ ░███ ░░███ ░░░███░    ░███░░███
;;;  ░███░░█    ░███ ░███ ░███   ███████ ░███ ░░░ ░░█████     ░███░░░░░███ ░███████ ░███ ░███░███ ░███ ░███  ░███   ░███     ░███ ░███
;;;  ░███ ░   █ ░███ ░███ ░███  ███░░███ ░███  ███ ░░░░███    ░███    ░███ ░███░░░  ░███ ░███░███ ░███ ░███  ░███   ░███ ███ ░███ ░███
;;;  ██████████ █████░███ █████░░████████░░██████  ██████     █████   █████░░██████ ░░███████░░██████  █████ █████  ░░█████  ████ █████
;;; ░░░░░░░░░░ ░░░░░ ░░░ ░░░░░  ░░░░░░░░  ░░░░░░  ░░░░░░     ░░░░░   ░░░░░  ░░░░░░   ░░░░░███ ░░░░░░  ░░░░░ ░░░░░    ░░░░░  ░░░░ ░░░░░
;;;                                                                                  ███ ░███
;;;                                                                                 ░░██████
;;;                                                                                  ░░░░░░

;;; Minimal init.el

;;; Contents:
;;;
;;;  - Basic settings
;;;  - Discovery aids
;;;  - Interface enhancements/defaults
;;;  - Tab-bar configuration
;;;  - Theme
;;;  - Optional extras
;;;  - Built-in customization framework

;; Lots of mentions of "Bedrock" in this file. See the README.md why.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Basic settings
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setopt
 user-full-name "Ivan Lazar Miljenovic"

 ;; TODO: not when working.
 user-mail-address "Ivan.Miljenovic@gmail.com"

 require-final-newline t
 select-enable-primary nil
 select-enable-clipboard t
 select-active-regions t

 history-length 1000
 history-delete-duplicates t

 bury-successful-compilation t
 truncate-lines t)

(add-hook 'after-save-hook 'executable-make-buffer-file-executable-if-script-p)

;; Make prompts shorter and easier to answer
(defalias 'yes-or-no-p 'y-or-n-p)

;; Package initialization
(with-eval-after-load 'package
  ;; prevent package.el from writing package-selected-packages
  (advice-add #'package--save-selected-packages :override
              (lambda (&rest _) nil))
  (setq package-selected-packages nil)

  ;; Don't suggest removing packages
  (defun package--removable-packages () nil)

  (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t))

;; If you want to turn off the welcome screen, uncomment this
(setopt inhibit-splash-screen t)

;; Changes default mode for the *scratch* buffer; keep it as is
;; (setopt initial-major-mode 'fundamental-mode)

(setopt display-time-default-load-average nil) ; this information is useless for most

(defun system-type-is-darwin ()
  "Return t if system is darwin-based (macOS)."
  (eq system-type 'darwin))

(defun system-type-is-gnu ()
  "Return t if system is GNU/Linux-based."
  (eq system-type 'gnu/linux))

(defun system-type-is-win ()
  "Return t if system is Windows-based."
  (memq system-type '(windows-nt ms-dos cygwin)))

;; Automatically reread from disk if the underlying file changes
(setopt auto-revert-avoid-polling t) ;; should this be system-type-is-gnu?
;; Some systems don't do file notifications well; see
;; https://todo.sr.ht/~ashton314/emacs-bedrock/11
(setopt auto-revert-interval 5)
(setopt auto-revert-check-vc-info t)
(setopt auto-revert-use-notify (system-type-is-gnu)) ;; Mac as well?
(global-auto-revert-mode)

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

;; But I do want two split windows side-by-side if possible
(add-hook 'window-setup-hook
          (lambda ()
            (when (and (>= (frame-width) 160)        ; Is the screen wide enough?
                       (= (length (window-list)) 1)) ; Ensure it hasn't been split yet
              (split-window-right))))

;; "Fixes" supposedly archaic defaults. But I like them. Leaving here
;; for documentation purposes.
;; (setopt sentence-end-double-space nil)

;; Make right-click do something sensible
(when (display-graphic-p)
  (context-menu-mode))

;; When doing Page-Up/Page-Down, preserve the cursor's position on the screen.
(setq scroll-preserve-screen-position t)

;; Don't litter file system with *~ backup files; put them all inside
;; ~/.emacs.d/backup or wherever
(defun bedrock--backup-file-name (fpath)
  "Return a new file path of a given file path.
If the new path's directories does not exist, create them."
  (let* ((backupRootDir (concat user-emacs-directory "emacs-backup/"))
         (filePath (replace-regexp-in-string "[A-Za-z]:" "" fpath )) ; remove Windows driver letter in path
         (backupFilePath (replace-regexp-in-string "//" "/" (concat backupRootDir filePath "~") )))
    (make-directory (file-name-directory backupFilePath) (file-name-directory backupFilePath))
    backupFilePath))
(setopt
 make-backup-file-name-function 'bedrock--backup-file-name
 backup-by-copying t
 delete-old-versions t)

;; The above creates nested directories in the backup folder. If
;; instead you would like all backup files in a flat structure, albeit
;; with their full paths concatenated into a filename, then you can
;; use the following configuration:
;; (Run `'M-x describe-variable RET backup-directory-alist RET' for more help)
;;
;; (let ((backup-dir (expand-file-name "emacs-backup/" user-emacs-directory)))
;;   (setopt backup-directory-alist `(("." . ,backup-dir))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Discovery aids
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Show the help buffer after startup
;; (add-hook 'after-init-hook 'help-quick)

;; Used to hide minor modes from the mode line.
(use-package delight
  :ensure t
  :demand t
  :delight
  (visual-line-mode)
  (outline-mode)
  (auto-fill-function)
  (flyspell-prog-mode)
  (abbrev-mode)
  (subword-mode)
  (which-key-mode)
  (eldoc-mode))

;; which-key: shows a popup of available keybindings when typing a long key
;; sequence (e.g. C-x ...)
(use-package which-key
  :ensure t
  :delight
  :config
  (which-key-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Interface enhancements/defaults
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; Enable horizontal scrolling
(setopt mouse-wheel-tilt-scroll t)
(setopt mouse-wheel-flip-direction t)

(setopt indent-tabs-mode nil)
(setopt tab-width 2)

;; Misc. UI tweaks
(blink-cursor-mode -1)                                ; Steady cursor
(pixel-scroll-precision-mode)                         ; Smooth scrolling

;; Use common keystrokes by default
;; (cua-mode)
;; No, don't do this.

;; For terminal users, make the mouse more useful

(xterm-mouse-mode 1)

;; Display line numbers in programming mode
(setopt display-line-numbers-width 3)           ; Set a minimum width

;; Modes to highlight the current line with
(let ((hl-line-hooks '(text-mode-hook prog-mode-hook)))
  (mapc (lambda (hook) (add-hook hook 'hl-line-mode)) hl-line-hooks))

;; Timestamp messages in the *Messages* buffer
(advice-add 'message :around
  (lambda (orig-fn &rest args)
    (if args
        (apply orig-fn (concat (format-time-string "[%Y-%m-%d %T %Z] ")
                               (car args))
               (cdr args))
      (apply orig-fn args))))

(use-package crux
  :ensure t
  :bind (("C-c C-r" . crux-sudo-edit)))

(use-package tramp
  :ensure nil
  :defer 30 ;; Only load after Emacs has been idle for 30s
  :custom
  (tramp-default-method "ssh")
  ;; No backups or auto-saves for remote files, especially when using sudo or su
  (tramp-backup-directory-alist nil)
  (tramp-auto-save-directory nil))

(use-package dired
  :ensure nil
  :custom
  (dired-dwim-target t)
  (dired-omit-verbose nil)
  ;;(dired-omit-files-p t)
  ;; toggle `dired-omit-mode' with C-x M-o

  ;; Default is "\\`[.]?#\\|\\`[.][.]?\\'"
  (dired-omit-files "^\\.?#\\|^\\.$\\|_flymake\\.hs$\\|\\.hie$")

  ;; default is -al
  (dired-listing-switches "-alh")
  (wdired-allow-to-change-permissions t)
  (dired-mode . #'dired-omit-mode))

;; Not really required any more as you can just use the
;; 'scratch-buffer' command to re-create it.
(use-package unkillable-scratch
  :ensure t
  :config
  (unkillable-scratch 1))

(use-package eww
  :ensure nil
  :bind
  (:map help-mode-map
        ("o" . eww)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Tab-bar configuration
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Show the tab-bar as soon as tab-bar functions are invoked
(setopt tab-bar-show 1)

;; Add the time to the tab-bar, if visible
(add-to-list 'tab-bar-format 'tab-bar-format-align-right 'append)
(add-to-list 'tab-bar-format 'tab-bar-format-global 'append)
(setopt display-time-format "%a %F %T")
(setopt display-time-interval 1)
(display-time-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Textual helpers
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun my/kill-line--remove-next-indentation (&rest _)
  "If at EOL (but not at BOL) remove leading whitespace on the next line.
This runs before `kill-line` so the following line's indentation is removed
without moving point."
  (when (and (eolp) (not (bolp)) (not (eobp)))
    (save-excursion
      (forward-char 1)
      (delete-horizontal-space))))

(advice-add 'kill-line :before #'my/kill-line--remove-next-indentation)

(use-package delsel
  :ensure nil                 ; built-in
  :custom
  (delete-active-region t)
  :config
  (delete-selection-mode 1))

(use-package align
  :ensure nil                 ; built-in
  :bind
  ("C-x a r" . align-regexp))

;; Highlight trailing whitespace, tabs, and empty lines
(use-package whitespace
  :ensure nil                 ; built-in
  :custom
  (whitespace-style '(face tabs trailing empty))
  :delight
  :config
  (global-whitespace-mode 1))

(use-package auto-highlight-symbol
  :ensure t
  :custom
  (ahs-case-fold-search nil)
  ;; Allow trailing '
  (ahs-include "^[0-9A-Za-z/_.,:;*+=&%|$#@!^?-]+'?$")
  :delight auto-highlight-symbol-mode
  :config
  ;; (add-to-list 'ahs-modes 'haskell-mode)
  (add-to-list 'ahs-modes 'haskell-ts-mode)
  (global-auto-highlight-symbol-mode 1))

(use-package subword
  :ensure nil
  :commands subword-mode
  :delight subword-mode)

;; Nice rectangle operations
;;
;; Can also look at the editkit part of the casual package.
;;
;; TODO: get help buffer to close if we exit rectangle-mark-mode
(use-package speedrect
  :ensure t
  :custom
  (speedrect-mode t))

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
;;;   Optional extras
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; UI/UX enhancements mostly focused on minibuffer and autocompletion interfaces
(load-file (expand-file-name "extras/base.el" user-emacs-directory))

;; Textual manipulation configuration
(load-file (expand-file-name "extras/text.el" user-emacs-directory))

;; Packages for software development
(load-file (expand-file-name "extras/dev.el" user-emacs-directory))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Built-in customization framework
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(setq gc-cons-threshold (or bedrock--initial-gc-threshold 800000))

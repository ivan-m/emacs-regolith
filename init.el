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

;; Lots of mentions of "Bedrock" in this file. See the README.md why.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Basic settings
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setopt
 user-full-name "Ivan Lazar Miljenovic"

 ;; Override in work mode.
 user-mail-address "Ivan.Miljenovic@gmail.com"

 require-final-newline t
 select-enable-primary nil
 select-enable-clipboard t
 select-active-regions nil

 ;; Default is 100
 history-length 1000
 history-delete-duplicates t)

;; Package initialization
(with-eval-after-load 'package
  ;; prevent package.el from writing package-selected-packages
  (advice-add #'package--save-selected-packages :override
              (lambda (&rest _)
                "Don't save which packages are installed"
                nil))

  (setq package-selected-packages nil)

  ;; Don't suggest removing packages
  (advice-add #'package--removable-packages :override
              (lambda (&rest _)
                "Don't try and uninstall packages"
                nil))

  (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t))

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
 ;; TODO: auto-save-file-name-transforms, especially for remote files, to avoid creating auto-save files on remote hosts
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

;; Used to hide minor modes from the mode line.  Used for :delight
;; settings in use-package.
;;
;; Note: since sleek-modeline suppresses minor mode display anyway,
;; these :delight settings have no visible effect while sleek-modeline
;; is active — but they're here for correctness if the modeline ever changes.
(use-package delight
  :ensure t
  :demand t)

(use-package emacs
  :ensure nil
  :delight
  (visual-line-mode)
  (auto-fill-function)
  (abbrev-mode)
  (subword-mode)
  (eldoc-mode))

(use-package outline
  :ensure nil
  :delight outline-mode)

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

(add-hook 'before-save-hook 'delete-trailing-whitespace)

(setopt indent-tabs-mode nil)
(setopt tab-width 2)

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
  :hook
  (dired-mode . dired-omit-mode))

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

;; Nice rectangle operations with documentation.
;;
;; Can also look at the editkit part of the casual package.
(use-package speedrect
  :ensure t
  :custom
  (speedrect-mode t)
  :config
  ;; Close SpeedRect's help buffers when exiting rectangle-mark-mode
  (defun my/speedrect-close-help-on-rectangle-exit ()
    "If the SpeedRect help buffer exists, close it when leaving `rectangle-mark-mode'."
    (when (not rectangle-mark-mode)
      (let ((buf (get-buffer "SpeedRect Command Key Help")))
        (when buf
          ;; If it's visible in windows, use quit-window to remove the window and kill/bury the buffer.
          (let ((wins (get-buffer-window-list buf nil t)))
            (if wins
                (dolist (w wins) (with-selected-window w (quit-window t)))
              ;; Otherwise just kill the buffer
              (kill-buffer buf)))))))
  :hook
  (rectangle-mark-mode-hook . my/speedrect-close-help-on-rectangle-exit))

;; Modify search results en masse
(use-package wgrep
  :ensure t
  :custom
  (wgrep-auto-save-buffer t))

;; Allow "C-x b" to open files that I've visited but are currently
;; closed.
(use-package recentf
  :ensure nil
  :init
  (setopt recentf-max-saved-items 1000)
  ;; Needs to be done before it's started: https://www.emacswiki.org/emacs/RecentFiles#toc12
  (setopt recentf-auto-cleanup 'never)
  :custom
  (recentf-save-file (locate-user-emacs-file "recentf"))
  :config
  ;; Add more files; can't be in :custom because of self-reference.
  (setopt recentf-exclude
          (append recentf-exclude
                  '("^/sudo:.*"
                    "^/docker:.*"
                    "COMMIT_EDITMSG\\'"
                    ".*-autoloads\\.el\\'"
                    "ido\\.last"
                    "^recentf$"
                    "[/\\]\\.elpa/"
                    "\\.git/"
                    "node_modules/"
                    "\\.cache/")))

  (recentf-mode 1)
  (add-hook 'kill-emacs-hook #'recentf-save-list)
  (run-with-idle-timer (* 10 60) t #'recentf-save-list))

(use-package saveplace
  :ensure nil
  :custom
  (save-place-file (locate-user-emacs-file "saveplace"))
  :config
  (save-place-mode 1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Additional configuration
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; UI configuration (plus I suppose technically some UX)
(load-file (expand-file-name "extras/ui.el" user-emacs-directory))

;; UI/UX enhancements mostly focused on minibuffer and autocompletion interfaces
(load-file (expand-file-name "extras/completion.el" user-emacs-directory))

;; Textual manipulation configuration
(load-file (expand-file-name "extras/text.el" user-emacs-directory))

;; Packages for software development
(load-file (expand-file-name "extras/dev.el" user-emacs-directory))

;; Work-specific configuration (if any)
(regolith-load-work-file "init.el")

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

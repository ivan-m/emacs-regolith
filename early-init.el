;; -*- lexical-binding: t; -*-

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

;;; Guardrail

(when (< emacs-major-version 30)
  (error "Emacs Regolith only works with Emacs 30 and newer; you have version %s" emacs-major-version))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Basic settings for quick startup and convenience
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Startup speed, annoyance suppression
(setq bedrock--initial-gc-threshold gc-cons-threshold)
(setq gc-cons-threshold 100000000)
(setq byte-compile-warnings '(not obsolete))
(setq warning-suppress-log-types '((comp) (bytecomp)))
(setq native-comp-async-report-warnings-errors 'silent)

(setq debug-on-error t)

;; Silence stupid startup message
(setq inhibit-startup-echo-area-message (user-login-name))

;; Default frame configuration: full screen, good-looking title bar on macOS
(setq frame-resize-pixelwise t)
(tool-bar-mode -1)                      ; All these tools are in the menu-bar anyway
(setq default-frame-alist '((fullscreen . maximized) ;; initial-frame-alist if only the first frame should be maximized

                            ;; You can turn off scroll bars by uncommenting these lines:
                            ;; (vertical-scroll-bars . nil)
                            ;; (horizontal-scroll-bars . nil)

                            ;; Setting the face in here prevents flashes of
                            ;; color as the theme gets activated
                            (background-color . "#242424")   ; matches bg-main override
                            (foreground-color . "#dedede"))) ; matches fg-main override

;; Needs to be defined before use-package is loaded.
(setq use-package-enable-imenu-support t)

(defconst regolith/work-directory
  (expand-file-name "work" user-emacs-directory)
  "Directory for work-related files.")

(defvar regolith/work-mode
  (file-directory-p regolith/work-directory)
  "Non-nil if I'm in work mode.")

(defun regolith/load-work-file (file)
  "If `regolith/work-mode' is non-nil and FILE exists inside `regolith/work-directory',
load it by calling `load-file'.

FILE is a filename (for example \"early-init.el\")."
  (let ((path (expand-file-name file regolith/work-directory)))
    (when (and regolith/work-mode ;; Do this check in case regolith/work-mode becomes a more complex check.
               (file-exists-p path))
      (load-file path))))

;; Explicit package archives set here so that it can be overridden
;; later in the init process (for example, in work/early-init.el).
(setq package-archives
      '(("gnu"     . "https://elpa.gnu.org/packages/")
        ("nongnu"  . "https://elpa.nongnu.org/nongnu/")   ;; official nonGNU
        ("melpa"   . "https://melpa.org/packages/")))

;; Sample values to use in work/early-init.el to override the default
;; package archives Elpa is blocked but GitHub is not.
;; (setq package-archives
;;       '(("gnu"    . "https://raw.githubusercontent.com/d12frosted/elpa-mirror/master/gnu/")
;;         ("nongnu" . "https://raw.githubusercontent.com/d12frosted/elpa-mirror/master/nongnu/")
;;         ("melpa"  . "https://raw.githubusercontent.com/d12frosted/elpa-mirror/master/melpa/")))

(regolith/load-work-file "early-init.el")

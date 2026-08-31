;;; ░█▀▀░█▄█░█▀█░█▀▀░█▀▀░░░█▀▄░█▀▀░█▀▀░█▀█░█░░░▀█▀░▀█▀░█░█
;;; ░█▀▀░█░█░█▀█░█░░░▀▀█░░░█▀▄░█▀▀░█░█░█░█░█░░░░█░░░█░░█▀█
;;; ░▀▀▀░▀░▀░▀░▀░▀▀▀░▀▀▀░░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░░▀░░▀░▀
;;;
;;; Cleaner interface, focussing on minibuffer and completion.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Basic/inbuilt values
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Save history of minibuffer
(savehist-mode)

(setopt enable-recursive-minibuffers t)                ; Use the minibuffer whilst in the minibuffer

;; For help, see: https://www.masteringemacs.org/article/understanding-minibuffer-completion

(add-to-list 'completion-ignored-extensions ".hi")

(setopt completion-cycle-threshold 1)                  ; TAB cycles candidates
(setopt completions-detailed t)                        ; Show annotations
(setopt tab-always-indent 'complete)                   ; When I hit TAB, try to complete, otherwise, indent

(setopt completion-auto-help 'always)                  ; Open completion always; `lazy' another option
(setopt completions-max-height 20)                     ; This is arbitrary
(setopt completions-format 'one-column)
(setopt completions-group t)
(setopt completion-auto-select 'second-tab)            ; Much more eager
;(setopt completion-auto-select t)                     ; See `C-h v completion-auto-select' for more possible values

(keymap-set minibuffer-mode-map "TAB" 'minibuffer-complete) ; TAB acts more like how it does in the shell

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Motion aids
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; I'm not completely sold on Avy; it looks like over-optimisation to
;; me, but I'm not going to get rid of it just now.
;;
;; https://karthinks.com/software/avy-can-do-anything/ is somewhat
;; motivating that it can be very powerful for bulk edits.

(use-package avy
  :ensure t
  :demand t
  :bind (("C-c j" . avy-goto-line)
         ("s-j"   . avy-goto-char-timer)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Power-ups: Embark and Consult
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Consult: Misc. enhanced commands
;;
;; The consult package has a vast number of functions that you can use
;; as replacements to what Emacs provides by default. Please see the
;; consult documentation for more information and help:
;;
;;     https://github.com/minad/consult
;;
;; In particular, many users may find `consult-line' to be more useful to them
;; than isearch, so binding this to `C-s' might make sense. This is left to the
;; user to configure, however, as isearch and consult-line are not equivalent.
(use-package consult
  :ensure t
  :custom
  ;; Narrowing lets you restrict results to certain groups of candidates
  (consult-narrow-key "<")
  :bind (
         ;; Drop-in replacements
         ("C-x b" . consult-buffer)     ; orig. switch-to-buffer
         ("M-y"   . consult-yank-pop)   ; orig. yank-pop
         ;; Searching
         ("M-s r" . consult-ripgrep)
         ("C-s"   . consult-line)       ; Replace isearch-forwar
         ("M-s L" . consult-line-multi) ; isearch to M-s s
         ("M-s o" . consult-outline)
         ;; Isearch integration
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)   ; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history) ; orig. isearch-edit-string
         ("M-s l" . consult-line)            ; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi)      ; needed by consult-line to detect isearch
         ))

(use-package embark-consult
  :ensure t)

;; Embark: supercharged context-dependent menu; kinda like a
;; super-charged right-click.
(use-package embark
  :ensure t
  :demand t
  :after (avy embark-consult)
  :bind (("C-c a" . embark-act))        ; bind this to an easy key to hit
  :init
  ;; Add the option to run embark when using avy
  (defun bedrock/avy-action-embark (pt)
    (unwind-protect
        (save-excursion
          (goto-char pt)
          (embark-act))
      (select-window
       (cdr (ring-ref avy-ring 0))))
    t)

  ;; After invoking avy-goto-char-timer, hit "." to run embark at the next
  ;; candidate you select
  (setf (alist-get ?. avy-dispatch-alist) 'bedrock/avy-action-embark))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Minibuffer and completion
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Vertico: better vertical completion for minibuffer commands
(use-package vertico
  :ensure t
  :custom
  (vertico-cycle t) ;; Cycle through candidates
  (vertico-resize t)
  :init
  (vertico-mode))

;; Vertico directory extension: makes DEL/Backspace behave like ido (go up dir),
;; provides tidy behaviour and entry for RET on directories.
(use-package vertico-directory
  :ensure nil
  :after vertico
  :custom
  (vertico-directory-tidy t)
  :bind
  ;; matches defaults, shown here for visibility
  (:map vertico-map
        ("M-DEL" . vertico-directory-delete-word)
        ("RET" . vertico-directory-enter)
        ("DEL" . vertico-directory-delete-char)))

;; Multiform: choose different presentation per-command / per-category
(use-package vertico-multiform
  :after vertico
  :ensure nil ;; Shipped with vertico

  :custom

  ;; By-category rules (category -> display function/symbol)
  ;; Common categories: file, buffer, imenu, consult-grep, default, ...
  (vertico-multiform-categories
   '((buffer            flat)            ; ido style, don't take too much space
     (imenu             reverse)         ; imenu -> show above minibuffer
     (file              reverse)
     (consult-grep      buffer)
     (t                 (:not buffer)))) ; fallback; can't just use 'vertical' annoyingly.

  ;; To find what category a command is in, use M-: to evaluate
  ;; (completion-metadata-get (completion-metadata "" minibuffer-completion-table minibuffer-completion-predicate) 'category)

  ;; Per-command overrides (command -> display style)
  ;; Use these if you want fine-grained control for specific commands.
  ;;
  ;; Is this duplicating what's above?
  (vertico-multiform-commands
   '((consult-buffer    flat))) ; category is multi-category
  :config
  (vertico-multiform-mode))

(use-package vertico-mouse
  :ensure nil
  :after vertico
  :config
  (vertico-mouse-mode))

;; Marginalia: annotations for minibuffer
(use-package marginalia
  :ensure t
  :config
  (marginalia-mode))

;; Corfu: Popup completion-at-point
;;
;; Something isn't quite right here: if there's only one completion
;; available, it's auto-inserting it rather than asking me if that's
;; the one I want.
(use-package corfu
  :ensure t
  :custom
  (corfu-auto nil) ;; Auto-completion, don't think I want that
  (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
  (corfu-quit-at-boundary nil)   ;; Never quit at completion boundary
  (corfu-quit-no-match nil)      ;; Never quit, even if there is no match
  (corfu-preview-current nil)    ;; Disable current candidate preview
  ;; (corfu-preselect 'prompt)      ;; Preselect the prompt, defaults to valid
  (corfu-on-exact-match 'show) ;; Show popup even on single completion, especially useful for tempel

  ;; Emacs 30 and newer: Disable Ispell completion function.
  ;; Try `cape-dict' as an alternative.
  (text-mode-ispell-word-completion nil)

  :init
  (global-corfu-mode)
  (corfu-history-mode)
  (corfu-mouse-mode)
  :bind
  (:map corfu-map
        ;; M-g will show location information (e.g. source code) and
        ;; M-h goes back to documentation; would be nice if they could
        ;; toggle.
        ("SPC" . corfu-insert-separator) ;; Normally M-SPC
        ("C-n" . corfu-next)
        ("C-p" . corfu-previous)
        ;; Allows pressing TAB to cycles through candidates once the popup is open
        ;; ("<tab>" . corfu-next)
        ;; ("TAB" . corfu-next)
        ))

;; Part of corfu
(use-package corfu-popupinfo
  :after corfu
  :ensure nil
  :hook (corfu-mode . corfu-popupinfo-mode)
  :custom
  (corfu-popupinfo-delay '(0.25 . 0.1))
  (corfu-popupinfo-hide nil)
  :config
  ;; Make the font slightly larger; doesn't seem to work
  ;; (set-face-attribute \\='corfu-popupinfo nil :height 1.2)
  (corfu-popupinfo-mode))

;; Make corfu popup come up in terminal overlay
(use-package corfu-terminal
  :if (and (not (display-graphic-p))
           (< emacs-major-version 31))
  :ensure t
  :config
  (corfu-terminal-mode))

(use-package transient
  :ensure nil
  :custom
  ;; Prevent Transient from reading or writing to the magic state file
  (transient-values-file nil))

;; Fancy completion-at-point functions; there's too much in the cape package to
;; configure here; dive in when you're comfortable!
(use-package cape
  :ensure t
  :bind*
  ;; All possible completion types; using this to ensure
  (("M-/" . regolith-mantle))

  :custom
  (cape-dict-file
   (cl-find-if #'file-exists-p
               '("/run/current-system/sw/share/dict/words"
                 "~/.nix-profile/share/dict/words"
                 "/usr/share/dict/words"
                 "/usr/dict/words")))

  :init
  ;; Inline mapping of global fallbacks: try files first, then text words, then keywords
  (mapc (lambda (backend)
          (add-to-list 'completion-at-point-functions
                       backend t)) ; <- FORCES interactive popup UI
        '(cape-file
          cape-dabbrev
          cape-keyword))

  :config
  ;; Load transient's macro definitions before evaluating
  ;; transient-define-prefix.
  ;;
  ;; Not using :after because that breaks the auto-loading and
  ;; prevents M-/ from binding correctly.
  (require 'transient)

  ;; Mantle, (n)
  ;;
  ;;   1. A loose garment to be worn over other garments; an
  ;;      enveloping robe; a cloak. Hence, figuratively, a covering
  ;;      or concealing envelope.
  ;;      [1913 Webster]
  ;;
  ;;   <snip>
  ;;
  ;;   7. (Geol.) The highly viscous shell of hot semisolid rock,
  ;;      about 1800 miles thick, lying under the crust of the Earth
  ;;      and above the core. Also, by analogy, a similar shell on
  ;;      any other planet.
  ;;      [PJC]
  ;;
  ;; So regolith-mantle is the cape configuration for regolith.
  ;;
  ;; (I don't have too much time on my hands at all...)
  (transient-define-prefix regolith-mantle ()
    "Mantle: the Cape of a Regolith"
    [["Text & Documents"
      ("d" "Dabbrev"          cape-dabbrev)
      ("f" "File Name"        cape-file)
      ("l" "Line"             cape-line)
      ("w" "Dict / Words"     cape-dict) ;; TODO: ensure we have /usr/share/dict/words
      ("e" "Emoji"            cape-emoji)
      ("a" "Abbrev"           cape-abbrev)
      ("i" "Input History"    cape-history) ;; Mostly for shells
      ("t" "Tempel Templates" tempel-complete)]

     ["Code & Symbols"
      ("s" "Elisp Symbol"         cape-elisp-symbol)
      ("b" "Elisp (Org/MD Block)" cape-elisp-block)
      ("k" "Keyword"              cape-keyword)
      ("h" "SGML/HTML Tag"        cape-sgml)
      ("x" "TeX / LaTeX"          cape-tex)
      ("r" "RFC 1345 Mnemonics"   cape-rfc1345)]]))

;; Pretty icons for corfu
(use-package kind-icon
  :if (display-graphic-p)
  :ensure t
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

;; Orderless: powerful completion style
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion orderless basic))))
  (completion-pcm-leading-wildcard t)
  (read-file-name-completion-ignore-case t))
;; Emacs 31: partial-completion behaves like substring

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Templating
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package tempel
  :ensure t
  :after
  cape
  ;; By default, tempel looks at the file "templates" in
  ;; user-emacs-directory, but you can customize that with the
  ;; tempel-path variable:
  ;; :custom
  ;; (tempel-path (concat user-emacs-directory "custom_template_file"))
  :bind (("M-*" . tempel-insert)
         ("M-+" . tempel-expand)
         :map tempel-map
         ("C-c RET" . tempel-done)
         ("C-<down>" . tempel-next)
         ("C-<up>" . tempel-previous)
         ("M-<down>" . tempel-next)
         ("M-<up>" . tempel-previous))
  :init
  ;; Make a function that adds the tempel expansion function to the
  ;; list of completion-at-point-functions (capf).
  (defun tempel-setup-capf ()
    ;; tempel-complete allows completion/listing of templates,
    ;; tempel-expand just instant replaces.
    (add-hook 'completion-at-point-functions #'tempel-complete -1 'local))

  ;; Put tempel-expand on the list whenever you start programming or
  ;; writing prose.
  (add-hook 'prog-mode-hook 'tempel-setup-capf)
  (add-hook 'text-mode-hook 'tempel-setup-capf))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Misc. editing enhancements
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Modify search results en masse
(use-package wgrep
  :ensure t
  :config
  (setq wgrep-auto-save-buffer t))

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
  :init
  (setq save-place-file (locate-user-emacs-file "saveplace"))
  :config
  (save-place-mode 1))

;;; Emacs Bedrock
;;;
;;; Extra config: Development tools

;;; Usage: Append or require this file from init.el for some software
;;; development-focused packages.
;;;
;;; It is **STRONGLY** recommended that you use the base.el config if you want to
;;; use Eglot. Lots of completion things will work better.
;;;
;;; This will try to use tree-sitter modes for many languages. Please run
;;;
;;;   M-x treesit-install-language-grammar
;;;
;;; Before trying to use a treesit mode.

;;; Contents:
;;;
;;;  - Built-in config for developers
;;;  - Version Control
;;;  - Common file types
;;;  - Eglot, the built-in LSP client for Emacs
;;;  - Templating

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Built-in config for developers
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Don't actually want this installed, just as a nice place to
;; configure these settings.
(use-package treesit
  :ensure nil
  :custom
  (treesit-font-lock-level 4 "Recommended by nix-ts-mode")

  ;; Tell Emacs to prefer the treesitter mode
  ;; You'll want to run the command `M-x treesit-install-language-grammar' before editing.

  ;; (major-mode-remap-alist
  ;;       '((yaml-mode . yaml-ts-mode)
  ;;         (bash-mode . bash-ts-mode)
  ;;         (js2-mode . js-ts-mode)
  ;;         (typescript-mode . typescript-ts-mode)
  ;;         (json-mode . json-ts-mode)
  ;;         (css-mode . css-ts-mode)
  ;;         (python-mode . python-ts-mode)))

  )

(use-package treesit-auto
  :ensure t
  :commands
  global-treesit-auto-mode
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode +1))

;; See also https://karthinks.com/software/even-more-batteries-included-with-emacs/#compare-windows--m-x-compare-windows
(use-package ediff
  :ensure nil
  :custom
  (ediff-split-window-function 'split-window-horizontally)
  (ediff-window-setup-function 'ediff-setup-windows-plain))

(use-package prog-mode
  :ensure nil)
  ;; :hook
  ;; ;; Auto parenthesis matching
  ;; ((prog-mode . electric-pair-mode)))

(use-package rainbow-delimiters
  :ensure t
  :hook
  ((prog-mode . rainbow-delimiters-mode)))

(use-package project
  :ensure nil
  :custom
  ;; If within a git repo with submodules, treat the submodules as
  ;; part of the top-level project.  But once in the submodule, treat
  ;; it as its own project.
  (project-vc-merge-submodules t)

  ;; Optimize file search caching for large monorepos/submodule trees.
  (project-vc-extra-files-cache t)

  ;; Default interactive modeline
  (project-mode-line 'non-remote)

  :config
  ;; Don't know if we need to do this or if the vc backend is smart
  ;; enough.
  ;; (add-to-list 'project-vc-root-markers ".git")

  ;; Define an explicit git-grep variant
  (defun my-project-git-grep ()
    "Force project-find-regexp to use git grep, bypassing ripgrep."
    (interactive)
    (let ((xref-search-program 'grep))
      (call-interactively #'project-find-regexp)))

  :bind-keymap
  ;; I'm used to this keybinding with projectile, so keeping it.
  ;; (Inherits native keys: f, b, g, r)
  ("C-c p" . project-prefix-map)

  :bind
  ;; 6. Map the two different keys into your project-prefix-map
  (:map project-prefix-map
        ;; ("g" . project-find-regexp)      ; Default (Uses fast ripgrep if available)
        ("G" . my-project-git-grep)))    ; Explicit (Forces git grep)

(use-package xref
  :ensure nil
  :custom
  ;; Dynamic Search Engine Selection
  ;; Evaluates at loading phase to select ripgrep or fallback grep (which includes git grep).
  (xref-search-program (if (executable-find "rg") 'ripgrep 'grep))

  ;; Open search results inside the current window layout rather than
  ;; jumping your focus or popping up aggressive side panes.
  ;;
  ;; TODO: check if the original version was fine.
  ;; (xref-show-xrefs-function #'xref-show-definitions-buffer)

  ;; Instantly update the adjacent window with a temporary file preview
  ;; the moment your cursor travels up or down the static result list.
  ;;
  ;; Use n/p to traverse the list, not arrow keys (n/p are per-match,
  ;; arrows are per line).
  (xref-auto-jump-to-first-xref 'show)

  :init
  ;; Fires after the Xref buffer finishes drawing to safely style the frame.
  (add-hook 'xref-after-update-hook
            (lambda ()
              ;; Collapse multiple file headers via 'outline-minor-mode' (Emacs 29+)
              ;; This lets you press TAB on file names to collapse them like an Org file.
              (outline-minor-mode +1)

              ;; Help-quick style reminder bar injected into the top header line
              (setq header-line-format
                    (propertize
                     "  [n/p]: Next/Prev  │  [o]: Preview Match  │  [Enter]: Go to File  │  [r]: Replace  │  [g]: Refresh  │  [q]: Quit  "
                     'face 'info-menu-header))))

  :bind
  ;; Declarative Xref Local Map Overrides
  (:map xref--xref-buffer-mode-map
        ("o" . xref-show-location-at-point)  ; Ergonomic one-key previewing
        ("TAB" . outline-cycle)              ; Overrides dangerous default to always fold text
        ("<tab>" . outline-cycle)))          ; Catch terminal/GUI variants to ensure folding

;; Not sure I like the behaviour of consult-ripgrep, etc. with the
;; live previews, so for now use the native project ones.
;; (use-package consult
;;   :ensure t ;; but should already have it
;;   :after project
;;   :init
;;   ;; 4. ISOLATE PREVIEWS TO THE OTHER WINDOW
;;   ;; This ensures that when consult-ripgrep previews files, it leaves your
;;   ;; original window alone and forces the candidate preview into the adjacent pane.
;;   (add-hook 'consult-preview-allowed-hooks
;;             (lambda ()
;;               (setq-local switch-to-buffer-obey-display-actions t)
;;               (setq-local display-buffer-overriding-action
;;                           '(display-buffer-use-some-window (inhibit-same-window . t)))))

;;   :bind
;;   (:map project-prefix-map
;;         ("f" . project-find-file)
;;         ("b" . consult-project-buffer)

;;         ;; 4. DYNAMIC FALLBACK SEARCH BINDING
;;         ;; Checks if ripgrep (rg) is installed on the system path.
;;         ;; If true, uses consult-ripgrep. If false, falls back to consult-git-grep.
;;         ("g" . (lambda ()
;;                  (interactive)
;;                  (if (executable-find "rg")
;;                      (call-interactively #'consult-ripgrep)
;;                    (call-interactively #'consult-git-grep))))))

(use-package imenu
  :ensure nil
  :custom
  (imenu-auto-rescan t)
  :config
  ;; from http://www.emacswiki.org/cgi-bin/wiki/ImenuMode
  (defun try-to-add-imenu ()
    (condition-case nil (imenu-add-menubar-index) (error nil)))
  :after consult
  :bind (("C-c i" . consult-imenu))
  :hook
  ((prog-mode . try-to-add-imenu)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Version Control
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Consider doing something with
;; https://karthinks.com/software/even-more-batteries-included-with-emacs/#highlight-buffer-changes--m-x-highlight-changes-mode
;; to see what isn't saved.

;; Magit: best Git client to ever exist
(use-package magit
  :ensure t

  :init
  (magit-auto-revert-mode +1)

  :custom
  ;; We should only pick one of global and magit-specific auto revert.
  (magit-auto-revert-mode (not global-auto-revert-mode))
  (auto-revert-buffer-list-filter 'magit-auto-revert-repository-buffer-p)
  (magit-delete-by-moving-to-trash nil)
  (magit-diff-refine-hunk t)
  (magit-save-repository-buffers nil)

  ;; Defaults seem to be from 'magit-module-sections-hook'
  (magit-section-initial-visibility-alist
   '((untracked . show)
     (unstaged . show)
     (staged . show)
     (stashes . show)
     (unpushed . show)
     (unpulled . show)))

  :config
  ;; Safely update specific values without overwriting the rest of the list
  (dolist (val '((magit-fetch "--prune" "--all")
                 (magit-cherry-pick "-x")
                 (magit-push "--follow-tags")))
    (setq transient-values (assq-delete-all (car val) transient-values))
    (push val transient-values))

  :bind (("C-x g" . magit-status)))

(use-package magit
  :if (system-type-is-gnu)

  :preface
  (defun my/magit-refresh-local-status-on-save ()
    "Refresh the `magit-status' buffer when a local file is saved.
This function safely ignores remote files handled via TRAMP to
prevent network latency issues."
    (when (and (fboundp 'magit-after-save-refresh-status)
               (not (file-remote-p (or buffer-file-name default-directory))))
      (magit-after-save-refresh-status)))

  :hook
  (after-save . my/magit-refresh-local-status-on-save))

(use-package git-gutter-fringe
  :ensure t
  :custom
  (git-gutter-fr:side 'right-fringe)
  :delight git-gutter-mode
  :config
  (global-git-gutter-mode 1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Common file types
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package markdown-mode
  :ensure t
  :custom
  ;; This seems to work well enough for previewing the output with markdown-live-preview-mode.
  (markdown-command "pandoc --standalone")
  (markdown-indent-on-enter nil)
  (markdown-italic-underscore t)
  (markdown-use-pandoc-style-yaml-metadata t)
  (markdown-fontify-code-blocks-natively t)
  (markdown-live-preview-delete-export 'delete-on-export)
  (markdown-asymmetric-header t)
  (markdown-header-scaling t)
  (markdown-marginalize-headers nil) ;; Too thick in practice
  (markdown-gfm-additional-languages '("elisp"))
  :config
  ;; Copilot tends to use emacs-lisp instead of elisp for the identifier.
  (add-to-list 'markdown-code-lang-modes '("emacs-lisp" . emacs-lisp-mode))

  ;; Define a rule that lets completion try first if we are typing text
  (defun my/markdown-cycle-allow-completion (orig-fun &rest args)
    "Let `completion-at-point` step in if the cursor is directly next to text."
    (if (and (not (bolp))                        ; Not at the start of a line
             (not (looking-back "^[ \t]*" nil))  ; Not pure indentation whitespace
             (bound-and-true-p corfu-mode))      ; Corfu is active
        ;; Run completion. If it returns nil (no templates/words match), run markdown-cycle
        (unless (completion-at-point)
          (apply orig-fun args))
      ;; Otherwise, pass control straight to native markdown-cycle
      (apply orig-fun args)))

  ;; Apply the advice to intercept markdown-cycle dynamically
  (advice-add 'markdown-cycle :around #'my/markdown-cycle-allow-completion)
  :init
  (defun disable-electric-indent ()
    (electric-indent-local-mode -1))
  :hook
  ((markdown-mode . visual-line-mode)
   (markdown-mode . disable-electric-indent)))

(use-package poly-markdown
  :ensure t
  :delight
  (poly-markdown-mode " Poly")
  ;; Historically used to use ("\\.md\\'" "\\.text\\'"
  ;; "\\.markdown\\'" "[cC]hange\\.?[lL]og?\\'") but in practice I
  ;; don't need them all any more.
  :mode ("\\.md\\'" . poly-markdown-mode))

;; TODO: look at changing this to flymake
;;
;; See this for some ideas:
;; https://magnus.therning.org/2026-01-25-more-on-the-switch-to-eglot.html
(use-package flycheck
  :ensure t
  :custom
  ;; These help with responsiveness
  (flycheck-check-syntax-automatically '(save))
  (flycheck-display-errors-delay 0.3)
  :commands
  flycheck-mode)

(use-package flycheck-color-mode-line
  :ensure t
  :after flycheck-mode
  :hook
  ((flycheck-mode . flycheck-color-mode-line-mode)))

(use-package flyspell
  :ensure t
  :if (system-type-is-gnu)
  :delight
  :custom
  (flyspell-issue-message-flag nil)
  (flyspell-issue-welcome-flag nil)
  :hook
  ((markdown-mode . flyspell-mode))
  ((prog-mode . flyspell-prog-mode))
  :bind
  ;; Forces flyspell to give C-M-i back to the global completion system
  (:map flyspell-mode-map
        ("C-M-i" . nil)
        ([(control meta i)] . nil)))

(use-package org-table
  ;; Use the version that ships with Emacs
  :ensure nil
  :config

  (defun my/markdown-enable-orgtbl ()
    "Enable orgtbl in this buffer and disable orgtbl's C-c C-c here.
The magic orgtbl-ctrl-c-ctrl-c blocks the C-c C-c prefix for
markdown-mode commands, so we need to disable it."
    (turn-on-orgtbl)
    ;; From https://stackoverflow.com/a/26297700
    ;;
    ;; Converts org-mode tables to markdown tables (which org-mode can still deal with).
    (defun cleanup-org-tables ()
      (save-excursion
        (goto-char (point-min))
        (while (search-forward "-+-" nil t) (replace-match "-|-"))))

    (let ((m (make-sparse-keymap)))
      (define-key m (kbd "C-c C-c") nil)
      (setq-local minor-mode-overriding-map-alist
                  (cons (cons 'orgtbl-mode m)
                        (assq-delete-all 'orgtbl-mode minor-mode-overriding-map-alist))))

    (add-hook 'after-save-hook 'cleanup-org-tables  nil 'make-it-local))
  :hook
  ((markdown-mode . my/markdown-enable-orgtbl)))

(use-package pandoc-mode
  :ensure t
  :hook
  ((markdown-mode . pandoc-mode)
   (pandoc-mode . pandoc-load-default-settings)))

(use-package yaml-ts-mode
  :ensure t
  :mode "\\.ya?ml\\'"
  :hook
  ((yaml-mode . (lambda ()
                  (electric-indent-local-mode -1)))))

(use-package nix-ts-mode
  :ensure t
  :mode "\\.nix\\'")

;; Currently not on MELPA.
;; (use-package ivy-nixos-options
;;   :ensure t
;;   :commands ivy-nixos-options)

(use-package haskell-ts-mode
  :ensure t
  :custom
  ;; May be broken
  (haskell-ts-use-indent t)
  (haskell-ts-font-lock-level 4)
  :mode "\\.hs\\'")

;; Enable cabal-mode for .cabal files
(use-package cabal-mode
  :ensure t
  :mode "\\.cabal\\'")

(use-package dhall-mode
  :ensure t
  :mode "\\.dhall\\'")

(use-package pulse
  :ensure nil
  :config
  (defun my/pulse-entire-buffer ()
    "Highlight the current buffer to emphasise it."
    (with-current-buffer (current-buffer)
      (pulse-momentary-highlight-region (point-min) (point-max)))))

(use-package js
  :ensure t
  :custom
  ;; Don't actually write JS code, so not sure if it's good to have
  ;; this hard-coded here... but I want it like this for restclient
  ;; and json.
  (js-indent-level 2))

(use-package restclient
  :ensure t
  :mode
  ("\\.http\\'" . restclient-mode)
  ("\\.rest\\'" . restclient-mode)

  ;; Note: consider overriding 'restclient-content-type-modes' to have
  ;; 'application/JSON' map to 'json-ts-mode' as it supports comments
  ;; but also highlights keys differently from other Strings.
  ;;
  ;; However, it might have a performance impact.

  :config
  (defun my/restclient-mode-hook ()
    "Ensure we have nice indentation of JSON"
    ;; Does this need to require 'js' first?
    (setq-local indent-line-function 'js-indent-line))

  :hook
  ((restclient-mode . rainbow-delimiters-mode)
   (restclient-mode . my/restclient-mode-hook)
   (restclient-response-loaded . my/pulse-entire-buffer)))

(use-package restclient
  :ensure t
  :after
  tempel ;; Already after cape
  :hook
  ;; restclient is derived from fundamental, not prog-mode, so need to
  ;; add this again.
  (restclient-mode . tempel-setup-capf))

(use-package jq-mode
  :ensure t
  :mode
  "\\.jq$")

(use-package restclient-jq
  :ensure t
  :after
  restclient
  :demand t ;; Load as soon as restclient does
  :bind (:map restclient-mode-map
              ("C-c C-j" . restclient-jq-interactive-result))
  :config
  (defun my/restclient-jq-inhibit-read-only (orig-fun &rest args)
    "Wrap restclient-jq to bypass the read-only buffer restriction.
Don't know when this started being a problem, but 'view-mode' seems to
get activated now making it read-only."
    (let ((inhibit-read-only t))
      (apply orig-fun args)))

  (advice-add 'restclient-jq-interactive-result :around #'my/restclient-jq-inhibit-read-only))

;; company-restclient is not amenable to wrapping by
;; cape-company-to-capf, so we create our own completion-at-point
;; function using cape.
;;
;; TODO: content type header values and variable names (latter
;; semi-covered by dabbrev).
(use-package know-your-http-well
  :ensure t
  :config
  (defun mantle-http--get-notes (cand alist)
    "Extract documentation list for CAND from ALIST using case-insensitive match."
    (cadr (assoc-string cand alist t)))

  (defun mantle-http--adjust-case (typed inserted)
    "Adjust INSERTED string to match the case style of TYPED."
    (cond
     ((string-equal typed (upcase typed))
      (upcase inserted))
     ((string-equal typed (capitalize typed))
      (capitalize inserted))
     (t (downcase inserted))))

  (defun mantle-http--make-completion-table (alist typed)
    "Return a completion table for ALIST with candidates formatted to match TYPED casing."
    (let ((cands (mapcar (lambda (key) (mantle-http--adjust-case typed key))
                         (mapcar #'car alist))))
      (lambda (string pred action)
        (let ((completion-ignore-case t))
          (if (eq action 'metadata)
              `(metadata
                (category . http-well)
                (annotation-function
                 . ,(lambda (cand)
                      (when-let ((notes (mantle-http--get-notes cand alist)))
                        (concat " — " (car notes))))))
            (complete-with-action action cands string pred))))))

  (defun mantle-http--make-capf (alist-var kind prefix-re interactive)
    "Return or invoke a Capf for ALIST-VAR with KIND annotation and PREFIX-RE filter."
    (let ((capf (lambda ()
                  (when (or (not prefix-re)
                            (looking-back prefix-re (line-beginning-position)))
                    (let* ((bounds (or (bounds-of-thing-at-point 'symbol)
                                       (cons (point) (point))))
                           (start (car bounds))
                           (end (cdr bounds))
                           (typed (buffer-substring-no-properties start end))
                           (alist (symbol-value alist-var)))
                      (list start end
                            (mantle-http--make-completion-table alist typed)
                            :exclusive 'no
                            :company-kind (lambda (_) kind)
                            :company-doc-buffer
                            (lambda (cand)
                              (when-let ((notes (mantle-http--get-notes cand alist)))
                                (with-current-buffer (get-buffer-create " *mantle-http-doc*")
                                  (erase-buffer)
                                  (insert (string-join notes "\n\n"))
                                  (current-buffer))))))))))
      (if interactive
          (cape-interactive capf)
        (funcall capf))))

  (defun mantle-http-headers-capf (&optional interactive)
    "Capf for HTTP headers."
    (interactive (list t))
    (mantle-http--make-capf 'http-headers 'property "^[a-zA-Z0-9-]*$" interactive))

  (defun mantle-http-methods-capf (&optional interactive)
    "Capf for HTTP methods."
    (interactive (list t))
    (mantle-http--make-capf 'http-methods 'function "^[a-zA-Z]*$" interactive))

  (defun mantle-http-status-capf (&optional interactive)
    "Capf for HTTP status codes."
    (interactive (list t))
    (mantle-http--make-capf 'http-status 'enum-member "^[0-9]*$" interactive))

  ;; Combined super Capf strictly for know-your-http-well
  (defalias 'mantle-http-super-capf
    (cape-capf-super
     #'mantle-http-headers-capf
     #'mantle-http-methods-capf
     #'mantle-http-status-capf))

  (defun mantle-http-setup-completion ()
    "Setup HTTP completion at point for restclient-mode buffers."
    (add-hook 'completion-at-point-functions
              #'mantle-http-super-capf nil t))

  (transient-append-suffix 'regolith-mantle '(-1)
    '["HTTP & Web"
     ("H" "HTTP Headers" mantle-http-headers-capf)
     ("M" "HTTP Methods" mantle-http-methods-capf)
     ("S" "HTTP Status Codes" mantle-http-status-capf)])

  :hook
  (restclient-mode . mantle-http-setup-completion))

;; See also the counsel-jq package; the restclient jq support is
;; probably similar enough I don't need it though.

;; jq-format might be usefil with the reformatter package

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Eglot, the built-in LSP client for Emacs
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Helpful resources:
;;
;;  - https://www.masteringemacs.org/article/seamlessly-merge-multiple-documentation-sources-eldoc

(use-package eglot
  :ensure nil

  ;; Configure hooks to automatically turn-on eglot for selected modes
  ; :hook
  ; (((python-mode ruby-mode elixir-mode) . eglot-ensure))

  :custom
  (eglot-send-changes-idle-time 0.1)
  (eglot-extend-to-xref t)              ; activate Eglot in referenced non-project files
  (eglot-autoshutdown t)                ; automatically shutdown server when last buffer is closed

  :config
  (fset #'jsonrpc--log-event #'ignore)  ; massive perf boost---don't log every event
  ;; Sometimes you need to tell Eglot where to find the language server
  ; (add-to-list 'eglot-server-programs
  ;              '(haskell-mode . ("haskell-language-server-wrapper" "--lsp")))
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Shells/terminals
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package eshell
  :init
  (defun bedrock/setup-eshell ()
    ;; Something funny is going on with how Eshell sets up its keymaps; this is
    ;; a work-around to make C-r bound in the keymap
    (keymap-set eshell-mode-map "C-r" 'consult-history))
  :hook ((eshell-mode . bedrock/setup-eshell)))

;; Eat: Emulate A Terminal
(use-package eat
  :ensure t
  :custom
  (eat-term-name "xterm")
  :config
  (eat-eshell-mode)                     ; use Eat to handle term codes in program output
  (eat-eshell-visual-command-mode))     ; commands like less will be handled by Eat

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   AI
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package copilot
  :ensure t
  :custom
  ;; https://github.com/copilot-emacs/copilot.el/issues/473
  ;; (copilot-chat-model "auto")
  (copilot-indent-offset-warning-disable t)
  (copilot-chat-enable-semantic-search t)

  :init
  (defun my/copilot-tab ()
    "Accept Copilot completion if ghost text is visible; else fallback to indent."
    (interactive)
    (or (copilot-accept-completion)
        (indent-for-tab-command)))

  (defun my/copilot-disable-corfu-auto ()
    "Disable auto Corfu completion in Copilot buffers to prevent overlay collisions."
    (setq-local corfu-auto nil))

  (defun my/copilot-chat-disable-flyspell ()
    "Disable flyspell modes in Copilot chat buffers."
    (when (bound-and-true-p flyspell-mode)
      (flyspell-mode -1))
    (when (and (fboundp 'flyspell-prog-mode)
               (bound-and-true-p flyspell-prog-mode))
      (flyspell-prog-mode -1)))

  :bind
  (:map copilot-completion-map
        ("<tab>" . my/copilot-tab)
        ("TAB" . my/copilot-tab)
        ("C-<tab>" . copilot-accept-completion-by-word)
        ("C-TAB" . copilot-accept-completion-by-word)
        ("C-n" . copilot-next-completion)
        ("C-p" . copilot-previous-completion))
  (:map copilot-mode-map
        ("C-c C-s" . copilot-chat-send-region)
        ("C-c C-f" . copilot-chat-send-file))

  :hook
  (prog-mode . copilot-mode)
  (copilot-mode . my/copilot-disable-corfu-auto)
  (copilot-chat-mode . my/copilot-chat-disable-flyspell)

  :after embark
  :config
  (push 'embark--ignore-target
        (alist-get 'copilot-chat-send-region embark-target-injection-hooks))
  ;; This used to be embark-consult-search-map so we might want to change this
  (keymap-set embark-region-map "c" #'copilot-chat-send-region))
;; Run copilot-install-server if there are issues, but this doesn't use the system-installed one!

;; Configure gptel with use-package, using GitHub Copilot as the model for responses
(use-package gptel
  :ensure nil ;; Don't install
  :if nil ;; Having this here as a snippet for now as a starting
          ;; point, but it appears to be completely wrong.
  :custom
  (gptel-model "github-copilot")
  (gptel-chat-buffer-name "*GPTel Chat*")
  :bind
  (:map gptel-chat-mode-map
        ("C-c C-s" . gptel-chat-send-region)
        ("C-c C-f" . gptel-chat-send-file)))

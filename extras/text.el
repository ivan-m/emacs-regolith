;; -*- lexical-binding: t; -*-

;;; ░█▀▀░█▄█░█▀█░█▀▀░█▀▀░░░█▀▄░█▀▀░█▀▀░█▀█░█░░░▀█▀░▀█▀░█░█
;;; ░█▀▀░█░█░█▀█░█░░░▀▀█░░░█▀▄░█▀▀░█░█░█░█░█░░░░█░░░█░░█▀█
;;; ░▀▀▀░▀░▀░▀░▀░▀▀▀░▀▀▀░░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░░▀░░▀░▀
;;;
;;; Text editing, writing, configuration.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Basic/inbuilt values
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-hook 'text-mode-hook 'turn-on-auto-fill)
(add-hook 'text-mode-hook 'visual-wrap-prefix-mode)
;; Nice line wrapping when working with text
(add-hook 'text-mode-hook 'visual-line-mode)

(defun regolith/unfill (&optional arg start end)
  "Unfill text, making paragraphs single long lines.

With prefix ARG (e.g. C-u) unfill all paragraphs in the buffer.
With an active region, unfill paragraphs in that region (START..END).
Otherwise unfill the paragraph at point (detected robustly)."
  (interactive
   (list current-prefix-arg
         (when (use-region-p) (region-beginning))
         (when (use-region-p) (region-end))))
  (let ((fill-column most-positive-fixnum))
    (cond
     (arg
      ;; Prefix arg: whole buffer
      (fill-individual-paragraphs (point-min) (point-max)))
     ((and start end)
      ;; Active region: fill each paragraph in the region
      (fill-individual-paragraphs start end))
     (t
      ;; No region: determine the paragraph bounds explicitly and fill that region.
      (save-excursion
        (let ((p1 (progn (backward-paragraph) (point)))
              (p2 (progn (forward-paragraph) (point))))
          (if (< p1 p2)
              (fill-region p1 p2)
            (message "No paragraph at point"))))))))

(keymap-set global-map "M-Q" #'regolith/unfill)

(use-package dictionary
  :ensure nil
  :custom
  (dictionary-use-single-buffer t)
  (dictionary-server "dict.org")
  :hook
  ;; https://karthinks.com/software/even-more-batteries-included-with-emacs/#dictionary-on-hover--m-x-dictionary-tooltip-mode
  ;;
  ;; It's slow to actually look words up though.
  (text-mode-hook . dictionary-tooltip-mode))

(defun my/kill-line--remove-next-indentation (&rest _)
  "If at EOL (but not at BOL) remove leading whitespace on the next line.
This runs before `kill-line` so the following line's indentation is removed
without moving point."
  (when (and (eolp) (not (bolp)) (not (eobp)))
    (save-excursion
      (forward-char 1)
      (delete-horizontal-space))))

(advice-add 'kill-line :before #'my/kill-line--remove-next-indentation)

;; Select a region, then type over it to replace it.
(setopt delete-selection-mode t)

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
  :hook
  (prog-mode . whitespace-mode)
  (text-mode . whitespace-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Markdown
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
  (defun regolith/disable-electric-indent ()
    (electric-indent-local-mode -1))
  :hook
  ((markdown-mode . regolith/disable-electric-indent)))

;; This is not actually a major mode: the major-mode will be
;; markdown-mode, but poly-markdown-mode will be active as a minor
;; mode to provide the multi-mode support.
(use-package poly-markdown
  :ensure t
  :delight
  (poly-markdown-mode " Poly")
  ;; Historically used to use ("\\.md\\'" "\\.text\\'"
  ;; "\\.markdown\\'" "[cC]hange\\.?[lL]og?\\'") but in practice I
  ;; don't need them all any more.
  :mode ("\\.md\\'" . poly-markdown-mode))

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Spellchecking
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Keeping this here as a backup for now, whilst trying out jinx.
(use-package flyspell
  :ensure nil
  :if nil ;; (system-type-is-gnu)
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

;; Jinx: Enchanted spell-checking
;;
;; Requires libenchant installed.  Probably want to use a system
;; package for jinx to avoid needing a compiler, etc.
(use-package jinx
  :ensure t
  :if (system-type-is-gnu)
  :hook (((text-mode prog-mode) . jinx-mode))
  :bind (("C-;" . jinx-correct))
  :custom
  (jinx-camel-modes '(prog-mode))
  (jinx-delay 0.01))

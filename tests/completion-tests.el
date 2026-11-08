;;; completion-tests.el --- Completion configuration tests -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(require 'use-package)
(require 'consult)
(require 'orderless)

;; Load only the Orderless configuration, without initializing unrelated packages.
(let ((config (expand-file-name "../extras/completion.el"
                                (file-name-directory (or load-file-name buffer-file-name))))
      form)
  (with-temp-buffer
    (insert-file-contents config)
    (goto-char (point-min))
    (while (and (not form) (not (eobp)))
      (let ((next (condition-case nil (read (current-buffer))
                    (end-of-file nil))))
        (when (and (eq (car-safe next) 'use-package)
                   (eq (cadr next) 'orderless))
          (setq form next))))
    (unless form (error "Orderless configuration not found"))
    (let ((use-package-ensure-function #'ignore))
      (eval form t))))

(defun regolith-test/completions (input table &optional predicate)
  "Return completions for INPUT using TABLE and PREDICATE."
  (let ((result (completion-all-completions input table predicate (length input)))
        candidates)
    (while (consp result)
      (push (consult--tofu-strip (substring-no-properties (car result))) candidates)
      (setq result (cdr result)))
    (nreverse candidates)))

(ert-deftest regolith-consult-line-matches-contiguous-words ()
  (with-temp-buffer
    (insert "copilot package\npackage supports copilot\nc-o-p-i-l-o-t\n")
    (goto-char (point-min))
    (let ((matches
           (catch 'matches
             (cl-letf (((symbol-function 'completing-read)
                        (lambda (_prompt table &optional predicate &rest _)
                          (throw 'matches
                                 (regolith-test/completions "copilot" table predicate)))))
               (consult-line)))))
      (should (member "copilot package" matches))
      (should (member "package supports copilot" matches))
      (should-not (member "c-o-p-i-l-o-t" matches)))))

(ert-deftest regolith-file-completion-keeps-flex-matching ()
  (let ((table (completion-table-with-metadata
                '("README.md" "history" ".dir-locals.el")
                '((category . file)))))
    (should (member "README.md" (regolith-test/completions "r" table)))
    (should (member "history" (regolith-test/completions "r" table)))
    (should (member ".dir-locals.el" (regolith-test/completions "rlo" table)))))

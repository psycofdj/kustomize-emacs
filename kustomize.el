(require 'ido)

(defcustom kustomize-yaml-helper-bin
  "kustomize-yaml-helper"
  "Path to kustomize-yaml-helper binary."
  :group 'kustomize
  :type 'string
  :safe 'stringp)

(defcustom kustomize-generate-command
  "kubectl kustomize"
  "command to generate kustomization from directory"
  :group 'kustomize
  :type 'string
  :safe 'stringp)

;;;###autoload
(defun kustomize-generate()
  )

;;;###autoload
(defun kustomize-get-base ()
  (let* ((origin   (buffer-file-name))
         (dir      (file-name-directory origin))
         (dirs     (split-string dir "/"))
         (result   nil))
    (nbutlast dirs 1)
    (while (and (> (length dirs) 1) (equal nil result))
      (let* ((init-dir  (concat (mapconcat 'identity dirs "/")))
             (init-file (concat init-dir "/base")))
        (if (file-exists-p (concat init-file "/kustomization.yaml"))
            (setq result init-file))
        (nbutlast dirs 1)
        ))
    result
    )
  )


;;;###autoload
(defun kustomize-get-root ()
  (let* ((origin   (buffer-file-name))
         (dir      (file-name-directory origin))
         (dirs     (split-string dir "/"))
         (result   nil))
    (nbutlast dirs 1)
    (while (and (> (length dirs) 1) (equal nil result))
      (let* ((init-dir  (concat (mapconcat 'identity dirs "/")))
             (init-file (concat init-dir "/kustomization.yaml")))
        (if (file-exists-p init-file)
            (setq result init-file))
        (nbutlast dirs 1)
        ))
    result
    )
  )

;;;###autoload
(defun kustomize-open-overlay  ()
  "switch from one overlay to another."
  (interactive)
  (let* ((data (kustomize-get-overlays-hash))
         (table (pop data))
         (hash  (pop data)))
    (find-file (gethash (ido-completing-read "overlays: " table) hash)))
  )


;;;###autoload
(defun kustomize-get-overlays-hash ()
  (let* ((origin   (buffer-file-name))
         (base     (kustomize-get-base))
         (parent   (file-name-directory base))
         (files    (directory-files-recursively parent ".*kustomization.yaml"))
         ;; sort files in order to get current buffer as last element in suggestions
         (sfiles   (sort files (lambda (v1 v2) (string= v1 origin))))
         (hash     (make-hash-table :test 'equal))
         (results  '()))
    (while (> (length sfiles) 0)
      (let* ((item (car sfiles))
             (part (substring item (length parent)))
             (overlay (substring part 0 -19)))
        (push overlay results)
        (puthash overlay item hash)
        (setq sfiles (cdr sfiles))))
    (list results hash)
    )
  )


;;;###autoload
(defun kustomize-patch-at-point()
  (interactive)
  (let* ((path (kustomize-get-patch-at-point)))
    (kill-new path)
    (message "%s" (kustomize-get-patch-at-point)))
  )

;;;###autoload
(defun kustomize-get-patch-at-point(&optional pline pcol)
  (let ((result "???")
        (line (if pline pline (number-to-string (+ 0 (line-number-at-pos)))))
        (col  (if pcol  pcol  (number-to-string (+ 1 (current-column)))))
        (outbuf (get-buffer-create "*kustomize-result*")))

    (when (= 0 (call-process-region
                (point-min) (point-max) kustomize-yaml-helper-bin
                nil outbuf nil "--stdin" (buffer-file-name)
                "--line" line "--col" col "--action" "patch-path"))
      (with-current-buffer outbuf
        (setq result (replace-regexp-in-string "\n+" "" (buffer-string)))
        ))
    (kill-buffer outbuf)
    result
    )
  )


;;;###autoload
(defun kustomize-resolve-at-point(&optional pline pcol)
  (let ((result "???")
        (line (if pline pline (number-to-string (+ 0 (line-number-at-pos)))))
        (col  (if pcol  pcol  (number-to-string (+ 1 (current-column)))))
        (outbuf (get-buffer-create "*kustomize-result*")))

    (when (= 0 (call-process-region
                (point-min) (point-max) kustomize-yaml-helper-bin
                nil outbuf nil "--stdin" (buffer-file-name)
                "--line" line "--col" col "--action" "resolve"))
      (with-current-buffer outbuf
        (setq result (replace-regexp-in-string "\n+" "" (buffer-string)))
        ))
    (kill-buffer outbuf)
    result
    )
  )

;;;###autoload
(defun kustomize-open-file(target &optional other-window)
  (if (file-exists-p target)
      (if other-window
          (find-file-other-window target)
        (find-file target))
    (message "file not found: %s" target))
  )

;;;###autoload
(defun kustomize-open-at-point(&optional other-window)
  (interactive)
  (let* ((value (kustomize-resolve-at-point))
         (subfile (concat (file-name-as-directory value) "kustomization.yaml")))
    (kustomize-open-file
     (if (and (file-directory-p value) (file-exists-p subfile))
         subfile
       value)
     other-window))
  )

;;;###autoload
(defun kustomize-open-at-point-other-window()
  (interactive)
  (kustomize-open-at-point t)
  )

;;;###autoload
(defun kustomize-which-func()
  (add-hook 'which-func-functions 'kustomize-get-patch-at-point t t)
  )

;;;###autoload
(defun kustomize-in-kustomize-file()
  (save-excursion
    (save-match-data
      (goto-char (point-min))
      (search-forward "kind:" nil t)))
  )


;;;###autoload
(defun kustomize-in-dir-strcture()
  (kustomize-get-base)
  )

;; --------------------------------------------------------------------------- ;

;;;###autoload
(put 'kustomize-yaml-helper-bin 'safe-local-variable 'stringp)

(provide 'kustomize)

;; Local Variables:
;; ispell-local-dictionary: "american"
;; End:

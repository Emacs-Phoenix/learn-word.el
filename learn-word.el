(require 'request)

(setq learn-word-server-url "http://localhost:7777")

(defvar say-sound t)

(setq current-word nil)

(setq has-meaning nil)

(defun learn-word-buffer ()
  (get-buffer-create "*learn-word*"))

(defun get-word-to-learn()
  (interactive)
  (with-current-buffer (learn-word-buffer)
    (request
     (concat learn-word-server-url "/word")
     :type "GET"
     :parser 'json-read
     :success (function* (lambda (&key data &allow-other-keys)
                           (let ((word (assoc-default 'word data)))
                             (setq current-word word)
                             (show-word word))
                           )))))

(defun play-sound (word-map)
  (if (equal system-type 'darwin)
      (start-process "say-word" nil "say" (assoc-default 'word word-map))))

(defun show-word (word-map)
  (with-current-buffer (learn-word-buffer)
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert (propertize "▋▋▋▋▋▋▋▋▋▋▋▋▋▋▋▋▋▋\n▋▋▋ LEARN WORD ▋▋▋\n▋▋▋▋▋▋▋▋▋▋▋▋▋▋▋▋▋▋" 'face 'message-header-newsgroups))
      (insert "\n\n")
      (insert (propertize "Word: " 'face 'message-header-name)
              (propertize (assoc-default 'word word-map) 'face 'message-header-subject))
      (insert "\n")
      (insert (propertize "pronunciations: " 'face 'message-header-name)
              (propertize (assoc-default 'pronunciations word-map) 'face 'message-header-subject))
      (play-sound word-map)
      (setq has-meaning nil)
      )))

(defun show-mean ()
  (interactive)
  (with-current-buffer (learn-word-buffer)
    (unless has-meaning
      (let ((inhibit-read-only t))
        (goto-char (point-max))
        (insert "\n")
        (insert (propertize "definition: " 'face 'message-header-name)
                (propertize (assoc-default 'definition current-word) 'face 'message-header-subject))
        (move-beginning-of-line 1)
        (setq has-meaning t)))))

(defun message-help ()
  (interactive)
  (message (concat (propertize "s: " 'face 'message-header-name)
                   (propertize "skip-this-word  " 'face 'message-header-subject))))

(defun say-word ()
  (interactive)
  (if current-word
      (play-sound current-word)))

(defvar learn-word-mode-map
  (let ((map (make-sparse-keymap)))
    (prog1 map
      (suppress-keymap map)
      (define-key map "q" 'quit-window)
      (define-key map "h" 'message-help)
      (define-key map "r" 'remember-next-word)
      (define-key map "s" 'show-mean)
      (define-key map "o" 'say-word))))

(defun learn-word-mode ()
  (interactive)
  (kill-all-local-variables)
  (use-local-map learn-word-mode-map)
  (setq major-mode 'learn-word-mode
        mode-name "learn-word-mode"
        truncate-lines nil
        buffer-read-only t)
  (toggle-truncate-lines nil)
  (buffer-disable-undo)
  (hl-line-mode)
  (run-hooks 'learn-word-mode-hook))

;;;###autoload
(defun learn-word ()
  (interactive)
  (switch-to-buffer (learn-word-buffer))
  (unless (eq major-mode 'learn-word-mode)
    (progn
      (message "learn word")
      (learn-word-mode)
      ))
  (get-word-to-learn))


;;;###autoload
(defun add-word-to-learn (word)
  (interactive (list (read-shell-command
                      "Please input the word you want to learn: ")))

  (request
   (concat learn-word-server-url "/word")
   :type "POST"
   :data  `(("word" . ,word))
   :parser 'json-read
   :success (function* (lambda (&key data &allow-other-keys)
                         (message (assoc-default 'message data))
                         ))))

(defun remember-next-word ()
  (interactive)
  (let ((word (assoc-default 'word current-word)))
    (request
     (concat learn-word-server-url "/word")
     :type "PUT"
     :data  `(("word" . ,word))
     :parser 'json-read
     :success (function* (lambda (&key data &allow-other-keys)
                           (message (assoc-default 'message data))
                           )))))

(provide 'learn-word)

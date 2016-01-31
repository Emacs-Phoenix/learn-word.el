(require 'request)

(setq learn-word-server-url "http://localhost:7777")

(defun get-word-to-learn()
  (interactive)
  (request
   (concat learn-word-server-url "/word")
   :type "GET"
   :parser 'json-read
   :success (function* (lambda (&key data &allow-other-keys)
                         (show-word (assoc-default 'word data))))))

(defun show-word (word-map)
  (message (assoc-default 'word word-map)))


(provide 'learn-word)

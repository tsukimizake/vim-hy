(import jedhy.api)
(import socket)
(import sys)
(import time)
(setv jed jedhy.api.API)
(defmacro --- []`()) ;; dummy macro to init --macros-- variable

(setv port (int (get sys.argv (- (len sys.argv) 1))))

;; LOADFILE filename
;;; load file contents to current process
;; COMPLETE prefix
;;; return list of candidates
(with [sock (socket.socket socket.AF-INET socket.SOCK-STREAM) ]
  (.bind sock (, "localhost" port))
  (.listen sock 1)
  (setv [conn addr] (.accept sock))
  (.close sock)
  (with [conn]
    (while [True]
      (setv text ((. (conn.recv 1024) decode)))
      (cond
        ;; load file should be evaluated on top level
        [ (.startswith text "EVALCODE ") 
              (do (-> 
                (get (text.split) (slice 1))
                (.join " ") 
                (read-str)
                (eval))
                (jed.set-namespace :self jed :locals- (locals) :macros- --macros--))]
        [(.startswith text "COMPLETE ")
          (do
            (jed.set-namespace :self jed :locals- (locals) :macros- --macros--)
              (print text)
             ( ->> 
              (get  (text.split) (slice 1 2))
              (.join " ")
              (print))
            (->> 
              (get  (text.split) (slice 1 2))
              (.join " ")
              (jed.complete jed)
              (str)
              ((fn [x] ( bytes x "utf8")))
              (conn.send)
              )
              )]
        [ (.startswith "KILL ")
          (.shutdown conn)
          (.close conn)
          (sys.exit 0)
          ]
        [True
          (do 
            (conn.send (bytes (+ "unknown command: " text))))
          ]
          ))))

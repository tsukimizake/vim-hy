;; add 'jedhyserv-' prefix to filter candidates from serv.hy
(import [jedhy [api :as jedhyserv-jedhy-api]])
(import [socket :as jedhyserv-socket])
(import [sys :as jedhyserv-sys])
(import [time :as jedhyserv-time])
(import [os :as jedhyserv-os])
(setv jedhyserv-jed jedhyserv-jedhy-api.API)
(defmacro jedhyserv-dummymacro []`()) ;; dummy macro to init --macros-- variable

(setv jedhyserv-port (int (get jedhyserv-sys.argv (- (len jedhyserv-sys.argv) 1))))

(jedhyserv-jed.set-namespace :self jedhyserv-jed :locals- (locals) :macros- --macros--)

;; CHDIR path
;;; call chdir for finding imports on EVALCODE
;; EVALCODE code
;;; set symbols available in the code to jedhy environment
;; COMPLETE prefix
;;; return list of candidates
(with [jedhyserv-sock (jedhyserv-socket.socket jedhyserv-socket.AF-INET jedhyserv-socket.SOCK-STREAM) ]
  (.bind jedhyserv-sock (, "localhost" jedhyserv-port))
  (.listen jedhyserv-sock 1)
  (setv [jedhyserv-conn jedhyserv-addr] (.accept jedhyserv-sock))
  (.close jedhyserv-sock)
  (with [jedhyserv-conn]
    (while [True]
      (setv jedhyserv-text ((. (jedhyserv-conn.recv 65536) decode)))
      (print jedhyserv-text)
      (cond
        ;; load file should be evaluated on top level
        [ (.startswith jedhyserv-text "CHDIR ")
          (->>
            (get jedhyserv-text (slice (len "CHDIR ") None))
            (jedhyserv-os.chdir))
          ]
        [(.startswith jedhyserv-text "EVALCODE ") 
            (do (try
                (->>
                  (get jedhyserv-text (slice (len "EVALCODE ") None))
                  (read-str)
                  (eval)
                  )
                  (jedhyserv-conn.send b"evalcode done")
                  (jedhyserv-jed.set-namespace :self jedhyserv-jed :locals- (locals) :macros- --macros--)
                  ;;(print (locals))
                  ;;(print --macros--)
                  (except [e Exception] 
                    (jedhyserv-conn.send (bytes (+ "jedhyserver error: " (str e)) "utf8")))
                  )
                )]
        [(.startswith jedhyserv-text "COMPLETE ")
          (do
            (->> 
              (get  (jedhyserv-text.split) (slice 1 2))
              (.join " ")
              (jedhyserv-jed.complete jedhyserv-jed)
              (str)
              ((fn [x] ( bytes x "utf8")))
              (jedhyserv-conn.send)
              )
              )]
        [(.startswith jedhyserv-text "KILL ")
          (.shutdown jedhyserv-conn jedhyserv-socket.SHUT_RDWR)
          (jedhyserv-sys.exit 0)
          ]
        [(.startswith jedhyserv-text "PING ")
          (jedhyserv-conn.send b"PONG ")
          ]
        [True
          (do 
            (jedhyserv-conn.send (bytes (+ "unknown command: " jedhyserv-text) "utf8")))
          ]
          ))))


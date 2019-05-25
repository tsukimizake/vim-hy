(import vim)
(import subprocess)
(import time)
(import os)
(import re)
(import socket)
(require [util[*]])
(setv sock None)
(setv proc None)

(defn find-imports [filepath]
  (setv str (->
    (open filepath "r")
    (.read)))
  (re.findall r"\(import.*?\)" str re.S))


;; (transform-cands-to-vim-style "('hy', 'hey', 'hoy')") ; => "[ hy, hey, hoy, ]"
;; TODO: filter unnecessary candidates from serv.hy implementation
(defn transform-cands-to-vim-style [s]
  (import ast)
  (print s)
  (setv lst (->>
  s
  ((app1 .decode "utf-8"))
  (ast.literal-eval)
  (list)
  ))
  (print lst)
  (setv res "[ ")
  (for [s lst]
    (when (not (.startswith s "jedhyserv-"))
    (setv res (+ res "'" s "', ")))
  )
  (setv res (+ res "]"))
  res)

(defn complete [text]
  (sock.sendall (bytes (+ "COMPLETE " text "\n") "utf8"))
  (setv cands
    (transform-cands-to-vim-style (sock.recv 65536))) 
  (vim.command (+ "let result = " cands)))

(defn eval-code [code]
  (->>
    code
    ((app2 + "EVALCODE (do " ")\n"))
    ((app1 bytes "utf8"))
    (sock.sendall)
    )
    (print (sock.recv 65536))
    )

(defn load-file [file]
  (->>
    file
    (open)
    (.read)
    (eval-code)
    ))

(defn kill-server []
  (global sock)

  (if (is not None sock)
    (do
      (print "kill sock")

      (sock.sendall b"KILL ")
      (.shutdown sock)
      (.close sock)
      (setv sock None)))
  (global proc)
  (if (and (is not None proc) (is None (.poll proc))) (do (print "kill proc") (.terminate proc)))
  )

(defn server-alive? []
  (is not None sock))

(defn init-server-maybe [serverpath port]
  (when (not (server-alive?))
    (init-server serverpath port)
  ))

(defn init-server[serverpath port]
  (global proc)
  (print serverpath)
  (print port)
  
  
  (setv proc (subprocess.Popen ["hy" serverpath port] )) ;; on debugging serv.hy, maybe you should comment out this line and run server by `hy serv.hy {PORT} on your terminal in order to see serv.hy's stdout
  (global sock)
  (setv sock (socket.socket socket.AF-INET socket.SOCK-STREAM))
  (time.sleep 0.5)
  (sock.connect (, "localhost" (int  port)))
  (print (+"jedhyserver started at " port)))

(print "jedhyclient loaded")

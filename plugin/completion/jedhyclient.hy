(import subprocess)
(import time)
(import os)
(import re)
(import socket)
(require [util[*]])
(setv sock None)
(setv proc None)

(try
  (import vim)
  (defn send-to-vim-maybe[s] (vim.command s))
  (except [e Exception]
    (defn send-to-vim-maybe[s] (print s))))

(defn find-imports [filepath]
  (setv str (->
    (open filepath "r")
    (.read)))
  (re.findall r"\(import.*?\)" str re.S))

;; (transform-cands-to-vim-style "('hy', 'hey', 'hoy')") ; => "[ hy, hey, hoy, ]"
(defn transform-cands-to-vim-style [s]
  (import ast)
  (setv lst (->>
  s
  ((app1 .decode "utf-8"))
  (ast.literal-eval)
  (list)
  ))
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
  (setv res (+ "let result = " cands))
  (send-to-vim-maybe res))

(defn change-dir [path]
  (sock.sendall (bytes (+ "CHDIR " path) "utf8"))
  )

(defn eval-code [code]
  (->>
    code
    ((app2 + "EVALCODE (do " "\n)\n"))
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
  (print sock)
  (when (server-alive?)
    (try
      (print "kill sock")
      (sock.sendall b"KILL ")
      (setv sock None)
      (setv proc None)
      (except [e BrokenPipeError]
      (print "server killed"))
      (except [e Exception]
      (print "error on kill-server:" e))
      )))

(defn server-alive? []
  (when (is None sock)
    (return False))
    (try
      (sock.send b"PING ")
      (sock.recv 100)
      (except [e Exception]
      (print e)
      (return False))
      )
    (return True)
    )

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
  (for [i (range 0 10)]
  (time.sleep 0.1)
  (try
    (sock.connect (, "localhost" (int port)))
    (break)
    (except [e Exception]
      (print e)
      (return))))
  (print (+"jedhyserver running at " port)))


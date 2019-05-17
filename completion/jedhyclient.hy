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
  (setv lst (->>
  s
  ((app1 .decode "utf-8"))
  (ast.literal-eval)
  (list)
  ))
  (setv res "[ ")
  (for [s lst]
    (setv res (+ res "'" s "', "))
  )
  (setv res (+ res "]"))
  res)

(defn complete [text]
  (sock.sendall (bytes (+ "COMPLETE " text "\n") "utf8"))
  (time.sleep 0.1)
  (setv cands
    (transform-cands-to-vim-style (sock.recv 16384))) 
  (vim.command (+ "let result = " cands)))

(defn eval-code [code]
  (->>
    code
    ((app3 + "EVALCODE (do " ")"))
    ((app1 bytes "utf8"))
    (sock.sendall)
    ))

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

(defn --init--[serverpath port]
  (global proc)
  (print serverpath)
  (print port) 
  (setv proc (subprocess.Popen ["hy" serverpath port] ))
  (global sock)
  (setv sock (socket.socket socket.AF-INET socket.SOCK-STREAM))
  (time.sleep 0.4)
  (sock.connect (, "localhost" (int  port)))
  (print (+"jedhyserver started at " port)))

(print "jedhyclient loaded")

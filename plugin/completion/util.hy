;; utility macros for threading macro
(defmacro/g! app0[&rest xs] `(fn [g!a] (g!a ~@xs)))
(defmacro/g! app1[f &rest xs] `(fn [g!a] (~f g!a ~@xs)))
(defmacro/g! app2[f p &rest xs] `(fn [g!a] (~f ~p g!a ~@xs)))
(defmacro/g! app3[f p q  &rest xs] `(fn [g!a] (~f ~p ~q g!a ~@xs)))
(defmacro/g! app4[f p q r &rest xs] `(fn [g!a] (~f ~p ~q ~r g!a ~@xs)))
;;; usage
;;(->
;;  1
;;  ((app1 - 3)) ; -2
;;  ((app2 - 9)) ; 11
;;  (print) ; => 11
;;  )

(defmacro/g! .-[f &rest xs] `(fn [g!ob] ((. g!ob ~f) ~@xs)))
;;; usage
;;(defclass cls[]
;;  (defn f[self]
;;  (print "f")
;;    (return self) 
;;  )
;;  (defn g[self arg]
;;    (print (+ "g " arg))
;;    (return self)
;;  )
;;  )
;;
;;(-> 
;;  (cls)
;;  ((.- f)) ; f
;;  ((.- g "hoge")) ; g hoge
;;  ) ; => <cls object ...>



(defmacro toB [str] `(bytes ~str "utf8"))
(defmacro/g! app0[&rest xs] `(fn [g!a] (g!a ~@xs)))
(defmacro/g! app1[f &rest xs] `(fn [g!a] (~f g!a ~@xs)))
(defmacro/g! app2[f p &rest xs] `(fn [g!a] (~f ~p g!a ~@xs)))
(defmacro/g! app3[f p q  &rest xs] `(fn [g!a] (~f ~p ~q g!a ~@xs)))
(defmacro/g! app4[f p q r &rest xs] `(fn [g!a] (~f ~p ~q ~r g!a ~@xs)))

(defmacro/g! .-[f &rest xs] `(fn [g!ob] ((. g!ob ~f) ~@xs)))


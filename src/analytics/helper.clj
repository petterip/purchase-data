(ns analytics.helper
  (:require [clojure.data.csv :as csv])
  (:require [clojure.java.io :as io])
  (:require [clj-time.core :as t])
  (:require [clj-time.format :as f])
  (:require [clj-time.local :as l])
  (:require [aerial.fs :as a])
  )

(defn not-nil [x]
  (if (nil? x)
    {}
    x))

(defn to-number [str]
  (if (or (nil? str) (= "" str))
    0
    (if (number? str)
      str
      (read-string str))))

(defn now-str [file]
  (str (f/unparse (f/formatter-local "yyyy-MM-dd-HHmm") (l/local-now) ) "-" file))

(defn parse [time]
  (let [input-format (f/formatter "dd.MM.yyyy")
        output-format (f/formatter "yyyy-MM-dd")]
    (try (let [d (f/parse input-format time)]
           (f/unparse output-format d)
           )
      (catch Exception e)
      )
    )
  )

(defn parse-fi [time]
  (let [input-format (f/formatter "yyyy-MM-dd")
        output-format (f/formatter "dd.MM.yyyy")]
    (try (let [d (f/parse input-format time)]
           (f/unparse output-format d)
           )
      (catch Exception e)
      )
    )
  )

(defn time? [t] (not (nil? (parse t))))

(defn comma [s] (clojure.string/replace s \, \.))

(defmacro swallow-exceptions [& body]
    (try ~@body (catch Exception e#)))

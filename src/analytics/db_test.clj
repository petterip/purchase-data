(ns analytics.db-test
  (:require [clojure.java.jdbc :refer :all])
  (:require [clojure.data.csv :as csv])
  (:require [clojure.java.io :as io])
  (:require [clj-time.core :as t])
  (:require [clj-time.format :as f])
  (:require [clj-time.local :as l])
  (:require [analytics.helper :refer :all])
  (:require [clj-http.client :as client])
  )

;(import TestApp TestApp)

(def testdata
  {:date "2011-9-12",
   :store "http://example.com",
   :class "SQLite Example",
   :category "Example using SQLite with Clojure"
   })

(def db
  {:classname   "org.sqlite.JDBC"
   :subprotocol "sqlite"
   :subname     "analytics_dev.db"
   })

(defn create-db []
  (do
    (try (db-do-commands db
                       (drop-table-ddl :purchases))
      (catch Exception e))
    (try (db-do-commands db
                       (create-table-ddl :purchases
                                         [:date :text]
                                         [:time :text]
                                         [:store :text]
                                         [:class :text]
                                         [:category :text]
                                         [:price :number]))
       (catch Exception e (println e)))))

;(create-db)

; 2
(defn db-store-csv [email csv-file]
  (with-open [in-file (io/reader csv-file :encoding "ISO-8859-1")]
    (doall
      (let [res (csv/read-csv in-file :separator \;)]
        (for [line res
          :let [d   (get line 0)     ;; date
                t   (get line 1)     ;; time
                s   (get line 2)     ;; store
                cl  (get line 3)     ;; product class
                cat (get line 4)     ;; category
                p   (get line 5)]    ;; price
          :when (time? d)]
          (insert! db :purchases
                   {:email email,
                    :date (parse d),
                    :time t,
                    :store s,
                    :class cl,
                    :category cat,
                    :price (comma p)
                    :timestamp (java.util.Date.)})
            )))))

; (println (parse d) t "-" s cl cat (comma p)
; 3
;(with-open [in-file (io/reader "heikki_mac.csv")]
;  (doall
;    (csv/read-csv in-file)))

(comment
(insert! db :purchases testdata)

(def output
  (query db "select * from purchases"))

(nth (take 1 output) 0)
(vals (first (take 1 output)))
(apply vals (take 1 output))
(vals (first (take 3 output)))
(dorun (map println (take 3 output)))
(println (take 3 output))
(keys (first output))
(println (vals (take 1 output)))
(println (apply str output))
(println (first output))
(apply println (interpose "\n" (map vals (take 3 output))))

;(def output (query db "select * from purchases"))
;(apply println (interpose "\n" (map vals (take 3 output))))
(l/local-now)
(f/unparse (f/formatter-local "yyyy-MM-dd-HHmm") (l/local-now) )

(now-str "saa")

(.endsWith "sad" "d")

(client/post "http://site.com/api"
  {:basic-auth ["user" "pass"]
   :body "{\"json\": \"input\"}"
   :headers {"X-Api-Version" "2"}
   :content-type :json
   :socket-timeout 1000  ;; in milliseconds
   :conn-timeout 1000    ;; in milliseconds
   :accept :json})

)

;(println (seq (.getURLs (java.lang.ClassLoader/getSystemClassLoader))))

;(def args (make-array String 1))
; specify single command line argument for method main(String[]args)
;(aset args 0 "my-file")

;(TestApp/main args)


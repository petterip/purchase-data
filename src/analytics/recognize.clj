(ns analytics.recognize
  (:require [clojure.data.csv :as csv])
  (:require [clojure.java.io :as io])
  (:require [clj-time.core :as t])
  (:require [clj-time.format :as f])
  (:require [clj-time.local :as l])
  (:require [aerial.fs :as a])
  (:require [clojure.data.json :as json])
  (:require [cheshire.core :refer :all])
  (:require [clj-fuzzy.metrics :as ff])
  (:require [analytics.db.core :as db])
  (:require [analytics.helper :as h])
  )

(import TestApp TestApp)

(def args (make-array String 4))
(def ignore-strings "YHTEENS|AVOINNA|Bonukseen|Bonuksen|kirjattu|KORTTITAPAHTUMA|Kortti|Autentisointi|Viite:|Veloitus|###|Tap. nro|Yritys/ala|Veroton|Verollinen|MAKSAESSASI|SAAT MEILT|Osuuskauppa")

;; Item is relevant (ie. real product), if its name is longer than 4 characters and the name does not match any words in the ignore-list
(defn relevant? [item]
  (and (not (nil? item)) (> (count item) 4) (nil? (re-matches (re-pattern (str "(?i).*(" ignore-strings ").*")) item))))

(defn call-ocrsdk [image-file]
  ; specify single command line argument for method main(String[]args)
  ; recognize 30.9.jpg results_30.9_tw.txt --lang=Finnish
  (let [text-file (a/replace-type image-file ".txt")]
    (aset args 0 "recognize")
    (aset args 1 (str image-file))
    (aset args 2 (str text-file))
    (aset args 3 "--lang=Finnish")
    (println "Starting... " (into [] args))
    (TestApp/main args)
    (if (.exists (io/file text-file))
      text-file
      nil
      )
    )
  )

;(call-ocrsdk "/a/b/c/30.9.jpg")
;; JSON file containing all the products
(def products-json (parse-stream (clojure.java.io/reader "all_prods.json") true))
;; JSON file containing all stores
(def stores-json (parse-stream (clojure.java.io/reader "stores.json") true))
;; JSON file for matching purchase report categories with those provided by Foodie
(def categories-json (parse-stream (clojure.java.io/reader "match_categories.json") true))

;(:KAHVIT categories-json)
;(second (first categories-json))
(first (filter (fn [x] (= (:foodiecat1 x) "JUOMAT")) categories-json))

(take 1 categories-json)
(defn get-category [foodiecat1 foodiecat2]
  (let [matches (filter (fn [x]
                          (and (= (:foodiecat1 x) foodiecat1)
                               (or (= (:foodiecat2 x) "*")
                                   (= (:foodiecat2 x) foodiecat2)))) categories-json)
        first-match (first matches)]
    (if (nil? first-match)
      nil
      (:category first-match)
      )
    )
  )

(get-category "PAKASTEET" "LEIPÄ")

(defn fuzzy-dice [item dist]
  (fn [x] (let [val-dist (ff/dice (x :name) item)]
            (if (>= val-dist dist)
              [val-dist (x :name) (x :ean)]
              nil))))

(defn fuzzy-store [line dist]
  (fn [x] (let [val-dist (ff/dice (x :name) line)]
            (if (>= val-dist dist)
              [val-dist (x :name) (x :city)]
              nil))))

(defn parse-store [lines]
  (let [get-store-from-line
        (fn [line]
          (println "Got line: " line)
          (if (not (nil? line))
            (do
              (println "Trying to find store:" line)
              (let [close-stores (keep (fuzzy-store line 0.6) ((:message stores-json) :stores))]
                (if (not (empty? close-stores))
                  (do
                    (println "Close-stores: " close-stores)
                    (let [closest (apply max-key first close-stores)]
                      ;(println "Store match: " (get closest 1) (get closest 0))           ; [dist name city]
                      [(get closest 1) (get closest 0)])
                    )
                  (do
                      (println "No store match")
                      ["" 0])
                  )
                )
              )
            )
          )
        all-found-stores (map get-store-from-line (take 3 lines))
        best-match (apply max-key second all-found-stores)
        ]
    ;(println (map get-store-from-line (take 3 lines)))
    (println "BEST STORE MATCH: " best-match)
    (first best-match)
    )
  )

;(apply max-key second (parse-store ["abcd" "Sale harju" "Sale kaijonharja"]))
;(parse-store ["abcd" "Sale harju" "Sale kaijonharja"])
;(apply merge (map (fn [x] {("x") (inc x)}) #{1 2 3}))
;(max-key val (map (fn [x] {(str "x") (inc x)}) #{1 2 3}))

(defn get-foodie-info [ean]
  (let [url (format "https://api.foodie.fm/api/entry?ean=%s" ean)
        rdr (clojure.java.io/reader url)
        response (parse-stream rdr true)
        entry ((:message response) :entry)]
    entry))

(def b (parse-string "
        {\"category_path\": [{
				\"id\": 351,
				\"name\": \"MAITO\",
				\"type\": \"PT\",
				\"entry_type\": \"PT\"
			},
			{
				\"id\": 352,
				\"name\": \"MAITO\",
				\"type\": \"PT\",
				\"entry_type\": \"PT\"
			},
			{
				\"id\": 1752,
				\"name\": \"ERIKOISMAIDOT KYLMÄSTÄ\",
				\"type\": \"PT\",
				\"entry_type\": \"PT\"
			}]}
        " true))

(defn read-text-file [text-file email date]
  (with-open [rdr (io/reader text-file)]
    (let [parsed-lines (map clojure.string/trim (line-seq rdr))
          store (parse-store parsed-lines)
          timestamp (java.util.Date.)]
      (println "GOT STORE: " store)
      (db/update-store! {:email email :date date :store store})

      (doseq [line parsed-lines]

        ;(println "Reading line: " line)
        (let [matches (mapv clojure.string/trim (re-find #"(\D+) ([\d\.]+)" (str line)))
              item (get matches 1)
              price (get matches 2)]
          ;(println item price)
          (if (and (relevant? item) (not (nil? price)))
             (do
               (println "Trying: " item "...")
               (let [close-eans (keep (fuzzy-dice item 0.6) ((:message products-json) :products))]
                 (if (not (empty? close-eans))
                   (do
                     ;(println "Close-eans: " close-eans)
                     (let [closest (apply max-key first close-eans)
                           name (get closest 1)
                           ean (get closest 2)
                           entry (get-foodie-info ean)
                           [foodiecat1 foodiecat2] (map :name (take 2 (entry :category_path)))
                           category (get-category foodiecat1 foodiecat2)
                           gpc (h/not-nil (entry :entry_gpc_category))]
                       (println "Match: " (get closest 2) price ":" category "-" foodiecat1 "/" foodiecat2)           ; [dist name ean]
                       (db/save-item! {:name name
                                       :ean ean
                                       :price price
                                       :sourcefile text-file
                                       :email email
                                       :date date
                                       :store store
                                       :foodiecat1 foodiecat1
                                       :foodiecat2 foodiecat2
                                       :category category
                                       :entry (encode entry)

                                       :pt_category (entry :pt_category_id)
                                       :gpc_id (gpc :ext_id)
                                       :gpc_name (gpc :name)
                                       :timestamp timestamp})))
                   (println "No match")
                 )
               )
             )
          )
        )
        )
      )
    )
  )

;(read-text-file "src/results_30.9.txt" "sadf@asdf" "2015-11-22")

;(re-matches (re-pattern (str "(?i).*(" unrelevant-strings ").*")) "tap.nro")
;;
;(apply str (interpose "|" ["saf" "asf"]))

;(relevant? "sdfs")
;(relevant? "tap. nro")
;(relevant? nil)

;(map clojure.string/trim (re-find #"(\D+)(\d+)" "ASFD ASDFSAF ASDFAF LOPPU          45.12"))
;(clojure.string/trim "   sadf   2")

;(get (re-find #"(\D+) (\d+)" "ASFD ASDFSAF ASDFAF LOPPU 4") 2)
;(get (mapv clojure.string/trim (re-find #"(\D+) (\d+)" "CHILI-CRISP    0.69                ")) 3)

;(def all-records (json/read-str (slurp "test.json") :key-fn keyword))
;; ==> [ { :column1 "value1", :column2 "value2", :column3 "value3" }, ...]


;(def a (parse-stream (clojure.java.io/reader "https://api.foodie.fm/api/entry?ean=6408430000142") true))
;((:message a) :entry)

(comment
(defn found? [key ean]
  (fn [x] (= (x key) ean)))

(defn fuzzy? [key ean dist]
  (fn [x] (< (ff/levenshtein (x key) ean) dist)))

(defn fuzzy-dice? [key ean dist]
  (fn [x] (>= (ff/dice (x key) ean) dist)))


(defn fuzzy-jaccard? [key ean dist]
  (fn [x] (< (ff/jaccard (x key) ean) dist)))

(defn fuzzy-jaro? [key ean dist]
  (fn [x] (>= (ff/jaro (x key) ean) dist)))

(defn fuzzy-winkler? [key ean dist]
  (fn [x] (>= (ff/jaro-winkler (x key) ean) dist)))

(defn fuzzy-tversky? [key ean dist]
  (fn [x] (>= (ff/tversky (x key) ean) dist)))



;(filter (found? 4055262413774) ((all-records :message) :products) )

;(defn find-matching [select-fn result-fn records]
;   (map result-fn (filter select-fn records)))

;(defn select-within [rec query]
;  (and (< (:column1 rec) query) (< query (:column2 rec))))

;(find-matching #(select-within % "status") :column3 all-records)

;; parse a stream (keywords option also supported)

;(apply max-key val (seq (keep (fuzzy-dice :name "Puma Pom Pomhipo" 0.1) ((:message a) :products))))
;(apply max-key val (apply merge (keep (fuzzy-dicemap :name "Puma Pom Pomhipo" 0.1) ((:message a) :products))))
;(assoc {:a 2} {:b 4})
(apply max-key val {:a 3 :b 7 :c 9})

(apply max-key second (keep (fuzzy-dice :name "Puma Pom Pomhipo" 0.1) ((:message a) :products)))

(keep (fuzzy-dice :name "Puma Pom Pomhipo" 1) ((:message a) :products))

(def a (parse-stream (clojure.java.io/reader "all_prods.json") true))

(:status a)
a
(a :status)
(apply :name (filter (found? :ean 4055262413774) ((:message a) :products) ))

; pienempi tarkempi - :-|
(map :name (filter (fuzzy? :name "Puma Pom Pomhipo" 4) ((:message a) :products) ))
(map :name (filter (fuzzy? :name "Kev7kerma" 4) ((:message a) :products) ))

; isompi tarkempi - :-)
(map :name (filter (fuzzy-dice? :name "Puma Pom Pomhipo" 0.6) ((:message a) :products) ))
(map :name (filter (fuzzy-dice? :name "Kev7kerma" 0.6) ((:message a) :products) ))

; pienempi tarkempi - :(
(map :name (filter (fuzzy-jaccard? :name "Puma Pom Pomhipo" 0.4) ((:message a) :products) ))
(map :name (filter (fuzzy-jaccard? :name "Kev7kerma" 0.4) ((:message a) :products) ))
; isompi tarkempi - :-|
(map :name (filter (fuzzy-jaro? :name "Puma Pom Pom pipo" 0.8) ((:message a) :products) ))
(map :name (filter (fuzzy-jaro? :name "Kev7kerma" 0.8) ((:message a) :products) ))

; isompi tarkempi - :-)
(map :name (filter (fuzzy-winkler? :name "Puma Pom Pomhipo" 0.9) ((:message a) :products) ))
(map :name (filter (fuzzy-winkler? :name "Kev7kerma" 0.9) ((:message a) :products) ))

; isompi tarkempi - :-(
(map :name (filter (fuzzy-tversky? :name "Puma Pom Pomhipo" 0.7) ((:message a) :products) ))
(map :name (filter (fuzzy-tversky? :name "Kev7kerma" 0.7) ((:message a) :products) ))

(ff/levenshtein "book" "back")
(ff/levenshtein "hello" "helo")
(ff/levenshtein "hello" "hello")

(ff/dice "book" "back")
(ff/dice "hello" "helo")
(ff/dice "hello" "hello")

(ff/jaccard "book" "back")
(ff/jaccard "hello" "helo")
(ff/jaccard "hello" "hello")

(ff/jaro "book" "back")
(ff/jaro "hello" "helo")
(ff/jaro "hello" "hello")

(ff/jaro-winkler "book" "back")
(ff/jaro-winkler "hello" "helo")
(ff/jaro-winkler "hello" "hello")

(ff/mra-comparison "book" "back")
(ff/mra-comparison "hello" "helo")
(ff/mra-comparison "hello" "hello")

(ff/tversky "book" "back")
(ff/tversky "hello" "helo")
(ff/tversky "hello" "hello")



(def a (cheshire.core/parsed-seq (clojure.java.io/reader "test.json") true))
a

;(def a (cheshire.core/parsed-seq (clojure.java.io/reader "test.json") true))
;(count (filter #(= (% "status") 0) (first a)))

(get a :status)
(:status a)

(def b (slurp "test.json"))

(decode b true
        (fn [field-name]
          (if (= field-name "ean")
            #{}
            [])))

;(cheshire.core/decode b true
;        (fn [field-name]
;          (if (not (nil? field-name))
;            (println #{}))))
)





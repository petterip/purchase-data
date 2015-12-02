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

;; Use ABBYY OcrSdk to recognize text
(defn call-ocrsdk [image-file]
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

;; JSON file containing all the products
(def products-json (parse-stream (clojure.java.io/reader "all_prods.json") true))
;; JSON file containing all stores
(def stores-json (parse-stream (clojure.java.io/reader "stores.json") true))
;; JSON file for matching purchase report categories with those provided by Foodie
(def categories-json (parse-stream (clojure.java.io/reader "match_categories.json") true))

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
              (let [close-stores (keep (fuzzy-store line 0.5) ((:message stores-json) :stores))]
                (if (not (empty? close-stores))
                  (do
                    (println "Close-stores: " close-stores)
                    (let [closest (apply max-key first close-stores)]
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
    (println "BEST STORE MATCH: " best-match)
    (first best-match)
    )
  )

(defn get-foodie-info [ean]
  (let [url (format "https://api.foodie.fm/api/entry?ean=%s" ean)
        rdr (clojure.java.io/reader url)
        response (parse-stream rdr true)
        entry ((:message response) :entry)]
    entry))

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
                   (println "No match"))))))))))
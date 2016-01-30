(ns analytics.recognize
  (:require [clojure.data.csv :as csv])
  (:require [clojure.java.io :as io])
  (:require [clojure.string :refer :all])
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
(def ignore-strings "YHTEENS|AVOINNA|Bonukseen|Bonuksen|kirjattu|KORTTITAPAHTUMA|TAKAISIN|Kortti|Autentisointi|Viite:|Veloitus|###|Tap. nro|Yritys/ala|Veroton|Verollinen|MAKSAESSASI|SAAT MEILT|Osuuskauppa")

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

(defn get-category [foodiecat1 foodiecat2]
  (let [matches (db/get-category {:foodiecat1 foodiecat1 :foodiecat2 foodiecat2})]
    (:category (first matches))))

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
              (let [close-stores (keep (fuzzy-store line 0.4) ((:message stores-json) :stores))]
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
    (if (nil? entry)
      {}
      entry)))

; DELETE THESE
;(float (* 2.5 (bigdec "3")))
;(float (read-string "2.5"))
;(read-text-file "src/results_30.9.txt" "sadf@asdf" "2015-11-22")
;(def line "   7 YTVAITO          60                    2.92        ")
;(def line "   «»..m»»    w*l t                       13.92       ")
;(def line "p/tmm 3X85G                      0.85 ")
;(def line " MARGARIINI 60%                           1.09")
(def line "RUISRUB 3 KPL 1-69   ")
(re-find #"(.{10,37})\s{1,}(\d+.+)" line)
;(re-find #"(\D+) ([\d\.]+)" line)

(defn read-text-file [text-file email date]
  (with-open [rdr (io/reader text-file)]
    (let [parsed-lines (map clojure.string/trim (line-seq rdr))
          store (parse-store parsed-lines)
          timestamp (java.util.Date.)]
      (println "GOT STORE: " store)
      (db/update-store! {:email email :date date :store store})

      (doseq [line (take 500 parsed-lines)]

        ;(println "Reading line: " line)
        (let [matches (mapv clojure.string/trim (re-find #"(.{10,37})\s{1,}(\d+.+)" (str line)))    ; (re-find #"(\D+) ([\d\.]+)" (str line))
              item (get matches 1)
              price (get matches 2)]
          ;(println item price)
          (if (and (relevant? item) (not (nil? price)))
             (do
               (println "Trying: " item "...")
               (let [close-eans (keep (fuzzy-dice (trim item) 0.6) ((:message products-json) :products))]
                 (if (not (empty? close-eans))
                   (do
                     (println "Close-eans: " (apply max-key first close-eans))
                     (let [closest (apply max-key first close-eans)
                           name (get closest 1)
                           ean (get closest 2)
                           entry (get-foodie-info ean)
                           weight (h/to-number (entry :net_weight))
                           energy (h/to-number (entry :kcal))
                           carb (h/to-number (entry :carbohydrate))
                           fiber (h/to-number (entry :fiber))
                           sugar (h/to-number (entry :sugar))
                           fat (h/to-number (entry :fat))
                           fat-saturated (h/to-number (entry :fat-saturated))
                           prot (h/to-number (entry :protein))
                           salt (* 2.5 (h/to-number (entry :sodium)))
                           origin (entry :origin)
                           type (entry :type)
                           is-food (not (== 0 energy fat carb))
                           [foodiecat1 foodiecat2] (map :name (take 2 (entry :category_path)))
                           category (get-category foodiecat1 foodiecat2)
                           gpc (h/not-nil (entry :entry_gpc_category))]
                       (print "Match: " (get closest 2) price ":" category "-" foodiecat1 "/" foodiecat2)           ; [dist name ean]
                       (println " Energy:" energy "Carb:" carb "Fiber:" fiber "Fat:" fat "Prot:" prot "Salt:" salt "Weight:" weight "Type:" is-food)
                       (db/save-item! {:name name
                                       :ean ean
                                       :price (trim price)
                                       :sourcefile text-file
                                       :email email
                                       :date date
                                       :store store
                                       :foodiecat1 foodiecat1
                                       :foodiecat2 foodiecat2
                                       :category category

                                       :entry (encode entry)
                                       :weight weight
                                       :energy energy
                                       :carb carb
                                       :fiber fiber
                                       :sugar sugar
                                       :fat fat
                                       :fat_saturated fat-saturated
                                       :prot prot
                                       :salt salt

                                       :origin origin
                                       :type type
                                       :food is-food

                                       :pt_category (entry :pt_category_id)
                                       :gpc_id (gpc :ext_id)
                                       :gpc_name (gpc :name)
                                       :timestamp timestamp})))
                   (println "No match"))))))))))

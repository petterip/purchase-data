(ns analytics.routes.home
  (:require [analytics.layout :as layout]
            [compojure.core :refer [defroutes GET POST]]
            [ring.util.http-response :refer [ok]]
            [clojure.java.io :as io]
            [clojure.data.codec.base64 :as b64]

            [analytics.db.core :as db]
            [analytics.db-test :as dbt]
            [analytics.helper :as h]
            [analytics.recognize :as r]
            [clojure.string :as s]

            [bouncer.core :as b]
            [bouncer.validators :as v]
            [ring.util.response :refer [redirect]])

  (:import  [org.apache.commons.io FilenameUtils]))

;; Load page
(defn load-page [{:keys [flash]}]
  (layout/render
    "load.html"
    (merge {:files (db/get-latest-files)}
           (select-keys flash [:email :file :message :errors]))))

(defn validate-file [params]
  (first
    (b/validate
      params
      :email v/required
      [:file :filename] v/required
      )))

(defn load-file! [{:keys [params]}]
  (do
    (println params)
    (if-let [errors (validate-file params)]
      (-> (redirect "/")
          (assoc :flash (assoc params :errors errors)))
      (do
        (let [file (params :file)
              filename (file :filename)
              size (file :size)
              email (params :email)
              date (params :date)
              filepath (io/file "resources" "public" (h/now-str filename))
              extension (FilenameUtils/getExtension (s/lower-case filename))]

          (println "\n\n!!! GOT DATE:" date)
          (io/copy (file :tempfile) filepath)
          (db/store-file!
            (assoc params :timestamp (java.util.Date.)
              :email email
              :fname filename
              :date date
              :store "n/a"
              :type extension))
          (cond
            (.endsWith (s/lower-case filename) ".csv")
            ;; Store csv files as S-Group's purchase reports into database
            (dbt/db-store-csv email filepath)
            (.endsWith (s/lower-case filename) ".jpg")
            ;; Store receipts into database
            (let [text-file
                  ;; Use OCR and Dice coefficient fuzzy matching to recognize text
                  (r/call-ocrsdk filepath)]
              (if (not (nil? text-file))
                ;; Read the recognized text file into database
                (do
                  (db/store-file!
                    (assoc params :timestamp (java.util.Date.)
                      :email email
                      :fname text-file
                      :date date
                      :store "n/a"
                      :type "txt"))
                  (r/read-text-file text-file email date)
                  (println "Receipt text recognized and products stored into database.")))
              )
            (.endsWith (s/lower-case filename) ".txt")
            ;; Read the recognized text file into database
            (do
              (r/read-text-file filepath email date)
              (println "Products stored into database.")
              )
            )
          (redirect "/"))))))

;; Purchases page
(defn purchases-page [request]
  (let [flash (:keys request)
        query (:query-params request)
        secret (second (first query))
        id (if (nil? secret)
             "id0%"
             (str (String. (b64/decode (.getBytes secret))) "@ostosdata.oulu.fi"))]
    (layout/render
      "purchases.html"
      (merge {:files (db/get-files-with-visits)}
             {:purchases (db/get-purchases {:email id})}
             (select-keys flash [:errors])))))

;; Items page
(defn items-page [request]
  (let [flash (:keys request)
        query (:query-params request)
        secret (second (first query))
        id (if (nil? secret)
             "id0%"
             (str (String. (b64/decode (.getBytes secret))) "@ostosdata.oulu.fi"))]
    (layout/render
      "items.html"
      (merge {:files (db/get-files-of-type {:type "txt"})}
             {:items (db/get-items {:email id})}
             (select-keys flash [:errors])))))

;; Home page
(defn home-page [{:keys [flash]}]
  (layout/render
    "home.html"
    (merge {:messages (db/get-messages)}
           (select-keys flash [:name :message :errors]))))

(defn validate-message [params]
  (first
    (b/validate
      params
      :name v/required
      :message [v/required [v/min-count 10]])))

(defn save-message! [{:keys [params]}]
  (if-let [errors (validate-message params)]
    (-> (redirect "/")
        (assoc :flash (assoc params :errors errors)))
    (do
      (db/save-message!
        (assoc params :timestamp (java.util.Date.)))
      (redirect "/"))))

(defn api-get-purchases [{:keys [params]}]
  (let [id (if (:id params)
             (:id params)
             "%")
        response (db/get-purchases {:email id})
        status (if (empty? response) 404 200)]
    {:status status
     :headers {"Content-Type" "text/html; charset=utf-8"}
     :body response
     }
    )
  )

(defn api-get-nutrition [{:keys [params]} unit]
  (let [id (if (:id params)
             (:id params)
             "%")
        response (cond
                   (= unit "m") (db/get-nutrition-month {:email id})
                   (= unit "w") (db/get-nutrition-week {:email id})
                   :else (db/get-nutrition {:email id}))
        status (if (empty? response) 404 200)]
    {:status status
     :headers {"Content-Type" "text/html; charset=utf-8"}
     :body response
     }
    )
  )

(defn api-get-nutrition-total [{:keys [params]}]
  (let [id (if (:id params)
             (:id params)
             "%")
        response (db/get-nutrition-total {:email id})
        status (if (empty? response) 404 200)]
    {:status status
     :headers {"Content-Type" "text/html; charset=utf-8"}
     :body response
     }
    )
  )

(defn api-get-purchases-by-date [{:keys [params]}]
  (let [id (if (:id params)
             (:id params)
             "%")
        date (:date params)
        response (db/get-purchases-by-date {:email id :date date})
        status (if (empty? response) 404 200)]
    {:status status
     :headers {"Content-Type" "text/html; charset=utf-8"}
     :body response
     }
    )
  )

(defn api-get-nutrition-by-date [{:keys [params]}]
  (let [id (if (:id params)
             (:id params)
             "%")
        month (:month params)
        order (if (:order params)
                (:order params)
                "fat")
        response (db/get-nutrition-by-date {:email id :month month :order order})
        status (if (empty? response) 404 200)]
    {:status status
     :headers {"Content-Type" "text/html; charset=utf-8"}
     :body (sort-by (keyword order) > response)
     }
    )
  )

(defn api-get-purchase-totals [{:keys [params]}]
  (let [id (if (:id params)
             (:id params)
             "%")
        response (db/get-purchase-totals {:email id})
        status (if (empty? response) 404 200)]
    {:status status
     :headers {"Content-Type" "text/html; charset=utf-8"}
     :body response
     }
    )
  )

(defn api-get-nutrition-categories [{:keys [params]}]
  (let [id (if (:id params)
             (:id params)
             "%")
        response (db/get-nutrition-by-categories {:email id})
        status (if (empty? response) 404 200)]
    {:status status
     :headers {"Content-Type" "text/html; charset=utf-8"}
     :body response
     }
    )
  )

(defn api-get-purchase-tops [{:keys [params]}]
  (let [id (if (:id params)
             (:id params)
             "%")
        response (db/get-purchase-tops {:email id})
        status (if (empty? response) 404 200)]
    {:status status
     :headers {"Content-Type" "text/html; charset=utf-8"}
     :body response
     }
    )
  )

(defn api-get-purchase-top-counts [{:keys [params]}]
  (let [id (if (:id params)
             (:id params)
             "%")
        response (db/get-purchase-top-counts {:email id})
        status (if (empty? response) 404 200)]
    {:status status
     :headers {"Content-Type" "text/html; charset=utf-8"}
     :body response
     }
    )
  )

;; Chart pages
(defn chart-page []
  (layout/render "chart.html"))

(defn nutrition-page []
  (layout/render "nutrition.html"))

(defn nutrition-area-page []
  (layout/render "nutrition_area.html"))

(defn nutrition-total-page []
  (layout/render "nutrition_total.html"))

(defn probe-t1-page []
  (layout/render "probe_t1.html"))

;; About page
(defn about-page []
  (layout/render "about.html"))

(defroutes home-routes

  ; Routes for the HTML pages
  (GET "/" request (load-page request))
  (POST "/" request (load-file! request))

  (GET "/purchases" request (purchases-page request))
  (GET "/items" request (items-page request))
  (GET "/chart" [] (chart-page))
  (GET "/nutrition" [] (nutrition-page))
  (GET "/nutrition-area" [] (nutrition-area-page))
  (GET "/nutrition-total" [] (nutrition-total-page))
  (GET "/probe-t1" [] (probe-t1-page))
  (GET "/about" [] (about-page))

  ; API routes
  (GET "/api/purchases/" request (api-get-purchases []))
  (GET "/api/purchases/:id" request (api-get-purchases request))
  (GET "/api/purchases/:id/totals" request (api-get-purchase-totals request))
  (GET "/api/purchases/:id/date/:date" request (api-get-purchases-by-date request))
  (GET "/api/purchases/:id/top5" request (api-get-purchase-tops request))
  (GET "/api/purchases/:id/top5-count" request (api-get-purchase-top-counts request))

  (GET "/api/nutrition/:id" request (api-get-nutrition request "d"))
  (GET "/api/nutrition/:id/month" request (api-get-nutrition request "m"))
  (GET "/api/nutrition/:id/week" request (api-get-nutrition request "w"))
  (GET "/api/nutrition/:id/date/:month/:order" request (api-get-nutrition-by-date request))
  (GET "/api/nutrition/:id/total" request (api-get-nutrition-total request))
  (GET "/api/nutrition/:id/categories" request (api-get-nutrition-categories request))
  )


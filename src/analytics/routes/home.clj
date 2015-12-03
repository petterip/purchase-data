(ns analytics.routes.home
  (:require [analytics.layout :as layout]
            [compojure.core :refer [defroutes GET POST]]
            [ring.util.http-response :refer [ok]]
            [clojure.java.io :as io]

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
(defn purchases-page [{:keys [flash]}]
  (layout/render
   "purchases.html"
   (merge {:files (db/get-files-with-visits)}
          {:purchases (db/get-purchases {:email "%"})}
          (select-keys flash [:errors]))))

;; Items page
(defn items-page [{:keys [flash]}]
  (layout/render
   "items.html"
   (merge {:files (db/get-files-of-type {:type "txt"})}
          {:items (db/get-items {:email "%"})}
          (select-keys flash [:errors]))))

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

;; About page
(defn about-page []
  (layout/render "about.html"))

(defroutes home-routes
  ;(GET "/" request (home-page request))
  ;(POST "/" request (save-message! request))

  ;(GET "/load" request (load-page request))
  ;(POST "/load" request (load-file! request))

  (GET "/" request (load-page request))
  (POST "/" request (load-file! request))

  (GET "/purchases" request (purchases-page request))
  (GET "/items" request (items-page request))
  (GET "/about" [] (about-page))

  ; API routes
  (GET "/api/purchases/:id" request (api-get-purchases request))
  (GET "/api/purchases/" request (api-get-purchases []))
  )


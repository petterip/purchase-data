-- name:save-message!
-- creates a new message
INSERT INTO receipts
(name, message, timestamp)
VALUES (:name, :message, :timestamp)

-- name:get-messages
-- selects all available messages
SELECT * from receipts

-- name:store-file!
-- creates a new file
INSERT INTO files
(email, fname, type, comment, store, date, timestamp)
VALUES (:email, :fname, :type, :comment, :store, :date, :timestamp)

-- name:update-store!
-- inserts new product item
UPDATE files
SET store = :store
WHERE email = :email AND date = :date

-- name:get-files
-- selects all available files
SELECT * from files

-- name:get-latest-files
-- selects all available files
SELECT * from files
ORDER BY timestamp DESC
LIMIT 3

-- name:get-files-of-type
-- selects all available files
SELECT * from files
WHERE type = :type

-- name:get-files-with-visits
-- selects all available files
SELECT DISTINCT files.*, count(distinct purchases.date) visits, sum(purchases.price), strftime('%d.%m.%Y', min(purchases.date)) start,  strftime('%d.%m.%Y', max(purchases.date)) end FROM purchases
JOIN files ON files.email = purchases.email
WHERE price > 0
GROUP BY purchases.email ORDER BY email, date

-- name:get-purchases
-- selects all available items from user email
SELECT * from purchases
WHERE email like :email

-- name:store-purchase!
-- creates a new file
INSERT INTO purchases
(email, date, time, store, class, category, price, timestamp)
VALUES (:email, :date, :time, :store, :class, :category, :price, :timestamp)

-- name:get-purchases-for-email
-- selects all available files
SELECT email, count(DISTINCT date) FROM purchases WHERE email = :email GROUP BY email ORDER BY email, date

-- name:save-item!
-- inserts new product item
INSERT INTO items
(name, ean, price, sourcefile, email, "date", store, foodiecat1, foodiecat2, entry, category,    pt_category, gpc_id, gpc_name, timestamp)
VALUES (:name, :ean, :price, :sourcefile, :email, :date, :store, :foodiecat1, :foodiecat2, :entry, :category,  :pt_category, :gpc_id, :gpc_name, :timestamp)

-- name:update-item!
-- inserts new product item
UPDATE items
SET category = :category, foodiecat1 = :foodiecat1, foodiecat2 = :foodiecat2, nutrition = :nutrition
WHERE ean = :ean

-- name:get-items
-- selects all available items from user email
SELECT * from items
WHERE email like :email

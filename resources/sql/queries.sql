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
WHERE price > 0 AND files.type = "csv"
GROUP BY purchases.email, fname ORDER BY email, date

-- name:get-purchases
-- selects all available purchases based on user email
SELECT * from purchases
WHERE email like :email

-- name:get-purchases-for-email
-- selects purchases by email, counts per visit
SELECT email, count(DISTINCT date) FROM purchases
WHERE email = :email GROUP BY email ORDER BY email, date

-- name:get-category
-- selects S Group category based on Foodie categories
SELECT category FROM food_categories
WHERE foodiecat1 = :foodiecat1 AND (foodiecat2 = :foodiecat2 OR foodiecat2 = "*")

-- name:get-purchase-totals
-- selects purchases by email, counts and groups them by date
SELECT p1.date, p1.count food_count, p1.cost food_cost, p2.count other_count, p2.cost other_cost, (p1.count+p2.count) total_count, round((p1.cost+p2.cost),2) total_cost FROM
(SELECT date, count(price) count, round(sum(price),2) cost FROM purchases
WHERE email LIKE :email AND price > 0 AND category IN (SELECT category FROM food_categories)
GROUP BY date) p1
JOIN
(SELECT date, count(price) count, round(sum(price),2) cost FROM purchases
WHERE email LIKE :email AND price > 0 AND category NOT IN (SELECT category FROM food_categories)
GROUP BY date) p2
ON p1.date = p2.date

-- name: get-purchase-tops
--
SELECT category, count(*) count, round(sum(price),2) total FROM purchases
WHERE email LIKE :email
GROUP BY category
ORDER BY total desc
LIMIT 50

-- name: get-purchase-top-counts
--
SELECT category, count(*) count, round(sum(price),2) total FROM purchases
WHERE email LIKE :email
GROUP BY category
ORDER BY count desc
LIMIT 50

-- name:get-purchases-by-date
-- selects purchases by email, counts and groups them by date
SELECT date, category, price, "food" food FROM purchases
WHERE email LIKE :email  AND date = :date AND category IN (SELECT category FROM food_categories)
UNION
SELECT date, category, price, "other" food FROM purchases
WHERE email LIKE :email  AND date = :date AND category NOT IN (SELECT category FROM food_categories)
ORDER BY food

-- name:store-purchase!
-- creates a new file
INSERT INTO purchases
(email, date, time, store, class, category, price, timestamp)
VALUES (:email, :date, :time, :store, :class, :category, :price, :timestamp)

-- name:get-nutrition
-- selects and merges nutrion value
SELECT date, avg(fat) fat, avg(energy) energy, avg(carb) carb FROM
(SELECT date, category FROM purchases WHERE email LIKE :email) p
JOIN
(SELECT category, avg(fat) fat FROM items WHERE email LIKE :email GROUP BY category) i1
ON i1.category = p.category
JOIN
(SELECT category, avg(energy) energy FROM items WHERE email LIKE :email GROUP BY category) i2
ON i2.category = p.category
JOIN
(SELECT category, avg(carb) carb FROM items WHERE email LIKE :email GROUP BY category) i3
ON i3.category = p.category
GROUP BY date
ORDER BY date

-- name:save-item!
-- inserts new product item
INSERT INTO items
(name,
 ean,
 price,
 sourcefile,
 email,
 "date",
 store,
 foodiecat1,
 foodiecat2,
 entry,

 weight,
 energy,
 carb,
 fiber,
 sugar,
 fat,
 fat_saturated,
 prot,
 salt,

 origin,
 type,
 food,

 category,
 pt_category,
 gpc_id,
 gpc_name,
 timestamp)
VALUES (:name,
        :ean,
        :price,
        :sourcefile,
        :email,
        :date,
        :store,
        :foodiecat1,
        :foodiecat2,
        :entry,

        :weight,
        :energy,
        :carb,
        :fiber,
        :sugar,
        :fat,
        :fat_saturated,
        :prot,
        :salt,

        :origin,
        :type,
        :food,

        :category,
        :pt_category,
        :gpc_id,
        :gpc_name,
        :timestamp)

-- name:update-item!
-- inserts new product item
UPDATE items
SET category = :category, foodiecat1 = :foodiecat1, foodiecat2 = :foodiecat2, nutrition = :nutrition
WHERE ean = :ean

-- name:get-items
-- selects all available items from user email
SELECT * from items
WHERE email like :email

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
LIMIT 15

-- name: get-purchase-top-counts
--
SELECT category, count(*) count, round(sum(price),2) total FROM purchases
WHERE email LIKE :email
GROUP BY category
ORDER BY count desc
LIMIT 15

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

-- name:get-nutrition-month
-- selects and merges nutrion value
SELECT date, month, round(sum(fat),1) fat, round(sum(fat_saturated),1) fat_saturated, round(sum(energy)/1000,1) energy, round(sum(carb),1) carb, round(sum(fiber),1) fiber,
round(sum(prot),1) prot, round(sum(sugar),1) sugar, round(sum(price),2) price FROM
(SELECT date, strftime('%m-%Y', date) month, category, price FROM purchases WHERE email LIKE :email) p
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(fat * weight / 100) ELSE avg(fat * 350 / 100) END AS fat FROM items WHERE food = 1 AND (email LIKE :email OR email="generic") GROUP BY category) i1
ON i1.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(energy * weight / 100) ELSE avg(energy * 350 / 100) END AS energy FROM items WHERE food = 1 AND (email LIKE :email OR email="generic") GROUP BY category) i2
ON i2.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(carb * weight / 100) ELSE avg(carb * 350 / 100) END AS carb FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i3
ON i3.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(fiber * weight / 100) ELSE avg(fiber * 350 / 100) END AS fiber FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i4
ON i4.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(fat_saturated * weight / 100) ELSE avg(fat_saturated * 350 / 100) END AS fat_saturated FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i5
ON i5.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(prot * weight / 100) ELSE avg(prot * 350 / 100) END AS prot FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i6
ON i6.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(sugar * weight / 100) ELSE avg(sugar * 350 / 100) END AS sugar FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i7
ON i7.category = p.category
GROUP BY month
ORDER BY date

-- name:get-nutrition-week
-- selects and merges nutrion value
SELECT date, round(sum(fat),1) fat, round(sum(fat_saturated),1) fat_saturated, round(sum(energy)/1000,1) energy, round(sum(carb),1) carb, round(sum(fiber),1) fiber,
round(sum(prot),1) prot, round(sum(sugar),1) sugar, round(sum(price),2) price FROM
(SELECT date, strftime('%Y-%W', date) week, category, price FROM purchases WHERE email LIKE :email) p
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(fat * weight / 100) ELSE avg(fat * 350 / 100) END AS fat FROM items WHERE food = 1 AND (email LIKE :email OR email="generic") GROUP BY category) i1
ON i1.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(energy * weight / 100) ELSE avg(energy * 350 / 100) END AS energy FROM items WHERE food = 1 AND (email LIKE :email OR email="generic") GROUP BY category) i2
ON i2.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(carb * weight / 100) ELSE avg(carb * 350 / 100) END AS carb FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i3
ON i3.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(fiber * weight / 100) ELSE avg(fiber * 350 / 100) END AS fiber FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i4
ON i4.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(fat_saturated * ELSE avg(fat_saturated * 350 / 100) END AS weight / 100) fat_saturated FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i5
ON i5.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(prot * weight / 100) ELSE avg(prot * 350 / 100) END AS prot FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i6
ON i6.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(sugar * weight / 100) ELSE avg(sugar * 350 / 100) END AS sugar FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i7
ON i7.category = p.category
GROUP BY week
ORDER BY date

-- name:get-nutrition
-- selects and merges nutrion value
SELECT date, round(sum(fat),1) fat, round(sum(fat_saturated),1) fat_saturated, round(sum(energy)/1000,1) energy, round(sum(carb),1) carb, round(sum(fiber),1) fiber,
round(sum(prot),1) prot, round(sum(sugar),1) sugar, round(sum(price),2) price FROM
(SELECT date, category, price FROM purchases WHERE email LIKE :email) p
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(fat * weight / 100) ELSE avg(fat * 350 / 100) END AS fat FROM items WHERE food = 1 AND (email LIKE :email OR email="generic") GROUP BY category) i1
ON i1.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(energy * weight / 100) ELSE avg(energy * 350 / 100) END AS energy FROM items WHERE food = 1 AND (email LIKE :email OR email="generic") GROUP BY category) i2
ON i2.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(carb * weight / 100) ELSE avg(carb * 350 / 100) END AS carb FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i3
ON i3.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(fiber * weight / 100) ELSE avg(fiber * 350 / 100) END AS fiber FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i4
ON i4.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(fat_saturated * weight / 100) ELSE avg(fat_saturated * 350 / 100) END AS fat_saturated FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i5
ON i5.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(prot * weight / 100) ELSE avg(prot * 350 / 100) END AS prot FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i6
ON i6.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(sugar * weight / 100) ELSE avg(sugar * 350 / 100) END AS sugar FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i7
ON i7.category = p.category
GROUP BY date
ORDER BY date

-- name:get-nutrition-by-date
SELECT month, p.category category, round(sum(fat)) fat, round(sum(fat_saturated)) fat_saturated, round(sum(energy)/1000) energy, round(sum(carb)) carb, round(sum(fiber)) fiber,
round(sum(prot)) prot, round(sum(sugar)) sugar, round(sum(price)) price FROM
(SELECT date, strftime('%m-%Y', date) month, category, price FROM purchases WHERE email LIKE :email AND month = :month AND category IN (SELECT category FROM food_categories)) p
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(fat * weight / 100) ELSE avg(fat * 350 / 100) END AS fat FROM items WHERE food = 1 AND (email LIKE :email OR email="generic") GROUP BY category) i1
ON i1.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(energy * weight / 100) ELSE avg(fat * 350 / 100) END AS energy FROM items WHERE food = 1 AND (email LIKE :email OR email="generic") GROUP BY category) i2
ON i2.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(carb * weight / 100) ELSE avg(fat * 350 / 100) END AS carb FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i3
ON i3.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(fiber * weight / 100) ELSE avg(fiber * 350 / 100) END AS fiber FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i4
ON i4.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(fat_saturated * weight / 100) ELSE avg(fat_saturated * 350 / 100) END AS fat_saturated FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i5
ON i5.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(prot * weight / 100) ELSE avg(prot * 350 / 100) END AS prot FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i6
ON i6.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(sugar * weight / 100) ELSE avg(sugar * 350 / 100) END AS sugar FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i7
ON i7.category = p.category
GROUP BY p.category
ORDER BY :order DESC

-- name:get-nutrition-total
-- gets nutritional values for fat, saturated fat, energy, carbs, fiber, protein, added sugar, salt and price, weight for all the purchases over the year
SELECT julianday(max(date))-julianday(min(date)) days, round(sum(fat),1) fat, round(sum(fat_saturated),1) fat_saturated, round(sum(energy),1) energy, round(sum(carb),1) carb, round(sum(fiber),1) fiber,
round(sum(prot),1) prot, round(sum(sugar),1) sugar, round(sum(salt),1) salt, round(sum(price),2) price, round(sum(weight),1) weight FROM
(SELECT date, price, category FROM purchases WHERE email LIKE :email) p
JOIN (SELECT category, case when weight > 0 then avg(fat * weight / 100) else avg(fat * 350 / 100) end as fat FROM items WHERE food = 1 AND (email LIKE :email OR email="generic") GROUP BY category) i1
ON i1.category = p.category
JOIN (SELECT category, case when weight > 0 then avg(energy * weight / 100) else avg(energy * 350 / 100) end as energy FROM items WHERE food = 1 AND (email LIKE :email OR email="generic") GROUP BY category) i2
ON i2.category = p.category
JOIN (SELECT category, case when weight > 0 then avg(carb * weight / 100) else avg(carb * 350 / 100) end as carb FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i3
ON i3.category = p.category
JOIN (SELECT category, case when weight > 0 then avg(fiber * weight / 100) else avg(fiber * 350 / 100) end as fiber FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i4
ON i4.category = p.category
JOIN (SELECT category, case when weight > 0 then avg(fat_saturated * weight / 100) else avg(fat_saturated * 350 / 100) end as fat_saturated FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i5
ON i5.category = p.category
JOIN (SELECT category, case when weight > 0 then avg(prot * weight / 100) else avg(prot * 350 / 100) end as prot FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i6
ON i6.category = p.category
JOIN (SELECT category, case when weight > 0 then avg(sugar * weight / 100) else avg(sugar * 350 / 100) end as sugar FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i7
ON i7.category = p.category
JOIN (SELECT category, case when weight > 0 then avg(salt * weight / 100) else avg(salt * 350 / 100) end as salt FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i8
ON i8.category = p.category
JOIN (SELECT category, case when weight > 0 then avg(weight) else 350 end as weight FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i9
ON i9.category = p.category

-- name:get-nutrition-by-categories
-- gets nutritional values for each category: fat, saturated fat, energy, carbs, fiber, protein, added sugar, salt and price, weight for all the purchases over the year
SELECT p.category category, round(sum(fat)) fat, round(sum(fat_saturated)) fat_saturated, round(sum(energy)/1000) energy, round(sum(carb)) carb, round(sum(fiber)) fiber,
round(sum(prot)) prot, round(sum(sugar)) sugar, round(sum(price)) price FROM
(SELECT date, category, price FROM purchases WHERE email LIKE :email AND category IN (SELECT category FROM food_categories)) p
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(fat * weight / 100) ELSE avg(fat * 350 / 100) END AS fat FROM items WHERE food = 1 AND (email LIKE :email OR email="generic") GROUP BY category) i1
ON i1.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(energy * weight / 100) ELSE avg(fat * 350 / 100) END AS energy FROM items WHERE food = 1 AND (email LIKE :email OR email="generic") GROUP BY category) i2
ON i2.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(carb * weight / 100) ELSE avg(fat * 350 / 100) END AS carb FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i3
ON i3.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(fiber * weight / 100) ELSE avg(fiber * 350 / 100) END AS fiber FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i4
ON i4.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(fat_saturated * weight / 100) ELSE avg(fat_saturated * 350 / 100) END AS fat_saturated FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i5
ON i5.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(prot * weight / 100) ELSE avg(prot * 350 / 100) END AS prot FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i6
ON i6.category = p.category
JOIN
(SELECT category, CASE WHEN weight > 0 THEN avg(sugar * weight / 100) ELSE avg(sugar * 350 / 100) END AS sugar FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i7
ON i7.category = p.category
GROUP BY p.category


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

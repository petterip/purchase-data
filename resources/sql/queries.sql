-- name:save-message!
-- Creates a new message
INSERT INTO receipts
(name, message, timestamp)
VALUES (:name, :message, :timestamp)

-- name:get-messages
-- Selects all available messages
SELECT * from receipts

-- name:store-file!
-- Creates a new file
INSERT INTO files
(email, fname, type, comment, store, date, timestamp)
VALUES (:email, :fname, :type, :comment, :store, :date, :timestamp)

-- name:update-store!
-- Updates the name of the store in files table
UPDATE files
SET store = :store
WHERE email = :email AND date = :date

-- name:get-files
-- Selects all available files
SELECT * from files

-- name:get-latest-files
-- Selects three latest added  files
SELECT * from files
ORDER BY timestamp DESC
LIMIT 3

-- name:get-files-of-type
-- Selects all available files based on type
SELECT * from files
WHERE type = :type

-- name:get-files-with-visits
-- Pulls out the number of store visits per user email
SELECT DISTINCT files.*, count(distinct purchases.date) visits, sum(purchases.price), strftime('%d.%m.%Y', min(purchases.date)) start,  strftime('%d.%m.%Y', max(purchases.date)) end
FROM purchases
JOIN files ON files.email = purchases.email
WHERE price > 0 AND files.type = "csv"
GROUP BY purchases.email, fname ORDER BY email, date

-- name:get-purchases
-- Selects all available purchases based on user email
SELECT * from purchases
WHERE email like :email

-- name:get-purchases-for-email
-- Selects purchases by email, counts per visit
SELECT email, count(DISTINCT date) FROM purchases
WHERE email = :email GROUP BY email ORDER BY email, date

-- name:get-category
-- Selects S Group category based on Foodie categories
SELECT category FROM food_categories
WHERE foodiecat1 = :foodiecat1 AND (foodiecat2 = :foodiecat2 OR foodiecat2 = "*")

-- name:get-purchase-totals
-- Selects purchases by email, counts and groups them by date, for a single user email
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
-- Get top 15 purchases for a single user and sort them by total costs
SELECT category, count(*) count, round(sum(price),2) total FROM purchases
WHERE email LIKE :email
GROUP BY category
ORDER BY total desc
LIMIT 15

-- name: get-purchase-top-counts
-- Get top 15 purchases for a single user and sort them by number of purchases
SELECT category, count(*) count, round(sum(price),2) total FROM purchases
WHERE email LIKE :email
GROUP BY category
ORDER BY count desc
LIMIT 15

-- name:get-purchases-by-date
-- Select purchases by email, counts and groups them by date
SELECT date, category, price, "food" food FROM purchases
WHERE email LIKE :email  AND date = :date AND category IN (SELECT category FROM food_categories)
UNION
SELECT date, category, price, "other" food FROM purchases
WHERE email LIKE :email  AND date = :date AND category NOT IN (SELECT category FROM food_categories)
ORDER BY food

-- name:store-purchase!
-- Insert a new purchase into purchases table
INSERT INTO purchases
(email, date, time, store, class, category, price, timestamp)
VALUES (:email, :date, :time, :store, :class, :category, :price, :timestamp)

-- name:get-nutrition-month
-- Get monthly nutritional values and monthly costs
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
-- Get weekly nutritional values and purchase costs
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
(SELECT category, CASE WHEN weight > 0 THEN avg(fat_saturated * weight / 100) ELSE avg(fat_saturated * 350 / 100) END AS fat_saturated FROM items WHERE food=1 AND (email LIKE :email OR email="generic") GROUP BY category) i5
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
-- Get daily nutritional values and purchase costs
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
-- Get nutritional values and monthly costs for one month
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
-- Get nutritional values for fat, saturated fat, energy, carbs, fiber, protein, added sugar, salt and price, weight for all the purchases
SELECT julianday(max(date))-julianday(min(date))-30*(round((julianday(max(date))-julianday(min(date)))/30)-count(distinct month)) days,
round(sum(fat),1) fat, round(sum(fat_saturated),1) fat_saturated, round(sum(energy),1) energy, round(sum(carb),1) carb, round(sum(fiber),1) fiber,
round(sum(prot),1) prot, round(sum(sugar),1) sugar, round(sum(salt),1) salt, round(sum(price),2) price, round(sum(weight),1) weight FROM
(SELECT date, strftime('%m-%Y', date) month, price, category FROM purchases WHERE email LIKE :email) p
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
-- Get nutritional values for each category: fat, saturated fat, energy, carbs, fiber, protein, added sugar, salt and price, weight for all the purchases
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
-- Insert a new product item
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
-- Inserts a new product item
UPDATE items
SET category = :category, foodiecat1 = :foodiecat1, foodiecat2 = :foodiecat2, nutrition = :nutrition
WHERE ean = :ean

-- name:get-items
-- Select all available items based on user email
SELECT * from items
WHERE email like :email

CREATE TABLE purchases
(id INTEGER PRIMARY KEY,
 email VARCHAR(30),
 date DATE,
 time VARCHAR(256),
 store VARCHAR(256),
 class VARCHAR(256),
 category VARCHAR(256),
 price REAL,
 timestamp TIMESTAMP);

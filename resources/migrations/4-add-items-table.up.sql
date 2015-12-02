CREATE TABLE items
(id INTEGER PRIMARY KEY,
 name VARCHAR(256),
 ean VARCHAR(30),
 price REAL,
 sourcefile VARCHAR(256),
 email VARCHAR(256),
 date DATE,
 store VARCHAR(256),
 category VARCHAR(256),
 foodiecat1 VARCHAR(256),
 foodiecat2 VARCHAR(256),

 gpc_name VARCHAR(256),
 gpc_id VARCHAR(256),
 pt_category VARCHAR(256),
 entry VARCHAR(256),

 timestamp TIMESTAMP);

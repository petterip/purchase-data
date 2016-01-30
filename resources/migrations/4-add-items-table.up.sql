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

 weight REAL,
 energy REAL,
 carb REAL,
 fiber REAL,
 sugar REAL,
 fat REAL,
 fat_saturated REAL,
 prot REAL,
 salt REAL,

 origin VARCHAR(256),
 type VARCHAR(30),
 food BOOLEAN,

 timestamp TIMESTAMP);
--;;
INSERT INTO items VALUES
("1","Naudaliha, keskiarvo (Fineli)","","5","","generic","","","KOKOLIHAVALMISTEET","LIHA","LIHATISKI",null,null,"","","400","153","0","0","0","8.4","4","19.3","0.1312","","","1","1454068374835"),
("2","Naudaliha, keskiarvo (Fineli)","","5","","generic","","","NAUDANLIHA","LIHA","LIHATISKI",null,null,"","","400","153","0","0","0","8.4","4","19.3","0.1312","","","1","1454068374835"),
("3","Lohifilee, keskiarvo (Fineli)","","5","","generic","","","SAVUKALA","KALA","KALATISKI",null,null,"","","400","195","0","0","0","13.5","2.5","18.7","0.1096","","","1","1454068374835");

create database if not exists db_training;

use db_training;

create rowstore table customers(
customerNumber bigint not null primary key,
customerName varchar(50) not null,
contactLastName varchar(50) not null,
contactFirstName varchar(50) not null,
phone varchar(50) not null,
addressLine1 varchar(50) not null,
addressLine2 varchar(50) null sparse,
country varchar(50) not null,
salesRepEmployeNumber int not null,
creditLimit int(10) not null);

show tables extended;

show columns IN customers;

show indexes in customers;

use information_schema;

select column_name, is_sparse from columns where table_name="customers";


create database if not exists db_training;

use db_training;


create table sales(
    productId bigint null,
    timeId int not null,
    customerId bigint null,
    promotionid int null,
    storeid int null,
    storeSales decimal(12,2) null,
    storecost decimal(12,2) null,
    unitSales decimal(12,2) null,
    KEY(timeId) USING CLUSTERED COLUMNSTORE
);


create reference table region(
    regionid int primary key,
    salescity nvarchar(50),
    salesstateprovince  nvarchar(50),
    salesregion  nvarchar(50),
    salescountry  nvarchar(50),
    salesdistrictid int,
    sort key(salesdistrictid)
);

create rowstore reference table productlines(
    productlineid int primary key,
    productlinename varchar(50) not null,
    textdescription varchar(4000) not null,
    htmldescription text not null,
    image blob not null
);

show tables extended;

show columns IN region;

show indexes in region;



use information_schema;

select * from columns where table_name in ("region","productlines");




create database if not exists twitter_pipeline;

use twitter_pipeline;

create rowstore table tweets(
    id BIGINT, shard(id),
    tweet json,
    text as tweet::$text persisted text);

show tables extended;
show columns IN tweets;
show indexes in tweets;

create pipeline twitter_pipeline
    as load data kafka
        'public-kafka.memcompute.com:9092/tweets-json'
    INTO table tweets(id,tweet);

drop pipeline twitter_pipeline;

test pipeline twitter_pipeline;

start pipeline twitter_pipeline;
stop pipeline twitter_pipeline;

select count(*) from tweets;



create database if not exists books;
use books;

create table classic_books(
    author varchar(255),
    date varchar(255)
);


create pipeline library
    as load data s3 'download.memsql.com/library'
    config '{"region":"us-east-1"}'
    INTO table classic_books
    FIELDS TERMINATED BY','
    ENCLOSED BY'"';

select * from information_schema.pipelines_files;

show pipelines;

start pipeline library;

select * from classic_books;

CREATE DATABASE IF NOT EXISTS twitter_pipeline;
USE twitter_pipeline;
CREATE ROWSTORE TABLE t1(a int);

CREATE PIPELINE json_text 
    AS LOAD DATA S3 'testing-ingest-examples/a_file.json' 
    CONFIG '{"region":"us-east-1"}' 
    CREDENTIALS '{"aws_access_key_id":"","aws_secret_access_key":""}' 
    INTO TABLE t1(a<-a::b) FORMAT JSON;

START PIPELINE json_text;

SELECT * FROM t1;

CREATE ROWSTORE TABLE m(
    b bool NOT NULL,
    s text,
    n double,
    o json NOT NULL,
    whole longblob
);


CREATE OR REPLACE PIPELINE json_text_2 
    AS LOAD DATA S3 'testing-ingest-examples/b_json.json' 
    CONFIG '{"region": "us-east-1"}' 
    CREDENTIALS '{"aws_access_key_id": "", "aws_secret_access_key": ""}' 
    INTO TABLE m FORMAT JSON( 
        b <- b default true, 
        s <- s default NULL, 
        n <- n default NULL, 
        o <- o default '{"subobject":"replaced"}', 
        whole <- %
    );

START PIPELINE json_text_2;
Select * from m;


CREATE ROWSTORE TABLE tweets_location(
    id bigint, 
    location varchar(255)
);

CREATE ROWSTORE TABLE tweets_txt(
    id bigint,
    tweet_text varchar(255)
);

DELIMITER // 
CREATE or REPLACE PROCEDURE proc_test(batch query(id BIGINT, tweet_text varchar(255), location varchar(255), id_str varchar(255))) 
    AS 
    BEGIN 
        INSERT INTO tweets_location(id, location) 
            SELECT id, location FROM batch; 
        INSERT INTO tweets_txt(id, tweet_text) 
            SELECT id, tweet_text FROM batch; 
    END// 
DELIMITER ;


CREATE OR REPLACE PIPELINE tweet 
    AS LOAD DATA S3 'testing-ingest-examples/tweet_json_v6.json'
    CONFIG '{"region": "us-east-1"}'
    CREDENTIALS '{"aws_access_key_id": "", "aws_secret_access_key": ""}'
    INTO PROCEDURE proc_test FORMAT JSON( 
        id <- id DEFAULT NULL,
        tweet_text <- text_tweet DEFAULT NULL,
        location <- user::location DEFAULT NULL,
        id_str <- id_str DEFAULT NULL
);

START PIPELINE tweet;

SELECT * FROM tweets_location;
SELECT * FROM tweets_txt;


RESTORE DATABASE employees
  FROM S3 'backup-employees'
  CONFIG'{"region":"us-east-1"}'
  CREDENTIALS'{"aws_access_key":"","aws_secret_access_key":""}';

USE employees;


SHOW tables;


SELECT COUNT(*) from <table_name>;

SELECT COUNT(DISTINCT emp_no) 
  FROM salaries 
  WHERE salary > 150000;

SELECT DISTINCT e.first_name, e.last_name, d.dept_name
  FROM employees e
  INNER JOIN dept_emp de ON e.emp_no=de.emp_no
  INNER JOIN departments d ON de.dept_no=d.dept_no
  WHERE dept_name='Marketing';

SELECT count(emp_no)
  FROM (SELECT emp_no, count(title) as title_count
          FROM titles
          GROUP BY emp_no)
  WHERE title_count >= 3;


SHOW plancache;




SELECT e.first_name, e.last_name, d.dept_name, t.title, t.from_date, t.to_date
  FROM employees e
  INNER JOIN dept_emp de ON e.emp_no=de.emp_no
  INNER JOIN departments d ON de.dept_no=d.dept_no
  INNER JOIN titles t ON e.emp_no=t.emp_no
  ORDER BY e.first_name, e.last_name, d.dept_name, t.from_date
  LIMIT 10;

CREATE REFERENCE TABLE departments_ref(
  dept_no CHAR(4) not null,
  dept_name varchar(40) not null,
  primary key (dept_no),
  key(dept_name)
);

INSERT INTO departments_ref (SELECT * FROM departments);







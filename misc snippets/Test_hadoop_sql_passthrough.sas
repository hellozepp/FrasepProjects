options sastrace=',,,d' sastraceloc=saslog nostsuffix;
options dbidirectexec sql_ip_trace=note msglevel=i;
option fullstimer;

options set=SAS_HADOOP_JAR_PATH="/opt/sas/hadoop/jars";
options set=SAS_HADOOP_CONFIG_PATH="/opt/sas/hadoop/sitexmls";

libname hdplib hadoop 
user="hive" 
password="Orion123" 
uri="jdbc:hive2://frasephdp.cloud.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2"
properties="hive.fetch.task.conversion=more;hive.fetch.task.conversion.threshold=-1;hive.execution.engine=tez" 
READ_METHOD=HDFS_SELSTAR
server="frasephdp.cloud.com"
SQL_FUNCTIONS=ALL
dbmax_text=128
DBCREATE_TABLE_OPTS='STORED AS ORC';

/* implicit passthrough */

proc sql;
	drop table hdplib.megagg;
	create table hdplib.megagg as
	(select min(year(date)), facility, product 
	from hdplib.megacorp_small 
	group by product, facility);
quit;

proc print data=hdplib.megagg;
run;


/* Explicit passthrough */

proc sql;
	
	drop table hdplib.megaagg2;

	connect using hdplib;
	
	create table hdplib.megaagg2 as select * from connection to hdplib (
		select min(year(`date`)), facility, product from megacorp_small group by facility, product
	);
    
	disconnect from hdplib;
quit;

options set=SAS_HADOOP_JAR_PATH="/opt/sas/hadoop/jars";
options set=SAS_HADOOP_CONFIG_PATH="/opt/sas/hadoop/sitexmls";

libname hdplib hadoop 
user="hive" 
password="Orion123" 
uri="jdbc:hive2://frasephdp.cloud.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2"
properties="hive.fetch.task.conversion=more;hive.fetch.task.conversion.threshold=-1;hive.execution.engine=tez" READ_METHOD=HDFS_SELSTAR
server="frasephdp.cloud.com";

options sastrace=',,,d' sastraceloc=saslog nostsuffix;
options dbidirectexec sql_ip_trace=note msglevel=i;

proc sql;
	drop table hdplib.megagg5;
	create table hdplib.megagg5 as
	(select min(year(date)), facility, product 
	from hdplib.megacorp_small 
	group by product, facility);
quit;


proc sql;
	Connect To hadoop (SERVER="frasephdp.cloud.com"
	User="hive"
	password="Orion123"
	dbmax_text=255
	uri='jdbc:hive2://frasephdp.cloud.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2'
	properties="hive.fetch.task.conversion=more;hive.fetch.task.conversion.threshold=-1;hive.execution.engine=tez" READ_METHOD=HDFS
	);
	
	create table hdplib.cars2 as select * from connection to hadoop (select * from cars limit 10);

    disconnect from hadoop;
quit;

proc sql;
	connect using hdplib as hdp;
	create table hdplib.cars3 as select * from connection to hdp (select * from cars2);
    disconnect from hdp;
quit;


proc sql;
	connect using hdplib;
	create table hdplib.cars4 as select * from connection to hdplib (select * from cars3);
    disconnect from hdplib;
quit;

proc sql;
	connect using hdplib;
	create table hdplib.cars4 as select * from connection to hdplib (select * from cars3);
    disconnect from hdplib;
quit;


proc sql;
	connect using hdplib;
	select * from connection to hdplib (select min(year(`date`)), facility, product from megacorp_small group by product, facility);
    disconnect from hdplib;
quit;

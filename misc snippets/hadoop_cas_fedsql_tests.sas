cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US");

caslib hdlib datasource=(
	srctype="hadoop", 
	dataTransferMode="serial", 
	username="hive", 
	password="hadoop"
	uri="jdbc:hive2://86.238.107.157:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2",
	hadoopjarpath="/opt/sas/hadoop/jars", 
	hadoopconfigdir="/opt/sas/hadoop/sitexmls", 
	schema="default");

caslib _all_ assign;

data hdlib.cars;
	set sashelp.cars;
run;

proc cas;
	table.save / table={caslib='hdlib' name="cars"} caslib="hdlib" name="cars";
run;

cas mySession terminate;


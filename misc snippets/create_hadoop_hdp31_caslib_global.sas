cas mysess;

proc cas;
	table.addcaslib /
		name="hdlib",
		datasource={
			srctype="hadoop",
			dataTransferMode="auto",
			username="hive",
			dbmaxText=255,
			password="Orion123",
			properties="hive.fetch.task.conversion=more;hive.fetch.task.conversion.threshold=-1;hive.execution.engine=tez",
			uri="jdbc:hive2://frasephdp.cloud.com:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2",
			hadoopjarpath="/opt/sas/hadoop/jars",
			hadoopconfigdir="/opt/sas/hadoop/sitexmls",
			schema="default"}
		session=false;
	run;
quit;

cas _ALL_ terminate;
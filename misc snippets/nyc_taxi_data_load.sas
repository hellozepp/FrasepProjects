/* Exemple code pour recuperer les donnees */
/* wget https://nyc-tlc.s3.amazonaws.com/trip+data/fhvhv_tripdata_2022-03.parquet */

cas mysess sessopts=(metrics="true" messagelevel="ALL");

proc cas;
	table.dropcaslib / caslib="parquets" quiet=true;
	table.addcaslib / caslib="parquets" datasource={srctype="path"} path="/opt/data/parquets/fhvhv" subdirs=true session=false;
	table.fileinfo result=listtab / caslib="parquets";

	table.columninfo table={caslib="parquets" name="fhvhv_tripdata_2022-01.parquet"};
	table.loadtable / sourcecaslib="parquets" casout={caslib="parquets", name="fhvhv_tripdata_2022-01", replication=0} path="fhvhv_tripdata_2022-01.parquet";
	table.tableinfo caslib="parquets" name="fhvhv_tripdata_2022-01";
	table.tabledetails caslib="parquets" name="fhvhv_tripdata_2022-01";
	table.promote / caslib="parquets" name="fhvhv_tripdata_2022-01" drop=true;
quit;

cas mysess terminate;

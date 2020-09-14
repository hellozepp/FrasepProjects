cas mysess;

caslib amldb desc='PostgreSQL Caslib' 
     dataSource=(srctype='postgres'
                 server='52.186.10.200'
                 username='sep'
                 password='Orion123'
                 database="tenant2"
                 schema='public'
				 conopts="sslmode=require"
				 INSERTBUFF="1000");


caslib _all_ assign;


data amldb.FSC_PARTY_DIM_TEST001;
set DNFSDATA.TABLE_FSC_PARTY_DIM;
run;

data DNFSDATA.FSC_PARTY_DIM_TEST001;
set DNFSDATA.TABLE_FSC_PARTY_DIM;
run;

proc cas;
	table.save / caslib="DNFSDATA" name="FSC_PARTY_DIM_TEST001.csv" table={caslib="DNFSDATA", name="FSC_PARTY_DIM_TEST001"} replace=true;
quit;


proc cas;
	table.save / caslib="amldb" name="FSC_PARTY_DIM_TEST001" table={caslib="amldb", name="FSC_PARTY_DIM_TEST001"} replace=true;
quit;



cas mysess terminate;
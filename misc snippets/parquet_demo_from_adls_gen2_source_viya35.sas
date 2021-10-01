cas mysess sessopts=(metrics=true);

proc cas;
	table.dropcaslib / caslib="AzureDL" silent=true;
quit;

caslib "AzureDL" 
	datasource=(
		srctype="adls"
			accountname='frasepstorage'
			filesystem="datalake"
			tenantid="b1c14d5c-3625-45b3-a430-9552373a0c2f"
			applicationId="e7af42e8-3ca8-47bb-97ce-ac764019be3a"
			timeout=50000
	)
	path="/" subdirs global;



/*********************************************/
/* Load ORC file in CAS                      */
/*********************************************/

libname mydata "/data";

proc cas;
	table.fileinfo / caslib="AzureDL" allfiles=true includedirectories=true;
quit;

proc cas;
	table.loadtable / caslib="AzureDL" path="megacorp5_4m.orc" casout="megacorp5_4m";
quit;

/* Add to path and dnfs caslib pointing on ephemeral storage */

proc cas;
	table.addcaslib / name="dnfs" dataSource={srctype="dnfs"} path="/mnt/demo/dnfs";
	table.addcaslib / name="mydata" dataSource={srctype="path"} path="/mnt/demo/sasdata";
quit;

caslib _all_ assign;

/* Save the test data to parquet and sas7bdat formats */
/* parquet : 132 Mo, 
   sas7bdat : 1,7 GB, 
   sashdat : 1,8 GB
*/

proc cas;
	table.save / caslib="dnfs" name="megacorp5_4m.parquet" table={caslib="AzureDL" name="megacorp5_4m"} replace=true;
quit;

proc cas;
	table.save / caslib="mydata" name="megacorp5_4m.sas7bdat" table={caslib="AzureDL" name="megacorp5_4m"} replace=true;
quit;

proc cas;
	table.save / caslib="dnfs" name="megacorp5_4m.sashdat" table={caslib="AzureDL" name="megacorp5_4m"} replace=true;
quit;

proc cas;
	table.columninfo / table={caslib="dnfs" name="megacorp5_4m.parquet"};
	table.columninfo / table={caslib="dnfs" name="megacorp5_4m.sashdat"};
	table.columninfo / table={caslib="mydata" name="megacorp5_4m.sas7bdat"};
quit;

/*
Compute aggregates directly on parquet files using CAS processing native support of parquet 
data without any data conversion to default CAS in-memory format
*/

/* With parquet source : load + processing = 0.39 secondes */
proc cas;
	simple.summary / 
		inputs={"Revenue","Expenses"} 
		subSet={"SUM"} 
		table={caslib="dnfs" name="megacorp5_4m.parquet" groupBy={"FacilityRegion","product","ProductLine","Productbrand"}}
        casout={caslib="casuser" name="megacorp_summary" replace=True replication=0};
quit;

/* With sas7bdat source : load + processing = 4.35 secondes */
proc cas;
	simple.summary / 
		inputs={"Revenue","Expenses"} 
		subSet={"SUM"} 
		table={caslib="mydata" name="megacorp5_4m.sas7bdat" groupBy={"FacilityRegion","product","ProductLine","Productbrand"}}
        casout={caslib="casuser" name="megacorp_summary" replace=True replication=0};
quit;

/* Load in CAS memory only columns and rows selected without preloading all the parquet data in memory */
/* Use CAS baseic native parquet processing */

proc cas;
	table.loadtable /
    caslib="dnfs" 
    path="megacorp5_4m.parquet"
    where="year(DateByYear) in (2007,2008,2009)"
	vars={{name="DateByYear",format="DATE9."},{name="FacilityRegion"},{name="product"},{name="Expenses"}}
    casout={caslib="dnfs" name="test_megacorp_parquet" replace="true" replication=0};
quit;

/* With parquet source : load + processing = 2.65 secondes */

proc cas;
	sampling.stratified / 
		display={names={"STRAFreq"}}
        output={casOut={caslib="casuser" name="out" replace=True} copyVars="ALL"}
        samppct=10 samppct2=20 partind=true seed=10
        table={caslib="dnfs" name="megacorp5_4m.parquet" groupBy={"FacilityRegion"} where="year(DateByYear) in (2009)"}
        outputTables={names={"STRAFreq"} replace=True};
quit;

/* With sas7bdat source : load + processing = 4.15 secondes */
proc cas;
	sampling.stratified / 
		display={names={"STRAFreq"}}
        output={casOut={caslib="casuser" name="out" replace=True} copyVars="ALL"}
        samppct=10 samppct2=20 partind=true seed=10
        table={caslib="mydata" name="megacorp5_4m.sas7bdat" groupBy={"FacilityRegion"} where="year(DateByYear) in (2009)"}
        outputTables={names={"STRAFreq"} replace=True};
quit;

cas mysess terminate;


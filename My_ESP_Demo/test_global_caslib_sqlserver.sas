options cashost="frasepviya35smp" casport=5570 CASNCHARMULTIPLIER=2;

cas mysess sessopts=(timeout=3600 metrics=true);

proc cas;
   session mysess;

   table.dropcaslib / caslib="SQLSRV" quiet=true;

   table.addCaslib result=r /
      caslib="SQLSRV"
      datasource={srctype="sqlserver",
                  username="sqlserver",
                  password="admin",
                  sqlserver_dsn="sqlserver_demodb",
				  charMultiplier=2}
	   session=TRUE;
   print r;
quit;

/* List all tables in SQLSERVER */
proc cas;
	table.fileinfo / caslib="SQLSRV";
quit;

caslib _all_ assign;

data SQLSRV.prdsale(drop=i) ;
   set sashelp.prdsale ;
   do i=1 to 100 ;
      output ;
   end ;
run ;

proc cas;
	table.save / table={caslib='SQLSRV' name="prdsale"} caslib="SQLSRV" name="prdsale" replace=true;
run;

/* List all tables in SQLSERVER */
proc cas;
	table.fileinfo / caslib="SQLSRV";
quit;

/* Work on CAS table loaded in memory */
proc cas;
	fedSql.execDirect / showStages=true query="select country, division, month, sum(actual) as total_actual from sqlsrv.prdsale group by country, division, month";
quit;

proc cas;
	table.droptable / caslib="SQLSRV" name="PRDSALE";
quit;

/* Work on CAS table not loaded in memory , explicit passthrough, query is pushed down to RDBMS */
proc cas;
	fedSql.execDirect / showStages=true query='create table prdsaleCAS as (select * from connection to sqlsrv (select country, division, month, sum(actual) as total_actual from dbo.prdsale group by country, division,month))';
quit;

/* Work on CAS table not loaded in memory , explicit passthrough, query is pushed down to RDBMS */
proc cas;
	fedSql.execDirect / showStages=true query='select * from connection to sqlsrv (select country, division, month, sum(actual) as total_actual from dbo.prdsale group by country, division,month)';
quit;


cas mysess terminate;

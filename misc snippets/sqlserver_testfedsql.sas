options set=CASCLIENTDEBUG=1;

cas mysess sessopts=(metrics=TRUE);

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

caslib _all_ assign;

data casuser.test001(drop=i) ;
   set sashelp.prdsale ;
   do i=1 to 100 ;
      output ;
   end ;
run ;

proc cas;
	fedSql.execDirect cntl={optimizeVarcharPrecision=TRUE} showStages=true query="create table test002{options replace=true} as (select * from connection to SQLSRV(SELECT * from test001))";
quit;

proc cas;
	table.save / caslib="SQLSRV" name="test001" table={caslib="SQLSRV", name="test001"} replace=true;
quit;


proc cas;
	table.fileinfo / caslib="SQLSRV";
quit;

cas mysess terminate;
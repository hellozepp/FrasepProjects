options cashost="frasepviya35smp" casport=5570 CASNCHARMULTIPLIER=2;

cas mysess;

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
	   session=FALSE;
   print r;
quit;

data SQLSRV.cars;
	set sashelp.cars;
run;

proc cas;

	table.fileinfo / caslib="SQLSRV";

quit;

proc cas;
	table.save / table={caslib='SQLSRV' name="cars"} caslib="SQLSRV" name="cars";
run;


cas mysess terminate;

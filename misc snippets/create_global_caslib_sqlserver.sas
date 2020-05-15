options cashost="frasepviya35smp" casport=5570 CASNCHARMULTIPLIER=2;

cas mysess;

proc cas;
   session mysess;

   table.dropcaslib / caslib="SQLSRV" quiet=true;

   table.addCaslib result=r /
      caslib="SQLSRV"
      datasource={srctype="sqlserver",
                  username="sqlserver",
                  password="demopw",
                  sqlserver_dsn="sqlserver_demodb",
				  charMultiplier=2,
				  catalog="demodb"}
	   session=FALSE;
   print r;
quit;


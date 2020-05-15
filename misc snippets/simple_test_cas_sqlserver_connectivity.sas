options cashost="frasepviya35smp" casport=5570 CASNCHARMULTIPLIER=2;

cas mysess;
caslib SQLservercaslib desc='Microsoft SQL Server Caslib' 
     dataSource=(srctype='sqlserver', 
                 username='sqlserver', 
                 password='demopw', 
                 sqlserver_dsn='sqlserver_demodb');

libname sqls cas caslib="SQLservercaslib";

data sqls.prdsal2(replace=yes);
	set sashelp.prdsal2;
run;

data sqls.latin1test(replace=yes);
input num1 num2 char1 $ num3;
datalines;
1 2 &#ùààààçççç  3
4 5 ùùùàààçççèèèêµ 6
;
run;

proc cas;
	table.save / caslib="SQLservercaslib" name="prdsal2" table={name="prdsal2" caslib="SQLservercaslib"} replace=true;
	table.save / caslib="SQLservercaslib" name="latin1test" table={name="latin1test" caslib="SQLservercaslib"} replace=true;
quit;


/* Example 2: Load Microsoft SQL Server Data into SAS Cloud Analytic Services Using PROC CASUTIL */

proc casutil;
   list files incaslib="SQLservercaslib";
   list files incaslib="casuser";
   contents casdata="latin1test" incaslib="SQLservercaslib";
quit;

cas mysess terminate;

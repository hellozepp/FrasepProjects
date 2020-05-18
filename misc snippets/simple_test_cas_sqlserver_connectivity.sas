options cashost="frasepviya35smp" casport=5570;

cas mysess;

caslib _all_ assign;

data SQLSRV.prdsal2(replace=yes);
	set sashelp.prdsal2;
run;

data SQLSRV.latin1test(replace=yes);
input num1 num2 char1 $ num3;
datalines;
1 2 &#ùààààçççç  3
4 5 ùùùàààçççèèèêµ 6
;
run;

proc cas;
	table.save / caslib="SQLSRV" name="prdsal2" table={name="prdsal2" caslib="SQLSRV"} replace=true;
	table.save / caslib="SQLSRV" name="latin1test" table={name="latin1test" caslib="SQLSRV"} replace=true;
quit;


/* Example 2: Load Microsoft SQL Server Data into SAS Cloud Analytic Services Using PROC CASUTIL */

proc casutil;
   list files incaslib="SQLSRV";
   list files incaslib="casuser";
   contents casdata="latin1test" incaslib="SQLSRV";
quit;

cas mysess terminate;

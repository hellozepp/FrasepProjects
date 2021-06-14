options msglevel=i; 
cas mysess sessopts=(metrics=true timeout=1800);

caslib _ALL_ assign;

proc cas;
	table.columninfo / table={name="ej", caslib="bdfdata"};
run;

proc fedsql sessref=mysess;
	select count(distinct secteur), count(distinct region) from bdfdata.ej; 
run;

/* secteur, 6 distinct values, varchar(200)
   region, 19 distinct values, char(4)
	config : for workers on VMs with 24 vpu (12 cores each)
	50 Go dataset as input 
*/

data casuser.agg_ej(copies=0 replace=yes);
	set bdfdata.ej end=done;
	by region;
	retain sum_bil_ca;
	sum_bil_ca + bil_ca;
	keep region sum_bil_ca;
	if done then output;
run;

/* TEST 1 region(char): without partitionning : 204 seconds */
/*
204 secondes
*/



proc cas;
	table.partition / table={caslib="bdfdata", name="ej", groupBy={{name="region"}}, orderBy={{name="region"}}} casout={caslib="casuser",name="ej_part", replace=true, replication=0};
run;
/*
76 secondes
*/

proc cas;
   table.tableDetails result=r / caslib="casuser", name="ej_part" level="node"; 
   print r;
run;

/* TEST 2 region(char): with partitionning on region : 173 seconds */

data casuser.agg_ej(copies=0 replace=yes);
	set casuser.ej_part end=done;
	by region;
	retain sum_bil_ca;
	sum_bil_ca + bil_ca;
	keep region sum_bil_ca;
	if done then output;
run;
/*
26 secondes
*/


/* TEST 3 secteur (varchar): without partitionning on secteur :  seconds */

data casuser.agg_ej(copies=0 replace=yes);
	set bdfdata.ej end=done;
	by secteur;
	retain sum_bil_ca;
	sum_bil_ca + bil_ca;
	keep secteur sum_bil_ca;
	if done then output;
run;

/*
282 secondes
*/

proc cas;
	table.partition / table={caslib="bdfdata", name="ej", groupBy={{name="secteur"}}, orderby={{name="secteur"}}} casout={caslib="casuser",name="ej_part", replace=true, replication=0};
run;
/*
180 secondes
*/

proc cas;
   table.tableDetails result=r / caslib="casuser", name="ej_part" level="node"; 
   print r;
run;

/* TEST 4 secteur(varchar): with partitionning on secteur :  seconds */

data casuser.agg_ej(copies=0 replace=yes);
	set casuser.ej_part end=done;
	by secteur;
	retain sum_bil_ca;
	sum_bil_ca + bil_ca;
	keep secteur sum_bil_ca;
	if done then output;
run;

/*
107 seccondes
*/

cas mysess terminate;

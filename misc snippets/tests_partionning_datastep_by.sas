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
NOTE: There were 61037936 observations read from the table EJ in caslib bdfdata.
NOTE: The table agg_ej in caslib CASUSER(viyademo01) has 17 observations and 2 variables.
NOTE: L'action 'dataStep.runBinary' a utilisé (Temps d'exécution total) :
NOTE:       temps réel              204,739550 secondes
NOTE:       temps UC                1055,667028 secondes (515,61 %)
NOTE:       durée dépl. données     79,109193 secondes
NOTE:       total nodes             5 (120 cores)
NOTE:       mémoire totale           628,76 Go
NOTE:       mémoire                 64,91 Mo (0,01 %)
NOTE:       octets dépl.            47,65 Go
*/



proc cas;
	table.partition / table={caslib="bdfdata", name="ej", groupBy={{name="region"}}, orderBy={{name="region"}}} casout={caslib="casuser",name="ej_part", replace=true, replication=0};
run;
/*
NOTE: Active Session now MYSESS.
NOTE: Executing action 'table.partition'.
NOTE: L'action 'table.partition' a utilisé (Temps d'exécution total) :
NOTE:       temps réel              76,973436 secondes
NOTE:       temps UC                588,665110 secondes (764,76 %)
NOTE:       durée dépl. données     76,573056 secondes
NOTE:       total nodes             5 (120 cores)
NOTE:       mémoire totale           628,76 Go
NOTE:       mémoire                 2,07 Go (0,33 %)
NOTE:       octets dépl.            47,65 Go
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
NOTE: There were 61037936 observations read from the table EJ_PART in caslib CASUSER(viyademo01).
NOTE: The table agg_ej in caslib CASUSER(viyademo01) has 17 observations and 2 variables.
NOTE: L'action 'dataStep.runBinary' a utilisé (Temps d'exécution total) :
NOTE:       temps réel              173,676226 secondes
NOTE:       temps UC                1019,168954 secondes (586,82 %)
NOTE:       durée dépl. données     68,599228 secondes
NOTE:       total nodes             5 (120 cores)
NOTE:       mémoire totale           628,76 Go
NOTE:       mémoire                 64,75 Mo (0,01 %)
NOTE:       octets dépl.            47,65 Go

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
Executing action 'dataStep.runBinary'.
NOTE: There were 61037936 observations read from the table EJ in caslib bdfdata.
NOTE: The table agg_ej in caslib CASUSER(viyademo01) has 7 observations and 2 variables.
NOTE: L'action 'dataStep.runBinary' a utilisé (Temps d'exécution total) :
NOTE:       temps réel              282,100915 secondes
NOTE:       temps UC                1191,804649 secondes (422,47 %)
NOTE:       durée dépl. données     76,172608 secondes
NOTE:       total nodes             5 (120 cores)
NOTE:       mémoire totale           628,76 Go
NOTE:       mémoire                 64,28 Mo (0,01 %)
NOTE:       octets dépl.            47,65 Go
*/

proc cas;
	table.partition / table={caslib="bdfdata", name="ej", groupBy={{name="secteur"}}, orderby={{name="secteur"}}} casout={caslib="casuser",name="ej_part", replace=true, replication=0};
run;
/*
NOTE: Executing action 'table.partition'.
NOTE: L'action 'table.partition' a utilisé (Temps d'exécution total) :
NOTE:       temps réel              72,809698 secondes
NOTE:       temps UC                563,687715 secondes (774,19 %)
NOTE:       durée dépl. données     72,577472 secondes
NOTE:       total nodes             5 (120 cores)
NOTE:       mémoire totale           628,76 Go
NOTE:       mémoire                 1,89 Go (0,30 %)
NOTE:       octets dépl.            47,65 Go
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
There were 61037936 observations read from the table EJ_PART in caslib CASUSER(viyademo01).
NOTE: The table agg_ej in caslib CASUSER(viyademo01) has 7 observations and 2 variables.
NOTE: L'action 'dataStep.runBinary' a utilisé (Temps d'exécution total) :
NOTE:       temps réel              248,142601 secondes
NOTE:       temps UC                1198,661474 secondes (483,05 %)
NOTE:       durée dépl. données     48,662147 secondes
NOTE:       total nodes             5 (120 cores)
NOTE:       mémoire totale           628,76 Go
NOTE:       mémoire                 64,80 Mo (0,01 %)
NOTE:       octets dépl.            47,65 Go
*/

cas mysess terminate;

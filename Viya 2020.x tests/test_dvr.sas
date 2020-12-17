/*
 Viya 2020.1
 Simple test of DVR duplicate Value reduction fro sashdat
*/

cas mysess sessopts=(metrics=true);

caslib _all_ assign;


proc cas;
table.fileinfo / caslib='public';
quit;

proc cas; 
  table.copyTable /
    table={name="fact_main" caslib="public"}
    casOut={name="fact_main_dvr" caslib="casuser" memoryFormat="DVR" replace=True replication=0};
run;

proc cas;
	table.tabledetails / caslib='public' name='fact_main';
	table.tabledetails / caslib='casuser' name='fact_main_dvr';
quit;
/* non dvr : 3661216000 bytes, with dvr : 1646036264 */

proc cas;
   simple.summary / table={name="fact_main" caslib="public" groupby={"account_id1"}}
   subset={"Mean"} inputs={"amount1" "balance1"};
run;
/*
NOTE: Active Session now MYSESS.
NOTE: Executing action 'simple.summary'.
NOTE: Action 'simple.summary' used (Total process time):
NOTE:       real time               9.676725 seconds
NOTE:       cpu time                34.420499 seconds (355.70%)
NOTE:       total nodes             1 (16 cores)
NOTE:       total memory            125.82G
NOTE:       memory                  47.75M (0.04%)
*/
proc cas;
   simple.summary / table={name="fact_main_dvr" caslib="casuser" groupby={"account_id1"}}
   subset={"Mean"} inputs={"amount1" "balance1"};
run;
/*
NOTE: Active Session now MYSESS.
NOTE: Executing action 'simple.summary'.
NOTE: Action 'simple.summary' used (Total process time):
NOTE:       real time               9.071892 seconds
NOTE:       cpu time                33.879843 seconds (373.46%)
NOTE:       total nodes             1 (16 cores)
NOTE:       total memory            125.82G
NOTE:       memory                  47.68M (0.04%)
*/
    

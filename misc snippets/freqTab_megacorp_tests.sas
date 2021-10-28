cas mysess sessopts=(metrics=true);
caslib "mycas" datasource=(srctype="PATH") path="/mnt/demo/sasdata" subdirs global;
caslib _all_ assign;
%let casdata = megacorp_20m;
	
proc cas;
	table.fileinfo / caslib="mycas";
quit;

/************************************************************************/
/* Load data into CAS if needed. Data should have been loaded in        */
/* step 1, it will be loaded here after checking if it exists in CAS    */
/************************************************************************/
proc cas;
    table.loadtable / caslib="mycas" path="&casdata..sas7bdat" casout={name="&casdata.",caslib="mycas", replace=true, replication=0};
	table.tabledetails / name="&casdata." caslib="mycas" ;
quit;

/*
proc cas;
	action freqTab.freqTab result=freqResults /
      table='hmeq',
      order='Internal',
      tabulate={{vars='BAD', cross={'reason','job','clage','clno','debtinc','loan','mortdue','value','yoj','derog','delinq','ninq'}}}
	  outputTables={includeAll=TRUE,replace=TRUE};
	run;
quit;
*/

ods trace on;
ods exclude where=(_name_ = 'CrossTabFreqs');

proc freqtab data=mycas.&casdata;
	tables ProductDescription * DateByMonth / measures;
	output out=casuser.freqout scorr ;
run;

cas mysess terminate;

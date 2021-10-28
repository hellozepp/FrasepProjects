cas mysess sessopts=(metrics=true);
caslib _all_ assign;
%let sasdata          = sampsio.hmeq;                     

/************************************************************************/
/* Load data into CAS if needed. Data should have been loaded in        */
/* step 1, it will be loaded here after checking if it exists in CAS    */
/************************************************************************/
%if not %sysfunc(exist(&casdata)) %then %do;
  proc casutil;
    load data=&sasdata casout="hmeq" outcaslib=casuser;
  run;
%end;

data casuser.hmeq(drop=i) ;
   set casuser.hmeq ;
   do i=1 to 1000 ;
      output ;
   end ;
run ;

proc cas ;
   tabledetails / table="hmeq" ;
quit ;

/*
2000 : records 11920000 / bytes:	1,239,680,000
5000 : records 29800000 : bytes:    3,0992,000,00
*/

proc cas;
	action freqTab.freqTab result=freqResults /
      table='hmeq',
      order='Internal',
      tabulate={{vars='BAD', cross={'reason','job','clage','clno','debtinc','loan','mortdue','value','yoj','derog','delinq','ninq'}}}
	  outputTables={includeAll=TRUE,replace=TRUE};
	run;
quit;
/* 5000 : 25 secondes, */

ods show;
ods exclude where=(_name_ <> 'SpearmanCorr');
ods output SpearmanCorr=casuser.SpearmanCorr;

proc freqtab data=casuser.hmeq;
	tables Bad * (reason job clage clno debtinc loan mortdue value yoj derog delinq ninq) / measures;
run;

cas mysess terminate;

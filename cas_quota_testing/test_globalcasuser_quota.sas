options set=CASCLIENTDEBUG=1;
cas benchsess sessopts=(timeout=3600 metrics=true caslib="casuser");
caslib _all_ assign;

%let sasdata          = sampsio.hmeq;                     
%let casdata          = caslib.hmeq;

%if not %sysfunc(exist(&casdata)) %then %do;
  proc casutil;
    load data=&sasdata casout="hmeq" outcaslib=casuser;
  run;
%end;

%let sizeGbFactor=14; /* Number of GB to generate */
%let techFactor=%eval(1700*&sizeGbFactor);


/************************************************************************************/
/* Generate artificially data records in casuser.hmeq personal table without copies */
/************************************************************************************/

data casuser.hmeq(drop=i copies=0 replace=yes) ;
   set casuser.hmeq ;
   do i=1 to &techFactor ;
      output ;
   end ;
run ;

/************************************************************************************/
/* Display table details                                                            */
/************************************************************************************/

proc cas;
	table.promote / sourcecaslib="casuser" name="hmeq" target="hmeq" targetcaslib="casuser";
quit;
     
cas benchsess terminate;

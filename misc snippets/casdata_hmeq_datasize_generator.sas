options set=CASCLIENTDEBUG=1;
cas benchsess sessopts=(timeout=3600 metrics=true caslib="casuser");
libname mycaslib cas caslib=casuser;
%let sasdata          = sampsio.hmeq;                     
%let casdata          = mycaslib.hmeq;

%if not %sysfunc(exist(&casdata)) %then %do;
  proc casutil;
    load data=&sasdata casout="hmeq" outcaslib=casuser;
  run;
%end;

%let sizeGbFactor=10; /* Number of GB to generate */
%let techFactor=%eval(1700*&sizeGbFactor);

%put "techFactor = " &techFactor;

data mycaslib.hmeq(drop=i copies=0 replace=yes) ;
   set mycaslib.hmeq ;
   do i=1 to &techFactor ;
      output ;
   end ;
run ;

proc cas ;
   table.tabledetails / caslib="casuser" table="hmeq" ;
quit ;

     
cas benchsess terminate;

options casdatalimit=10G;

%global castabname caslibname corrclause varclause withclause;

/* Macro to rename variable with their label */

%macro NameToLabel(data=, out=);
   %if &out= %then %let out=&data;
   proc contents noprint data=&data out=__vars;
     run;
   options validvarname=any; 
   data _null_;
     set __vars end=eof;
     if _n_ = 1 then call execute("data &out; set &data;");
     if label ne "" then do;
       label = nliteral(substr(label, 1, 32));
       call execute(trim(label) || '=' || trim(name) || ';');
	   call execute('DROP ' || trim(name) || ';');
       call symput(name,trim(label));
     end;
     else call symput(name,trim(name));
     if eof then call execute("run;");
%mend;

cas mysess;
caslib _all_ assign;

proc corr data=&caslibname..&castabname(keep=&varclause. &withclause.) &corrclause. out=out_table;
   var &varclause.;
   with &withclause.;
run;

/* Replace column name with detailed labels */
%NameToLabel(data=out_table); run;

proc json out=_webout nosastags  pretty;
  export out_table;
run;
quit;

cas mysess terminate;

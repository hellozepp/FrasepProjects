/* Global variable name which have to be declared as job input parameter */
%global castabname caslibname tablesclause table_options output_options;

/* Macro to rename variable with their label */
/* Used to replace variable name with label for json output with more explicit keys */

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

/* Initiate CAS session and assign all global caslibs to libnames to use proc freqtab with */
cas mysess;
caslib _all_ assign;

/* Execute the proc freqtab with job parameters */
proc freqtab data=&caslibname..&castabname;
	tables &tablesclause / &table_options;
	output out=out_table &output_options;
	ods exclude all;
run;

/* Replace column name with labels */
%NameToLabel(data=out_table); run;

/* Send result table to a json on the web standard output of the job */
proc json out=_webout nosastags  pretty;
  export out_table;
run;
quit;

/* Close CAS session */
cas mysess terminate;

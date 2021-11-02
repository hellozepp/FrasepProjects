%global castabname caslibname tablesclause table_options output_options;
cas mysess;
caslib _all_ assign;

proc freqtab data=&caslibname..&castabname;
	tables &tablesclause / &table_options;
	output out=out_table &output_options;
	ods exclude all;
run;

proc json out=_webout nosastags pretty;
  export out_table;
run;
quit;

cas mysess terminate;
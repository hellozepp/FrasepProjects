cas mysess sessopts=(metrics=true caslib=casuser);

caslib _all_ assign;

data casuser.cars(copies=0);
	set sashelp.cars;
run;

proc fedsql sessref=mysess;
	create table casuser.cars_agg {options replication=0 replace=true} as select count(*) from casuser.cars;
run;

cas mysess terminate;
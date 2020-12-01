cas mysess;

caslib _all_ assign;

data casuser.HMEQ;
set public.hmeq;
run;

proc cas;

table.alterTable / 
	caslib="casuser"
	columns={{name="BAD",rename="bad"}, {name="CLAGE",rename="clage"}}
	name="hmeq";
quit;

cas mysess terminate;

cas mysess sessopts=(metrics=true);

caslib _all_ assign;

proc cas;
	table.fileinfo / caslib="s3fs";
quit;

data casuser.hmeq(drop=i) ;
   set sampsio.hmeq ;
   do i=1 to 1000 ;
      output ;
   end ;
run ;

proc cas;
	table.promote /   drop=TRUE name="hmeq" target="hmeq" targetLib="s3fs"; 
quit;

proc cas;
	table.save / caslib="s3fs" name="hmeq.sashdat" table={caslib="s3fs",name="hmeq"} replace=true;
quit;

proc cas;
	table.droptable / caslib="s3fs" name="hmeq" quiet=true;
	table.loadtable / caslib="s3fs" path="hmeq.sashdat" casout={name="hmeq" caslib="s3fs" promote=true};
quit;

cas mysess terminate;

/*

options sastrace=',,,d' sastraceloc=saslog;

proc s3 config="/home/viyademo01/.tks3.conf";
	REGION ADD HOST="frasepviya35smp.cloud.com" NAME="fr-local-frasep" PORT=9000 REPLACE;
	REGION LIST;
run;
quit;

proc s3 region="fr-local-frasep";
   list "/datalake";
run;


*/


options sastrace='d,d,,d' sastraceloc=saslog nostsuffix sql_ip_trace=(note,source) msglevel=i fullstimer ;

libname mongosas mongo server="192.168.1.32" port=27017 db='db' trace=YES TRACEFLAGS=ALL TRACEFILE="/tmp/test_mongo.trc";

cas mysess;

caslib mongocas desc='MongoDB Caslib' dataSource=(srctype='mongodb' server='192.168.1.32' db="db" port=27017);

caslib _all_ assign;

proc cas;
	table.fileinfo / caslib='mongocas';
quit;

PROC SQL;
     CREATE TABLE CALCUL_R84_2020M12 as 
     select item from mydb.inventory2_flat where status="D";
QUIT;

/* FEDSQL on SAS 9 libname */

proc fedsql libs=(mongosas);
     create table inventory as
     select * from connection to mongosas
	 (inventory2.find({"status":"D"}));
quit;

proc fedsql;
   execute (refresh) by mongosas;
quit;

/* FEDSQL on CASLIB libname */
/* pas de passthrough fedsql ? */
proc fedsql sessref=mysess;
     create table casuser.inventory as
     select * from connection to mongocas(db.inventory2.find({"status":"D"}));
quit;


cas mysess terminate;

options sastrace='d,d,,d' sastraceloc=saslog nostsuffix sql_ip_trace=(note,source) msglevel=i fullstimer ;

libname mongosas mongo server="192.168.1.32" port=27017 db='db' trace=YES TRACEFLAGS=ALL TRACEFILE="/tmp/test_mongo.trc" SCHEMA_COLLECTION='$temp$';

/******************************/
/* Refresh default sas schema */

proc fedsql;
   execute (refresh) by mongosas;
quit;

cas mysess;

caslib mongocas desc='MongoDB Caslib' dataSource=(srctype='mongodb' server='192.168.1.32' db="db" port=27017);

caslib _all_ assign;

proc cas;
	table.fileinfo / caslib='mongocas';
quit;

PROC SQL;
     CREATE TABLE CALCUL_R84_2020M12 as 
     select * from mongosas.inventory2 where status="D";
QUIT;

/***************************/
/* FEDSQL on SAS 9 libname */

proc fedsql;
     select * from connection to mongosas(db.inventory2.find({}));
quit;

/****************************/
/* FEDSQL on CASLIB libname */
/* pas de passthrough fedsql ? */

proc fedsql sessref=mysess;
     select * from connection to mongocas(inventory2.find({"status":"D"}));
quit;

proc cas;
fedsql.execdirect / query="" requireFullPassThrough=TRUE;
quit;


cas mysess terminate;

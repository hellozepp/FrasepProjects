/* Specify a host and port that are valid for your site.*/
*options cashost="cloud.example.com" casport=5570;  

/* If not already done, start session Casauto. */ 
cas sessiomgmt001;        

proc cas;
    session sessiomgmt001;
    accessControl.assumeRole / adminRole="superuser";        
    builtins.getCacheInfo result=results;  
    describe results;
run;
    print results.diskCacheInfo;
run;
quit;

proc cas;
	session sessiomgmt001;
	session.listSessions result=r;
	print r;
quit;

/* Recuperation des sessions sans action en cours */

proc cas;
   session sessiomgmt001;

   session.listSessions result=r;                    /*  */
   actstat = 0;
   uuid = "";
   do i=1 to r.Session.nrows;
   	name = substr(r.Session[i][1], 1, index(r.Session[i][1], ":") - 1);
    uuid = r.Session[i]["UUID"];
    session.actionstatus result=r_act / uuid=uuid;  /*  */
    actstat = r_act.status[1]["Active"];
    print name || ":" || actstat ;
	*if actstasession.endSession sessref=name;
  end;
run;
quit;

cas sessiomgmt001 terminate;

/* Launch streaming data subscriptions in parallel sessions to trade demo on all necessary windows */
/* output : streamTrades and streamTotalCost in caslib public */

options cashost="frasepviya35smp" casport=5570;

cas master sessopts=(caslib="casuser" timeout=1800) ;
cas background1 sessopts=(caslib="casuser" timeout=1800) ;
cas background2 sessopts=(caslib="casuser" timeout=1800) ;

options sessref=master ;

/* Output table cleanup */

/* cleanup*/
proc cas ;
   session master ;
   print "Before drop" timestamp() ;
   table.droptable / caslib='public' name='streamTrades' quiet=true;
   table.droptable / caslib='public' name='streamTotalCost' quiet=true;
   print "After drop" timestamp() ;
run ;
quit ;


/* parallel */
proc cas ;
   session master ;
   print "Beginning Streaming trades data capture in CAS... " timestamp() ;

   action table.addCaslib session="background1" async="job1" /
	      dataSource={
				port=5555,
				server="frasepviya35smp.c.sas-frasep.internal",
				srcType="esp"}
	      name="espStatic";
	run;

   action table.addCaslib session="background2" async="job2" /
	      dataSource={
				port=5555,
				server="frasepviya35smp.c.sas-frasep.internal",
				srcType="esp"}
	      name="espStatic";
	run;

	action loadStreams.loadStream session="background1" async="job1" /
	      casLib="espStatic"
	      espUri="trades/trades_cq/Trades"  
	      casOut={caslib="public", name="streamTrades", promote=true}
		  commitValue=1;
	run;

	action loadStreams.loadStream session="background2" async="job2"/
	      casLib="espStatic"
	      espUri="trades/trades_cq/TotalCost"  
	      casOut={caslib="public", name="streamTotalCost", promote=true}
		  commitValue=1;
	run;
 
   job = wait_for_next_action(0) ;
   do while (job) ;
      print "*** " job.job " ***" ;
      print "end ***** " job.job " " timestamp() ;
      print job.logs ;
      job = wait_for_next_action(0) ;
   end ;
   
   print "end Streaming data. " timestamp() ;
run ;
quit ;

cas _all_ terminate;


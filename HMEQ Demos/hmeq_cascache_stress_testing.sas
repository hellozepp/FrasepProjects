options cashost="frasepviya35smp.cloud.com" casport=5570;
options set=CASCLIENTDEBUG=1;

cas master sessopts=(caslib="casuser" timeout=10) ;
cas background1 sessopts=(caslib="casuser" timeout=10) ;
cas background2 sessopts=(caslib="casuser" timeout=10) ;
cas background3 sessopts=(caslib="casuser" timeout=10) ;
cas background4 sessopts=(caslib="casuser" timeout=10) ;

libname mycaslib cas caslib=casuser;
%let sasdata          = sampsio.hmeq;
%let casdata          = mycaslib.hmeq;
%let sizeMultiplier   = 1000; /* Baseline : 100 = 59,1 Mo */
                 
%if not %sysfunc(exist(&casdata)) %then %do;
  proc casutil;
    load data=&sasdata casout="hmeq" outcaslib=casuser promote;
  run;
%end;

proc cas ;

   testcode="
			data casuser.hmeqTest(drop=i) ;
			   set casuser.hmeq ;
			   do i=1 to " || &sizeMultiplier || " ;
			      output ;
			   end ;
			run ;";

   session master ;
   print "************************************************************";
   print "Beginning cascache stress test ... " timestamp() ;
   print "************************************************************";

   dataStep.runCode session="background1" async="job1" / code=testcode nThreads="MAX";
   dataStep.runCode session="background2" async="job2" / code=testcode nThreads="MAX";
   dataStep.runCode session="background3" async="job3" / code=testcode nThreads="MAX";
   dataStep.runCode session="background4" async="job4" / code=testcode nThreads="MAX";

   job = wait_for_next_action(0) ;
   do while (job) ;
      print "*** " job.job " ***" ;
      print "end ***** " job.job " " timestamp() ;
      print job.logs ;
      job = wait_for_next_action(0) ;
   end ;
   print "************************************************************";
   print "end Beginning cascache stress test." timestamp() ;
   print "************************************************************";
run ;
quit ;


proc cas;

	session background1;
   	/**************** function to get a simple table with the cas table actual size in MB and the number of rows ****************/
	function get_table_size(caslib,castab_name);
			table.tabledetails result=r/ caslib=caslib name=castab_name;
			out_table = newtable("CAS Table size", {"Size in MB", "Number of rows"}, {"integer", "integer"});
			addrow(out_table, {r.TableDetails[1].Datasize/1024/1024, r.TableDetails[1].Rows});
			print out_table;
	end;
   print "Test table size :"
   get_table_size("casuser","hmeqTest");
   run;
   accessControl.assumeRole / adminRole="superuser";
   builtins.getCacheInfo result=results;
   run;

	print results.diskCacheInfo;
run;
quit;

cas _all_ terminate;


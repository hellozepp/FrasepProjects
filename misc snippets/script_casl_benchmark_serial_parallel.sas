options cashost="sepviya35.aws.sas.com" casport=5570;

cas master sessopts=(caslib="PUBLIC") ;
cas background1 sessopts=(caslib="PUBLIC") ;
cas background2 sessopts=(caslib="PUBLIC") ;

options sessref=master ;

libname casdm cas caslib="PUBLIC" ;

/* cleanup*/
proc cas ;
   session master ;
   print "beginning" timestamp() ;
   table.dropTable / caslib="PUBLIC" name="bigprdsale" quiet=true ;
   table.dropTable / caslib="PUBLIC" name="bigprdsale_aggregate1" quiet=true ;
   table.dropTable / caslib="PUBLIC" name="bigprdsale_aggregate2" quiet=true ;
   table.dropTable / caslib="PUBLIC" name="bigprdsale_summary" quiet=true ;
   print "after drop" timestamp() ;
run ;
quit ;

data casdm.bigprdsale(drop=i promote=yes) ;
   set sashelp.prdsale ;
   do i=1 to 100000 ;
      output ;
   end ;
run ;

/*
proc casutil ;
   load data=bigprdsale casout="bigprdsale" promote ;
quit ;
*/

proc cas ;
   tabledetails / table="bigprdsale" ;
quit ;

/* serial */
proc cas ;
   session master ;
   print "beginning ***** " timestamp() ;
   aggregation.aggregate result=r status=s /
      table={caslib="PUBLIC",
         name="bigprdsale",
         groupBy={"country","product","prodtype"},
         vars={"actual","predict"}
         },
      varSpecs={{name='PREDICT', summarySubset={'SUM'}, columnNames={'PREDICT'}}
      {name='ACTUAL', summarySubset={'SUM'}, columnNames={'ACTUAL'}}}
      casout={caslib="PUBLIC", name="bigprdsale_aggregate1", promote=True, replication=0};
   print s ;
   print "end aggregate 1 ***** " timestamp() ;
   aggregation.aggregate result=r status=s /
      table={caslib="PUBLIC",
         name="bigprdsale",
         groupBy={"country","product","prodtype"},
         vars={"actual","predict"}
         },
      varSpecs={{name='PREDICT', summarySubset={'SUM'}, columnNames={'PREDICT'}}
      {name='ACTUAL', summarySubset={'SUM'}, columnNames={'ACTUAL'}}}
      casout={caslib="PUBLIC", name="bigprdsale_aggregate2", promote=True, replication=0};
   print s ;
   print "end aggregate 2 ***** " timestamp() ;
   simple.summary result=r status=s /
      inputs={"actual","predict"},
      subSet={"SUM"},
      table={caslib="PUBLIC",
         name="bigprdsale",
         groupBy={"country","product","prodtype"}
         },
      casout={caslib="PUBLIC", name="bigprdsale_summary", promote=True, replication=0};
   print s ;
   print "end summary ***** " timestamp() ;
run ;
quit ;

/* cleanup*/
proc cas ;
   session master ;
   print "beginning" timestamp() ;
   table.dropTable / caslib="PUBLIC" name="bigprdsale_aggregate1" quiet=true ;
   table.dropTable / caslib="PUBLIC" name="bigprdsale_aggregate2" quiet=true ;
   table.dropTable / caslib="PUBLIC" name="bigprdsale_summary" quiet=true ;
   print "after drop" timestamp() ;
run ;
quit ;

/* parallel */
proc cas ;
   session master ;
   print "beginning ***** " timestamp() ;
   aggregation.aggregate result=r status=s session="background1" async="job1" /
      table={caslib="PUBLIC",
         name="bigprdsale",
         groupBy={"country","product","prodtype"},
         vars={"actual","predict"}
         },
      varSpecs={{name='PREDICT', summarySubset={'SUM'}, columnNames={'PREDICT'}}
      {name='ACTUAL', summarySubset={'SUM'}, columnNames={'ACTUAL'}}}
      casout={caslib="PUBLIC", name="bigprdsale_aggregate1", promote=True, replication=0};
      
   aggregation.aggregate result=r status=s session="background2" async="job2" /
      table={caslib="PUBLIC",
         name="bigprdsale",
         groupBy={"country","product","prodtype"},
         vars={"actual","predict"}
         },
      varSpecs={{name='PREDICT', summarySubset={'SUM'}, columnNames={'PREDICT'}}
      {name='ACTUAL', summarySubset={'SUM'}, columnNames={'ACTUAL'}}}
      casout={caslib="PUBLIC", name="bigprdsale_aggregate2", promote=True, replication=0};
      
   job = wait_for_next_action(0) ;
   do while (job) ;
      print "*** " job.job " ***" ;
      print "end ***** " job.job " " timestamp() ;
      print job.logs ;
      job = wait_for_next_action(0) ;
   end ;
   
   simple.summary result=r status=s /
      inputs={"actual","predict"},
      subSet={"SUM"},
      table={caslib="PUBLIC",
         name="bigprdsale",
         groupBy={"country","product","prodtype"}
         },
      casout={caslib="PUBLIC", name="bigprdsale_summary", promote=True, replication=0};
   print s ;
   print "end ***** " timestamp() ;
run ;
quit ;

/* cleanup*/
proc cas ;
   session master ;
   print "beginning" timestamp() ;
   table.dropTable / caslib="PUBLIC" name="bigprdsale" quiet=true ;
   table.dropTable / caslib="PUBLIC" name="bigprdsale_aggregate1" quiet=true ;
   table.dropTable / caslib="PUBLIC" name="bigprdsale_aggregate2" quiet=true ;
   table.dropTable / caslib="PUBLIC" name="bigprdsale_summary" quiet=true ;
   print "after drop" timestamp() ;
run ;
quit ;

cas _all_ terminate;


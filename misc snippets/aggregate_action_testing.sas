cas casauto;
caslib _all_ assign;

data casuser.timedata;
	set sashelp.timedata;
run;

data casuser.prdsale;
	set sashelp.prdsale;
	retain id 0;
	id=id+1;
run;

proc cas ;
   aggregation.aggregate result=r status=s /
      table={
         name="prdsale",
         groupBy={"country","product","prodtype","id"},
         vars={"actual","predict"}
      },
      varSpecs={
         {name='PREDICT', summarySubset={'SUM'}, columnNames={'PREDICT'}}
         {name='ACTUAL', summarySubset={'SUM'}, columnNames={'ACTUAL'}}
      },
	  id="id",
      bin={5,15},
      casout={name="prdsale_aggregate", replace=True, replication=0} ;
quit ;

cas casauto terminate;
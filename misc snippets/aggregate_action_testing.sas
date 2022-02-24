cas casauto;
caslib _all_ assign;

data casuser.prdsale;
	set sashelp.prdsale;
	format id date9.;
	retain idt 0;
	id='17oct1991'd + idt;
	idt=idt+1;
	drop idt;
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
      interval="DAY",
	  offset=3,
      casout={name="prdsale_aggregate", replace=True, replication=0} ;
quit ;

proc cas ;
   aggregation.aggregate result=r status=s /
      table={
         name="prdsale",
         groupBy={"country","id"},
         vars={"actual"}
      },
      varSpecs={
         {name='PREDICT', summarySubset={'SUM'}, columnNames={'PREDICT'}}
         {name='ACTUAL', summarySubset={'SUM'}, columnNames={'ACTUAL'}}
      },
	  id="id",
	  raw="TRUE",
      interval="WEEK",
      casout={name="prdsale_aggregate", replace=True, replication=0} ;
quit ;

cas casauto terminate;
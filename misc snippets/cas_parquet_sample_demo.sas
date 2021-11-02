cas mysess_parquet sessopts=(metrics=true);

caslib _ALL_ assign;

proc cas;
	table.fileinfo / caslib="mydata" allfiles=true includedirectories=true;
	table.fileinfo / caslib="dnfs" allfiles=true includedirectories=true;
quit;

/*
proc cas;
	table.loadtable / caslib="mydata" path="megacorp5_4m.sas7bdat" casout={name="megacorp5_4m", caslib="mydata"} ;
	table.tabledetails / caslib="mydata" name="megacorp5_4m";
quit;

/* SASHDAT datasize in bytes : 1881513088 */
/*
proc cas;
	table.save / caslib="mydata" name="megacorp5_4m.parquet" table={caslib="mydata",name="megacorp5_4m"} replace=true;
	table.save / caslib="mydata" name="megacorp5_4m.sashdat" table={caslib="mydata",name="megacorp5_4m"} replace=true;
quit;
*/

proc cas;
	table.tabledetails / table={caslib="dnfs", name='megacorp5_4m.parquet'};
	table.columninfo / table={caslib="dnfs", name='megacorp5_4m.parquet'};
quit;


proc cas ;
   simple.summary result=r status=s /
      inputs={"Revenue","UnitCapacity"},
      subSet={"SUM"},
      table={
         caslib="mydata",
         name="megacorp5_4m.sashdat",
         groupBy={"FacilityRegion","product","ProductLine"}
      },
      casout={caslib="casuser",name="prdsale_summary",replace=True,replication=0} ;
quit ;
/*
NOTE: Active Session now MYSESS_PARQUET.
NOTE: Executing action 'table.loadTable'.
NOTE: Action 'table.loadTable' used (Total process time):
NOTE:       real time               4.601327 seconds
NOTE:       cpu time                1.433496 seconds (31.15%)
NOTE:       total nodes             1 (16 cores)
NOTE:       total memory            62.67G
NOTE:       memory                  1.12M (0.00%)
NOTE: Executing action 'simple.summary'.
NOTE: Action 'simple.summary' used (Total process time):
NOTE:       real time               4.912125 seconds
NOTE:       cpu time                4.856973 seconds (98.88%)
NOTE:       total nodes             1 (16 cores)
NOTE:       total memory            62.67G
NOTE:       memory                  3.84M (0.01%)
NOTE: PROCEDURE CAS used (Total process time):
      real time           4.91 seconds
      cpu time            0.04 seconds
*/

proc cas ;
   simple.summary result=r status=s /
      inputs={"Revenue","UnitCapacity"},
      subSet={"SUM"},
      table={
         caslib="dnfs",
         name="megacorp5_4m.parquet",
         groupBy={"FacilityRegion","product","ProductLine"}
      },
      casout={caslib="casuser",name="prdsale_summary",replace=True,replication=0} ;
quit ;
/* 
NOTE: Active Session now MYSESS_PARQUET.
NOTE: Executing action 'table.loadTable'.
NOTE: Action 'table.loadTable' used (Total process time):
NOTE:       real time               0.007036 seconds
NOTE:       cpu time                0.007025 seconds (99.84%)
NOTE:       total nodes             1 (16 cores)
NOTE:       total memory            62.67G
NOTE:       memory                  669.97K (0.00%)
NOTE: Executing action 'simple.summary'.
NOTE: Action 'simple.summary' used (Total process time):
NOTE:       real time               0.345062 seconds
NOTE:       cpu time                4.530100 seconds (1312.84%)
NOTE:       total nodes             1 (16 cores)
NOTE:       total memory            62.67G
NOTE:       memory                  38.31M (0.06%)
NOTE: PROCEDURE CAS used (Total process time):
      real time           0.35 seconds
      cpu time            0.02 seconds
 */

proc cas ;
   simple.summary result=r status=s /
      inputs={"Revenue","UnitCapacity"},
      subSet={"SUM"},
      table={
         caslib="mydata",
         name="megacorp5_4m.sas7bdat",
         groupBy={"FacilityRegion","product","ProductLine"}
      },
      casout={caslib="casuser",name="prdsale_summary",replace=True,replication=0} ;
quit ;

/* 
NOTE: Active Session now MYSESS_PARQUET.
NOTE: Executing action 'table.loadTable'.
NOTE: Action 'table.loadTable' used (Total process time):
NOTE:       real time               9.011099 seconds
NOTE:       cpu time                7.449212 seconds (82.67%)
NOTE:       total nodes             1 (16 cores)
NOTE:       total memory            62.67G
NOTE:       memory                  19.65M (0.03%)
NOTE: Executing action 'simple.summary'.
NOTE: Action 'simple.summary' used (Total process time):
NOTE:       real time               9.603449 seconds
NOTE:       cpu time                10.891424 seconds (113.41%)
NOTE:       total nodes             1 (16 cores)
NOTE:       total memory            62.67G
NOTE:       memory                  19.86M (0.03%)
NOTE: PROCEDURE CAS used (Total process time):
      real time           9.60 seconds
      cpu time            0.05 seconds
*/

cas mysess_parquet terminate;

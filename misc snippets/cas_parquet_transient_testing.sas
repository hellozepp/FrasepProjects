cas mysess_parquet sessopts=(metrics=true);

caslib _ALL_ assign;

proc cas;
	table.fileinfo / caslib="mydata" allfiles=true includedirectories=true;
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
NOTE: Active Session now MYSESS.
NOTE: Executing action 'table.loadTable'.
NOTE: Action 'table.loadTable' used (Total process time):
NOTE:       real time               0.572754 seconds
NOTE:       cpu time                0.572079 seconds (99.88%)
NOTE:       total nodes             1 (16 cores)
NOTE:       total memory            62.67G
NOTE:       memory                  1.14M (0.00%)
NOTE: Executing action 'simple.summary'.
NOTE: Action 'simple.summary' used (Total process time):
NOTE:       real time               0.893936 seconds
NOTE:       cpu time                3.626003 seconds (405.62%)
NOTE:       total nodes             1 (16 cores)
NOTE:       total memory            62.67G
NOTE:       memory                  3.84M (0.01%)
NOTE: PROCEDURE CAS used (Total process time):
      real time           0.90 seconds
      cpu time            0.03 seconds
*/

proc cas ;
   simple.summary result=r status=s /
      inputs={"Revenue","UnitCapacity"},
      subSet={"SUM"},
      table={
         caslib="mydata",
         name="megacorp5_4m.parquet",
         groupBy={"FacilityRegion","product","ProductLine"}
      },
      casout={caslib="casuser",name="prdsale_summary",replace=True,replication=0} ;
quit ;
/* 
NOTE: Active Session now MYSESS.
NOTE: Executing action 'table.loadTable'.
NOTE: Action 'table.loadTable' used (Total process time):
NOTE:       real time               0.007409 seconds
NOTE:       cpu time                0.007399 seconds (99.87%)
NOTE:       total nodes             1 (16 cores)
NOTE:       total memory            62.67G
NOTE:       memory                  669.97K (0.00%)
NOTE: Executing action 'simple.summary'.
NOTE: Action 'simple.summary' used (Total process time):
NOTE:       real time               0.354429 seconds
NOTE:       cpu time                4.519786 seconds (1275.23%)
NOTE:       total nodes             1 (16 cores)
NOTE:       total memory            62.67G
NOTE:       memory                  38.31M (0.06%)
NOTE: PROCEDURE CAS used (Total process time):
      real time           0.36 seconds
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

NOTE: Active Session now MYSESS.
NOTE: Executing action 'table.loadTable'.
NOTE: Action 'table.loadTable' used (Total process time):
NOTE:       real time               7.186072 seconds
NOTE:       cpu time                7.097319 seconds (98.76%)
NOTE:       total nodes             1 (16 cores)
NOTE:       total memory            62.67G
NOTE:       memory                  19.63M (0.03%)
NOTE: Executing action 'simple.summary'.
NOTE: Action 'simple.summary' used (Total process time):
NOTE:       real time               9.911314 seconds
NOTE:       cpu time                11.363916 seconds (114.66%)
NOTE:       total nodes             1 (16 cores)
NOTE:       total memory            62.67G
NOTE:       memory                  19.85M (0.03%)
NOTE: PROCEDURE CAS used (Total process time):
      real time           9.91 seconds
      cpu time            0.04 seconds

*/


cas mysess_parquet terminate;

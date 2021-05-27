cas mysess_parquet sessopts=(metrics=true);

caslib _ALL_ assign;

proc cas;
	table.fileinfo / caslib="bdfrisq" allfiles=true includedirectories=true;
quit;

proc cas;
	table.columninfo / table={caslib="bdfrisq" name="central_risq.parquet"};
quit;

proc cas ;
   simple.summary result=r status=s /
      inputs={"MT_RUB1_DECL","MT_RUB2_DECL","MT_RUB3_DECL","MT_RUB4_DECL"},
      subSet={"SUM"},
      table={
         caslib="bdfrisq",
         name="central_risq.parquet",
         groupBy={"GUICHET_DECLA"},
		 where="GUICHET_DECLA in ('01648','01440')"
      },
      casout={caslib="casuser",name="central_risq_summary",replace=True,replication=0} ;
quit ;

proc cas;
   simple.crossTab /
      row="GUICHET_DECLA",
      col="MT_RUB1_DECL",
      aggregator="MEAN",
       table={
         caslib="bdfrisq",
         name="central_risq.parquet",
		 where="GUICHET_DECLA in ('01648','01440')"
      };
run;
quit;

cas mysess_parquet terminate;

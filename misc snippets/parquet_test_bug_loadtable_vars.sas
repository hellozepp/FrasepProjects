cas mysess;

/* Add path library to read parquet files */
proc cas;
	table.dropcaslib / caslib='parquets' quiet=true;
	table.addcaslib / dataSource={srcType='PATH'} path='/data/data/parquets' caslib='parquets' session=false;
quit;

caslib _ALL_ assign;


proc cas;
	table.fileinfo / caslib="parquets";
	table.columninfo / table={caslib="parquets" name="p1.parquet"};
run;

/*****************************************************/
/* Load full parquet file without any vars statement */
proc cas;
	table.loadtable /  
		caslib="parquets" 
		casout={caslib="parquets",name="p1"}
		path="p1.parquet"
		importoptions={filetype='PARQUET'};
run;
/*****************************************************/
/* RESULT : OK */

/********************************************************************************************/
/* Load partial parquet file with vars statement on CO1_IDF_COLLAT and CO0_DAT_ARR varchars */
proc cas;
	table.loadtable /  
		caslib="parquets" 
		casout={caslib="parquets",name="p2"}
		path="p1.parquet"
		importoptions={filetype='PARQUET'}
		vars={{name="CO0_DAT_ARR",label="CO0_DAT_ARR"},{name="CO1_IDF_COLLAT",label="CO1_IDF_COLLAT"}};
run;
/**************************************************************************************************/
/* RESULT : NOK, truncated columns in CAS, CO0_DAT_ARR with only 1 bytes instead of 10 in source  */
/**************************************************************************************************/

proc cas;
	table.loadtable /  
		caslib="parquets" 
		casout={caslib="parquets",name="p3"}
		path="p1.parquet"
		importoptions={filetype='PARQUET'}
		vars={{name="CO1_IDF_COLLAT"},{name="CO2_COD_COLLAT"}};
run;

proc cas;
	table.loadtable /  
		caslib="parquets" 
		casout={caslib="parquets",name="p4"}
		path="p1.parquet"
		importoptions={filetype='PARQUET'}
		vars={{name="CO2_COD_COLLAT"},{name="CO1_IDF_COLLAT"}};
run;

cas mysess terminate;


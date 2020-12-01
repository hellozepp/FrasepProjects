options cashost="frasepviya35smp" casport=5570;

cas mysess;

caslib _all_ assign;

/************************************************************************************/
/* Load in-memory all model performance tables and drop all existing datamart table */
/************************************************************************************/

proc cas;
	table.fileinfo result=listfiles / caslib="ModelPerformanceData";
	
	do row over listfiles.fileinfo[1:listfiles.fileinfo.nrows];
		if (index(upcase(row.Name),'.MM_')<>0) then do;
			datafile=row.Name;
			tableNameLength=index(row.Name,".sashdat")-1;
			tablename=substr(row.Name, 1, tableNameLength);
			projectID=scan(tablename,1,'.');
			PerfDataTimestamp=row.Time;
			dtmTableName=scan(tablename,2,'.');
			
			table.tableExists result=tableExistsFlag / caslib="ModelPerformanceData" name=tablename;
 			if tableExistsFlag.exists=0 then table.loadTable / casout={caslib="ModelPerformanceData" name=tablename} caslib="ModelPerformanceData" path=datafile;
		end; 
	end;
quit;

/*******************************************************************/
/* Create the model performance datamart (containing all projects) */
/*******************************************************************/

proc cas;

	function appendTable(inputcaslib, inputcastab, outputcaslib, outputcastab, projectid, perftime);
		codeds="data """ || outputcastab || """(caslib=""" || outputcaslib || """ append=yes); set """ || inputcastab || """(caslib=""" || inputcaslib || """); project_ID=""" || projectid ||""";  project_perf_time=""" || perftime || """; run;";
		print codeds;
 		dataStep.runCode / code=codeds;
	end;

	table.fileinfo result=listfiles / caslib="ModelPerformanceData";
	
	do row over listfiles.fileinfo[1:listfiles.fileinfo.nrows];
		if (index(upcase(row.Name),'.MM_')<>0) then do;
			datafile=row.Name;
			tableNameLength=index(row.Name,".sashdat")-1;
			tablename=substr(row.Name, 1, tableNameLength);
			projectID=scan(tablename,1,'.');
			dtmTableName=scan(tablename,2,'.');
			appendTable("ModelPerformanceData",tablename,"casuser",dtmtablename, projectID);
		end; 
	end;

quit;

proc cas;
	table.tableinfo result=listfiles / caslib="casuser";
	do row over listfiles.tableinfo[1:listfiles.tableinfo.nrows];
		table.tableExists result=tableExistsFlag / caslib="public" name=row.Name;
		if tableExistsFlag.exists=2 then table.droptable / caslib="public" name=row.Name;
		table.promote / caslib="casuser" name=row.Name target=row.Name targetlib="public";
	end;
quit;


cas mysess terminate;

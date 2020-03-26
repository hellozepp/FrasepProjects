options cashost="sepviya35.aws.sas.com" casport=5570;

cas mysess;

caslib _all_ assign;

proc cas;

	function appendTable(input, output, projectid, perftime);
		codeds=	"data " || output || "(append=yes); set " || input || "; project_ID=""" || projectid ||""";  project_perf_time=""" || perftime || """; run;";
		print codeds;
		dataStep.runCode result=r status=rc / code=codeds;
	end;

	table.fileinfo result=listfiles / caslib="ModelPerformanceData";
	
	print listfiles;

	do row over listfiles.fileinfo[1:listfiles.fileinfo.nrows];
		if (index(upcase(row.Name),'.MM_')<>0) then do;
			datafile=row.Name;
			tableNameLength=index(row.Name,".sashdat")-1;
			tablename=substr(row.Name, 1, tableNameLength);
			projectID=scan(tablename,1,'.');
			PerfDataTimestamp=row.Time;
			dtmTableName=scan(tablename,2,'.');
			table.tableExists result=tableExistsFlag / caslib="public" name=dtmTableName;
			if tableExistsFlag.exists=1 then table.droptable / caslib="public" name=dtmTableName;
			fullInputName="ModelPerformanceData."||tablename;
			fullOutputName="public."||dtmTableName;
			appendTable(fullInputName,fullOutputName, projectID,PerfDataTimestamp);

/* 			table.loadTable / casout={caslib="ModelPerformanceData" name=tablename promote=true} caslib="ModelPerformanceData" path=datafile; */
			print tablename " " projectID " " PerfDataTimestamp " " dtmTableName " " tableExistsFlag.exists " " fullInputName;
		end; 
	end;
quit;

cas mysess terminate;

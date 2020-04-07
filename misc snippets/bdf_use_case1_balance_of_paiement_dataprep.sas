/*****************************************************************************/
/*****************************************************************************/

cas mySession sessopts=(metrics=true);
caslib myCaslib datasource=(srctype="dnfs") path="/data/data" sessref=mySession subdirs;
libname myCaslib cas;

caslib _all_ assign;

/* Scan the input directory for .csv files */
proc cas;
	table.fileinfo result=listfiles / caslib="myCaslib";
	do row over listfiles.fileinfo[1:listfiles.fileinfo.nrows];
		if (index(row.Name,'.csv')<>0) then do;
			datafile=row.Name;
			tablename=scan(row.Name,1);
			table.droptable / caslib="public" name=tablename quiet=true;
			table.loadTable / 
				casout={caslib="public" name=tablename promote=true} 
				caslib="myCaslib" 
				path=datafile 
				importoptions={delimiter=";" filetype="csv" guessRows=10000 getnames=true varchars=true stripblanks=true nThreads=8};
			table.columninfo / table={caslib="public" name=tablename} ;
			table.tableinfo / caslib="public" name=tablename ;
		end;
	end;
quit;


cas mySession terminate;
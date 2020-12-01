/* Loal all mydata sas7bdat lat9 and utf8 and sashdat data in public */

options cashost="frasepviya35smp" casport=5570;

cas mysess sessopts=(metrics=true);

caslib _all_ assign;

proc cas;
	table.fileinfo result=listfiles / caslib="mydata";
	do row over listfiles.fileinfo[1:listfiles.fileinfo.nrows];
		if (index(row.Name,'.sas7bdat')<>0) then do;
			datafile=row.Name;
			tablename=scan(row.Name,1);
			table.droptable / caslib="public" name=tablename quiet=true;
			table.loadTable / casout={caslib="public" name=tablename promote=true} caslib="mydata" path=datafile
			importOptions={filetype="basesas", varcharConversion=16};
		end;

		if (index(row.Name,'.sashdat')<>0) then do;
			datafile=row.Name;
			tablename=scan(row.Name,1);
			table.droptable / caslib="public" name=tablename quiet=true;
			table.loadTable / casout={caslib="public" name=tablename promote=true} caslib="mydata" path=datafile;
		end;
	end;
quit;

cas mysess terminate;


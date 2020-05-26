/*****************************************************************************/

%let INPATH="/data/dvf";
%let FILEWILDCARD="full%.csv";
%let FINALTABLE="FULLDVF";
%let DELIM=",";

/*****************************************************************************/

cas mySession sessopts=(metrics=true timeout=3600);
caslib myCaslib datasource=(srctype="dnfs") path=&INPATH sessref=mySession subdirs;
libname myCaslib cas;

caslib _all_ assign;

/*****************************************************************************/
/* Scan the input directory for .csv files */

proc cas;
	table.fileinfo result=listfiles / caslib="myCaslib" path=&FILEWILDCARD;
	listTable="";
	do row over listfiles.fileinfo[1:listfiles.fileinfo.nrows];
		datafile=row.Name;
		tablename=scan(row.Name,1);
		listTable=listTable || " casuser." || tablename;
		table.droptable / caslib="casuser" name=tablename quiet=true;
		table.loadTable / 
			casout={caslib="casuser" name=tablename promote=true} 
			caslib="myCaslib"
			path=datafile 
			importoptions={delimiter=&DELIM filetype="csv" guessRows=50000 getnames=true varchars=true stripblanks=true};
	end;
	
	codeMerge="data public." || &FINALTABLE || "(promote=yes); set " || listTable || "; run;";
	datastep.runCode / code = codeMerge;
quit;

cas mySession terminate;

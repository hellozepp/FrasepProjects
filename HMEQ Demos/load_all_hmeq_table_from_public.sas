/* Loal all HMEQ data in memory */

*options cashost="frasepviya35smp" casport=5570;
options cashost="frasep.local.fr" casport=5570;

cas mysess;

caslib _all_ assign;

proc cas;
	table.fileinfo result=listfiles / caslib="public";
	do row over listfiles.fileinfo[1:listfiles.fileinfo.nrows];
		if (index(row.Name,'HMEQ')<>0) then do;
			datafile=row.Name;
			tablename=scan(row.Name,1);
			table.loadTable / casout={caslib="public" name=tablename promote=true} caslib="public" path=datafile;
		end;
	end;
quit;


cas mysess terminate;

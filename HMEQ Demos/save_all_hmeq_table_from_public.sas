/* Loal all HMEQ data in memory */

options cashost="frasepviya35smp" casport=5570;

cas mysess;

caslib _all_ assign;

proc cas;
	table.tableinfo result=listtables / caslib="public";
	do row over listtables.tableinfo[1:listtables.tableinfo.nrows];
		if (index(row.Name,'HMEQ')<>0) then do;
			table.save / table={caslib="public" name=row.Name} caslib="public" name=row.Name || ".sashdat";
		end;
	end;
quit;

cas mysess terminate;

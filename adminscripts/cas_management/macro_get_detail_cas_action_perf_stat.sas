options set=CASCLIENTDEBUG=1;
cas benchsess sessopts=(timeout=3600 metrics=true);

caslib _all_ assign;

%macro get_last_action_perf_stat(first_action, last_action);
	proc cas;
 		out_table = newtable("Action performance statistics", {"Command","elapsedTime","memory(MBytes)", "memoryOS(MBytes)","memoryQuota(MBytes)","dataMovementBytes(MBytes)","dataMovementTime","responsesize","responscount","cpuusertime","cpusystemtime","CPU(100% by core)"}, {"varchar","double","double", "double","double","double","double","double","double","double","double","double'});
		action builtins.history result=perf first=&first_action last=&last_action verbose=False;
		do p over perf["actions"];
       		addrow(out_table, {
				p.command, 
				p.performance.elapsedtime,
				p.performance.memory/1024/1024, 
				p.performance.memoryOS/1024/1024, 
				p.performance.memoryQuota/1024/1024,
				p.performance.dataMovementBytes/1024/1024,
				p.performance.dataMovementTime,
				p.performance.responsesize,
				p.performance.responsecount,
				p.performance.cpuusertime,
				p.performance.cpusystemtime,
				p.performance.cpuusertime/p.performance.elapsedtime
				
		});   
		end;
		print out_table;
	quit;
%mend get_last_action_perf_stat;


data casuser.prdsales;
	set sashelp.prdsale;
run;

proc treesplit data=CASUSER.PRDSALES maxdepth=10;
	input QUARTER YEAR MONTH / level=interval;
	input COUNTRY REGION DIVISION PRODTYPE PRODUCT / level=nominal;
	target ACTUAL / level=interval;
	grow rss;
	prune none;
run;

%get_last_action_perf_stat(1,-1);

cas benchsess terminate;

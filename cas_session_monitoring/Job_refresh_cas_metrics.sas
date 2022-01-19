/*****************************************************************************************************/
/* Code used to get all node metrics about CPU and RAM for all cas sessions visible by current user  */
/*****************************************************************************************************/
ods _all_ close;
cas sess_ctrl;
caslib _ALL_ assign;

/****************************************/
/* Define caslib and cas tables targets */
/****************************************/
%let CASMONITOR_CASLIB=public;
%let CASMONITOR_SESSION_METRICS=ALL_SESSION_DATA;
%let CASMONITOR_SYS_RAM_METRICS=system_memory_metrics;
%let CASMONITOR_SYS_CPU_METRICS=system_cpu_metrics;
%let CASMONITOR_CASCACHE_METRICS=cascache_info;

%let BASE_URI=%sysfunc(getoption(servicesbaseurl));
/* Flag to force final table truncation (=1) */
%let truncate_flag=0;
/* idle time threshold in seconds to filter sessions */
%let idletime_threshold=0;
%let start_datetime=%sysfunc(datetime());

proc cas;
	if &truncate_flag == 1 then do;
		table.droptable / caslib="&CASMONITOR_CASLIB" name="&CASMONITOR_SESSION_METRICS" quiet=true;
		table.droptable / caslib="&CASMONITOR_CASLIB" name="&CASMONITOR_SYS_RAM_METRICS" quiet=true;
		table.droptable / caslib="&CASMONITOR_CASLIB" name="&CASMONITOR_SYS_CPU_METRICS" quiet=true;
		table.droptable / caslib="&CASMONITOR_CASLIB" name="&CASMONITOR_CASCACHE_METRICS" quiet=true;
	end;
quit;

/* 	FILEREFs for the response and the response headers; */
filename respb temp encoding='UTF-8';
filename resphdrb temp encoding='UTF-8';

/************************************************************************************************/
/* Macro used to get the list of of all current cas sessions */
%macro get_detailed_cas_session_list();
	proc http url="&BASE_URI/cas-shared-default-http/cas/sessions" 
			oauth_bearer=sas_services method='get' out=respb headerout=resphdrb 
			headerout_overwrite;
	run;
%mend get_detailed_cas_session_list;

/************************************************************************************************/
/* Macro used to get the node memory metrics */
%macro get_node_memory_metrics();
	proc http url="&BASE_URI/cas-shared-default-http/cas/nodes/memoryMetrics" 
			oauth_bearer=sas_services method='get' out=respb headerout=resphdrb 
			headerout_overwrite;
	run;
%mend get_node_memory_metrics;

/************************************************************************************************/
/* Macro used to get the node cpu metrics */
%macro get_node_cpu_metrics();
	proc http url="&BASE_URI/cas-shared-default-http/cas/nodes/cpuTime"
			oauth_bearer=sas_services method='get' out=respb headerout=resphdrb 
			headerout_overwrite;
	run;
%mend get_node_cpu_metrics;


/* Get all current CAS Sessions */
libname obj2 clear;
%get_detailed_cas_session_list();
libname obj2 json "%sysfunc(pathname(respb))";

/************************************************************************************************/
/* Get all sessions with idle time greater than the theshold defined in idletime_threshod macro */
/* variable */
/************************************************************************************************/
proc sql;
	create table detailed_session_list as select A.uuid, A.name, A.state, A.user, A.activeAction, A.owner, A.provider ,
		(B.seconds+B.minutes*60+B.hours*3600) as idletime from obj2.root as A, 
		obj2.idletime as B where A.ordinal_root=B.ordinal_root and ((B.seconds+B.minutes*60+B.hours*3600)>&idletime_threshold);
quit;

%get_node_memory_metrics();
LIBNAME obj2 CLEAR;
libname obj2 json "%sysfunc(pathname(respb))";

data casuser.system_memory_metrics_tmp;
	set obj2.root;
	format metrics_datetime datetime20.;
	metrics_datetime=&start_datetime;
run;

%get_node_cpu_metrics();
LIBNAME obj2 CLEAR;
libname obj2 json "%sysfunc(pathname(respb))";

data casuser.system_cpu_metrics_tmp;
	set obj2.root;
	format metrics_datetime datetime20.;
	metrics_datetime=&start_datetime;
run;

/************************************************************************************************************/
/* Macro used to get node metrics for a given session uuid and append metrics data to dataset in parameter */
%macro get_session_node_metrics(session_uuid, output_ds=SESSION_NODE_METRICS);
	proc http url="&BASE_URI/cas-shared-default-http/cas/sessions/&session_uuid/nodes/metrics" 
			oauth_bearer=sas_services method='get' out=respb headerout=resphdrb 
			headerout_overwrite;
	run;

	libname obj3 json "%sysfunc(pathname(respb))";

	data data_to_insert;
		set obj3.root(drop=uuid id);
		rename name=node_name type=node_type;
		format metrics_datetime datetime20.;
		uuid="&session_uuid";
		metrics_datetime=&start_datetime;
	run;

	proc append base=&output_ds data=data_to_insert force;
	run;

	LIBNAME obj3 CLEAR;
%mend get_session_node_metrics;

/************************************************************************************************/
/* Main loop to get metrics of the selected sessions                                                 */
proc delete data=session_node_metrics;
run;

data _null_;
	set detailed_session_list;
	call execute('%get_session_node_metrics('||uuid||')');
run;

/************************************************************************************************/
proc sort data=WORK.DETAILED_SESSION_LIST;
	by uuid;
run;

proc sort data=WORK.SESSION_NODE_METRICS;
	by uuid;
run;

/********************************/
/* Consolidate all session date */
DATA casuser.ALL_SESSION_DATA_TMP;
	MERGE WORK.DETAILED_SESSION_LIST WORK.SESSION_NODE_METRICS;
	BY uuid;
RUN;

/* Get cascache information in casuser.cascache_info_tmp cas table */
proc cas;
  	accessControl.assumeRole / adminRole="superuser";
   	builtins.getCacheInfo result=results;
	table.droptable / caslib="casuser" name="cascache_info" quiet=true;
	do current_node over results.diskCacheInfo[1:results.diskCacheInfo.nrows];
		ds1_code='
		data casuser.cascache_info(append=yes);
		   length node varchar(100) FS_free 8. FS_usage 8. FS_size 8. path varchar(150);
		   node="' || current_node.node || '";
		   FS_free=' || scan(current_node.FS_free,1) || ';
		   FS_usage=' || scan(current_node.FS_usage,1) || ';
		   FS_size=' || scan(current_node.FS_size,1) || ';
		   path="' || current_node.path || '";
		   output;
		run;';
		datastep.runcode / code=ds1_code single='yes';
	 end;
quit;
/* We add the global timestamp */
data casuser.cascache_info_tmp;
		set casuser.cascache_info;
		format metrics_datetime datetime20.;
		metrics_datetime=&start_datetime;
run;


proc cas;
	function doesTableExist(casLib, casTable);
		table.tableExists result=r status=rc / caslib=casLib table=casTable;
		tableExists=dictionary(r, "exists");
		return tableExists;
	end func;
	
	tableExists=doesTableExist("&CASMONITOR_CASLIB", "&CASMONITOR_CASCACHE_METRICS");

	if tableExists !=0 then
		do;
			dataStep.runCode result=r status=rc / code='
			data "' || "&CASMONITOR_CASCACHE_METRICS" || '" (caslib="casuser" promote="no");
			    set "' || "&CASMONITOR_CASCACHE_METRICS" || '"(caslib="' || "&CASMONITOR_CASLIB" || '") "cascache_info_TMP"(caslib="casuser");
			run;
			';
		end;
	else do;
			dataStep.runCode result=r status=rc / code='
			data "' || "&CASMONITOR_CASCACHE_METRICS" || '" (caslib="casuser" promote="no");
			    set "cascache_info_TMP" (caslib="casuser");
			run;
			';
		end;

	tableExists=doesTableExist("&CASMONITOR_CASLIB", "&CASMONITOR_SESSION_METRICS");

	if tableExists !=0 then
		do;
			dataStep.runCode result=r status=rc / code='
			data "' || "&CASMONITOR_SESSION_METRICS" || '" (caslib="casuser" promote="no");
			   set "' || "&CASMONITOR_SESSION_METRICS" || '"(caslib="' || "&CASMONITOR_CASLIB" || '") "ALL_SESSION_DATA_TMP"(caslib="casuser");
			run;
			';
		end;
	else do;
			dataStep.runCode result=r status=rc / code='
			data "' || "&CASMONITOR_SESSION_METRICS" || '" (caslib="casuser" promote="no");
			    set "ALL_SESSION_DATA_TMP" (caslib="casuser");
			run;
			';
		end;

	tableExists=doesTableExist("&CASMONITOR_CASLIB", "&CASMONITOR_SYS_RAM_METRICS");

	if tableExists !=0 then
		do;
			dataStep.runCode result=r status=rc / code='
			data "' || "&CASMONITOR_SYS_RAM_METRICS" || '" (caslib="casuser" promote="no");
			    set "' || "&CASMONITOR_SYS_RAM_METRICS" || '"(caslib="' || "&CASMONITOR_CASLIB" || '") "system_memory_metrics_tmp"(caslib="casuser");
			run;
			';
		end;
	else do;
			dataStep.runCode result=r status=rc / code='
			data "' || "&CASMONITOR_SYS_RAM_METRICS" || '" (caslib="casuser" promote="no");
			    set "system_memory_metrics_tmp" (caslib="casuser");
			run;
			';
		end;

	tableExists=doesTableExist("&CASMONITOR_CASLIB", "&CASMONITOR_SYS_CPU_METRICS");

	if tableExists !=0 then
		do;
			dataStep.runCode result=r status=rc / code='
			data "' || "&CASMONITOR_SYS_CPU_METRICS" || '" (caslib="casuser" promote="no");
			    set "' || "&CASMONITOR_SYS_CPU_METRICS" || '"(caslib="' || "&CASMONITOR_CASLIB" || '") "system_cpu_metrics_tmp"(caslib="casuser");
			run;
			';
		end;
	else do;
			dataStep.runCode result=r status=rc / code='
			data "' || "&CASMONITOR_SYS_CPU_METRICS" || '" (caslib="casuser" promote="no");
			    set "system_cpu_metrics_tmp" (caslib="casuser");
			run;
			';
		end;

quit;

proc cas;
	table.droptable / caslib="&CASMONITOR_CASLIB" name="&CASMONITOR_SESSION_METRICS" quiet=true;
	table.droptable / caslib="&CASMONITOR_CASLIB" name="&CASMONITOR_SYS_RAM_METRICS" quiet=true;
	table.droptable / caslib="&CASMONITOR_CASLIB" name="&CASMONITOR_SYS_CPU_METRICS" quiet=true;
	table.droptable / caslib="&CASMONITOR_CASLIB" name="&CASMONITOR_CASCACHE_METRICS" quiet=true;

	table.promote / sourcecaslib='casuser' name="&CASMONITOR_SESSION_METRICS" targetcaslib="&CASMONITOR_CASLIB" target="&CASMONITOR_SESSION_METRICS";
	table.promote / sourcecaslib='casuser' name="&CASMONITOR_SYS_CPU_METRICS" targetcaslib="&CASMONITOR_CASLIB" target="&CASMONITOR_SYS_CPU_METRICS";
	table.promote / sourcecaslib='casuser' name="&CASMONITOR_SYS_RAM_METRICS" targetcaslib="&CASMONITOR_CASLIB" target="&CASMONITOR_SYS_RAM_METRICS";
	table.promote / sourcecaslib='casuser' name="&CASMONITOR_CASCACHE_METRICS" targetcaslib="&CASMONITOR_CASLIB" target="&CASMONITOR_CASCACHE_METRICS";

	table.save / caslib="&CASMONITOR_CASLIB"  name="&CASMONITOR_SESSION_METRICS" || ".sashdat" table={caslib="&CASMONITOR_CASLIB" name="&CASMONITOR_SESSION_METRICS"} replace=true;
	table.save / caslib="&CASMONITOR_CASLIB"  name="&CASMONITOR_SYS_CPU_METRICS" || ".sashdat" table={caslib="&CASMONITOR_CASLIB" name="&CASMONITOR_SYS_CPU_METRICS"} replace=true;
	table.save / caslib="&CASMONITOR_CASLIB"  name="&CASMONITOR_SYS_RAM_METRICS" || ".sashdat" table={caslib="&CASMONITOR_CASLIB" name="&CASMONITOR_SYS_RAM_METRICS"} replace=true;
	table.save / caslib="&CASMONITOR_CASLIB"  name="&CASMONITOR_CASCACHE_METRICS" || ".sashdat" table={caslib="&CASMONITOR_CASLIB" name="&CASMONITOR_CASCACHE_METRICS"} replace=true;
quit;

cas sess_ctrl terminate;
ods _all_ close;

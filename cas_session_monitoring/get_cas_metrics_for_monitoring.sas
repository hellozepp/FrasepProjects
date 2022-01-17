/*****************************************************************************************************/
/* Code used to get all node metrics about CPU and RAM for all cas sessions visible by current user  */
/*****************************************************************************************************/
ods _all_ close;

cas sess_ctrl;
caslib _ALL_ assign;

%let BASE_URI=%sysfunc(getoption(servicesbaseurl));

/* Flag to force final table truncation (=1) */
%let truncate_flag=0;

/* idle time threshold in seconds */
%let idletime_threshold=0;

%let start_datetime=%sysfunc(datetime());

proc cas;
	if &truncate_flag == 1 then do;
		table.droptable / caslib='public' name='ALL_SESSION_DATA' quiet=true;
		table.droptable / caslib='public' name='system_memory_metrics' quiet=true;
		table.droptable / caslib='public' name='system_cpu_metrics' quiet=true;
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

/************************************************************************************************/
/* Macro used to get cas node memory metrics */
%macro get_cas_nodes_memorymetrics();
	proc http url="&BASE_URI/cas-shared-default-http/cas/nodes/memoryMetrics"
			oauth_bearer=sas_services method='get' out=respb headerout=resphdrb 
			headerout_overwrite;
	run;
%mend get_cas_nodes_memorymetrics;

libname obj2 clear;
%get_cas_nodes_memorymetrics();
libname obj2 json "%sysfunc(pathname(respb))";

data work.get_cas_nodes_memorymetrics;
	set obj2.root;
run;

/************************************************************************************************/
/* Macro used to get cas grid nodes list */

%macro get_test();
	proc http url="&BASE_URI/cas-shared-default-http/grid/frasepViya35vm3.cloud.com/processes"
			oauth_bearer=sas_services method='get' out=respb headerout=resphdrb 
			headerout_overwrite;
	run;
%mend get_test;

libname obj2 clear;
%get_test();
libname obj2 json "%sysfunc(pathname(respb))";

data work.grid_node_list;
set obj2.root(keep=name);
run;


/* Get list of user processes PID liked to user CAS sessions */
%macro get_test2();
	proc http url="&BASE_URI/cas-shared-default-http/cas/nodes/frasepViya35vm3.cloud.com/sessionProcessesForUser"
			oauth_bearer=sas_services method='get' out=respb headerout=resphdrb 
			headerout_overwrite;
	run;
%mend get_test2;

libname obj2 clear;
%get_test2();
libname obj2 json "%sysfunc(pathname(respb))";

data work.cas_node_user_processes;
	set obj2.alldata(keep=value rename=(value=PID));
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
/* Main loop to terminate the selected sessions                                                 */
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
DATA work.ALL_SESSION_DATA_TMP;
	MERGE WORK.DETAILED_SESSION_LIST WORK.SESSION_NODE_METRICS;
	BY uuid;
RUN;

proc sort data=WORK.ALL_SESSION_DATA_TMP;
	by pid;
run;

proc sort data=WORK.CAS_PROCESSES;
	by pid;
run;

DATA casuser.ALL_SESSION_DATA_TMP;
	MERGE WORK.ALL_SESSION_DATA_TMP(IN=fromleft) WORK.CAS_PROCESSES;
	BY pid;
	leftInd=fromleft;
	if leftInd eq 1;
RUN;



proc cas;
	
	function doesTableExist(casLib, casTable);
		table.tableExists result=r status=rc / caslib=casLib table=casTable;
		tableExists=dictionary(r, "exists");
		return tableExists;
	end func;
	
	tableExists=doesTableExist("public", "all_session_data");

	if tableExists !=0 then
		do;
			dataStep.runCode result=r status=rc / code='
			data "ALL_SESSION_DATA" (caslib="casuser" promote="no");
			    set "ALL_SESSION_DATA"(caslib="Public") "ALL_SESSION_DATA_TMP"(caslib="casuser");
			run;
			';
		end;
	else do;
			dataStep.runCode result=r status=rc / code='
			data "ALL_SESSION_DATA" (caslib="casuser" promote="no");
			    set "ALL_SESSION_DATA_TMP" (caslib="casuser");
			run;
			';
		end;

	tableExists=doesTableExist("public", "system_memory_metrics");

	if tableExists !=0 then
		do;
			dataStep.runCode result=r status=rc / code='
			data "system_memory_metrics" (caslib="casuser" promote="no");
			    set "system_memory_metrics"(caslib="Public") "system_memory_metrics_TMP"(caslib="casuser");
			run;
			';
		end;
	else do;
			dataStep.runCode result=r status=rc / code='
			data "system_memory_metrics" (caslib="casuser" promote="no");
			    set "system_memory_metrics_tmp" (caslib="casuser");
			run;
			';
		end;

	tableExists=doesTableExist("public", "system_cpu_metrics");

	if tableExists !=0 then
		do;
			dataStep.runCode result=r status=rc / code='
			data "system_cpu_metrics" (caslib="casuser" promote="no");
			    set "system_cpu_metrics"(caslib="Public") "system_cpu_metrics_TMP"(caslib="casuser");
			run;
			';
		end;
	else do;
			dataStep.runCode result=r status=rc / code='
			data "system_cpu_metrics" (caslib="casuser" promote="no");
			    set "system_cpu_metrics_tmp" (caslib="casuser");
			run;
			';
		end;

quit;

proc cas;
	table.droptable / caslib='public' name='ALL_SESSION_DATA' quiet=true;
	table.droptable / caslib='public' name='system_memory_metrics' quiet=true;
	table.droptable / caslib='public' name='system_cpu_metrics' quiet=true;

	table.promote / sourcecaslib='casuser' name='ALL_SESSION_DATA' targetcaslib="public" target='ALL_SESSION_DATA';
	table.promote / sourcecaslib='casuser' name='system_cpu_metrics' targetcaslib="public" target='system_cpu_metrics';
	table.promote / sourcecaslib='casuser' name='system_memory_metrics' targetcaslib="public" target='system_memory_metrics';

	table.save / caslib="public"  name='ALL_SESSION_DATA.sashdat' table={caslib="public" name='ALL_SESSION_DATA'};
	table.save / caslib="public"  name='system_cpu_metrics.sashdat' table={caslib="public" name='system_cpu_metrics'};
	table.save / caslib="public"  name='system_memory_metrics.sashdat' table={caslib="public" name='system_memory_metrics'};
quit;

cas sess_ctrl terminate;
ods _all_ close;




/************************************************************************************************/
/* Macro used to get cas grid information */
/* /grid */
%macro get_cas_grid_information();
	proc http url="&BASE_URI/cas-shared-default-http/grid"
			oauth_bearer=sas_services method='get' out=respb headerout=resphdrb 
			headerout_overwrite;
	run;
%mend get_cas_grid_information;

libname obj2 clear;
%get_cas_grid_information();
libname obj2 json "%sysfunc(pathname(respb))";

/************************************************************************************************/
/* Macro used to get the top metrics by user */
/* /grid/{node name}/top/{user} */
%macro get_top_metrics_by_user(nodename,username);
	proc http url="&BASE_URI/cas-shared-default-http/grid/&nodename/top/&username"
			oauth_bearer=sas_services method='get' out=respb headerout=resphdrb 
			headerout_overwrite;
	run;
%mend get_top_metrics_by_user;


/* Get all current CAS Sessions */
libname obj2 clear;
%get_top_metrics_by_user(frasepViya35vm2.cloud.com,viyademo02);
libname obj2 json "%sysfunc(pathname(respb))";
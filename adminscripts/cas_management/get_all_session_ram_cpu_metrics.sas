ods _all_ close;
/* Job parameters */
cas sess_ctrl;

caslib _ALL_ assign;

/************************************************************************************************/
/* Snippet used to get all disconnected and idle for too long cas sessions and terminate them   */
/************************************************************************************************/
%let BASE_URI=%sysfunc(getoption(servicesbaseurl));
%let idletime_threshold=0; /* idle time threshold in seconds

/* 	FILEREFs for the response and the response headers; */
filename respb temp encoding='UTF-8';
filename resphdrb temp encoding='UTF-8';

/************************************************************************************************/
/* Macro used to get the list of of all current cas sessions */
%macro get_detailed_cas_session_list();
	proc http url="&BASE_URI/cas-shared-default-http/cas/sessions" oauth_bearer=sas_services
		method='get' out=respb headerout=resphdrb headerout_overwrite;
	run;
%mend get_detailed_cas_session_list;

/* Get all current CAS Sessions */
%get_detailed_cas_session_list();

libname obj2 json "%sysfunc(pathname(respb))";
/************************************************************************************************/
/* Get all sessions with idle time greater than the theshold defined in idletime_threshod macro */
/* variable or disconnected */
/************************************************************************************************/

proc sql;
	create table detailed_session_list
	as 
	select A.uuid, A.name, A.state, A.user, (B.seconds+B.minutes*60+B.hours*3600) as idletime 
	from obj2.root as A, obj2.idletime as B 
	where A.ordinal_root=B.ordinal_root and 
	((B.seconds+B.minutes*60+B.hours*3600)>&idletime_threshold or A.clientcount=0);
quit;

/************************************************************************************************************/
/* Macro used to get node metrics for a given session uuid and append metrics data to dataset in parameter */
%macro get_session_node_metrics(session_uuid, output_ds=SESSION_NODE_METRICS);
	proc http url="&BASE_URI/cas-shared-default-http/cas/sessions/&session_uuid/nodes/metrics" oauth_bearer=sas_services
		method='get' out=respb headerout=resphdrb headerout_overwrite;
	run;
	libname obj3 json "%sysfunc(pathname(respb))";
	data data_to_insert;
		set obj3.root(drop=uuid id);
		rename name=node_name type=node_type;
		uuid="&session_uuid";
		metrics_datetime = datetime();
 		format metrics_datetime datetime20.;
	run;
	proc append base=&output_ds data=data_to_insert force;
	run;
	LIBNAME obj3 CLEAR ;
%mend get_session_node_metrics;

/************************************************************************************************/
/* Main loop to terminate the selected sessions                                                 */
*proc delete data=session_node_metrics; run;

data _null_;
	set detailed_session_list;
	put "Getting metrics for cas session with uuid : " uuid;
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

proc append base=casuser.all_session_data data=public.all_session_data force;
run;

proc cas;
	function doesTableExist(casLib, casTable);
  		table.tableExists result=r status=rc / caslib=casLib table=casTable;
  		tableExists = dictionary(r, "exists");
  		return tableExists;
	end func;

	tableExists = doesTableExist("public", "all_session_data");
  	if tableExists != 0 then do;
			print "Appending data";
			dataStep.runCode result=r status=rc / code='
			data "ALL_SESSION_DATA" (caslib="casuser" promote="no");
			    set "ALL_SESSION_DATA" (caslib="Public") "ALL_SESSION_DATA_TMP" (caslib="casuser");
			run;
			';
	end;
	else do;
			dataStep.runCode result=r status=rc / code='
			data "ALL_SESSION_DATA" (caslib="casuser" promote="no");
			    set ALL_SESSION_DATA_TMP" (caslib="casuser");
			run;
			';
  	end;

	table.droptable / caslib='public' name='ALL_SESSION_DATA' quiet=true;
	table.promote / sourcecaslib='casuser' name='ALL_SESSION_DATA_TMP' targetcaslib="public" target='ALL_SESSION_DATA';
quit;

cas sess_ctrl terminate;
ods _all_ close;

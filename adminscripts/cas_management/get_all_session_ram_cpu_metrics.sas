/************************************************************************************************/
/* Snippet used to get all disconnected and idle for too long cas sessions and terminate them   */
/************************************************************************************************/
%let BASE_URI=%sysfunc(getoption(servicesbaseurl));
%let idletime_threshold=0; /* idle time threshold in seconds

/* 	FILEREFs for the response and the response headers; */
filename respb temp encoding='UTF-8';
filename resphdrb temp encoding='UTF-8';

/************************************************************************************************/
/* Macro used to terminate a specific CAS session */
%macro terminate_session(session_uuid);
	proc http url="&BASE_URI/cas-shared-default-http/cas/sessions/&session_uuid/terminate" oauth_bearer=sas_services
		method='post' out=respb headerout=resphdrb headerout_overwrite;
	run;
%mend terminate_session;

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

/************************************************************************************************/
/* Macro used to get node metrics fro a givens session uuid */
%macro get_session_node_metrics(session_uuid);
	proc http url="&BASE_URI/cas-shared-default-http/cas/sessions/&session_uuid/nodes/metrics" oauth_bearer=sas_services
		method='get' out=respb headerout=resphdrb headerout_overwrite;
		debug level=3;
	run;
%mend get_session_node_metrics;

%get_session_node_metrics(1f48359c-22e4-af44-baf8-fd7da2a471b3);

libname obj3 json "%sysfunc(pathname(respb))";

/************************************************************************************************/
/* Main loop to terminate the selected sessions                                                 */

data _null_;
	set detailed_session_list;
	put "Terminating cas session with uuid : " uuid;
	%get_session_node_metrics(uuid);
run;

/************************************************************************************************/

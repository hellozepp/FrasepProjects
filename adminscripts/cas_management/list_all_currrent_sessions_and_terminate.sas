%let BASE_URI=%sysfunc(getoption(servicesbaseurl));
%let idletime_threshold=300;
%let location=/tmp;

/* 	FILEREFs for the response and the response headers; */
filename resp temp encoding='UTF-8';
filename resp_hdr temp encoding='UTF-8';

%macro get_detailed_cas_session_list();
	proc http url="&BASE_URI/cas-shared-default-http/cas/sessions" oauth_bearer=sas_services
		method='get' out=respb headerout=resphdrb headerout_overwrite;
		debug level=3;
	run;
%mend get_detailed_cas_session_list;

%macro drop_session(session_uuid);
	proc http url="&BASE_URI/cas-shared-default-http/cas/sessions/&session_uuid" oauth_bearer=sas_services
		method='delete' out=respb headerout=resphdrb headerout_overwrite;
		debug level=3;
	run;
%mend drop_session;

%macro terminate_session(session_uuid);
	proc http url="&BASE_URI/cas-shared-default-http/cas/sessions/&session_uuid/terminate" oauth_bearer=sas_services
		method='post' out=respb headerout=resphdrb headerout_overwrite;
		debug level=3;
	run;
%mend terminate_session;

%macro get_session_information(session_uuid);
	proc http url="&BASE_URI/cas-shared-default-http/cas/sessions/&session_uuid" oauth_bearer=sas_services
		method='get' out=respb headerout=resphdrb headerout_overwrite;
		debug level=3;
	run;
%mend get_session_information;


filename respb "&location/get_ref_b.json";
filename resphdrb "&location/get_ref_b.txt";

%get_detailed_cas_session_list();


/************************************************************************************************/
/* Get all sessions with idle time greater than the theshold defined in idletime_threshod macro */
/* variable or disconnected */
/************************************************************************************************/
libname obj2 json "%sysfunc(pathname(respb))";

proc sql;
	create table detailed_session_list
	as 
	select A.uuid, A.name, A.state, A.user, (B.seconds+B.minutes*60+B.hours*3600) as idletime 
	from obj2.root as A, obj2.idletime as B 
	where A.ordinal_root=B.ordinal_root and 
	((B.seconds+B.minutes*60+B.hours*3600)>&idletime_threshold or A.clientcount=0);
quit;

proc print data=work.detailed_session_list;
run;

filename respb "&location/get_ref_b.json";
filename resphdrb "&location/get_ref_b.txt";

%get_session_information(4466974c-2746-d44d-8ee3-6b3131f594a3);
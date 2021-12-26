%let idletime_threshold=3600;
%let BASE_URI=http://frasepviya35smp.cloud.com;
%let USERNAME=viyademo01;
%let PASSWORD=demopw;
%let CLIENT_ID=frasepapp;
%let CLIENT_SECRET=frasepsecret;
%let location=/tmp;

/* 	FILEREFs for the response and the response headers; */
filename respb temp;
filename resphdrb temp;

options ls=max nodate;
ods _all_ close;

/*********************************************************************************/
/* 	Get access and refresh tokens in JSON format; */

proc http url="&BASE_URI/SASLogon/oauth/token" method='post' 
		in="grant_type=password%nrstr(&username=)&USERNAME%nrstr(&password=)&PASSWORD" 
		username="&CLIENT_ID" password="&CLIENT_SECRET" out=respb auth_basic;
run;
quit;

libname tokens json "%sysfunc(pathname(respb))";

proc sql noprint;
	select access_token into:ACCESS_TOKEN from tokens.root;
quit;

/*********************************************************************************/
%macro get_detailed_cas_session_list();
	proc http url="&BASE_URI/cas-shared-default-http/cas/sessions" 
		method='get' out=respb headerout=resphdrb headerout_overwrite;
		debug level=0;
		headers 'Authorization'="Bearer &ACCESS_TOKEN";
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
	((B.seconds+B.minutes*60+B.hours*3600)>&idletime_threshold or A.clientcount=0 or state="terminate");
quit;


%macro drop_session(session_uuid);
	proc http url="&BASE_URI/cas-shared-default-http/cas/sessions/&session_uuid" 
		method='delete' out=respb headerout=resphdrb headerout_overwrite;
		debug level=3;
		headers 'Authorization'="Bearer &ACCESS_TOKEN";
	run;
%mend drop_session;

/************************************************************************************************/
/* Main loop to terminate the selected sessions                                                 */

data _null_;
	set detailed_session_list;
	put "Terminating cas session with uuid : " uuid;
	call execute('%drop_session('||uuid||')'  );
run;


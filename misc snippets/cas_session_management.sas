cas mysess;

/**********************************************************/
/* As a supersuer, get all sessions of the cas controller */
/**********************************************************/
proc cas;
	accessControl.assumeRole / adminRole="superuser";
	session.listSessions;
quit;

%let idletime_threshold=300;
%let BASE_URI=http://frasepviya35smp.cloud.com;
%let USERNAME=viyademo01;
%let PASSWORD=demopw;
%let CLIENT_ID=frasepapp;
%let CLIENT_SECRET=frasepsecret;
%let location=/tmp;

/* 	FILEREFs for the response and the response headers; */
filename resp temp;
filename resp_hdr temp;

options ls=max nodate;
ods _all_ close;

%macro get_detailed_cas_session_list();
	proc http url="&BASE_URI/cas-shared-default-http/cas/sessions" 
		method='get' out=respb headerout=resphdrb headerout_overwrite;
		debug level=0;
		headers 'Authorization'="Bearer &ACCESS_TOKEN";
	run;
%mend get_detailed_cas_session_list;

%macro drop_session(session_uuid);
	proc http url="&BASE_URI/cas-shared-default-http/cas/sessions/&session_uuid" 
		method='delete' out=respb headerout=resphdrb headerout_overwrite;
		debug level=0;
		headers 'Authorization'="Bearer &ACCESS_TOKEN";
	run;
%mend drop_session;

/* 	Get access and refresh tokens in JSON format; */
proc http url="&BASE_URI/SASLogon/oauth/token" method='post' 
		in="grant_type=password%nrstr(&username=)&USERNAME%nrstr(&password=)&PASSWORD" 
		username="&CLIENT_ID" password="&CLIENT_SECRET" out=resp auth_basic verbose;
	debug level=3;
run;
quit;

/* 	Get the access token from the JSON data and store it in the ACCESS_TOKEN macro variable. */
libname tokens json "%sysfunc(pathname(resp))";

proc sql noprint;
	select access_token into:ACCESS_TOKEN from tokens.root;
quit;

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

/**********************************************************/
/* Terminate all sessions identified in the previous step */
/**********************************************************/
data _null_;
	set detailed_session_list;
	%drop_session(uuid);
run;

/* Drop a specific session even for another user as superuser role is assumed in the current session */
%drop_session(27eba82c-6ba9-324b-b16b-b2669d1d84a7);

cas mysess terminate;

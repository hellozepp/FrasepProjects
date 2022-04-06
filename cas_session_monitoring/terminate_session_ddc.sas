/************************************************************************************************/
/* Terminate a specfic CAS sessions                                                             */
/************************************************************************************************/
ods _all_ close;

%global session_uuid;

%let BASE_URI=%sysfunc(getoption(servicesbaseurl));

/* 	FILEREFs for the response and the response headers; */
filename respb temp encoding='UTF-8';
filename resphdrb temp encoding='UTF-8';

%macro terminate_session(session_uuid);
  proc http url="&BASE_URI/cas-shared-default-http/cas/sessions/&session_uuid/terminate" oauth_bearer=sas_services
  	method='post' out=respb headerout=resphdrb headerout_overwrite;
run;
%mend terminate_session;

%terminate_session(&session_uuid);

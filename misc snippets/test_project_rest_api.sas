options cashost="sepviya35.aws.sas.com" casport=5570;

cas lineagesess;

caslib _all_ assign;

/********************************************/
/* GLOBAL PARAMETERS FOR LINEAGE EXTRACTION */
/********************************************/

%let BASE_URI=http://sepviya35.aws.sas.com;
%let USERNAME=viyademo01;
%let PASSWORD=demopw;
%let NAME=HMEQ_TRAIN;
%let limit=100000;
%let depth=1000;
%let truncate_flag=1;
%let CAS_OUTPUT_TAB_REL=relationships;
%let CAS_OUTPUT_TAB_REF=references;
%let CAS_OUTPUT_TAB_FACT=relationships_facts;

%let CAS_OUTPUT_LIB=public;
%let location=/tmp;

%let OBJECT_URI=/casManagement/servers/cas-shared-default/caslibs/Public/tables/HMEQ_TRAIN;

*Use the Client ID to Get an Access Token;
*Submit this code once to get the access token or repeat if your access token has expired.;
options ls=max nodate;
ods _all_ close;

/* 	Specify the new Client ID name; */
*! Name must be registered above - no spaces;
%let CLIENT_ID=frasepapp;

/* 	Specify the secret for the new Client ID; */
	%let CLIENT_SECRET=frasepsecret;

/* 	FILEREFs for the response and the response headers; */
filename resp temp;
filename resp_hdr temp;

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

%put &ACCESS_TOKEN;
filename respb "&location/get_ref_b.json";
filename resphdrb "&location/get_ref_b.txt";

/* resourceUri=&OBJECT_URI%str(&) */

proc http url="&BASE_URI/projects/projects" 
		method='get' out=respb headerout=resphdrb headerout_overwrite;
	debug level=0;
	headers 'Authorization'="Bearer &ACCESS_TOKEN";
run;
quit;

libname obj2 clear;
libname obj2 json "%sysfunc(pathname(respb))";



proc http url="&BASE_URI/projects/projects/79b3e3c2-d517-4f82-8b1b-6695c1b7bc93/resources" 
		method='get' out=respb headerout=resphdrb headerout_overwrite;
	debug level=0;
	headers 'Authorization'="Bearer &ACCESS_TOKEN";
run;
quit;

libname obj2 clear;
libname obj2 json "%sysfunc(pathname(respb))";


proc http url="&BASE_URI/projects/activities?limit=10000" 
		method='get' out=respb headerout=resphdrb headerout_overwrite;
	debug level=0;
	headers 'Authorization'="Bearer &ACCESS_TOKEN";
run;
quit;

libname obj2 clear;
libname obj2 json "%sysfunc(pathname(respb))";


proc http url="&BASE_URI/annotations/annotations?limit=10000" 
		method='get' out=respb headerout=resphdrb headerout_overwrite;
	debug level=0;
	headers 'Authorization'="Bearer &ACCESS_TOKEN";
run;
quit;

libname obj2 clear;
libname obj2 json "%sysfunc(pathname(respb))";


cas lineagesess terminate;

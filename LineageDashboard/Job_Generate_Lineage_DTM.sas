/********************************************/
/* GLOBAL PARAMETERS FOR LINEAGE EXTRACTION */
/********************************************/
 /* 1: purge previous table, 0:append new lineage data to existing table */
%global truncate_flag;

%let BASE_URI=http://frasepviya35smp.cloud.com;
%let USERNAME=viyademo01;
%let PASSWORD=demopw;
%let NAME=HMEQ_TRAIN;
%let limit=100000;
%let depth=50;
%let CAS_OUTPUT_TAB_REL=relationships;
%let CAS_OUTPUT_TAB_REF=references;
%let CAS_OUTPUT_TAB_FACT=relationships_facts;
%let CAS_OUTPUT_LIB=public;
%let location=/tmp;
%let OBJECT_URI=/casManagement/servers/cas-shared-default/caslibs/Public/tables/HMEQ_TRAIN;

%let currdt=%sysfunc(datetime());

/********************************************/
options cashost="frasepviya35smp.cloud.com" casport=5570;

cas lineagesess;

caslib _all_ assign;

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

/* Use relationship REST API to get all links with limits and depth set as parameters */

proc http url="&BASE_URI/relationships/relationships/?limit=&limit%str(&)depth=&depth" 
		method='get' out=respb headerout=resphdrb headerout_overwrite;
	debug level=0;
	headers 'Authorization'="Bearer &ACCESS_TOKEN";
run;
quit;

libname obj2 json "%sysfunc(pathname(respb))";


data casuser.&CAS_OUTPUT_TAB_REL;
	length resourceUri $ 160 relatedResourceUri $ 160;
	format lineage_collection_date datetime.;
	set obj2.items;
	resourceUri=resourceUri;
	relatedResourceUri=relatedResourceUri;
	lineage_collection_date=&currdt;
run;

/* Use relationship REST API to get all object references details used in links */

proc http url="&BASE_URI/relationships/references?limit=&limit" 
		method='get' out=respb headerout=resphdrb headerout_overwrite;
	debug level=0;
	headers 'Authorization'="Bearer &ACCESS_TOKEN";
run;
quit;

libname obj2 clear;
libname obj2 json "%sysfunc(pathname(respb))" ;

data casuser.&CAS_OUTPUT_TAB_REF;
	length resourceUri $ 160;
	set obj2.items;
	format lineage_collection_date datetime.;
	resourceUri=resourceUri;
	lineage_collection_date=&currdt;
run;

proc fedsql sessref=lineagesess;
	create table casuser.&CAS_OUTPUT_TAB_FACT{options replace=TRUE} as 
	select
		REF1.name as SRC_name, 
		REF1.contentType as SRC_contentType, 
		REF1.resourceUri as SRC_resourceUri,
		REF1.createdBy as SRC_createdBy,
		REL.lineage_collection_date,
		REL.type as link_type,
		REF2.name as TGT_name, 
		REF2.contentType as TGT_contentType, 
		REF2.resourceUri as TGT_resourceUri,
		REF2.createdBy as TGT_createdBy
	from casuser.&CAS_OUTPUT_TAB_REF as REF1, casuser.&CAS_OUTPUT_TAB_REF as REF2, casuser.&CAS_OUTPUT_TAB_REL as REL 
	where REF1.id=REL.referenceId and REF2.id=REL.relatedReferenceId;
	
	create table casuser.&CAS_OUTPUT_TAB_FACT{options replace=TRUE} as
	select * from casuser.&CAS_OUTPUT_TAB_FACT
	union
	select
		T1.TGT_name as SRC_name, 
		T1.TGT_contentType as SRC_contentType, 
		T1.TGT_resourceUri as SRC_resourceUri,
		T1.TGT_createdBy as SRC_createdBy,
		T1.lineage_collection_date,
		T1.link_type,
		'' as TGT_name, 
		'' as TGT_contentType, 
		'' as TGT_resourceUri,
		'' as TGT_createdBy
	from casuser.&CAS_OUTPUT_TAB_FACT as T1 left outer join casuser.&CAS_OUTPUT_TAB_FACT as T2
	on (T1.TGT_RESOURCEURI=T2.SRC_RESOURCEURI)
	where T2.SRC_RESOURCEURI is NULL;
quit;


proc cas;
	tflag=&truncate_flag;
	fact_table="&CAS_OUTPUT_TAB_FACT";
	ref_table="&CAS_OUTPUT_TAB_REF";
	out_cas_lib="&CAS_OUTPUT_LIB";

    table.tableExists result=r status=rc / caslib=out_cas_lib table=fact_table;

	if (tflag=0) and (r.exists <> 0) then do;
		runCode1="data casuser." || fact_table || "(append=YES); set " || out_cas_lib || "." || fact_table || "; run;";	
		datastep.runCode / code=runCode1;
		runCode2="data casuser." || ref_table || "(append=YES); set " || out_cas_lib || "." || ref_table || ";	run;";
		datastep.runCode / code=runCode2;
	end;

	/* Create fact table with relationships and promote object inventory and relation facts */

	table.droptable / caslib=out_cas_lib name=fact_table quiet=true;
	table.droptable / caslib=out_cas_lib name=ref_table quiet=true;
	table.promote / targetcaslib=out_cas_lib sourcecaslib='casuser' name=fact_table;
	table.promote / targetcaslib=out_cas_lib sourcecaslib='casuser' name=ref_table;

	table.save / table={caslib=out_cas_lib name=fact_table} name=fact_table || ".sashdat" caslib=out_cas_lib ;
	table.save / table={caslib=out_cas_lib name=ref_table} name=ref_table || ".sashdat" caslib=out_cas_lib ;

quit;

cas lineagesess terminate;

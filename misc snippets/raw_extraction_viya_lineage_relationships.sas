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

proc http url="&BASE_URI/relationships/relationships/?limit=&limit%str(&)depth=&depth" 
		method='get' out=respb headerout=resphdrb headerout_overwrite;
	debug level=0;
	headers 'Authorization'="Bearer &ACCESS_TOKEN";
run;

quit;
libname obj2 json "%sysfunc(pathname(respb))";

%let currdt=%sysfunc(datetime());

data casuser.&CAS_OUTPUT_TAB_REL;
	length resourceUri $ 160;
	format lineage_collection_date datetime.;
	set obj2.items;
	resourceUri=resourceUri;
	lineage_collection_date=&currdt;
run;

%if &truncate_flag=0 %then
%do;
		data casuser.&CAS_OUTPUT_TAB_REL(append=YES);
			format lineage_collection_date datetime.;
			length resourceUri $ 160;
			set &CAS_OUTPUT_LIB..&CAS_OUTPUT_TAB_REL;
			resourceUri=resourceUri;
			lineage_collection_date=&currdt;
		run;	
%end;

proc http url="&BASE_URI/relationships/references?limit=&limit" 
		method='get' out=respb headerout=resphdrb headerout_overwrite;
	debug level=0;
	headers 'Authorization'="Bearer &ACCESS_TOKEN";
run;
quit;

libname obj2 clear;
libname obj2 json "%sysfunc(pathname(respb))" ;

data casuser.&CAS_OUTPUT_TAB_REF;
	set obj2.items;
	format lineage_collection_date datetime.;
	lineage_collection_date=&currdt;
run;

%if &truncate_flag=0 %then
%do;
		data casuser.&CAS_OUTPUT_TAB_REF(append=YES);
			set &CAS_OUTPUT_LIB..&CAS_OUTPUT_TAB_REF;
			format lineage_collection_date datetime.;
			lineage_collection_date=&currdt;
		run;	
%end;

proc casutil;
	DROPTABLE CASDATA="&CAS_OUTPUT_TAB_REF" INCASLIB="&CAS_OUTPUT_LIB" QUIET;
	PROMOTE CASDATA="&CAS_OUTPUT_TAB_REF" CASOUT="&CAS_OUTPUT_TAB_REF" 
		OUTCASLIB="&CAS_OUTPUT_LIB" DROP;

proc casutil;
	DROPTABLE CASDATA="&CAS_OUTPUT_TAB_REL" INCASLIB="&CAS_OUTPUT_LIB" QUIET;
	PROMOTE CASDATA="&CAS_OUTPUT_TAB_REL" CASOUT="&CAS_OUTPUT_TAB_REL" 
		OUTCASLIB="&CAS_OUTPUT_LIB" DROP;
	quit;

quit;

proc casutil;
	droptable casdata="&CAS_OUTPUT_TAB_FACT" incaslib="&CAS_OUTPUT_LIB" quiet;
quit;

* Create Star Schema;

proc cas; 

	fact_table="&CAS_OUTPUT_TAB_FACT";
	ref_table="&CAS_OUTPUT_TAB_REF";
	rel_table="&CAS_OUTPUT_TAB_REL";
	out_cas_lib="&CAS_OUTPUT_LIB";
	table.droptable caslib=out_cas_lib name=fact_table quiet=true;

	table.view / caslib='casuser' name=fact_table replace=true
	tables={
		{caslib=out_cas_lib name=rel_table, 
		varlist={'createdBy','creationTimeStamp','id','lineage_collection_date','modifiedBy','modifiedTimeStamp','ordinal_items','ordinal_root','relatedResourceUri','resourceUri','source','type'}, as='link'},
		{keys={'link_resourceUri = resource_resourceUri'},
	    caslib=out_cas_lib name=ref_table,  varlist={'contentType','createdBy','modifiedBy','name','resourceUri','source'},as='resource'},
		{keys={'link_relatedResourceUri = relatedResource_resourceUri'},
	    caslib=out_cas_lib name=ref_table,  varlist={'contentType','createdBy','modifiedBy','name','resourceUri','source'},as='relatedResource'}
		};

	table.promote targetcaslib=out_cas_lib sourcecaslib='casuser' name=fact_table;

quit;


cas lineagesess terminate;

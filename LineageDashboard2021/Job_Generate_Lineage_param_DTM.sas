/* Job parameters */
%global cashostname truncate_flag src_object_uri limit depth;

/* Global variables settingq */
%let BASE_URI=%sysfunc(getoption(SERVICESBASEURL));
%let REST_BASE_URI=&BASE_URI.relationships/relationships?limit=&limit.;
%let CAS_OUTPUT_TAB_REL=query_relationships;
%let CAS_OUTPUT_TAB_REF=query_references;
%let CAS_OUTPUT_TAB_FACT=query_relationships_facts;
%let CAS_OUTPUT_LIB=public;

%let currdt=%sysfunc(datetime());

options cashost="&cashostname." casport=5570;
cas lineagesess;
caslib _all_ assign;

FILENAME obj2 TEMP ENCODING='UTF-8'; /* file to get json response content */
FILENAME respHdr TEMP ENCODING='UTF-8'; /* file to get json response header */
filename fbody temp ENCODING='UTF-8';

%let REST_QUERY_URI=&REST_BASE_URI%str(&)referenceUri=&src_object_uri.%str(&)depth=&depth.;

%put &REST_QUERY_URI;

/* Execute the get  */
PROC HTTP 
	METHOD="GET"
	URL = "&REST_QUERY_URI"
	oauth_bearer = sas_services
	out=obj2
	headerout=respHdr
	headerout_overwrite;
RUN;
QUIT;

libname obj2 json;

data casuser.&CAS_OUTPUT_TAB_REL;
	length resourceUri $ 160 relatedResourceUri $ 160;
	format lineage_collection_date datetime.;
	set obj2.items;
	resourceUri=resourceUri;
	relatedResourceUri=relatedResourceUri;
	lineage_collection_date=&currdt;
run;

/* Execute the get for references */
PROC HTTP 
	METHOD="GET"
	URL = "&BASE_URI/relationships/references?limit=50000"
	oauth_bearer = sas_services
	out=obj2
	headerout=respHdr
	headerout_overwrite;
RUN;
QUIT;

libname obj2 clear;
libname obj2 json ;

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

	table.save / table={caslib=out_cas_lib name=fact_table} name=fact_table || ".sashdat" replace=true caslib=out_cas_lib ;
	table.save / table={caslib=out_cas_lib name=ref_table} name=ref_table || ".sashdat" replace=true caslib=out_cas_lib ;

quit;

cas lineagesess terminate;
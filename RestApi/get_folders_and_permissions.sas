/*******************************************************************************************/
/* Script to execute on Viya SPRE and user belonging to SAS Administrator custom group     */
/* Use REST API to get all content folders with full path and permissions                  */
/* and put it in a 2 reporting cas tables                                                  */
/*******************************************************************************************/

%let BASE_URI=%sysfunc(getoption(SERVICESBASEURL));
%let fullpath=/;

/******************************************************************************/
FILENAME rFold TEMP ENCODING='UTF-8';
proc http 
	url="&BASE_URI/folders/folders?limit=999999" method='get' oauth_bearer=sas_services out=rFold;
	debug level=1;
run;
quit;
LIBNAME rFold json;

data ds_rfld (keep=fldUri name id memberCount parentFolderUri createdBy creationTimeStamp modifiedTimeStamp);
	length fldUri $ 60 fldPath $ 200;
	set rFold.items;
	fldUri='/folders/folders/' || id;
	fldPath = '/'||name;
run;

/******************************************************************************/
%MACRO save_VA_Object_Path(objectURI);
	FILENAME fldFile TEMP ENCODING='UTF-8';
	%let locURI = &objectURI;

	/*  get the folders in which the objectURI is in  */
	PROC HTTP METHOD = "GET" oauth_bearer=sas_services OUT = fldFile
		URL = "&BASE_URI/folders/ancestors?childUri=/folders/folders/&objectURI";
     	HEADERS "Accept" = "application/vnd.sas.content.folder.ancestor+json";
	RUN;
	LIBNAME fldFile json;

	%let fldname="";
	/* 	generate the path from the returned folders above */
	proc sql noprint ;
		select name into :fldname separated by '/'
		from fldFile.ancestors 
		order by ordinal_ancestors desc;
	quit;
	
	data tmpsave;
		length cc $ 36;
		set ds_rfld;
		cc = "&locURI";
		if trim(id) = trim(cc) then 
			fldPath=resolve('&fullpath.&fldname.');
		drop cc;
	run;
	
	data ds_rfld;
		set tmpsave;
	run;
%MEND save_VA_Object_Path;

DATA _null_;
	set ds_rfld;
	call execute('%save_VA_Object_Path('||id||')');
RUN;
/******************************************************************************/
/* Get all permissions for folders                                            */
/******************************************************************************/

FILENAME rRul TEMP ENCODING='UTF-8';
proc http url="&BASE_URI/authorization/rules" 
	method='get' oauth_bearer=sas_services 
	out=rRul 
	query=("limit"="999999" "filter"="startsWith(objectUri,'/folders/folders')");
	debug level=1;
run;
quit;
LIBNAME rRul json;

proc sql;
	create table ds_fldperms as 
	(select A.objectUri as ruleUri, A.'condition'n, A.containerUri as foldersUri , A.contentType, A.createdBy, A.createdTimestamp, 
		A.creationTimeStamp, A.description, A.enabled, A.modifiedBy, A.modifiedTimeStamp, 
		A.principal, A.principalType, A.reason, A.'type'n , 
		B.permissions1,B.permissions2,B.permissions3,B.permissions4,B.permissions5,B.permissions6,B.permissions7
	from 
		rRul.items as A, rRul.items_permissions as B where 
		A.ordinal_items=B.ordinal_items);
run;
quit;


proc print data=ds_rfld; run;

proc print data=ds_fldperms; run;


/******************************************************************************/
/* Write and promote cas tables containing folders and permissions            */
/******************************************************************************/
/*
cas mysess sessopts=(timeout=30);

caslib _all_ assign;

data casuser.viya_folders_list;
	set ds_rfld;
run;

data casuser.viya_folders_perms;
	set ds_fldperms;
run;

proc cas;
	table.droptable / caslib="public" name="viya_folders_list" quiet=true;
	table.promote / caslib="casuser" drop=TRUE name="viya_folders_list" targetLib="public";
	table.droptable / caslib="public" name="viya_folders_perms" quiet=true;
	table.promote / caslib="casuser" drop=TRUE name="viya_folders_perms" targetLib="public";
quit;

cas mysess terminate;

*/
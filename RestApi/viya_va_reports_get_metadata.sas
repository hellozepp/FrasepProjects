%let BASE_URI=%sysfunc(getoption(SERVICESBASEURL));
%let fullpath=/SAS Content/;

FILENAME rptFile TEMP ENCODING='UTF-8';
PROC HTTP METHOD = "GET" oauth_bearer=sas_services OUT = rptFile
/* get a list of reports, say created by sbjciw, or report name is 'Report 2' */
/*      URL = "&BASE_URI/reports/reports?filter=eq(createdBy,'sbjciw')" */
/*     URL = "&BASE_URI/reports/reports?filter=eq(name,'Retail Insights')"; */
 URL = "&BASE_URI/reports/reports";
	HEADERS "Accept" = "application/vnd.sas.collection+json"
			"Accept-Item" = "application/vnd.sas.summary+json";

RUN;

LIBNAME rptFile json;

data ds_rpts (keep=rptID id name createdBy creationTimeStamp modifiedTimeStamp  
			  rename=(modifiedTimeStamp=LastModified creationTimeStamp=CreatedAt));
	length rptID $ 60 rptPath $ 100;
	set rptFile.items;
	rptID = '/reports/reports/'||id;
run;

%MACRO save_VA_Report_Path(reportURI);
	FILENAME fldFile TEMP ENCODING='UTF-8';
	%let locURI = &reportURI;
	
	PROC HTTP METHOD = "GET" oauth_bearer=sas_services OUT = fldFile
	/*  get the folders in which the reportURI is in  */
		URL = "&BASE_URI/folders/ancestors?childUri=/reports/reports/&reportURI";
     	HEADERS "Accept" = "application/vnd.sas.content.folder.ancestor+json";
	RUN;
	LIBNAME fldFile json;
	
/* 	generate the path from the returned folders above */
	proc sql noprint;
		select name into :fldname separated by '/'
		from fldFile.ancestors 
		order by ordinal_ancestors desc;
	quit;

	data tmpsave;
		length cc $ 36;
		set ds_rpts;
		cc = "&locURI";
		if trim(id) = trim(cc) then 
			rptPath=resolve('&fullpath.&fldname.');
		drop cc;
	run;
	
	data ds_rpts;
		set tmpsave;
	run;

%MEND save_VA_Report_Path;

/* Possible filters on rules :
    principal (eq, ne, startsWith, endsWith, contains)
    type (eq, ne)
    principalType (eq, ne)
    permissions (in)
    objectUri (eq, ne, startsWith, endsWith, contains)
    containerUri (eq, ne, startsWith, endsWith, contains)
    mediaType (eq, ne, startsWith, endsWith, contains)
    enabled (eq, ne)
*/
FILENAME rulFile TEMP ENCODING='UTF-8';
PROC HTTP METHOD = "GET" oauth_bearer=sas_services OUT = rulFile
/* URL = "&BASE_URI/authorization/rules?filter=eq(objectUri,'/reports/reports/aaea273e-aa15-43c9-9213-d85280f61ed8')"; */
URL = "&BASE_URI/authorization/rules";
	HEADERS "Accept" = "application/vnd.sas.collection+json"
			"Accept-Item" = "string";

RUN;
LIBNAME rulFile json;



DATA _null_;
	set ds_rpts;
	call execute('%save_VA_Report_Path('||id||')');
RUN;

PROC PRINT data=ds_rpts;
	var rptPath name rptID createdBy CreatedAt LastModified;
RUN;
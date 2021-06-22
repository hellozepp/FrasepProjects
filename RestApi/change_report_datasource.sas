/*
cas mysess;

caslib _ALL_ assign;

data PUBLIC.RAND_RETAILDEMO_oak (promote=YES);
	set SAMPLES.RAND_RETAILDEMO(where=(Brand_name='Oak'));
run;

cas _all_ terminate;
*/

/*
Reference : 
https://github.com/sassoftware/devsascom-rest-api-samples/blob/master/Visualization/reportTransforms.md
*/


* * GLOBAL VARIABLES **********************************************************;
* Base URI for the service call;
%let BASE_URI=%sysfunc(getoption(servicesbaseurl));

* Name of the report;
%let REPORT_NAME=Retail Insights;

* *Get ID of the report *********************************************************;

FILENAME rptFile TEMP ENCODING='UTF-8';

PROC HTTP METHOD = "GET" oauth_bearer=sas_services OUT = rptFile
      URL = "&BASE_URI/reports/reports?filter=eq(name,'&REPORT_NAME')";
      HEADERS "Accept" = "application/vnd.sas.collection+json"
               "Accept-Item" = "application/vnd.sas.summary+json";
RUN;

LIBNAME rptFile json;

proc sql noprint;
  select id into :report_id trimmed from rptFile.items;
quit;

%put &report_id;
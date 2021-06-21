* * GLOBAL VARIABLES **********************************************************;
* Base URI for the service call;
%let BASE_URI=%sysfunc(getoption(servicesbaseurl));

* Name of the report;
%let REPORT_NAME=Report_API_test;

* *Get ID of the report *********************************************************;

FILENAME rptFile TEMP ENCODING='UTF-8';

PROC HTTP METHOD = "GET" oauth_bearer=sas_services OUT = rptFile
      URL = "&BASE_URI/reports/reports?filter=eq(name,'&REPORT_NAME')";
      HEADERS "Accept" = "application/vnd.sas.collection+json"
               "Accept-Item" = "application/vnd.sas.summary+json";
RUN;

LIBNAME rptFile json;

data _NULL_;
	set rptFile.items(obs=1);
	call symputx('report_id',id);
run;

%put &report_id;

* *******************************************************************************;
* * Make a report image job request *********************************************;

filename startjob temp;
filename resp_hdr temp;
filename json_in filesrvc folderpath="/Public" filename="json_in.json";

data _null_;
	file json_in;
	put '{'/
	  '"version" : 1,'/
	  '"reportUri" : "/reports/reports/' "&report_id" '",'/
	  '"layoutType" : "entireSection",'/
	  '"selectionType" : "report",'/
	  '"size" : "800x600",'/
	  '"refresh":true,'/
	  '"sectionIndex" : 0'/
	'}';
run;

proc http 
	method="POST" oauth_bearer=sas_services
	url="&BASE_URI/reportImages/jobs"
	ct="application/vnd.sas.report.images.job.request+json"
	in=json_in
	out=startjob
	headerout=resp_hdr 
	headerout_overwrite;
run;

libname startjob json;

data _NULL_;
	set startjob.root;
	call symputx('job_id',id);
run;

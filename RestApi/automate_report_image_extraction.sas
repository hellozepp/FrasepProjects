/* Used reference : 
https://github.com/sascommunities/sas-community-articles/tree/master/export-report-ppt
https://github.com/sassoftware/devsascom-rest-api-samples/tree/master/Visualization
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

* *******************************************************************************;
* * Make a report image job request *********************************************;

filename startjob temp;
filename resp_hdr temp;
filename json_in filesrvc folderpath="/Public" filename="json_in.json";

/* Parameter to get all sections, one image for each with maximum of 20 sections */
data _null_;
	file json_in;
	put '{'/
	  '"version" : 1,'/
	  '"reportUri" : "/reports/reports/' "&report_id" '",'/
	  '"layoutType" : "entireSection",'/
	  '"selectionType" : "perSection",'/
	  '"size" : "1280x720",'/
	  '"refresh":true,'/
	  '"renderLimit" : 20,'/
	  '"version" : 1'/
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

/* Get job id ina macro variable */

proc sql noprint;
  select id into :job_id trimmed from startjob.root;
quit;

%put &job_id;


/* Macro to wait for job completion and get the image */

%macro va_img_check_jobstatus(jobid=, sleep=1, maxloop=50);
	%local jobStatus i;
	
	%do i = 1 %to &maxLoop;
	  filename jobrc temp;
	  proc http
	    method='GET' 
	    url="&BASE_URI//reportImages/jobs/&jobid/state"
	    oauth_bearer=sas_services
	    out=jobrc
	    verbose;
	    headers
	      "Accept" = "text/plain";
	    debug level=0;
	  run;
	  %put NOTE: &=SYS_PROCHTTP_STATUS_CODE;
	  %put NOTE: &=SYS_PROCHTTP_STATUS_PHRASE;
	  
	  %put NOTE: response check job status;
	  data _null_;
	      infile jobrc;
	      input line : $32.;
	      putlog "NOTE: &sysmacroname jobId=&jobid i=&i status=" line;
	      if line in ("completed", "failed") then do;
	      end;
	      else do;
	        putlog "NOTE: &sysmacroname &jobid status=" line "sleep for &sleep.sec";
	        rc = sleep(&sleep, 1);
	      end;  
	      call symputx("jobstatus", line);
	  run;
	  filename jobrc clear;
	  %if &jobstatus = completed %then %do;
	    %put NOTE: &sysmacroname &=jobid &=jobStatus;
	    %return;
	  %end;
	  %if &jobstatus = failed %then %do;
	    %put ERROR: &sysmacroname &=jobid &=jobStatus;
	    %return;
	  %end;
	%end;
%mend;

%va_img_check_jobstatus(jobid=&job_id)


/*
 * Get job info
 * using API
 * https://developer.sas.com/apis/rest/Visualization/#get-specified-job
 */
filename resp temp;
proc http
  method='GET' 
  url="&BASE_URI/reportImages/jobs/&job_id"
  oauth_bearer=sas_services
  out=resp
  verbose
  ;
  headers
    "Accept" = "application/vnd.sas.report.images.job+json"
    "Content-Type" = "application/vnd.sas.report.images.job.request+json"
  ;
  debug level=0;
run;
%put NOTE: &=SYS_PROCHTTP_STATUS_CODE;
%put NOTE: &=SYS_PROCHTTP_STATUS_PHRASE;

%put NOTE: response create image job;
%*put %sysfunc( jsonpp(resp, log));

libname resp json;
title "get report images root";
proc print data=resp.root;
run;
title "get report images links";
proc print data=resp.images_links;
run;
title;

proc sql;
  create table img_info as
  select
    img.* , imgl.*
  from
    resp.images as img , resp.images_links as imgl
  where
    img.ordinal_images = imgl.ordinal_images and method = "GET" and rel = "image";
quit;


/* 6.3.
 * macro to get images
 * using API
 * https://developer.sas.com/apis/rest/Visualization/#get-image
 */
%macro va_report_get_image(method=get, imghref=, outfile=, type=, jobid=);
	%put NOTE: &sysmacroname &method &imghref &outfile;
	data _null_;
	  rc = dcreate("&jobid", "~");
	run;
	filename img "~/&jobid/&outfile..svg";
	proc http
	  method = "&method"
	  url = "&BASE_URI/&imghref"
	  out=img
	  oauth_bearer=sas_services
	  verbose
	;
	  headers
	    "Accept" = "&type"
	    "Content-Type" = "application/vnd.sas.report.images.job.request+json"
	  ;
	  debug level=0;
	run;
	%put NOTE: response get image;
	%put NOTE: &=SYS_PROCHTTP_STATUS_CODE;
	%put NOTE: &=SYS_PROCHTTP_STATUS_PHRASE;
%mend;

/* build macro calls */

%put "flag1";

filename getimg temp;

data _null_;
  set img_info;
  file getimg;
  length line $ 2048;
  line = cats(
    '%va_report_get_image('
    , cats("method=", method)
    , ","
    , cats("imghref=", href)
    , ","
    , cats("type=", type)
    , ","
    , cats("outfile=", catx("_", sectionName, elementName,  visualType) )
    , ","
    , "jobid=&job_id"
    , ")"
  );
  put line;
  %put line;
  putlog line;
run;

%inc getimg / source2;


/* PPT generation integrating the images */
/* Warning : svg needs to be converted to png or jpeg through xcmd and command line tool or other means */

/*

%macro print_images(name, folder, titl);
	title "Export for graph: &titl";

	data _NULL_;
	 	dcl odsout obj();
	 	obj.image(file:"~/&job_id/&name..png", height:"720", width:"1280");
	run;
%mend;

filename ppt temp;

data _null_;
  set img_info;
  file ppt;
  length line $ 2048;
  line = cats(
    '%print_images('
    , cats("name=", catx("_", sectionName, elementName,  visualType) )
    , ","
    , "folder=&job_id,"
    , cats("titl=",sectionLabel)
	, ")" 
  );
  put line;
  putlog line;
run;

ods powerpoint file="~/&job_id/new_ppt.pptx";

%inc ppt / source2;  

ods powerpoint close;

*/
/* pour le report */

%let BASE_URI=%sysfunc(getoption(SERVICESBASEURL));
FILENAME rptFile TEMP ENCODING='UTF-8';

PROC HTTP METHOD = "GET" oauth_bearer=sas_services OUT = rptFile
      /* get a list of reports, say report name is 'Report 2' */
      URL = "&BASE_URI/reports/reports?filter=eq(name,'NICOAPI')";
      HEADERS "Accept" = "application/vnd.sas.collection+json"
               "Accept-Item" = "application/vnd.sas.summary+json";
RUN;
LIBNAME rptFile json;

/* en proc http  pour le detail image */

/* le body est mis dans un fichier externe */
filename json_in temp;
data _null_;
file json_in;
input;
put _infile_;
datalines;
{
  "version" : 1,
  "reportUri" : "/reports/reports/b97f5e34-2b47-4770-8f97-ff4e2f8df1f2",
  "layoutType" : "entireSection",
  "selectionType" : "report",
  "size" : "800x600",
  "refresh":true
}
;;;;
run;


%let BASE_URI=%sysfunc(getoption(SERVICESBASEURL));
FILENAME ImgFile TEMP ENCODING='UTF-8';

PROC HTTP METHOD = "POST" oauth_bearer=sas_services in=json_in OUT = ImgFile
      /* get a list of reports, say report name is 'Report 2' */
      URL = "&BASE_URI/reportImages/jobs?filter=eq(name,'NICOAPI')";
/* /reports/reports/a5d501ff-cdbf-41e4-a59d-9912d3759b4c */
      HEADERS "Accept" = "application/vnd.sas.report.images.job+json"
               "Content-Type" = "application/vnd.sas.report.images.job.request+json";
RUN;
LIBNAME ImgFile json;



/* on s'interresse a limage qui va bien */

/* en proc http */
%let BASE_URI=%sysfunc(getoption(SERVICESBASEURL));
FILENAME resultIM TEMP ENCODING='UTF-8';

PROC HTTP METHOD = "GET" oauth_bearer=sas_services OUT = resultIM
      /* get a list of reports, say report name is 'Report 2' */
      URL = "&BASE_URI/reportImages/jobs/abc5822a-f91c-4607-b6c7-221365bbc9b5";
      HEADERS "Accept" = "application/vnd.sas.report.images.job+json";

RUN;
LIBNAME resultIM json;



/* enfin on recupere le SVG */

/* en proc http */
%let BASE_URI=%sysfunc(getoption(SERVICESBASEURL));

filename mysvg filesrvc folderpath="/France/Tmp/NCO/Temp" filename='report2.svg';
PROC HTTP METHOD = "GET" oauth_bearer=sas_services OUT = mysvg
      /* get a list of reports, say report name is 'Report 2' */
      URL = "&BASE_URI/reportImages/images/K1266513883B1548982811.svg";
HEADERS "Accept" = "image/svg+xml";
RUN;


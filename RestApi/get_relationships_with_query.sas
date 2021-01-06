options ls=max nodate;
ods _all_ close;
filename resp temp;
%let limit=10;

%let BASE_URI=%sysfunc(getoption(SERVICESBASEURL));

filename body_in temp  ENCODING='UTF-8'; /* file to put body content */
FILENAME resp TEMP ENCODING='UTF-8'; /* file to get json response content */
FILENAME respHdr TEMP ENCODING='UTF-8'; /* file to get json response header */


data _null_;
	file body_in;
	input;
	put _infile_;
	datalines;
{
  "referenceId":[
    "70a41c20-0246-49ff-ab5e-dce53a2ca8c8"
  ],
  "depth": 3
}
run;

PROC HTTP 
	METHOD = "GET"
	URL = "&BASE_URI/relationships/relationships#withQuery?limit=&limit" 
	oauth_bearer = sas_services
	out=resp 
	headerout=respHdr
	headerout_overwrite
	IN=body_in;
	HEADERS
		'Accept' = 'application/vnd.sas.collection+json'
		'Content-type'= 'application/vnd.sas.relationship.query+json';
	debug level=1;
RUN;
QUIT;

libname resp json;


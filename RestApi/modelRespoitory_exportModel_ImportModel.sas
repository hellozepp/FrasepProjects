ods _all_ close;

/***************************************************************************/
*%global model_id location datalabUrl productionUrl destModelName destProjectName versionOption;

/****************************************************************************************************************/
/* Connection profile for target environment */
%let CLIENT_ID=sas.ec;
%let CLIENT_SECRET=;
%let USERNAME=viadmin;
%let PASSWORD=Orion123;

/***************************************************************************/
/* Unit test : source datalab environment */
%let datalabUrl=https://tenant2.sasserver.demo.sas.com:443/;
*%let productionUrl=https://tenant1.sasserver.demo.sas.com:443/;
%let srcModelId=ba07ff28-207a-48c7-9f95-54608f1e57b3;
%let fileType=zip;
/* Unit test : target production environment */
%let productionUrl=https://tenant2.sasserver.demo.sas.com:443/;
%let destProjectid=41efd9b7-d7ea-47f7-a0ba-802c8a6e367c;
%let destProjectName=QS_HMEQ;
%let destModelName=QSTree1;
%let versionOption=NEW;
/***************************************************************************/

%let currdt=%sysfunc(putn(%sysfunc(datetime()),datetime18.));
%let zipFileName=%str(/)tmp%str(/)&srcModelId%str(.)&fileType;

FILENAME respHdr "/tmp/respHdr" ENCODING='UTF-8'; /* file to get json response header */
filename zipFile "&zipFileName";
%put &zipFileName;

/***************************************************************************/
/* Generate zip package of the model content                               */
/***************************************************************************/
%let REST_QUERY_URI=&datalabUrl.modelRepository/models%str(/)&srcModelId%str(?)format=&fileType;
/* Execute the get  */
PROC HTTP 
	METHOD="GET" URL="&REST_QUERY_URI" oauth_bearer = sas_services out=ZipFile headerout=respHdr headerout_overwrite;
RUN;
QUIT;

/****************************************************************************************************************/
/* Import the model in the target project and target environment                                                */
/* API used : https://developer.sas.com/apis/rest/DecisionManagement/#import-a-model-through-an-octet-stream    */
/****************************************************************************************************************/
%let REST_QUERY_URI=&productionUrl.modelRepository/models%str(?)name=&destModelName%str(&)type=&fileType%str(&)projectId=&destProjectId%str(&)versionOption=&versionOption;
*%let REST_QUERY_URI=&productionUrl.modelRepository/models%str(?)name=&destModelName%str(&)type=&fileType%str(&)projectName=&destProjectName%str(&)versionOption=&versionOption;
%put &REST_QUERY_URI;

filename resp temp;
filename resp_hdr temp;

/* 	Get access and refresh tokens in JSON format; */
proc http url="&productionUrl.SASLogon/oauth/token" method='post' in="grant_type=password%nrstr(&username=)&USERNAME%nrstr(&password=)&PASSWORD" username="&CLIENT_ID" password="&CLIENT_SECRET" out=resp auth_basic verbose;
run;
quit;

/* 	Get the access token from the JSON data and store it in the ACCESS_TOKEN macro variable. */
libname tokens json "%sysfunc(pathname(resp))";
proc sql noprint;
	select access_token into:ACCESS_TOKEN from tokens.root;
quit;

PROC HTTP 
	URL="&REST_QUERY_URI" METHOD="POST" IN=ZipFile headerout=respHdr headerout_overwrite;
	debug level=3;
	headers 'Authorization'="Bearer &ACCESS_TOKEN";
	headers 'Content-Type'="application/octet-stream";
	*headers 'Content-Type'="multipart/form-data";
	*headers 'Accept'="application/vnd.sas.collection+json";
RUN;
QUIT;

ods _all_ close;


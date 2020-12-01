%let BASE_URI=%sysfunc(getoption(SERVICESBASEURL));
%let USERNAME=viyademo01;
%let PASSWORD=demopw;
%let limit=100;
%let location=/tmp;

%let currdt=%sysfunc(datetime());

/***************************************************************************************************/
*Use the Client ID to Get an Access Token;
*Submit this code once to get the access token or repeat if your access token has expired.;
options ls=max nodate;
ods _all_ close;
%let CLIENT_ID=frasepapp;
%let CLIENT_SECRET=frasepsecret;
filename resp temp;
filename resp_hdr temp;

proc http url="&BASE_URI/SASLogon/oauth/token" method='post' 
		in="grant_type=password%nrstr(&username=)&USERNAME%nrstr(&password=)&PASSWORD" 
		username="&CLIENT_ID" password="&CLIENT_SECRET" out=resp auth_basic verbose;
	debug level=3;
run;
quit;

libname tokens json "%sysfunc(pathname(resp))";

proc sql noprint;
	select access_token into:ACCESS_TOKEN from tokens.root;
quit;

/***************************************************************************************************/
/* Get all authorization rules                                                                     */
/***************************************************************************************************/
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

filename rRul "&location/get_rules_b.json";
filename rRulhdr "&location/get_rules_b.txt";

proc http url="&BASE_URI/authorization/rules?limit=100000" method='get' out=rRul headerout=rRulhdr headerout_overwrite;
	debug level=3;
	headers 'Authorization'="Bearer &ACCESS_TOKEN";
run;
quit;

LIBNAME rRul json;


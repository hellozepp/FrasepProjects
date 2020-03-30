options cashost="sepviya35.aws.sas.com" casport=5570;

cas lineagesess;

caslib _all_ assign;

%macro getlineagedata(BASE_URI, USERNAME, PASSWORD, NAME, limit, depth, CAS_OUTPUT_TABLE); 
	*Use the Client ID to Get an Access Token;
	*Submit this code once to get the access token or repeat if your access token has expired.;
	options ls=max nodate;
	ods _all_ close;
/* 	Specify the new Client ID name; */
	*! Name must be registered above - no spaces;
	%let CLIENT_ID=frasepapp;
/* 	Specify the secret for the new Client ID; */
	%let CLIENT_SECRET=frasepsecret;
/* 	FILEREFs for the response and the response headers; */
	filename resp temp;
	filename resp_hdr temp;
/* 	Get access and refresh tokens in JSON format; */

	proc http url="&BASE_URI/SASLogon/oauth/token" method='post' in="grant_type=password%nrstr(&username=)&USERNAME%nrstr(&password=)&PASSWORD" username="&CLIENT_ID" password="&CLIENT_SECRET" out=resp auth_basic verbose;
		debug level=3;
		run;
	quit;
/* 	Get the access token from the JSON data and store it in the ACCESS_TOKEN macro variable. */
	libname tokens json "%sysfunc(pathname(resp))";

	proc sql noprint;
		select access_token into:ACCESS_TOKEN from tokens.root;
	quit;

	filename respb "&location/get_ref_b.json";
	filename resphdrb "&location/get_ref_b.txt";

	proc http url="&BASE_URI/relationships/relationships/?filter=contains(resourceUri,&NAME)%str(&)limit=&limit%str(&)depth=&depth"
			method='get' 
		out=respb headerout=resphdrb headerout_overwrite;
		debug level=0;
		headers 'Authorization'="Bearer &ACCESS_TOKEN";
	run;
	quit;

	libname obj2 json "%sysfunc(pathname(respb))";
	data casuser.&CAS_OUPUT_TABLE;
		set obj2.items;
	run;

	proc casutil;
		PROMOTE CASDATA="&CAS_OUTPUT_TABLE"  CASOUT="&CAS_OUTPUT_TABLE" OUTCASLIB="public" DROP;
	quit;
	
%mend getlineagedata;

%let hostname=&http://sepviya35.aws.sas.com;

%macro getlineagedata(&hostname, viyademo01, demopw, HMEQ_TRAIN, 100, 20, LINEAGE); 

cas lineagesess terminate;

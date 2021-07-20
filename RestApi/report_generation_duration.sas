* Base URI for the service call;
%let BASE_URI=%sysfunc(getoption(servicesbaseurl));

%macro report_generation_duration(caslib, sourcedata, srcextension, report_name, report_uri);
	/* Refresh Data in CAS */
	cas myses;
	proc casutil;
		droptable incaslib="&caslib" casdata="&sourcedata" quiet;
		load incaslib="&caslib" outcaslib="&caslib" casdata="&sourcedata.&srcextension" casout="&sourcedata" promote;
	run;
	/* create dynamic proc http 'in=' statement  */
	data create_params;
		request_params = "'"|| trim('{"reportUri" : "') || "&report_uri"|| trim('","layoutType" : "entireSection","refresh":true,"selectionType" : "report","size" : "1680x1050","version" : 1}'|| "'");
		call symput('request_params',request_params);
	run;
	/* create job and get response */
	filename resp_hdr clear;
	filename startjob clear;
	libname startjob clear;
	
	filename startjob temp;
	filename resp_hdr temp;
	
	proc http method="POST" oauth_bearer=sas_services 
		url="&BASE_URI/reportImages/jobs"
		ct="application/vnd.sas.report.images.job.request+json"
		in=&request_params.
		out=startjob
		headerout=resp_hdr
		headerout_overwrite;
	run;
	
	libname startjob json;
	
	/* capture job id into macro variable job_id */
	data _NULL_;
		set startjob.root;
		call symputx('job_id',id);
	run;
	/* Set initial &status to be zero */
	
	%let status=0;
	
	/* macro to check status until job is completed */
	%macro jobstatus;
		%do %until(&status ne 0);
			filename res_hdr clear;
			filename j_status clear;
			libname j_status clear;
			filename j_status temp;
			filename res_hdr temp;
			
			/* Make API Call*/
			proc http method="GET" oauth_bearer=sas_services
				url="&BASE_URI/reportImages/jobs/&job_id"
				out=j_status
				headerout=res_hdr
				headerout_overwrite;
			run;
			
			libname j_status json;
			%put "FLAG1"
			/* create &status macro variable */
			data job_status;
				set j_status.root;
				if state = 'running' then status = 0;
				else if state = 'completed' then status = 1;
				call symputx('status',status);
			run;
			
		%end;
	%mend jobstatus;
	
	/* call macro %jobstatus */
	%jobstatus;
	/* create and print final dataset */
	data report;
		set j_status.root;
		reportName = "&report_name";
		reportURI = "&report_uri";
		label id = "reportImagesJob ID" duration = "Job Duration"
		label state="Job Status";
	run;
	/* Print output */
	title "reportImages Duration -Report: '&report_name'";
	proc print data=report noobs label;
		var reportName reportURI id state duration;
	run;
	
	cas myses terminate;
%mend report_generation_duration;
			
			
/* Unit test */
%report_generation_duration(dnfs,megacorp5_4m,.parquet,Report_API_test,/reports/reports/0c6b6b59-1a11-435f-ba6a-aba0fd154b80);
			
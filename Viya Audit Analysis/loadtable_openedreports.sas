/******************************************************************************/
/* $Id:$*/
/**/
/* Copyright(c) 2017 SAS Institute Inc., Cary, NC, USA. All Rights Reserved.*/
/**/
/* Name: loadtable_openedreports.sas*/
/**/
/* Purpose: Capture data on report open events by date, time, user and report */
/**/
/* Author: Tommy Armstrong*/
/**/
/* Support: SAS(r) Global Hosting and US Professional Services */
/**/
/* Input: Metadata, server name, server type, base url, report opening csv file, */
/* 		  CAS report opening table */
/**/
/* Output:*/
/**/
/* Parameters: (if applicable)*/
/**/
/* Dependencies/Assumptions: A report opening table is currently loaded in memory */
/*							 under the internal caslib */
/**/
/* Usage: Daily update to pull in the new report open events */
/**/
/* History:*/
/* 08DEC2020 toarms adding to SVN */
/* 09DEC2020 toarms implemented VA report links into table */
/******************************************************************************/

/* Code written to be run in SAS Studio on Viya */

/* Get Rules */


%let BASE_URI=%sysfunc(getoption(servicesbaseurl));

filename uri temp;
filename uri_hdr temp;

proc http url="&BASE_URI/authorization/rules?limit=100000" method='get' oauth_bearer=sas_services out=uri headerout=uri_hdr headerout_overwrite;
     headers "Accept"="application/json";
run;

libname uri json;

proc sql;
create table work.folder_rule as 
select substr(ObjectUri,1,find(ObjectUri,'/**')-1) as FolderURI, Principal as group
from
uri.ITEMS
where
objectUri contains '/folders/folders/' and objectUri contains '/**' and Principal ne '';
quit;

proc sql;
create table work.dashboard_rule as 
select *
from
uri.ITEMS
where
objectUri = '/folders/folders/73b46bb2-0fe9-4276-a0c9-7948b3e9f642/**';
quit;

/* Get Folders */

filename full temp;
filename full_hdr temp;

proc http url="&BASE_URI/folders/folders/eac327fc-fa30-4f56-810b-c7e98e68d071/members?limit=100000&recursive=true" method='get' oauth_bearer=sas_services out=full headerout=full_hdr headerout_overwrite;
     headers "Accept"="application/json";
run;

libname full json;

proc sql;
create table work.base_folder as
select distinct  
a.id, a.name,
case 
when a.ParentFolderURI = '/folders/folders/eac327fc-fa30-4f56-810b-c7e98e68d071' then catt('/NDT/',a.name) 
when b.ParentFolderURI = '/folders/folders/eac327fc-fa30-4f56-810b-c7e98e68d071' then catt('/NDT/',b.name,'/',a.name) 
when c.ParentFolderURI = '/folders/folders/eac327fc-fa30-4f56-810b-c7e98e68d071' then catt('/NDT/',c.name,'/',b.name,'/',a.name) 
when d.ParentFolderURI = '/folders/folders/eac327fc-fa30-4f56-810b-c7e98e68d071' then catt('/NDT/',d.name,'/',c.name,'/',b.name,'/',a.name) 
when e.ParentFolderURI = '/folders/folders/eac327fc-fa30-4f56-810b-c7e98e68d071' then 
catt('/NDT/',e.name,'/',d.name,'/',c.name,'/',b.name,'/',a.name)
else ''
end as path format=$char320.,
a.uri, 
a.ParentFolderURI as Pa, 
b.ParentFolderURI as Pb, 
c.ParentFolderURI as Pc, 
d.ParentFolderURI as Pd, 
e.ParentFolderURI as Pe
from 
full.items as a
left join
full.items as b
on b.uri = a.ParentFolderURI
left join
full.items as c
on c.uri = b.ParentFolderURI
left join
full.items as d
on d.uri = c.ParentFolderURI
left join
full.items as e
on e.uri = d.ParentFolderURI;
quit;

data work.base_folder2;
id = '';
name = 'NDT';
path = '/NDT';
uri = '/folders/folders/eac327fc-fa30-4f56-810b-c7e98e68d071';
run;

proc append base=work.base_folder data=work.base_folder2;
quit;

proc sql;
create table work.folder_path as 
select a.*, b.path, b.Pa as ParentFolder, count(*) as group_rules
from 
work.folder_rule as a
inner join
work.base_folder as b
on a.FolderURI = b.URI
group by group;

create table sub_group as
select *
from work.folder_path 
where group in (select group from work.folder_path where ParentFolder = '/folders/folders/73b46bb2-0fe9-4276-a0c9-7948b3e9f642')
and ParentFolder = '/folders/folders/73b46bb2-0fe9-4276-a0c9-7948b3e9f642';

create table master_group as
select *
from work.folder_path 
where group not in (select group from work.folder_path where ParentFolder = '/folders/folders/73b46bb2-0fe9-4276-a0c9-7948b3e9f642')
and ParentFolder = ''
;
quit;

/* Get Reports */

%let folder_users=/folders/folders/944527eb-fc9c-4866-be24-87adff30ba12;
%let folder_dashboards=/folders/folders/73b46bb2-0fe9-4276-a0c9-7948b3e9f642;

filename rpt temp;
filename rpt_hdr temp;
proc http url="&BASE_URI.&folder_dashboards./members?limit=100000&recursive=true" method='get' oauth_bearer=sas_services out=rpt headerout=rpt_hdr headerout_overwrite;
     headers "Accept"="application/json";
run;
libname rpt json;

filename rpt_usr temp;
filename rpt_hdru temp;
proc http url="&BASE_URI.&folder_users./members?limit=100000&recursive=true" method='get' oauth_bearer=sas_services out=rpt_usr headerout=rpt_hdru headerout_overwrite;
     headers "Accept"="application/json";
run;
libname rpt_usr json;

proc sql;
create table work.report_folder as 
select URI as ReportURI, Name as ReportName, parentFolderUri as FolderURI
from
rpt.ITEMS
union
select URI as ReportURI, Name as ReportName, parentFolderUri as FolderURI
from
rpt_usr.ITEMS
where
contentType = 'report';
quit;

proc sql;
create table work.folder_folder as 
select distinct b.ReportName, b.ReportURI,
case 
when a.ParentFolderURI = '/folders/folders/73b46bb2-0fe9-4276-a0c9-7948b3e9f642' then a.Name 
when c.ParentFolderURI = '/folders/folders/73b46bb2-0fe9-4276-a0c9-7948b3e9f642' then c.Name
when d.ParentFolderURI = '/folders/folders/73b46bb2-0fe9-4276-a0c9-7948b3e9f642' then d.Name
when e.ParentFolderURI = '/folders/folders/73b46bb2-0fe9-4276-a0c9-7948b3e9f642' then e.Name
else '' 
end as Workstream,
case 
when a.ParentFolderURI = '/folders/folders/73b46bb2-0fe9-4276-a0c9-7948b3e9f642' then a.URI 
when c.ParentFolderURI = '/folders/folders/73b46bb2-0fe9-4276-a0c9-7948b3e9f642' then c.URI
when d.ParentFolderURI = '/folders/folders/73b46bb2-0fe9-4276-a0c9-7948b3e9f642' then d.URI
when e.ParentFolderURI = '/folders/folders/73b46bb2-0fe9-4276-a0c9-7948b3e9f642' then e.URI
else '' 
end as Workstream_URI
from
rpt.ITEMS a
inner join
work.report_folder b
on a.URI = b.FolderURI
left join
rpt.ITEMS c
on a.parentFolderUri = c.URI
left join
rpt.ITEMS d
on c.parentFolderUri = d.URI
left join
rpt.ITEMS e
on d.parentFolderUri = e.URI;

create table work.report_groups_sub as
select a.*, b.group
from 
work.folder_folder a
left join
work.folder_rule b
on a.Workstream_URI = b.FolderURI
where b.group not in (select group from work.master_group);

create table work.report_groups as
select a.*, b.group
from 
work.folder_folder a
left join
work.master_group b
on 1 = 1;

quit;

proc append base=work.report_groups data=work.report_groups_sub;
quit;

/* Get Users */

proc sql;
create table groups as
select distinct group
from work.report_groups
where group not in  ('','NDT_Bridge_B','NDT_Bridge_R', 'majose');

create table WORK.USER_GROUP
  (
   id char(50),
   name char(100),
   group char(50)
  );
quit;

data groups;
set groups;
n = _n_;
run;

%macro get_users;

proc sql noprint;
select n into :n
from groups
having n = max(n);
quit;


%do i = 1 %to &n;

proc sql noprint;
select group into :group
from groups
where n = &i;
quit;

filename resp temp;
filename resp_hdr temp;

%put &group;

proc http url="&BASE_URI/identities/groups/%TRIM(&group)/members?limit=100000" method='get' oauth_bearer=sas_services out=resp headerout=resp_hdr headerout_overwrite;
     headers "Accept"="application/json";
run;

libname resp json;

proc sql noprint;
select count into :count
from resp.root;
quit;

%if &count ^= 0 %then
%do;

proc sql;
create table work.user_group_temp as
select id, name, "%TRIM(&group)" as group
from resp.items;
quit;

proc append base=WORK.USER_GROUP data=WORK.USER_GROUP_temp force;
quit;

%end;
%end;

%mend;

%get_users


/******************************************************************************/
/* CREATION/UPDATE OF OPENEDREPORTS DATA TABLE								  */
/******************************************************************************/

/* Import a csv file from the location specified on the filename statement */
filename rptcsv '/ndt/projects/internal/toarms/trunk/output/reportsopened.csv';

/* Import the CSV file  */
proc import datafile=rptcsv out=work.openedreports_raw dbms=csv replace;
   	getnames=yes;
	guessingrows=max;
run;

/* Create a new column that will store the VA link to the report */
%let base_link=https://ndtviyaprod.ondemand.sas.com/links/resources/report?uri=/reports/reports/;
data openedreports_links;
	set work.openedreports_raw;
	if report_uri =: '/reports/reports/' then
		report_link=cats("&base_link",substr(report_uri,18));
	else report_link=report_uri;
run;

/* create a datatable that combines the data from the csv file and the data queried */
/* from the above API calls in order to join the report open events with report */
/* names, user names, and workstreams */
proc sql;
	create table new_open_reports as
	select distinct or.date format=date9., or.time format=timeampm11., or.user, 
					ug.name, rf.reportname, or.report_uri, ff.workstream, or.report_link,
					catx('T',put(or.date,yymmddd10.),put(or.time,time12.3)) as unique_open
	from work.openedreports_links as 'or'n left join
		 (select distinct reporturi, reportname, folderuri from work.report_folder) as rf
		 on or.report_uri = rf.reporturi left join
		 (select distinct id, name from work.user_group) as ug
		 on or.user = ug.id left join
		 (select distinct reporturi, workstream from work.folder_folder) as ff
		 on or.report_uri = ff.reporturi
	order by or.date, or.time;
quit;

/* open a cas session to connect to the internal caslib and update the in-memory */
/* openedreports table */
cas mySession sessopts=(caslib=internal);
libname internal cas caslib=internal;

/* append the new open report events to the in-memory openedreports table */
data internal.openedreports(append=force);
	set work.new_open_reports;
run;

/* data step used if the entire in-memory table needs replaced or updated */
/* data internal.openedreports(replace=yes); */
/* 	set work.new_open_reports; */
/* run; */

/* save the newly appended in-memory table to a sashdat file, drop the table from */
/* memory, and then reload it from the newly saved sashdat table */
proc casutil incaslib="internal" outcaslib="internal";
	save casdata="openedreports" casout="openedreports" replace;
	droptable casdata="openedreports" quiet;
	droptable casdata="openedreports" quiet;
	load casdata="openedreports.sashdat" casout="openedreports" promote;
quit;

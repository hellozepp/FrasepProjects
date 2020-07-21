cas casauto;

caslib _all_ assign;

ods noproctitle;

/* removed outlier by trader, and get from data viz a usable filter */
data casuser.new_train;
set PUBLIC.STREAMTOTALCOST_TRAIN;
where NOT(( ( 'totalCost'n >= 15000 ) AND ( 'totalCost'n < 75000 ) ))
AND NOT(( ( 'totalCost'n >= 75000 ) AND ( 'totalCost'n < 90000 )
)) AND ( NOT(( ( 'totalCost'n >= 97500 ) AND ( 'totalCost'n <
142500 ) )) AND NOT(( ( 'totalCost'n >= 157500 ) AND (
'totalCost'n < 262500 ) )) ) AND ( NOT(( ( 'totalCost'n >= 0 )
AND ( 'totalCost'n < 20000 ) )) AND NOT(( ( 'totalCost'n >=
140000 ) AND ( 'totalCost'n < 160000 ) )) AND NOT(( (
'totalCost'n >= 260000 ) AND ( 'totalCost'n < 320000 ) )) );
run;

proc svdd data=casuser.new_train;
	input totalCost / level=interval;
	input name / level=nominal;
	kernel rbf / bw=2;
	savestate rstore=casuser.trade_outliers_svdd;
	id _all_;
run;

/*
proc forest data=PUBLIC.STREAMTOTALCOST_TRAIN isolation seed=12345;
   input totalCost /level=interval;
   id id;
   output out=mycas.score copyvars=(_ALL_);
run;
*/

%let MyMMProject = %str(Trade_ML001);

%mm_delete_project(projectnm=&MyMMProject);

%mm_get_folder_id(foldernm=public, idvar=folderID);

%mm_create_project(
	projectnm        = &MyMMProject,    
	folderID         = %str(&folderID),    
	function         = Classification,
	projectID        = projID,
	projectversionID = projVerID);

/*
%mm_get_project_id(projectNm=%str(Trade_ML001), idvar=myProjID);
*/

%mm_import_astore_model(
	locationID=%str(&projID), 
	modelname=%str(outliers_svdd), 
	modeldesc=%str(SVDD unsupervised model used to detect outliers in trades), 
	projectVersion=%str(new), 
	rstore=CASUSER.TRADE_OUTLIERS_SVDD);

cas casauto terminate;

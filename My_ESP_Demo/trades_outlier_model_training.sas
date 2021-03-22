cas casauto;

caslib _all_ assign;

ods noproctitle;

/*
proc cas;
	table.loadtable / caslib='PUBLIC' path='STREAMTOTALCOST_TRAIN.sashdat' casout={caslib='PUBLIC' name='STREAMTOTALCOST_TRAIN' replace=true};
quit;
*/

/* get from data viz a usable filter to retrieve a normal activity period */
data PUBLIC.STREAMTOTALCOST_TRAIN;
	set PUBLIC.STREAMTOTALCOST_TRAIN(drop=_SVDDDISTANCE_ _SVDDSCORE_);
run;

proc cas;
	table.save / caslib='public' name='STREAMTOTALCOST_TRAIN.sashdat' table={caslib='public' name='STREAMTOTALCOST_TRAIN'} replace=true;
quit;

proc svdd data=casuser.new_train;
	input totalCost / level=interval;
	kernel rbf / bw=mean2;
	savestate rstore=casuser.trade_outliers_svdd;
	id _all_;
run;

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

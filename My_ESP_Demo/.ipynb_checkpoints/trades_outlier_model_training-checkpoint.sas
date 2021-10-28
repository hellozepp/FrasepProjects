%let csvdata=/home/viyademo01/my_git/My_ESP_Demo/data/trade_events_training.csv;

cas casauto;
caslib _all_ assign;
ods noproctitle;

/* Upload training data */

proc cas;
	table.droptable / caslib="PUBLIC" name="STREAMTOTALCOST_TRAIN" quiet=true;
	upload / path="&csvdata" casOut={caslib="PUBLIC", name="STREAMTOTALCOST_TRAIN", promote=TRUE,replication=0} importOptions={fileType="csv", guessRows=20};
quit;

proc cas;
   table.droptable / caslib="PUBLIC" name="STREAMTOTALCOST_SCORED" quiet=true;
quit;

/*
proc svdd data=PUBLIC.STREAMTOTALCOST_TRAIN;
	id traderID;
	input totalCost / level=interval;
	kernel rbf / bw=mean2;
	savestate rstore=casuser.trade_outliers_svdd;
run;
*/

proc forest data=PUBLIC.STREAMTOTALCOST_TRAIN isolation seed=12345;
   id traderID;
   input totalCost /level=interval;
   output out=PUBLIC.STREAMTOTALCOST_SCORED copyvars=(_ALL_);
   savestate rstore=casuser.trade_outliers_isolation_forest;
run;

/*
proc cas;
   table.droptable / caslib="PUBLIC" name="STREAMTOTALCOST_SCORED" quiet=true;
   action aStore.score /
      table={name='STREAMTOTALCOST_TRAIN', caslib="PUBLIC"},
      out={name='STREAMTOTALCOST_SCORED', caslib="PUBLIC", promote="TRUE"},
	  copyVars={"name","price","quantity","security","time","totalCost","tradeID","traderID"},
      rstore={name='trade_outliers_svdd'};
run;
quit;
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
	modelname=%str(outliers_isolation_forest), 
	modeldesc=%str(Isolation forest model used to detect outliers in trades), 
	projectVersion=%str(new), 
	rstore=CASUSER.trade_outliers_isolation_forest);

cas casauto terminate;


/*
proc cas;
	table.loadtable / caslib='PUBLIC' path='STREAMTOTALCOST_TRAIN.sashdat' casout={caslib='PUBLIC' name='STREAMTOTALCOST_TRAIN' replace=true};
quit;
*/

/* get from data viz a usable filter to retrieve a normal activity period */
/*
data PUBLIC.STREAMTOTALCOST_TRAIN;
	set PUBLIC.STREAMTOTALCOST_TRAIN(drop=_SVDDDISTANCE_ _SVDDSCORE_);
run;

proc cas;
	table.save / caslib='public' name='STREAMTOTALCOST_TRAIN.sashdat' table={caslib='public' name='STREAMTOTALCOST_TRAIN'} replace=true;
quit;
*/

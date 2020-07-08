cas casauto;

caslib _all_ assign;


ods noproctitle;

proc svdd data=PUBLIC.STREAMTOTALCOST;
	input quantity totalCost / level=interval;
	kernel rbf / bw=mean;
	solver stoch;
	savestate rstore=casuser.trade_outliers_svdd;
	id _all_;
run;

%mm_get_project_id(projectNm=%str(Trade_ML001), idvar=myProjID);
%mm_import_astore_model(locationID=%str(&myprojID), 
	modelname=%str(outliers_svdd), modeldesc=%str(), projectVersion=%str(new), 
	rstore=CASUSER.TRADE_OUTLIERS_SVDD);

cas casauto terminate;

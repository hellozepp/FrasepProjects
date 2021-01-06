/******************************************************************************/
/* DEMO HMEQ : SAS Random Forest training code and model registering in the   */
/* central model repository of SAS Viya                                       */
/******************************************************************************/

%let cashost=frasepviya35smp.cloud.com;
%let mmbaseurl=http://frasepviya35smp.cloud.com;

options cashost=&cashost casport=5570;

cas _CAS_PUBLIC_;

caslib _ALL_ assign;

/******************************************************************************/
/* Create a Forest analytic store model and store the model in a  CAS table.  */
/******************************************************************************/

proc forest data=public.hmeq_train 
     seed=12345 loh=0 binmethod=QUANTILE maxbranch=2 
     assignmissing=USEINSEARCH minuseinsearch=1
     ntrees=100
     maxdepth=20
     inbagfraction=0.6
     minleafsize=5
     numbin=50
     vote=PROBABILITY printtarget;
  target BAD / level=nominal;
  input LOAN MORTDUE VALUE YOJ DEROG DELINQ CLAGE CLNO DEBTINC / level=interval;
  input REASON JOB NINQ / level=nominal;
  savestate rstore=public.state;
run;

/******************************************************************************/
/* Create a GBM analytic store model and store the model in a  CAS table.  */
/******************************************************************************/
/*
proc gradboost data=PUBLIC.HMEQ_TRAIN;
	partition fraction(validate=0.3 test=0.1 seed=567);
	target BAD / level=nominal;
	input LOAN MORTDUE VALUE YOJ DEROG DELINQ CLAGE NINQ CLNO DEBTINC / 
		level=interval;
	input REASON JOB / level=nominal;
	savestate rstore=public.state_gbm;
	id _all_;
run;
*/
/******************************************************************/
/* Optional : Recreate a clean HMEQ_Modeling project for the demo */
/******************************************************************/

%mm_delete_project(projectnm=HMEQ_Modeling, servernm=&mmbaseurl);
%mm_get_folder_id(foldernm=Public, idvar=myFldrID, servernm=&mmbaseurl);
%mm_create_project(projectnm = HMEQ_Modeling, folderID= &myFldrID,function= Classification,servernm= &mmbaseurl,projectID= myProjID, projectversionID = projVerID);

/******************************************************************/
/* REGISTER NEW TRAINED MODEL IN THE CENTRALIZED MODEL REPOSITORY */
/* through MACRO (coded or generated by graphical task)           */
/******************************************************************/

%mm_get_project_id(projectnm=%nrstr(HMEQ_Modeling), idvar=myProjID, servernm=&mmbaseurl);

%mm_import_astore_model(
	locationID=&myProjID,
	isfolder=N, 
	modelname=%nrstr(Forest Astore SAS Studio on HMEQ TRAIN),  
	modeldesc=Forest,	
	target=BAD,  
	targetlevel=binary, 
	projectVersion=%str(new), 
	rstore=public.state /* Specify the binary state of the model produced in the training phase */, 
	miningAlgorithm=%nrstr(forest), 
	miningFunction=classification,  
	pkgfolder=/opt/demo/mmpkgs);


cas _CAS_PUBLIC_ terminate;

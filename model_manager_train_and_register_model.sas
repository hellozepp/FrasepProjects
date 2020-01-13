cas _CAS_PUBLIC_;
caslib _ALL_ assign;
libname local '/opt/shared/MMLib';

%mm_loadData2CAS
(
  sasData= local.hmeqperf_1_q1,
  outcaslib=public,
  options=replace
);

/* Create a Forest analytic store model and store the model in a CAS table. */


proc forest data=public.hmeqperf_1_q1 
     seed=12345 loh=0 binmethod=QUANTILE maxbranch=2 
     assignmissing=USEINSEARCH minuseinsearch=1
     ntrees=50
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



%mm_get_project_id(
    projectnm=%nrstr(QS_HMEQ),
    idvar=myProjID,
    servernm=%nrstr(https://sepviya35.aws.sas.com)
);

%mm_import_astore_model(
    locationID=&myProjID,
    isfolder=N,    
	modelname=%nrstr(Forest Astore),
    modeldesc=Forest,
    /* projectVersion=%str(new), */
    rstore=public.state,
    miningAlgorithm=%nrstr(forest),
    miningFunction=classification,    
	pkgfolder=/opt/shared/mmpkgs);
/* PKGFOLDER =ZIP-package-folder
specifies the location for the ZIP package that is built during the macro execution. 
The ZIP file contains all the supporting component files, such as JSON, XML, and SAS files. */

cas _CAS_PUBLIC_ terminate;
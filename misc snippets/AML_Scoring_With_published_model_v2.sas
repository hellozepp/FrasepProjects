cas mysess;

caslib pglib datasource=(srctype="postgres", username="dbmsowner", password="LyuoysIuWjr09T3g1SGE1Lz49Pv0ajt", server="52.186.10.200", database="tenant2",schema='public', conopts="sslmode=required");

proc casutil; 
	list files incaslib="pglib";
run;

proc cas;
	function doesTableExist(casLib, casTable);
  		table.tableExists result=r status=rc / caslib=casLib table=casTable;
  		tableExists = dictionary(r, "exists");
  		return tableExists;
	end func;

	/* Load model table if not already loaded */
	exists = doesTableExist("public", "sas_model_table");
	if (exists=0) then do;
  	  table.loadtable / caslib="public" path="sas_model_table.sashdat" casout={name="sas_model_table", caslib="public"};
  	end;

	exists = doesTableExist("pglib", "fsc_party_dim");
	if (exists=0) then do;
  	  table.loadtable / caslib="pglib" path="fsc_party_dim" casout={caslib="pglib", name="fsc_party_dim"};
  	end;

	/* Score with published model the production party data from AML core model directly*/
	loadactionset "modelPublishing";
	runModelLocal / outTable={caslib="casuser", name="TMP_PARTY_SCORED"}, intable={caslib="pglib" name="FSC_PARTY_DIM"}, modelName="AMLAlertScoring" , modelTable={caslib="public" name="sas_model_table"};
	run;
quit;

data pglib.party_score;
	set casuser.TMP_PARTY_SCORED(keep=party_key EM_EVENTPROBABILITY);
	if EM_EVENTPROBABILITY>=0 and EM_EVENTPROBABILITY<0.07 then score_fccr=1;
		else if EM_EVENTPROBABILITY>=0.07 and EM_EVENTPROBABILITY<0.09 then score_fccr=2;
			else if EM_EVENTPROBABILITY>=0.09 and EM_EVENTPROBABILITY<0.15 then score_fccr=3;
				else score_fccr=4;
run;

/* Save physical table in AML core model */
proc cas;
	table.save / caslib="pglib"  name="party_score" table={caslib="pglib" name="party_score"} replace=true;	
quit;

cas mysess terminate;

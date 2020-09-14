cas sessionsep01;

caslib _all_ assign;

/* Score with published model the production party data from AML core model directly*/

proc cas;
	loadactionset "modelPublishing";
	runModelLocal / 
		outTable={caslib="casuser", name="TMP_PARTY_SCORED"},
		intable={caslib="psql" name="FSC_PARTY_DIM"},
		modelName="AMLAlertScoring" ,
		modelTable={caslib="public" name="sas_model_table"};
	run;
quit;

proc cas;
	table.droptable / caslib="psql" name="party_score" quiet=true;	
quit;

/* Publish the lookup table for score for realtime scoring of transactions */

data psql.party_score(promote=yes);
	set casuser.TMP_PARTY_SCORED(keep=party_key EM_EVENTPROBABILITY);
	if EM_EVENTPROBABILITY>=0 and EM_EVENTPROBABILITY<0.05 then score_fccr=1;
		else if EM_EVENTPROBABILITY>=0.05 and EM_EVENTPROBABILITY<0.09 then score_fccr=2;
			else if EM_EVENTPROBABILITY>=0.09 and EM_EVENTPROBABILITY<0.15 then score_fccr=3;
				else score_fccr=4;
run;


/* Save physical table in AML core model */
proc cas;
	table.save / caslib="psql" path="party_score" table={caslib="psql" name="party_score"} replace=true;	
quit;

cas sessionsep01 terminate;

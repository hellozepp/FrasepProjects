cas sessionsep01 sessopts=(timeout=3600 metrics=true);

caslib _all_ assign;

/* Score with published model the production data */

proc cas;
	loadactionset "modelPublishing";
	runModelLocal / 
		outTable={caslib="casuser", name="TMP_SCORED_HMEQ_DATA"},
		intable={caslib="public" name="HMEQ_TEST"},
		modelName="Random_forest_model_prod" ,
		modelTable={caslib="public" name="sas_model_table"};
	run;
quit;

cas sessionsep01 terminate;

cas sessionsep01;
caslib _all_ assign;

proc cas;
	loadactionset "modelPublishing";
	runModelLocal / 
		outTable={caslib="public", name="PARTY_SCORED"},
		intable={caslib="psql" name="FSC_PARTY_DIM"},
		modelName="AMLAlertScoring" ,
		modelTable={caslib="public" name="sas_model_table"};
	run;
quit;

cas sessionsep01 terminate;

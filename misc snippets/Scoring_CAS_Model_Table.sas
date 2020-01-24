cas sessionsep01;
caslib _all_ assign;

proc cas;
	loadactionset "modelPublishing";
	runModelLocal / 
		outTable={caslib="public", name="CHURN_SCORED"},
		intable={caslib="public" name="CHURN_ANALYSE"} ,
		modelName="DT1" ,
		modelTable={caslib="public" name="sas_model_table"};
	run;
quit;



cas sessionsep01 terminate;

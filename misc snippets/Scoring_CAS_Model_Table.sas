cas sessionsep01;
caslib _all_ assign;

proc cas;
	loadactionset "modelPublishing";
	runModelLocal / 
		outTable={caslib="public", name="HMEQ_SCORED"},
		intable={caslib="public" name="HMEQ_TEST"} ,
		modelName="Forest Model using Python swat" ,
		modelTable={caslib="public" name="sas_model_table"};
	run;
quit;

cas sessionsep01 terminate;

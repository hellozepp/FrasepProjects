/* Test script : generate scored data for latter performance job */

cas sessionsep01 sessopts=(timeout=3600 metrics=true);
caslib _all_ assign;

proc cas;

	loadactionset "modelPublishing";

	/*************************************************************************************************************/
	/* Function generate_scoring_data_monitoring_table */
	/*************************************************************************************************************/
	function generate_scoring_data_monitoring_table(prefix, model_caslib, model_castable, input_data_caslib, input_data_castable, model_name, sequence_number, time_label, monitoring_caslib);
		
		table.fetch result=f  / table={name=model_castable, caslib=model_caslib, where="ModelName='" || model_name || "'"}, index=false;
		modeluuid = f.fetch[,"modeluuid"][1];
		full_output_table_name = prefix || '_' || sequence_number || '_' || time_label || '_' || modeluuid;

		table.droptable / caslib=monitoring_caslib name=full_output_table_name quiet=true;
		
		table.tableExists result=tableExistsFlag / caslib=input_data_caslib name=input_data_castable;
 		if tableExistsFlag.exists=0 then table.loadTable / casout={caslib=input_data_caslib name=input_data_castable} caslib=input_data_caslib path=input_data_castable||'.sashdat';

		runModelLocal / 
			outTable={name=full_output_table_name},
			intable={caslib=input_data_caslib name=input_data_castable},
			modelName=model_name,
			modelTable={caslib=model_caslib name=model_castable};
	
		table.promote / targetcaslib=monitoring_caslib sourcecaslib='casuser' name=full_output_table_name;

	end;
	/*************************************************************************************************************/

	generate_scoring_data_monitoring_table("QSHMEQ", "public", "sas_model_table", "public", "HMEQPERF_1_Q1", "GBT_SAS", "1", "Q1", "public");
	generate_scoring_data_monitoring_table("QSHMEQ", "public", "sas_model_table", "public", "HMEQPERF_2_Q2", "GBT_SAS", "2", "Q2", "public");
	generate_scoring_data_monitoring_table("QSHMEQ", "public", "sas_model_table", "public", "HMEQPERF_3_Q3", "GBT_SAS", "3", "Q3", "public");
	generate_scoring_data_monitoring_table("QSHMEQ", "public", "sas_model_table", "public", "HMEQPERF_4_Q4", "GBT_SAS", "4", "Q4", "public");

	generate_scoring_data_monitoring_table("QSHMEQ", "public", "sas_model_table", "public", "HMEQPERF_1_Q1", "QS_Tree1", "1", "Q1", "public");
	generate_scoring_data_monitoring_table("QSHMEQ", "public", "sas_model_table", "public", "HMEQPERF_2_Q2", "QS_Tree1", "2", "Q2", "public");
	generate_scoring_data_monitoring_table("QSHMEQ", "public", "sas_model_table", "public", "HMEQPERF_3_Q3", "QS_Tree1", "3", "Q3", "public");
	generate_scoring_data_monitoring_table("QSHMEQ", "public", "sas_model_table", "public", "HMEQPERF_4_Q4", "QS_Tree1", "4", "Q4", "public");

quit;

cas sessionsep01 terminate;

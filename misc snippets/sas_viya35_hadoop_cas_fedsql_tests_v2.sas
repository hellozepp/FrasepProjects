cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US" metrics=true);

proc cas;

	/**************** function to get a simple table with the cas table actual size in MB and the number of rows ****************/
	function get_table_size(caslib,castab_name);
			table.tabledetails result=r/ caslib=caslib name=castab_name;
			out_table = newtable("CAS Table size", {"Size in MB", "Number of rows"}, {"integer", "integer"});
			addrow(out_table, {r.TableDetails[1].Datasize/1024/1024, r.TableDetails[1].Rows});
			print out_table;
	end;

	/**************** function to get detailed columninfo in log with all characteritic not shown in default output ****************/
	function get_detailed_columninfo(caslib,castab_name);
		output log;
		columninfo table={caslib=caslib, name=castab_name} extended=true;
	end;

	/**************************** defined the caslib pointing on the hadoop cluster *******************************/
	table.addcaslib /
		name="hdlib",
		datasource={
			srctype="hadoop",
			dataTransferMode="auto",
			username="hive",
			dbmaxText=255,
			password="admin",
			uri="jdbc:hive2://frasephdp.cloud.com:2181/default;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2",
			hadoopjarpath="/opt/sas/hadoop/jars",
			hadoopconfigdir="/opt/sas/hadoop/sitexmls",
			schema="default"};

	run;

	/***************************** List all accessible table in the datasource, here hive, before any load in CAS *******************/
	table.fileinfo caslib="hdlib";
	run;

	/********************************** Load hive table directly in CAS memory ***********************************/
	table.loadtable caslib="hdlib" path="testbdf" casout={caslib="hdlib", name="testbdf", replace=true} readahead=true;
	get_table_size("hdlib","testbdf");
	run;

	/************************ Create a cas table from an hiveql query in explicit passthrough **************************/
	fedSql.execDirect cntl={optimizeVarcharPrecision=TRUE} query="create table casuser.testbdf{options replace=true} as (select * from connection to hdlib(SELECT * from testbdf limit 100000))";
	get_table_size("casuser","testbdf");


quit;



cas mySession terminate;

/* Hive describe tesbdf;

|             col_name              |   data_type    | comment  |
+-----------------------------------+----------------+----------+
| extraction_id                     | string         |          |
| code_riad                         | string         |          |
| code_riad_temp                    | string         |          |
| lei                               | string         |          |
| siren                             | string         |          |
| siren_fictif                      | string         |          |
| cib                               | string         |          |
| code_opc                          | string         |          |
| code_ot                           | string         |          |
| code_ncb                          | string         |          |
| code_amf                          | string         |          |
| code_org_int                      | string         |          |
| code_nis                          | string         |          |
| identifiant_rci                   | string         |          |
| identifiant_rna                   | string         |          |
| code_bic                          | string         |          |
| identifiant_etranger              | string         |          |
| type_identifiant_etranger         | string         |          |
| identifiant_head_office           | string         |          |
| identifiant_immediate_parent      | string         |          |
| identifiant_ultimate_parent       | string         |          |
| date_debut_entite                 | date           |          |
| date_fin_entite                   | date           |          |
| denomination                      | string         |          |
| adresse_ligne1                    | string         |          |
| adresse_ligne2                    | string         |          |
| adresse_ligne3                    | string         |          |
| adresse_ligne4                    | string         |          |
| code_postal                       | string         |          |
| ville                             | string         |          |
| code_nuts                         | string         |          |
| pays                              | string         |          |
| forme_juridique                   | string         |          |
| code_secteur                      | string         |          |
| code_sous_secteur                 | string         |          |
| code_nace                         | string         |          |
| statut_procedure_judiciaire       | string         |          |
| date_statut_procedure_judiciaire  | string         |          |
| taille_entreprise                 | string         |          |
| date_taille_entreprise            | date           |          |
| nombre_employes                   | bigint         |          |
| total_bilan                       | decimal(20,2)  |          |
| chiffre_affaires                  | decimal(20,2)  |          |
| norme_comptable_indiv             | string         |          |
| actif                             | string         |          |
+-----------------------------------+----------------+----------+
*/

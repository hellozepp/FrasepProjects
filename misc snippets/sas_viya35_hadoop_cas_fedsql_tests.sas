cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US" metrics=true);

caslib hdlib datasource=(
	srctype="hadoop",
	dataTransferMode="auto",
	username="hive",
	dbmaxText=255,
	password="admin",
	uri="jdbc:hive2://master.hadoop.com:2181/default;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2",
	hadoopjarpath="/opt/sas/hadoop/jars",
	hadoopconfigdir="/opt/sas/hadoop/sitexmls",
	schema="default"
);

caslib _all_ assign;

proc cas;
	table.fileinfo / caslib="hdlib";
quit;

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

/* Test raw loadtable from hive to cas table */
proc cas;
	table.loadtable / caslib="hdlib" path="testbdf" casout={caslib="hdlib", name="testbdf", replace=true} readahead=true datasourceoptions={dbmaxtext=255};
	table.tabledetails / caslib="hdlib"  name="testbdf";
	table.columninfo / table={caslib="hdlib", name="testbdf"};
quit;
/*
NOTE: Action 'table.loadTable' used (Total process time):
NOTE:       real time               7.778578 seconds
NOTE:       cpu time                1.589287 seconds (20.43%)
NOTE:       total nodes             1 (32 cores)
NOTE:       total memory            117.88G
NOTE:       memory                  19.39M (0.02%)
*/


/* Create a cas table from an hiveql query in explicit passthrough */
proc cas;
	fedSql.execDirect cntl={optimizeVarcharPrecision=TRUE} query="create table casuser.testbdf{options replace=true} as (select * from connection to hdlib(SELECT * from testbdf limit 100000))";
quit;

/*
NOTE: Action 'fedSql.execDirect' used (Total process time):
NOTE:       real time               49.266544 seconds
NOTE:       cpu time                21.160406 seconds (42.95%)
NOTE:       total nodes             1 (32 cores)
NOTE:       total memory            117.88G
NOTE:       memory                  178.86M (0.15%)
*/

/* avec dbsmaxtext=255

NOTE: Action 'fedSql.execDirect' used (Total process time):
NOTE:       real time               11.470497 seconds
NOTE:       cpu time                4.029391 seconds (35.13%)
NOTE:       total nodes             1 (32 cores)
NOTE:       total memory            117.88G
NOTE:       memory                  185.85M (0.15%)
*/

proc cas; 
	output log;
	columninfo table={caslib="casuser", name='testbdf'} extended=true;
	output ods;
	columninfo table={caslib="casuser" ,name='testbdf'};
	table.tabledetails / caslib="casuser" name="testbdf";
quit;

/* Create a cas table from an hiveql query in explicit passthrough */
proc cas;
	fedSql.execDirect query="create table casuser.testbdf{options replace=true} as (select * from connection to hdlib(SELECT * from testbdf limit 100000))";
quit;

/*
NOTE: Action 'fedSql.execDirect' used (Total process time):
NOTE:       real time               57.538447 seconds
NOTE:       cpu time                157.332580 seconds (273.44%)
NOTE:       total nodes             1 (32 cores)
NOTE:       total memory            117.88G
NOTE:       memory                  1.97G (1.67%)
*/

/* avec dbmsmaxtext=255
NOTE: Action 'fedSql.execDirect' used (Total process time):
NOTE:       real time               10.094314 seconds
NOTE:       cpu time                9.746883 seconds (96.56%)
NOTE:       total nodes             1 (32 cores)
NOTE:       total memory            117.88G
NOTE:       memory                  179.13M (0.15%)
*/

proc cas;
	output log;
	columninfo table={caslib="casuser", name='testbdf'} extended=true;
	output ods;
	columninfo table={caslib="casuser" ,name='testbdf'};
	table.tabledetails result=r/ caslib="casuser" name="testbdf";
	
	out_table = newtable("CAS Table size", {"Size in MB", "Number of rows"}, {"integer", "integer");
	addrow(out_table, {})
	size_in_MB = (string)r.TableDetails[1].Datasize/1024/1024;

	print "CAS Table size : " || size_in_MB || " MB    CAS Table number of records : " ||  r.TableDetails[1].Rows;
quit;

proc cas;
	table.fileinfo / caslib="hdlib";
quit;

cas mySession terminate;


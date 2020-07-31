options set=SAS_HADOOP_CONFIG_PATH "/opt/sas/hadoop/sitexmls";
options set=SAS_HADOOP_JAR_PATH="/opt/sas/hadoop/jars";

libname hdplib hadoop user="hive" password="admin" uri="jdbc:hive2://master.hadoop.com:2181/default;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2"
server="master.hadoop.com";

proc sql;
	Connect To hadoop (SERVER="master.hadoop.com"
	User="hive"
	password="admin"
	dbmax_text=255
	uri='jdbc:hive2://master.hadoop.com:2181/default;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2'
	properties="hive.fetch.task.conversion=more;hive.fetch.task.conversion.threshold=-1;hive.execution.engine=tez" READ_METHOD=HDFS
	);
	
	create table table as select * from connection to hadoop (select * from testbdf limit 100000);
    disconnect from hadoop;
quit;

/*
      real time           1:12.67
*/


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


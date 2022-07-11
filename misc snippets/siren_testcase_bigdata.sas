/* URL to get siren open data : https://files.data.gouv.fr/insee-sirene/StockEtablissement_utf8.zip */
/* URL to get siren unite legal : https://files.data.gouv.fr/insee-sirene/StockUniteLegale_utf8.zip */

cas mysess_test_siren;

proc cas;
	table.dropcaslib / caslib="mycsv" quiet=true;
	table.addcaslib / caslib="mycsv" datasource={srctype="path"} path="/tmp/csv" subdirs=true session=true;

	table.droptable / caslib="mycsv" name="STOCKETABLISSEMENT_UTF8" quiet=true;
	table.droptable / caslib="mycsv" name="StockUniteLegale_utf8" quiet=true;
	table.droptable / caslib="public" name="siren_ej_fake" quiet=true;
	table.droptable / caslib="public" name="siren_unites_legales_fake" quiet=true;

	table.columninfo / table={caslib="mycsv" name="StockEtablissement_utf8.csv"};
	table.columninfo / table={caslib="mycsv" name="StockUniteLegale_utf8.csv"};
run;

/*
	table.loadtable / 
		caslib="mycsv" 
		casout={caslib="mycsv" name="STOCKETABLISSEMENT_UTF8" replication=0} 
		path="StockEtablissement_utf8.csv"
		importoptions={
			fileType="CSV", getnames=true,
			vars={
				{name="alt.siren", type="double"},
				{name="alt.nic", type="double"},
				{name="alt.siret", type="double"},
				{name="alt.statutDiffusionEtablissement", type="CHAR",length=1},
				{name="alt.dateCreationEtablissement", type="CHAR",length=10},
				{name="alt.trancheEffectifsEtablissement", type="CHAR",length=2},
				{name="alt.anneeEffectifsEtablissement", type="INT32"},
				{name="alt.activitePrincipaleRegistreMetiersEtablissement", type="CHAR",length=6},
				{name="alt.dateDernierTraitementEtablissement", type="VARCHAR"},
				{name="alt.etablissementSiege", type="CHAR",length=5},
				{name="alt.nombrePeriodesEtablissement", type="double"},
				{name="alt.complementAdresseEtablissement", type="VARCHAR"},
				{name="alt.numeroVoieEtablissement", type="CHAR",length=5},
				{name="alt.indiceRepetitionEtablissement", type="CHAR",length=2},
				{name="alt.typeVoieEtablissement", type="CHAR",length=4},
				{name="alt.libelleVoieEtablissement", type="VARCHAR"},
				{name="alt.codePostalEtablissement", type="double"},
				{name="alt.libelleCommuneEtablissement", type="VARCHAR"},
				{name="alt.libelleCommuneEtrangerEtablissement", type="VARCHAR"},
				{name="alt.distributionSpecialeEtablissement", type="VARCHAR"},
				{name="alt.codeCommuneEtablissement", type="CHAR", length=5},
				{name="alt.codeCedexEtablissement", type="CHAR",length=9},
				{name="alt.libelleCedexEtablissement", type="VARCHAR"},
				{name="alt.codePaysEtrangerEtablissement", type="CHAR",length=5},
				{name="alt.libellePaysEtrangerEtablissement", type="VARCHAR"},
				{name="alt.complementAdresse2Etablissement", type="VARCHAR"},
				{name="alt.numeroVoie2Etablissement", type="CHAR",length=4},
				{name="alt.indiceRepetition2Etablissement", type="CHAR",length=1},
				{name="alt.typeVoie2Etablissement", type="CHAR",length=4},
				{name="alt.libelleVoie2Etablissement", type="VARCHAR"},
				{name="alt.codePostal2Etablissement", type="CHAR",length=5},
				{name="alt.libelleCommune2Etablissement", type="VARCHAR"},
				{name="alt.libelleCommuneEtranger2Etablissement", type="CHAR",length=1},
				{name="alt.distributionSpeciale2Etablissement", type="CHAR",length=9},
				{name="alt.codeCommune2Etablissement", type="CHAR",length=5},
				{name="alt.codeCedex2Etablissement", type="CHAR",length=5},
				{name="alt.libelleCedex2Etablissement", type="VARCHAR"},
				{name="alt.codePaysEtranger2Etablissement", type="CHAR",length=5},
				{name="alt.libellePaysEtranger2Etablissement", type="CHAR",length=11},
				{name="alt.dateDebut", type="CHAR",length=10},
				{name="alt.etatAdministratifEtablissement", type="CHAR",length=1},
				{name="alt.enseigne1Etablissement", type="VARCHAR"},
				{name="alt.enseigne2Etablissement", type="VARCHAR"},
				{name="alt.enseigne3Etablissement", type="VARCHAR"},
				{name="alt.denominationUsuelleEtablissement", type="VARCHAR"},
				{name="alt.activitePrincipaleEtablissement", type="CHAR",length=6},
				{name="alt.nomenclatureActivitePrincipaleEtablissement", type="CHAR", length=7},
				{name="alt.caractereEmployeurEtablissement", type="CHAR", length=1}}};
*/
	table.loadtable / 
		caslib="mycsv" 
		casout={caslib="mycsv" name="StockUniteLegale_utf8" replication=0} 
		path="StockUniteLegale_utf8.csv"
		importoptions={fileType="CSV", getnames=true, guessRows=500000};
run;

	table.loadtable / 
		caslib="mycsv" 
		casout={caslib="mycsv" name="StockEtablissement_utf8" replication=0} 
		path="StockEtablissement_utf8.csv"
		importoptions={fileType="CSV", getnames=true, guessRows=500000};
run;

	table.tabledetails / caslib="mycsv" name="StockEtablissement_utf8";
	table.columninfo / table={caslib="mycsv" name="StockEtablissement_utf8"};
	table.tabledetails / caslib="mycsv" name="StockUniteLegale_utf8";
	table.columninfo / table={caslib="mycsv" name="StockUniteLegale_utf8"};

quit;


proc cas;
	source pgm;
		data public.siren_ej_fake(promote=yes copies=0);
			set mycsv.StockEtablissement_utf8;
			length annee 8.;
			annee=2000;
			output;
			annee=2001;
			output;
			annee=2002;
			output;
			run;
	endsource;
	action runCode / code=pgm;
quit;

proc cas;
	source pgm;
		data public.siren_ej_fake(promote=yes copies=0);
			set mycsv.StockUniteLegale_utf8;
			run;
	endsource;
	action runCode / code=pgm;
quit;


proc cas;
	table.tabledetails / caslib="public" name="siren_ej_fake";
quit;

cas _all_ terminate;
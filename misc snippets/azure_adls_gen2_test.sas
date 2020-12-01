cas mysess;

proc cas;
	table.dropcaslib / caslib="AzureDL" silent=true;
quit;

caslib "AzureDL" 
	datasource=(
		srctype="adls"
			accountname='frasepstorage'
			filesystem="datalake"
			tenantid="b1c14d5c-3625-45b3-a430-9552373a0c2f"
			applicationId="e7af42e8-3ca8-47bb-97ce-ac764019be3a"
			timeout=50000
	)
	path="/" subdirs global;

caslib _all_ assign;

libname mydata "/data";

proc cas;
	table.fileinfo / caslib="AzureDL";
quit;

proc cas;
	table.loadtable / caslib="AzureDL" path="CHURN_DONNEES_CLIENT_BRUTES_FR.orc" casout="CHURN_DONNEES_CLIENT_BRUTES_FR";
quit;



/*
data AzureDL.churn_fr;
	set mydata.churn_fr;
run;
data AzureDL.CHURN_DONNEES_CLIENT_BRUTES_FR;
	set mydata.CHURN_DONNEES_CLIENT_BRUTES_FR;
run;

proc cas;
	table.save / caslib="AzureDL" name="CHURN_DONNEES_CLIENT_BRUTES_FR.orc" table={caslib="AzureDL",name="CHURN_DONNEES_CLIENT_BRUTES_FR"} replace=true;
	table.save / caslib="AzureDL" name="CHURN_FR.orc" table={caslib="AzureDL",name="CHURN_FR"} replace=true;
quit;

proc cas;
	table.save / caslib="AzureDL" name="citiday.orc" table={caslib="AzureDL",name="citiday"} replace=true;
quit;

proc cas;
	table.loadtable / caslib="AzureDL" path="citiday.orc" casout="citidayorc";
quit;

data AzureDL.cars;
	set sashelp.cars;
run;

proc cas;
	table.save / caslib="AzureDL" name="cars.csv" table={caslib="AzureDL",name="cars"} replace=true;
quit;

data AzureDL.prdsale(replace=yes);
	set sashelp.prdsale;
run;

proc cas;
	table.save / caslib="AzureDL" name="prdsale.orc" table={caslib="AzureDL",name="prdsale"} replace=true;
quit;
*/

cas mysess terminate;

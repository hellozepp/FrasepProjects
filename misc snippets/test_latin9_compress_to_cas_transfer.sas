cas stst001 sessopts=(metrics=true);

caslib _all_ assign;

libname sassrc "/opt/sas/data/sasdata/latin9" cvpmultiplier=2;

libname sasdest "/opt/sas/data/sasdata";

proc cas;
   upload path="/opt/sas/data/sasdata/latin9/assu_prestations_sante_light.sas7bdat"
   casout={caslib="casuser", name="test_sas_utf8_nocomp_varchar", replace=True, replication=0}
   importOptions={charMultiplier=2,fileType="basesas",varcharConversion=20};
run;
quit;

proc cas;
	table.tabledetails caslib="casuser" name="test_sas_utf8_nocomp_varchar";
	table.tabledetails caslib="public" name="test_sas_utf8_nocomp";
	table.tabledetails caslib="public" name="test_sas_latin9_comp";
run;

cas stst001 terminate;

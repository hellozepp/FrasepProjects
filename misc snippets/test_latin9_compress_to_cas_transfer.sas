cas stst001 sessopts=(metrics=true);

caslib _all_ assign;

libname sassrc "/opt/demo/sasdata/lat9" cvpmultiplier=2;

libname sasdest "/opt/demo/sasdata/utf8";


/* 5.6 G */
data sasdest.assu_presta_sante_light_utf8;
	set sassrc.assu_prestations_sante_light;
run;

proc cas;
   upload path="/opt/sas/data/sasdata/assu_presta_sante_light_utf8.sas7bdat"
   casout={caslib="casuser", name="assu_presta_sante_light_utf8", replace=True, replication=0}
   importOptions={fileType="basesas",charMultiplier=2};
run;
quit;

proc cas;
   upload path="/opt/sas/data/sasdata/assu_presta_sante_light_utf8.sas7bdat"
   casout={caslib="casuser", name="assu_presta_sante_light_utf8_varchar", replace=True, replication=0}
   importOptions={charMultiplier=2,fileType="basesas",varcharConversion=16};
run;
quit;


proc cas;
   upload path="/opt/sas/data/sasdata/latin9/assu_prestations_sante_light.sas7bdat"
   casout={caslib="casuser", name="test_sas_utf8_nocomp_varchar", replace=True, replication=0}
   importOptions={charMultiplier=2,fileType="basesas",varcharConversion=16};
run;
quit;


proc cas;
	table.save / caslib="casuser" name="assu_presta_sante_light_utf8.sas7bdat" table={caslib="casuser",name="assu_presta_sante_light_utf8"} replace=true;
quit;

proc cas;
	table.loadtable / caslib="casuser" path="assu_presta_sante_light_utf8.sas7bdat" casout="assu_presta_sante_light_utf8_v2" importOptions={filetype="basesas", varcharConversion=16};
quit;


proc cas;
	*table.tabledetails caslib="casuser" name="test_sas_utf8_nocomp_varchar";
	*table.tabledetails caslib="public" name="test_sas_utf8_nocomp";
	*table.tabledetails caslib="public" name="test_sas_latin9_comp";
	table.tabledetails caslib="casuser" name="assu_presta_sante_light_utf8_v2";
	*table.tabledetails caslib="casuser" name="assu_presta_sante_light_utf8_varchar";
run;
quit;

cas stst001 terminate;

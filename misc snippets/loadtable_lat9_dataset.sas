cas stst001 sessopts=(metrics=true);

caslib _all_ assign;

proc cas;
 	table.loadtable / caslib="mydata" path="assu_prestations_sante_light.sas7bdat"
	casout={caslib="mydata", name="assu_prestations_sante_light"} 
	importOptions={filetype="basesas", varcharConversion=16};
quit;

proc cas;
	table.promote / 
		caslib="mydata" 
		name="assu_prestations_sante_light" 
		target="assu_prestations_sante_light" 
		targetcaslib="public";
quit;

cas stst001 terminate;

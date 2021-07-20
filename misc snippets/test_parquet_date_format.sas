cas mysess;

caslib _all_ assign;

proc cas;
	table.fileinfo / caslib="mydata";
run;

proc cas;
	table.loadtable / caslib="mydata" casout="megacorp5_4m" path="megacorp5_4m.sashdat";
run;

proc cas;
	table.loadtable /  caslib="mydata" casout={caslib="mydata",name="megacorp5_4m"}  path="megacorp5_4m.sashdat";
run;

proc cas;
	table.save / 
		caslib="mydata" 
		name="megacorp5_4m_test.parquet"  
		table={caslib="mydata",
		name="megacorp5_4m",
		vars={{format="DATE", name="DATE"}}} replace=true exportoptions=;
run;

proc cas;
	table.loadtable /  caslib="mydata" casout={caslib="mydata",name="megacorp5_4m_test"}  path="megacorp5_4m_test.parquet" 
	importoptions={vars={{name="date",format="DATE"}}};
run;

importoptions={"fileType":"csv","getNames":True, "vars":{   
                        "publication_table.inserttimestamp":{"type":"double","informat":"ANYDTDTM23.3","format":"DATETIME23.3"},
                        "publication_table.dfauai":{"type":"varchar"},
                        "publication_table.serveruai":{"type":"varchar"},
                        "publication_table.objectuai":{"type":"varchar"},
                        "publication_table.variablename":{"type":"varchar"},
                        "publication_table.sourcetimestamp":{"type":"double","informat":"ANYDTDTM23.3","format":"DATETIME23.3"},
                        "publication_table.sourcepicoseconds":{"type":"double"},
                        "publication_table.datavalue":{"type":"varchar"},
                        "publication_tabl

proc casutil;
    contents incaslib="mydata" casdata="megacorp5_4m.parquet" ;
    contents incaslib="mydata" casdata="megacorp5_4m" ;
run;


cas mysess terminate;

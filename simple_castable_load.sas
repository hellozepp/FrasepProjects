options cashost="sepviya35.aws.sas.com" casport=5570;

cas mysess;



caslib mys3 datasource=(srctype="s3"
               accesskeyid="ASIA2X2Z5C5ZKALAJ4FF"
               secretaccesskey="Cb9TVDjeeNZjU4+ujDUjBLd9ym+sxqL7Mt/D34IP"
               region="US_East"
               bucket="sas-eapsl"
               objectpath="/frasep"
               usessl=false);

caslib _all_ assign;

proc cas;
	table.loadTable /  casout={caslib="dnfs" name="MEGACORP5_4M_PARQUET" promote=true} caslib="dnfs" path="MEGACORP5_4M_PARQUET.parquet";
run;

data mys3.MEGACORP5_4M_PARQUET;
	set dnfs.MEGACORP5_4M_PARQUET;
run;

proc cas;
	table.save /  table={caslib="mys3" name="MEGACORP5_4M_PARQUET"} caslib="mys3" name="MEGACORP5_4M_PARQUET.parquet";
run;

cas mysess terminate;

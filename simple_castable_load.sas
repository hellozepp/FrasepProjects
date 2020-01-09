
options cashost="sepviya35.aws.sas.com" casport=5570;

cas mysess;

caslib _all_ assign;

proc cas;
	table.loadTable /  casout={caslib="dnfs" name="MEGACORP5_4M_PARQUET" promote=true} caslib="dnfs" path="MEGACORP5_4M_PARQUET.parquet";
run;

cas mysess terminate;

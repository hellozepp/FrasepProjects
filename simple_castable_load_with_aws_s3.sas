options cashost="sepviya35.aws.sas.com" casport=5570;

cas mysess;

caslib s3aws datasource=(srctype="s3",                    
                   awsConfigPath="/opt/sas/viya/config/data/AWSdata/config",                   
				   awsCredentialsPath="/opt/sas/viya/config/data/AWSdata/credentials",
                   awsCredentialsProfile="default",
                   region="US_East",
                   bucket="sas-eapsl",
                   objectpath="/frasep/"
               ) subdirs global;  

caslib _all_ assign;

proc cas;
	table.loadTable /  casout={caslib="dnfs" name="MEGACORP5_4M_PARQUET" promote=true} caslib="dnfs" path="MEGACORP5_4M_PARQUET.parquet";
run;

data AWSCAS1.MEGACORP5_4M_PARQUET;
	set dnfs.MEGACORP5_4M_PARQUET;
run;

proc cas;
	table.save /  table={caslib="AWSCAS1" name="MEGACORP5_4M_PARQUET"} caslib="AWSCAS1" name="MEGACORP5_4M_PARQUET.parquet";
run;

cas mysess terminate;

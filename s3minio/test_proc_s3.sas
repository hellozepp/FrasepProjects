/*
S3 Configuration file documentation :
https://go.documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/proc/n0qozoux9a0633n1du4xy40vksf5.htm

S3 config file sample :

ssl=no
keyID=minioadmin
secret=minioadmin
region=fr-west-region-1

TEST : minio on container with public bucket named datalake

put in /opt/sas/viya/config/etc/cas/default/cas_usermods.settings on all CAS nodes :

export TKS3_CUSTOM_REGION=fr-local-frasep,frasepviya35smp.cloud.com,9000,0,false,false

/opt/sas/spre/home/SASFoundation/bin/sasenv_local on all the programming/ComputeServer :

*/


%log4sas();
%log4sas_logger("App.tk.s3","level=trace");
%log4sas_logger("App.tk.htclient","level=trace");

proc s3 config="/home/viyademo01/my_git/s3minio/.s3conf";
   list "/";
run;

proc s3 config="/home/viyademo01/my_git/s3minio/.s3conf";
   list _short_ '/datalake';
run;

proc s3 config="/home/viyademo01/my_git/s3minio/.s3conf";
   create "/mybucket";
   *put "/tmp/data/CHURN_ANALYSE.sashdat" "/mybucket/test.sashdat";
   *list "/mybucket";
run;

proc s3 config="/home/viyademo01/my_git/s3minio/.s3conf";
   put "/tmp/data/CHURN_ANALYSE.sashdat" "/datalake/CHURN_ANALYSE.sashdat";
run;

proc s3 config="/home/viyademo01/my_git/s3minio/.s3conf";
   get "/datalake/CHURN_ANALYSE.sashdat" "/tmp/data/CHURN_ANALYSE_GET.sashdat";
run;


options sastrace=',,,d' sastraceloc=saslog;
options fullstimer;

cas casauto;

caslib "s3minio" datasource=(srctype="s3", accessKeyId="minioadmin", secretAccessKey="minioadmin",
                   region="fr-local-frasep", bucket="datalake", usessl=FALSE);

caslib _ALL_ assign;

proc cas;
	table.caslibinfo / caslib="s3minio";
quit;

proc cas;
	table.fileinfo / caslib="s3minio" path="/";
quit;

cas casauto terminate;








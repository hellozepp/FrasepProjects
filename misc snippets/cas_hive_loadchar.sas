%let conf='/sgrid/hadoop_jars_conf/hwx2.6_fsdshadoop-1_for_viya34/conf';
%let jar='/sgrid/hadoop_jars_conf/hwx2.6_fsdshadoop-1_for_viya34/lib';
%let server='fsdshadoop-1.fsl.sashq-d.openstack.sas.com';
%let schemaread=default;              /* Hive schema of source table */
%let table=ins;                       /* Hive source table */
%let schemawrite=sasccr;              /* Hive schema of external table */
%let tablelike=ins_like;              /* Name of Hive External table being created */
%let fref1='/home/sasccr/fref1.txt';  /* Location and name of code1 being generated */
%let fref2='/home/sasccr/fref2.txt';  /* Location and name of code2 being generated */
%let session=ccrSession;
%let caslib=cashive;
%let ncharx=1;                        /* ncharmultiplier option in caslib */
%let castable=ins_cas;
%let outcaslib=cashive;
%let copies=0;
%let length=16;                       /* VARCHAR of this length or less will be altered to CHAR */

options msglevel=i;
options symbolgen mprint merror mlogic;
options sastrace=",,,d" sastraceloc=saslog no$stsuffix;
options set=SAS_HADOOP_CONFIG_PATH=&conf;
options set=SAS_HADOOP_JAR_PATH=&jar;
/*libname myhive1 hadoop server=&server schema=&schemaread;*/

proc sql;
connect to hadoop (server=&server);
   select * from connection to hadoop (describe formatted &schemaread..&table);
disconnect from hadoop; 
quit;

proc sql;
connect to hadoop (server=&server);
   create table work.varchar as select col_name length 128 format $128., data_type length 15 format $15.,
        input(substr(data_type, 9, index(data_type,')') - 9), 8.) as len,
        cat ("char", substr(data_type, 8, index(data_type,')') - 7)) as new_data_type
        from connection to hadoop (describe formatted &schemaread..&table)
        where data_type contains 'varchar';
   create table work.loc as select col_name length 128 format $128., data_type length 150 format $150.
        from connection to hadoop (describe formatted &schemaread..&table)
        where col_name = 'Location:';
disconnect from hadoop; 
quit;

data work.loc;
set work.loc;
data_type = cats("'",data_type,"'");
run;

filename fref1 &fref1;

data _null_;
set work.loc;
file fref1;

put "proc sql;";
put "connect to hadoop (server=&server);";
put @ 5 "execute (drop table if exists &schemawrite..&tablelike) by hadoop;";
put @ 5 "execute (create external table &schemawrite..&tablelike like &schemaread..&table location " data_type ") by hadoop;";
put "disconnect from hadoop;"; 
put "quit;";
run;

%include fref1;
run;

filename fref2 &fref2;

data _null_;
set work.varchar end=lastrow;

file fref2;

if _N_ = 1 then do;
put "proc sql;";
put "connect to hadoop (server=&server);";
end;

if len <= &length then put @ 5 "execute (ALTER TABLE &schemawrite..&tablelike CHANGE " col_name col_name new_data_type") by hadoop;";

if lastrow then do;
put "disconnect from hadoop;"; 
put "quit;";
end;
run;

%include fref2;
run;

cas &session /*sessopts=(caslib=casuser timeout=3600 MAXTABLEMEM="150G")*/;

caslib &caslib datasource=(srctype="hadoop" server=&server
schema=&schemawrite dataTransferMode="parallel"
hadoopjarpath=&jar,
hadoopconfigdir=&conf
ncharmultiplier=&ncharx);

/*libname cashive cas caslib=&caslib;*/

proc casutil;
   load incaslib="&caslib" casdata="&tablelike" casout="&castable" outcaslib="&outcaslib" copies=&copies /*replace*/
      options=(dataTransferMode="parallel");
run;
quit;

proc cas;
table.tableInfo /
name="&castable";
run;

/* tableDetails can take a while to run if your table is very large, comment it out if you like */
table.tableDetails /
name="&castable";
run;

table.columnInfo /
table={name="&castable"};
run;
quit;

/* Comment out the following lines if you want to review the temporary tables */
proc sql;
connect to hadoop (server=&server);
   execute (drop table if exists &schemawrite..&tablelike) by hadoop;
disconnect from hadoop; 
quit;

proc delete data=work.varchar work.loc;
run;

/* Uncomment if you are loading to Public or other persistent Caslib and want to terminate this session */
/*cas &session terminate;*/

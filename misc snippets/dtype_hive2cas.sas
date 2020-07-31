%let conf='/sgrid/hadoop_jars_conf/hwx2.6_fsdshadoop-1_for_viya34/conf';
%let jar='/sgrid/hadoop_jars_conf/hwx2.6_fsdshadoop-1_for_viya34/lib';
%let server='fsdshadoop-1.fsl.sashq-d.openstack.sas.com';
%let schemaread=default;                    /* Hive schema of source table */
%let table=test_datatypes_string_integers;  /* Hive source table */
%let schemawrite=sasccr;                    /* Hive schema of external table */
%let tablelike=ins_like;                    /* Name of Hive External table being created */
%let fref1='/sgrid/home/sasccr/fref1.txt';  /* Location and name of code1 being generated */
%let fref2='/sgrid/home/sasccr/fref2.txt';  /* Location and name of code2 being generated */
%let frefmaxl='/sgrid/home/sasccr/frefmaxl.txt';  /* Location and name of sql max length code being generated */
%let session=ccrSession;
%let caslib=cashive;
%let ncharx=1;                         /* ncharmultiplier option in caslib */
%let castable=test_datatypes_string_integers;
%let outcaslib=cashive;
%let copies=0;
%let mod_varchar=Y;                    /* Modify VARCHAR Y or N */
%let length=24;                        /* VARCHAR of this length or less will be altered to CHAR, also STRING if using sqlmaxlength macro */
%let mod_string=Y;                     /* Modify STRING Y or N */
%let calcmax=Y;                        /* Y to use sqlmaxlength macro to calculate each STRING columns max length */
%let dbmaxtext=32;                     /* max length of STRING if not using sqlmaxlength macro, suggest using 8 byte increments */
%let mod_integers=Y;                   /* Modify TINYINT, SMALLINT, INT, and BIGINT Y or N */

options msglevel=i;
options symbolgen mprint merror mlogic;
options sastrace=",,,d" sastraceloc=saslog no$stsuffix;
options set=SAS_HADOOP_CONFIG_PATH=&conf;
options set=SAS_HADOOP_JAR_PATH=&jar;
libname myhive1 hadoop server=&server schema=&schemaread;

proc sql;
connect to hadoop (server=&server);
   select * from connection to hadoop (describe formatted &schemaread..&table);
   create table work.describe as select col_name length 128 format $128., data_type length 15 format $15.
       from connection to hadoop (describe formatted &schemaread..&table.);
disconnect from hadoop; 
quit;

data work.varchar;
length new_data_type $15;
set work.describe;
len = input(substr(data_type, 9, index(data_type,')') - 9), 8.);
new_data_type = cat ("char", substr(data_type, 8, index(data_type,')') - 7));
where substr(data_type, 1, 7) = 'varchar';
run;

data work.integer;
length new_data_type $15;
set work.describe;
len = 8;
new_data_type = "double";
where data_type IN ('tinyint','smallint','int','bigint');
run;

data work.string;
length new_data_type $15;
set work.describe end=lastrow;
len = &dbmaxtext.;
new_data_type = "char(&dbmaxtext.)";
where data_type IN ('string');
run;

data _null_;
set work.describe end=lastrow;
retain strcount;
if _N_ = 1 then strcount = 0;
if data_type = 'string' then strcount = strcount + 1;
if lastrow then call symput("strcount", strcount);
run;

/* sqlmaxlength macro to be used IF calcmax parameter is YES AND strcount parameter > 0 */

%macro sqlmaxlength;
/* Generate SQL for max length of each STRING columns */
filename frefmaxl &frefmaxl;

data _null_;
set work.string end=lastrow;
file frefmaxl;
if _N_ = 1 then do;
put "proc sql;";
put "connect to hadoop (server=&server);";
put "create table work.maxlengths as select * from connection to hadoop";
put @ 5 "(select";
end;

if not lastrow then do;
put @ 10 "max(length(" col_name +(-1) ")) as " col_name +(-1) ",";
end;

if lastrow then do;
put @ 10 "max(length(" col_name +(-1) ")) as " col_name +(-1);
put " from &schemaread..&table.);";
put "disconnect from hadoop;"; 
put "quit;";
end;
run;

%include frefmaxl;
run;

proc transpose data=work.maxlengths out=work.transposed (rename=(_name_=col_name col1=maxlength));
run;

/* Use data step Hash object to update work.string */
data work.string;
/*length maxlength 8.;*/ /* Not necessary for numeric???*/
declare HASH newlen(dataset:'work.transposed');
newlen.DEFINEKEY ('col_name');
newlen.DEFINEDATA('maxlength');
newlen.DEFINEDONE(); 
DO UNTIL (eof_string);
SET work.string END = eof_string;
rc = newlen.FIND();
IF rc ne 0 THEN DO;
put 'maxlength Not Found';
END;
IF rc = 0 THEN DO;
if maxlength <= &length then
new_data_type = cat('char(',maxlength,')');
else new_data_type = cat('varchar(',maxlength,')');
END;
OUTPUT;
END;
STOP;
run;

%mend;

%if ((&strcount. > 0 and &calcmax. = Y) and &mod_string = Y) %then %do;
%sqlmaxlength;
run;
%end;

data work.newdtypes;
set work.varchar work.integer work.string /*(drop=strcount rc maxlength)*/;
run;

proc sql;
connect to hadoop (server=&server);
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
set work.newdtypes end=lastrow;
mod_varchar = "&mod_varchar.";
mod_string = "&mod_string.";
mod_integers = "&mod_integers.";
file fref2;

if _N_ = 1 then do;
put "proc sql;";
put "connect to hadoop (server=&server);";
end;

if mod_varchar = 'Y' then do;
	if substr(data_type, 1, 7) = 'varchar' AND len <= &length then put @ 5 "execute (ALTER TABLE &schemawrite..&tablelike CHANGE " col_name col_name new_data_type") by hadoop;";
end;

if mod_string = 'Y' then do;
    if data_type = 'string' then put @ 5 "execute (ALTER TABLE &schemawrite..&tablelike. CHANGE " col_name col_name new_data_type") by hadoop;";
end;

if mod_integers = 'Y' then do;
    if data_type IN ('tinyint' 'smallint' 'int' 'bigint') then put @ 5 "execute (ALTER TABLE &schemawrite..&tablelike. CHANGE " col_name col_name new_data_type") by hadoop;";
end;

if lastrow then do;
put "disconnect from hadoop;"; 
put "quit;";
end;
run;

%include fref2;
run;

cas &session /*sessopts=(caslib=casuser timeout=3600)*/;

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

proc delete data=work.describe work.varchar work.integer work.string work.loc
                 work.newdtypes work.maxlengths /*work.string_new*/ work.transposed;
run;

/* Uncomment if you are loading to Public or other persistent Caslib and want to terminate this session */
/*cas &session terminate;*/

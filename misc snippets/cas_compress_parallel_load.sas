options cashost="frasepviya35smp.cloud.com" casport=5570;

cas mysess;
caslib _all_ assign;

proc cas;
	table.fileinfo / caslib="mydata";
quit;

proc cas;
  file log;

  index /
    table={caslib="mydata" name="comms_demo.sas7bdat" singlepass=true}
    casout={caslib="casuser" name="comms_demo" BLOCKSIZE=536870912 compress=true replication=0}; 
  run;
  
  print _status;
  run;
quit;

proc cas;
  
proc cas;
  table.loadTable / path="comms_demo.sas7bdat" casout={caslib="casuser" name="comms_demo_nocomp"}
  caslib="mydata" importoptions={charMultiplier=2, filetype="basesas", varcharConversion=16};
  run;
quit;


proc cas;
  table.promote / caslib="casuser" name="comms_demo" target="comms_demo" targetLib="public";
  table.promote / caslib="casuser" name="comms_demo_nocomp" target="comms_demo_nocomp" targetLib="public";
  table.tabledetails / caslib="public" name="comms_demo";
  table.tabledetails / caslib="public" name="comms_demo_nocomp";
  run;
quit;

cas mysess terminate;

cas mysess;

proc cas;
table.addCaslib /
     caslib="我的桌子"
     description="我的桌子"
     dataSource={srctype="path"}
     path="/tmp";
quit;

caslib _all_ assign;



data casuser.我的桌子1;
	set sashelp.cars;
	薪金薪=78;
run;

proc cas;
	dscode="data casuser.我的桌子2; set casuser.我的桌子1; 薪金=78; 薪金薪金薪金薪金薪金薪金薪金薪金薪金薪金薪金薪金薪金薪金=78; run;";
	datastep.runcode / code=dscode single="yes";
quit;

data casuser.我的桌子2;
	set sashelp.cars;
	薪金=78;
	薪金薪金薪金薪金薪金薪金薪金薪金薪金薪金薪金薪金薪金薪金=78;
run;

proc cas;
	table.tabledetails / caslib="casuser" name="我的桌子2";
quit;

cas mysess terminate;

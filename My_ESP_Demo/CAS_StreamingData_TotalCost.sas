/*
Stream Continuous Data into a Table : StreamTotalCost

The loadStream action stays connected to the ESP server and continues to gather data. 
The action periodically (based on a number of rows, or a specified length of time) appends 
the data gathered to an output table. The output table in CAS must be global in scope. 
The global CAS table continues to grow until this action is stopped. 
*/

cas mysess_totalcost;


proc cas;
	session.sessionId; 
	builtins.loadActionSet actionSet="loadStreams";

	table.addCaslib 
	      dataSource={
				port=5555,
				server="frasepviya35smp.c.sas-frasep.internal",
				srcType="esp"}
	      name="espStatic";

	run;
	
	table.droptable / caslib='public' name='streamTotalCost' quiet=true;
	run;
	action loadStreams.loadStream /
	      casLib="espStatic"
	      espUri="trades/trades_cq/TotalCost"  
	      casOut={caslib="public", name="streamTotalCost", promote=true}
		  commitValue=1;
	run;

quit;

cas mysess_totalcost terminate;







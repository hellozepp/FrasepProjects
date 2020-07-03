cas mysess;


proc cas;

builtins.loadActionSet actionSet="loadStreams";

table.addCaslib 
      dataSource={
			port=5555,
			server="frasepviya35smp.c.sas-frasep.internal",
			srcType="esp"}
      name="espStatic";

quit;

/*
Stream Continuous Data into a Table

The loadStream action stays connected to the ESP server and continues to gather data. 
The action periodically (based on a number of rows, or a specified length of time) appends 
the data gathered to an output table. The output table in CAS must be global in scope. 
The global CAS table continues to grow until this action is stopped. 
*/

proc cas;

session.sessionId; 

table.droptable / caslib='public' name='streamTrades' quiet=true;

loadStreams.loadStream /
      casLib="espStatic"
      espUri="trades/trades_cq/Trades"  
      casOut={caslib="public", name="streamTrades", promote=true};

loadStreams.loadStream /
      casLib="espStatic"
      espUri="trades/trades_cq/TotalCost"  
      casOut={caslib="public", name="streamTotalCost", promote=true};

quit;

cas mysess terminate;







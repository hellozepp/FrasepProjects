cas mysess;


/*
Stream Continuous Data into a Table

The loadStream action stays connected to the ESP server and continues to gather data. 
The action periodically (based on a number of rows, or a specified length of time) appends 
the data gathered to an output table. The output table in CAS must be global in scope. 
The global CAS table continues to grow until this action is stopped. 
*/

proc cas;

	builtins.loadActionSet actionSet="loadStreams";

	table.addCaslib 
	      dataSource={
				port=5555,
				server="frasepviya35smp.c.sas-frasep.internal",
				srcType="esp"}
	      name="espStatic";

	table.droptable / caslib='public' name='streamTrades' quiet=true;
	table.droptable / caslib='public' name='streamTotalCost' quiet=true;
	
	source pgm;
		sc_1 = create_parallel_session();   
		sc_2 = create_parallel_session();
	
		loadStreams.loadStream session=sc_1 /
		      casLib="espStatic"
		      espUri="trades/trades_cq/Trades"  
		      casOut={caslib="public", name="streamTrades", promote=true}
			  commitValue=1;
		
		loadStreams.loadStream session=sc_2 /
		      casLib="espStatic"
		      espUri="trades/trades_cq/TotalCost"  
		      casOut={caslib="public", name="streamTotalCost", promote=true}
			  commitValue=1;
	
	endsource;

	sccasl.runCasl result=outer / code=pgm;

quit;

cas mysess terminate;







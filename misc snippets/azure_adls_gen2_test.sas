cas mysess;

caslib "AzureDL" 
	datasource=(
		srctype="adls"
			accountname='frasepstorage '
			filesystem="adls-1"
			tenantid="b1c14d5c-3625-45b3-a430-9552373a0c2f"
			applicationId="e7af42e8-3ca8-47bb-97ce-ac764019be3a"
		
			/* dnsSuffix=dfs.core.windows.net */
			timeout=50000
	)
	path="/" subdirs global;

caslib _all_ assign;


data AzureDL.cars;
	set sashelp.cars;
run;

proc cas;
	table.save / caslib="AzureDL" name="cars.csv" table={caslib="AzureDL",name="cars"};
quit;

caslib _all_ assign;


cas mysess terminate;

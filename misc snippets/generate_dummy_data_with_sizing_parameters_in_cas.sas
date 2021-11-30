cas casauto sessopts=(timeout=3600, caslib='casuser', metrics=true);

caslib _ALL_ assign;

proc cas;

    /**************************** function to generate dummy data in CAS *************************/
    function generate(n_records, n_num_cols, n_char_cols, mindate, maxdate, outcaslib, outcastab, seed);
		
		table.droptable / caslib=outcaslib name=outcastab quiet=true;

		code_ds1='''data "' || outcastab || '" (caslib="' || outcaslib || '") ;
				array nums[' || n_num_cols || '];
				array chars[' || n_char_cols || '] $;
				temp = "abcdefghijklmnopqrstuvwxyz";
				range = ' || maxdate || '-' || mindate || '+1;
				format range date date9.;
				call streaminit(' || seed || ');
				do i=1 to ' || n_records || ';
					do j=1 to ' || n_num_cols || ';
						nums[j] = rand("UNIFORM");
					end;
					do j=1 to ' || n_char_cols || ';
						chars[j] = substr(temp,ceil(rand("UNIFORM")*18),8);
					end;
					date = ' || mindate || '+int(rand("UNIFORM")*range);
			    	output;
				end;
			run;''';

		print code_ds1;

  		datastep.runCode result=r / code=code_ds1;

	end func;
    /*************************************** En of function body *********************************/

	generate(100, 120, 120, '01jan2005'd, '30jun2009'd, 'casuser', 'test',0);

quit;

proc cas;

	n_records=100;
	n_num_cols=2;
	n_char_cols=2;
	mindate='01jan2005'd;
	maxdate='30jun2009'd;
	outcaslib='casuser';
    outcastab='test';
	seed=1234;

    table.droptable / caslib=outcaslib name=outcastab quiet=true;

	code_ds1='''data "' || outcastab || '" (caslib="' || outcaslib || '") ;
			array nums[' || n_num_cols || '];
			array chars[' || n_char_cols || '] $;
			temp = "abcdefghijklmnopqrstuvwxyz";
			range = ' || maxdate || '-' || mindate || '+1;
			format range date date9.;
			call streaminit(' || seed || ');
			do i=1 to ' || n_records || ';
				do j=1 to ' || n_num_cols || ';
					nums[j] = rand("UNIFORM");
				end;
				do j=1 to ' || n_char_cols || ';
					chars[j] = substr(temp,ceil(rand("UNIFORM")*18),8);
				end;
				date = ' || mindate || '+int(rand("UNIFORM")*range);
		    	output;
			end;
	run;''';

	print code_ds1;

  	datastep.runCode result=r / code=code_ds1;

quit;

proc cas;


	datastep.runcode / code='data "test" (caslib="casuser") ;array nums[120];array chars[120] $;temp = "abcdefghijklmnopqrstuvwxyz";range = 
18078-16437+1;format range date date9.;call streaminit(0);do i=1 to 100;    do j=1 to 120;        nums[j] 
= rand("UNIFORM");    end;    do j=1 to 120;        chars[j] = substr(temp,ceil(rand("UNIFORM")*18),8);  
  end;    date = 16437+int(rand("UNIFORM")*range);    output;end;run;';


quit;



cas _all_ terminate;


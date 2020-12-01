cas mysess;

caslib _ALL_ assign;

data casuser.one;
	input chaine $50.;
	datalines;
député,çàù
opérateur,èà
éà@ds,7890
;
run;

proc print data=casuser.one; run;

proc fedsql sessref=mysess;
	select chaine, length(chaine),scan(chaine,1,','),substr(chaine,1,3) from casuser.one;
quit;

proc fedsql sessref=mysess;
	select chaine, length(chaine) as A,scan(chaine,1,',') as B,substr(chaine,1,3) as C from casuser.one where trim(scan(chaine,1,','))='député';
quit;

proc fedsql sessref=mysess;
	select chaine, length(chaine) as A,scan(chaine,1,',') as B,substr(chaine,1,3) as C from casuser.one where substr(trim(chaine),1,3)='dép';
quit;



proc print data=casuser.out0; run;

proc cas;
	fedsql.execdirect / query="select length(chaine), scan(chaine,1,','), substr(chaine,1,3) from casuser.one";
quit;

data casuser.out2; 
	set casuser.one; 
	l=length(chaine); 
	c=scan(chaine,1,',');
	c2=substr(chaine,1,3);
run;

proc print data=casuser.out2; run;

data casuser.out3; 
	set casuser.one; 
	l=klength(chaine); 
	c=kscan(chaine,1,',');
	c2=ksubstr(chaine,1,3);
run;

proc print data=casuser.out3; run;

proc cas;
	datastep.runcode / code="
		data casuser.out4; 
			set casuser.one; 
			l=klength(chaine); 
			c=kscan(chaine,1,',');
			c2=ksubstr(chaine,1,3);
		run;";
quit;

proc print data=casuser.out4; run;

cas mysess terminate;

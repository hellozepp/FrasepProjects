cas mysess;

caslib _ALL_ assign;

data casuser.one;
	input chaine $50.;
	datalines;
	Aéèèèéé,ééàààéààé
;
run;

proc print data=casuser.one; run;

proc fedsql sessref=mysess;
	select length(chaine),scan(chaine,1,','),substr(chaine,1,8) from casuser.one;
quit;

proc cas;
	fedsql.execdirect / query="select length(chaine), scan(chaine,1,','), substr(chaine,1,8) from casuser.one";
quit;

data casuser.out2; 
	set casuser.one; 
	l=length(chaine); 
	c=scan(chaine,1,',');
	c2=substr(chaine,1,8);
run;

proc print data=casuser.out2; run;

data casuser.out3; 
	set casuser.one; 
	l=klength(chaine); 
	c=kscan(chaine,1,',');
	c2=ksubstr(chaine,1,8);
run;

proc print data=casuser.out3; run;

proc cas;
	datastep.runcode / code="
		data casuser.out4; 
			set casuser.one; 
			l=klength(chaine); 
			c=kscan(chaine,1,',');
			c2=ksubstr(chaine,1,8);
		run;";
quit;

proc print data=casuser.out4; run;

cas mysess terminate;

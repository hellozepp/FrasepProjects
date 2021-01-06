%macro boucle_yulia;
	/* nombre de ligne à lire */
	data _null_;
		set YULIA nobs=ligne;
		call symputx("ligne", ligne);
		stop;
	run;

	%put &ligne;

	%do i=1 %to &ligne;

		data YULIA1;
			set YULIA(keep=itemkey orderweekpatterndetails firstobs=&i obs=&i);
			file 
				"C:\Users\franco\OneDrive - SAS\Documents\Test DATA\YULIAJSON\yuliatemp.json";
			put orderweekpatterndetails;
		run;

		filename in 
			"C:\Users\franco\OneDrive - SAS\Documents\Test DATA\YULIAJSON\yuliatemp.json";
		libname in json;

		data YULIAMERGE;
			if _N_=1 then
				set YULIA1;

			/* juste pour lire le ITEMKEY */
			else
				do;
					set in.root;
					output;
				end;
		run;

		proc append base=final data=YULIAMERGE;
		run;

	%end;
%mend;

options mprint;
%boucle_yulia
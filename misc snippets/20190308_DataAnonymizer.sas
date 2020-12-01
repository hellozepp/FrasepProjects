%macro DataAnonymizer(DSin=, DSout=, id=, var=, type=, substr_length=, dropvars=, print=1, debug=0);
	%***********************************************************************************;
	%*                                                                       	       *;
	%*  MACRO: DataAnonymizer                                                	       *;
	%*                                                                       	       *;
	%*  USAGE: %DataAnonymizer(DSin=ib_contact, DSout=anonymize, id=personid,          *;
	%*          var=gebdatum, type=date, dropvars=dept, print=1, debug=0)              *;
	%*                                                                       	       *;
	%*  PARAMETERS:                                                          	       *;
	%*  - DSIN          : Input dataset name                                   	       *;
	%*  - DSOUT         : Output dataset name                                  	       *;
	%*  - ID            : ID variable name (unique key)                        	       *;
	%*  - VAR           : Anonimized variable name                             	       *;
	%*  - TYPE          : Used algorithm (see Description below)               	       *;
	%*  - SUBSTR_LENGTH : Substring length in combination with type=SUBSTR     	       *;
	%*  - DROPVARS	    : Variable(s) to be dropped in output dataset          	       *;
	%*  - PRINT (0|1)   : Print subset of data to check result                 	       *;
	%*  - DEBUG (0|1)   : Provide debugging details                            	       *;
	%*                                                                       	       *;
	%*                                                                       	       *;
	%*  DESCRIPTION:                                                         	       *;
	%*    This macro is used to anonimize PII data, using the following      	       *;
	%*    algorithms (specified with the type parameter):                    	       *;
	%*    - HASH		         : using SHA256 algorithm         	 			 	   *;
	%*      				       can also be used for Pseudonymization               *;
	%*    - HASH_PLUS		     : using SHA256 algorithm after adding random chars	   *;
	%*      				       even stronger algorithm, not for Pseudonymization   *;
	%*    - SHUFFLE_DATASET      : random shuffle to complete dataset 			 	   *;
	%*    - SHUFFLE_DATASET_PLUS : random shuffle N times to complete dataset          *;
	%*    - SUBSTR	             : keep only N positions from variable (eg. zipcodes)  *;
	%*    - DUTCHZIPAA           : replacing the 2 letters with AA in Dutch Zip codes  *;
	%*    - DATE        	     : setting date on July 1 (keep actual year)      	   *;
	%*                                                                       	       *;
	%***********************************************************************************;
	%put NOTE: DataAnonymizer macro beginning.;
	options nonotes nosource;
	title;
	%local msg substr_length_old;
	%let DSin = %upcase(&DSin);
	%let DSout = %upcase(&DSout);
	%let id = %upcase(&id);
	%let var = %upcase(&var);
	%let type = %upcase(&type);
	%let dropvars = %upcase(&dropvars);

	%if &type NE %str(HASH) %then
		%do;
			%if &type NE %str(HASH_PLUS) %then
				%do;
					%if &type NE %str(SHUFFLE_DATASET) %then
						%do;
							%if &type NE %str(SHUFFLE_DATASET_PLUS) %then
								%do;
									%if &type NE %str(SUBSTR) %then
										%do;
											%if &type NE %str(DUTCHZIPAA) %then
												%do;
													%if &type NE %str(DATE) %then
														%do;
															%put ERROR: invalid value: %KCMPRES(&type) for parameter type.;
															%put ERROR: value should be: HASH, HASH_PLUS, SHUFFLE_DATASET, SHUFFLE_DATASET_PLUS, SUBSTR, DUTCHZIPAA or DATE.;
															%goto exit;
														%end;
												%end;
										%end;
								%end;
						%end;
				%end;
		%end;

	%if &debug = 1 %then
		%do;
			options source notes mprint mlogic mprintnest;
		%end;
	%else %if &debug = 0 %then
		%do;
			options nomprint nomlogic nomprintnest;
		%end;
	%else
		%do;
			%put WARNING: invalid value %KCMPRES(&debug) for parameter debug, value set to 0.;
			options nosource nonotes nomprint nomlogic nomprintnest;
		%end;

	%if %sysfunc(exist(&DSin)) ge 1 %then
		%do;

			proc sql noprint;
				select count(*) into :AantalObs from &DSin;
			quit;

			/* get metadata from DSin*/
			data _null_;
				length vartype $3 varlen $8 idtype $3 idlen $8;
				dsid=open("&DSin", 'I');

				if dsid then
					do;
						id=varlen(dsid,varnum(dsid,"&id"));
						idtype=vartype(dsid,varnum(dsid,"&id"));

						if idtype='C' then
							idlen=compress("$"||put(id,3.)||".");
						else idlen=compress(put(id,3.)||".");
						var=varlen(dsid,varnum(dsid,"&var"));
						vartype=vartype(dsid,varnum(dsid,"&var"));

						if vartype='C' then
							varlen=compress("$"||put(var,3.)||".");
						else varlen=compress(put(var,3.)||".");
						call symput('varlen',trim(left(varlen)));
						call symput('idlen',trim(left(idlen)));
						call symput('varlength',trim(left(var)));

						%if &debug = 1 %then
							%do;
								put _all_;
							%end;
					end;

				rc = close(dsid);

				%if &debug = 1 %then
					%do;
						put rc=;
					%end;
			run;

			%if &debug = 1 %then
				%do;
					%put varlen=&varlen idlen=&idlen;
				%end;

			%if &print = 1 %then
				%do;
					title "Original dataset: %KCMPRES(&DSin)";

					proc print data=&dsin (obs=10);
					run;

				%end;

			/* Define hashtable for type=shuffle_dataset */
			%if &type=SHUFFLE_DATASET %then
				%do;

					data HashObject (keep=&var);
						attrib &var length=&varlen;
						attrib &id length=&idlen;

						if _N_ = 1 then
							do;
								declare hash h(dataset:"&dsin", ordered: 'no');
								declare hiter iter('h');
								h.defineKey("&id");
								h.defineData("&id", "&var");
								h.defineDone();

								/* Avoid uninitialized variable notes */
								call missing(&id, &var);
							end;

						/* Retrieve values */
						rc = iter.first();

						do while (rc = 0);
							output;
							rc = iter.next();
						end;
					run;

					%if &print = 1 %then
						%do;
							title "Shuffled_dataset variable: %KCMPRES(&var)";

							proc print data=hashobject (obs=10);
							run;

						%end;
				%end;

			/* Define hashtable N times for type=shuffle_dataset+ */
			%if &type=SHUFFLE_DATASET_PLUS %then
				%do;

					data HashObject (keep=&var);
						attrib &var length=&varlen;
						attrib &id length=&idlen;

						if _N_ = 1 then
							do;
								declare hash h(dataset:"&dsin", ordered: 'no');
								declare hiter iter('h');
								h.defineKey("&id");
								h.defineData("&id", "&var");
								h.defineDone();

								/* Avoid uninitialized variable notes */
								call missing(&id, &var);
							end;

						/* Retrieve values */
						rc = iter.first();

						do while (rc = 0);
							output;
							rc = iter.next();
						end;
					run;

					data _sort (keep=&var sortvar);
						set hashobject;
						random=round(ranuni(0)*10)+1;
						len=length(&var);
						sortindex=mod(len,random)+1;
						sortvar=substr(&var,sortindex);
					run;

					proc sort data=_sort out=hashobject (drop=sortvar);
						by sortvar;
					run;

					%if &print = 1 %then
						%do;
							title "Shuffled_dataset_plus variable: %KCMPRES(&var)";

							proc print data=hashobject (obs=10);
							run;

						%end;
				%end;

			data &dsout;
				merge &dsin

				%if &type=SHUFFLE_DATASET %then

					%do;
						(drop=&var) Hashobject
					%end;

				%if &type=SHUFFLE_DATASET_PLUS %then
					%do;
						(drop=&var) Hashobject
					%end;
				;
				%if &type=HASH %then
					%do;
						&var=sha256hex(&var);
					%end;

				%if &type=HASH_PLUS %then
					%do;
						random=round(ranuni(0)*10)+1;
						len=length(&var);
						index=mod(len,random)+1;
						substr(&var,index,1)='A';
						&var=sha256hex(&var);
						drop random len index;
					%end;

				%if &type=SUBSTR %then
					%do;
						%let substr_length_old = &substr_length;

						%if %eval(&varlength < &substr_length) %then
							%do;
								%let substr_length = &varlength;
								%let msg = NOTE: Supplied substr_length value: %KCMPRES(&substr_length_old) longer than variable length %KCMPRES(&varlength). Actual value used.;
							%end;

						&var=substr(&var,1,&substr_length);
					%end;

				%if &type=DUTCHZIPAA %then
					%do;
						if &var = '' then
							&var='_NULL_';
						else
							do;
								revpc=reverse(&var);
								substr(revpc,1,2)='AA';

								if length(&var) >= 7 then
									do;
										substr(revpc,3,1) ='';
									end;

								&var=reverse(revpc);
								drop revpc;
							end;
					%end;

				%if &type=DATE %then
					%do;
						&var=mdy(7,1,year(&var));
					%end;

				%if &dropvars NE %then
					%do;
						drop &dropvars;
					%end;
			run;

			%if &print = 1 %then
				%do;
					title "Output dataset: %KCMPRES(&DSout) with type = %KCMPRES(&type) %KCMPRES(&substr_length_old) for variable %KCMPRES(&var)";

					proc print data=&dsout (obs=10);
					run;

				%end;
		%end;
	%else
		%do;
			%put ERROR: Dataset: %KCMPRES(&DSin) does not exist.;
			%goto exit;
		%end;

	/* Summary and cleanup */
	proc datasets noprint mt=data;
		delete hashobject _sort;
	quit;

	title;
	options notes;
	%put %str();
	%put NOTE: Output dataset: %KCMPRES(&DSout) created with: %KCMPRES(&AantalObs) observations.;
	%put NOTE: Method: %KCMPRES(&type) used for variable %KCMPRES(&var) with id variable %KCMPRES(&id).;
	%put &msg;

	%if &dropvars NE %then
		%put NOTE: Variable(s): %KCMPRES(&dropvars) dropped.;
	%put %str();
	options source;

%exit:
	options source notes;;
	%put NOTE: DataAnonymizer macro ended.;
%mend;

* Create sample PII dataset;
Data PII_test;
	infile cards dlm=',';
	input PERSONID : $13. CITY : $24. ZIP : $7. COMPANY : $54. ADDRESS1 : $24. SNAME : $20. GEBDATUM : date9.;
	format GEBDATUM date9.;
	cards;
NL-P-0003155,'S-GRAVENHAGE,2500 EE,KBP Operator Vaste Net,Postbus 2024,van der Genugten,06JUL1981
NL-P-0003156,WOERDEN,3441 XD,ABC Holland Trust Company Nederland B.V,Prins Hendrikkade 22,van der Harst AC,01FEB1964 
NL-P-0003157,WOERDEN,3440 AJ,Stichting European Rail Research Institute,Postbus 398,Klaassen,28MAY1975
NL-P-0003181,ZWOLLE,8000 AM,ECC Gemini Ernst & -Jan,Postbus 548,Schellekens,09FEB1969
NL-P-0003183,OSS,5340 AA,Travel Card Nederland B.V.,Postbus 12,van den Goorbergh,05SEP1970  
NL-P-0003187,HENGELO OV,7550 AA,Oud Clingendaal Management Services B.V.,Postbus 35,Ballero,03NOV1986  
NL-P-0003188,UTRECHT,3532 AD,NoRRoD,Vleutensevaart 36,Berg,09JUL1985
NL-P-0003192,BILTHOVEN,3720 AC,NOWM Verzekeringen N.V.,Postbus 148,Doff,25JAN1969
NL-P-0003193,'S-HERTOGENBOSCH,5201 GA,Trespa International B.V.,Postbus 5048,Remerij,14JUL1970  
NL-P-0003194,RIDDERKERK,2985 BD,Accentuur CT Information Technology,De Merodelaan 5,de Wal,25JUN1963
;
run;

%DataAnonymizer(DSin=PII_test, DSout=anonymize, id=personid, var=gebdatum, type=date, dropvars=dept, print=1, debug=1)
%DataAnonymizer(DSin=anonymize, DSout=anonymize2, id=personid, var=city, type=shuffle_dataset, print=1, debug=0)
%DataAnonymizer(DSin=anonymize2, DSout=anonymize3, id=personid, var=city, type=shuffle_dataset_plus, print=1, debug=1)
%DataAnonymizer(DSin=anonymize3, DSout=anonymize4, id=personid, var=zip, type=dutchzipaa, print=1, debug=0)
%DataAnonymizer(DSin=anonymize4, DSout=anonymize5, id=personid, var=company, type=substr, substr_length=10, print=1, debug=9)
%DataAnonymizer(DSin=anonymize4, DSout=anonymize5, id=personid, var=address1, type=hash, substr_length=, print=1, debug=0)
%DataAnonymizer(DSin=anonymize5, DSout=anonymize6, id=personid, var=sname, type=hash, substr_length=, print=1, debug=0)
%DataAnonymizer(DSin=anonymize5, DSout=anonymize7, id=personid, var=sname, type=hash_plus, substr_length=, print=1, debug=0)
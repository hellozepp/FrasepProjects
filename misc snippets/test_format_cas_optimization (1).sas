cas mysess_testsep;
caslib _ALL_ assign;

data casuser.liste_siren_exemple_1;
	set casuser.bdf_dtm_l(keep=ej_fact_SIREN_EJ ej_fact_VECTEUR_PERIMETRES);
	where ej_fact_SIREN_EJ not in (349850784,495170599,479092546,404328239,325654051,440414761,448030072,809931702,819006347,834187551,444573109,491258497,
493822050,394767685,508689932,450972104,452578180,418655346,517956207,493329551,502327000,412047250,823157870,
489017541,480571546,811078773,377969522,510256449,791572845,478474281,834245466,404470460,752983650,831821525,419617402,444698690,878215136,530241744,
529395881,380922575,444636849,504017732,845096957,851452565,814063947,439901158,503454951,498242601,499781383,810822155,349122200,811381375,812765766,808418461,
394715965,404148934,438078016,490477445,310712989,493996730,831243258,344805866,824344188,521176230,801619248);
run;

proc cas;
	action deduplication.deduplicate / 
	  table={caslib="casuser" name="liste_siren_exemple_1",
	        groupBy={{name="ej_fact_SIREN_EJ"},{name="ej_fact_VECTEUR_PERIMETRES"}}},                         
	  casOut={caslib="casuser" name="liste_siren_exemple_1",replace=true},
	  noDuplicateKeys=true;
	run;
quit;

proc cas;
	fedsql.execdirect / query="select ej_fact_siren_ej, count(*) from casuser.liste_siren_exemple_1 group by ej_fact_siren_ej having count(*)>1";
quit;

data casuser.fmt_liste_siren / sessref=mysess_testsep single=yes;
   set CASUSER.LISTE_SIREN_EXEMPLE_1(rename=(ej_fact_SIREN_EJ=start ej_fact_VECTEUR_PERIMETRES=label)) end=last;
   retain fmtname "vperimetres" type "c";
   output;
   if last then do;
      hlo='O';
      label='*';
      output;
   end;
run;

proc format cntlin=casuser.fmt_liste_siren casfmtlib='myformats' sessref=mysess_testsep;
run;

data casuser.test_left_join_format_1 / sessref=mysess_testsep;
   set BDFDATA.BDF_DTM_L;
   keep 
   vecteur_perimetres=input(put(put(ej_fact_SIREN_EJ,$10.), $VPERIMETRES.),$10.);
run;

cas _all_ terminate;

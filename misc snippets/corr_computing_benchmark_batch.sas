options cashost='frasepviya35smp.cloud.com' casport=5570 casdatalimit=10G;

cas casauto sessopts=(timeout=3600, metrics=true);
caslib _all_ assign;

proc cas;
	table.tabledetails / caslib='public' name='test_corr';
quit;

proc corr data=public.test_corr(keep=nums1 nums2) spearman;
   var nums1;
   with nums2;
run;

proc freqtab data=public.test_corr;
	tables nums1 * nums2 / chisq;
	output out=casuser.out_freqtab chisq;
	ods exclude all;
run;

proc cas;
	table.droptable / caslib='public' name='out_freqtab' quiet=true;
    table.promote / caslib='casuser' name='out_freqtab' targetcaslib='public' target='out_freqtab' drop=true;
quit;

/* 9 100 000 : 16,7 secondes */
/* 91 000 000 : 207 secondes */

cas casauto terminate;

options cashost='frasepviya35smp.cloud.com' casport=5570 casdatalimit=10G fullstimer;
 
cas casauto sessopts=(timeout=3600, metrics=true);
caslib _all_ assign;

proc corr data=public.test_corr(keep=nums1 nums2) spearman out=out_table;
   var nums1;
   with nums2;
run;

cas casauto terminate;

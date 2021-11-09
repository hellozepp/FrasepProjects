options cashost='frasepviya35smp.cloud.com' casport=5570 casdatalimit=10G;

cas casauto sessopts=(timeout=3600, metrics=true);
caslib _all_ assign;

%macro generate(n_rows=10, n_num_cols=1, n_char_cols=1, mindate='01jan2005'd, maxdate='30jun2009'd, outdata=test, seed=0);
	data &outdata;
		array nums[&n_num_cols];
		array chars[&n_char_cols] $;
		temp="abcdefghijklmnopqrstuvwxyz";
		range=&maxdate-&mindate+1;
		format range date date9.;

		do i=1 to &n_rows;
			do j=1 to &n_num_cols;
				nums[j]=ranuni(&seed);
			end;

			do j=1 to &n_char_cols;
				chars[j]=substr(temp, ceil(ranuni(&seed)*18), 8);
			end;
			date=&mindate +int(ranuni(&seed)*range);
			output;
		end;
		drop i j temp;
	run;
%mend generate;

%generate(n_rows=91000000,n_num_cols=2,n_char_cols=1,outdata=casuser.test_corr,seed=0);

proc cas;
	table.droptable / caslib='public' name='test_corr' quiet=true;
    table.promote / caslib='casuser' name='test_corr' targetcaslib='public' target='test_corr' drop=true;
quit;

proc cas;
	table.tabledetails / caslib='public' name='test_corr';
quit;


proc corr data=public.test9M(keep=nums1 nums2) spearman;
   var nums1;
   with nums2;
run;

/* 9 100 000 : 16,7 secondes */

cas casauto terminate;

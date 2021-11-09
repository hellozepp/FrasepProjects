options cashost='frasepviya35smp.cloud.com' casport=5570;

cas casauto;
caslib _all_ assign;


%macro generate(n_rows,n_num_cols,n_char_cols,mindate,maxdate,outdata=test,seed=0);
data &outdata;
array nums[&n_num_cols];
array chars[&n_char_cols] $;
temp = "abcdefghijklmnopqrstuvwxyz";
range = &maxdate-&mindate+1;
format range date date9.;
do i=1 to &n_rows;
    do j=1 to &n_num_cols;
        nums[j] = ranuni(&seed);
    end;
    do j=1 to &n_char_cols;
        chars[j] = substr(temp,ceil(ranuni(&seed)*18),8);
    end;
    date = &mindate +int(ranuni(&seed)*range);
    output;
end;
drop i j temp;
run;
%mend;

%generate(9100000,2,1,'01jan2005'd,'30jun2009'd,outdata=casuser.test9M);


proc cas;
    table.promote / caslib='casuser' name='test9M' targetcaslib='public' target='test9M' drop=true;
quit;

proc corr data=public.test9M(keep=nums1 nums2) spearman;
   var nums1;
   with nums2;
run;

cas casauto terminate;

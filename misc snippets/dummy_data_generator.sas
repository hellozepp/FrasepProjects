
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

%generate(100000000,1,1,'01jan2005'd,'30jun2009'd,outdata=test);
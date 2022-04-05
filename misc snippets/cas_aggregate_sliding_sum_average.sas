cas mysess sessopts=(metrics=true);
caslib _ALL_ assign;

/* Generate a dummy dataset in cas with date and total column */

data casuser.test;
	do y=1700 to 2021;
		do m=1 to 12;
    		do j=1 to 31;
            	date=mdy(m, j, y);
                total=round(rand("uniform", 1, 10));
                output;
             end;
        end;
	end;
    format date date9.;
    drop m j y;
run;

/* Example of a sliding mean and sum on a window of 3 days */

proc cas;
	aggregation.aggregate / 
		table={name="test", caslib="casuser", groupBy="Date"},
		varSpecs={{name="Total", subset={"MEAN","SUM"} }} , ID="Date"
       , Interval="DAY"
       , windowInt="3"
       , casOut={name="summary", caslib="casuser", replace=TRUE};

	table.fetch / table={name="summary", caslib="casuser", orderBy={"date"}} , index=FALSE;	
	
quit;

/* Example of a sliding mean and sum on a window of a quarter */

proc cas;
	aggregation.aggregate / 
		table={name="test", caslib="casuser", groupBy="Date"},
		varSpecs={{name="Total", subset={"MEAN","SUM"} }} , ID="Date"
       , Interval="MONTH"
       , windowInt="QTR"
       , casOut={name="summary", caslib="casuser", replace=TRUE};

	table.fetch / table={name="summary", caslib="casuser", orderBy={"date"}} , index=FALSE;	
	
quit;


cas mysess terminate;



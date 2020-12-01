data lineage(keep=hist1-hist5);
 /* Read in SAS data set */
9
 set TEST;
 /* Create an array with enough elements to hold the maximum number of
 observations that will 'link' together. */
 array hist(5);
 count=1;
 /* Put the value of CHILD variable into the array HIST */
 hist(count)=child;
 /* Process through the entire data set while the value of COUNT is less
 than 4, i.e. the upper boundary of the array minus 1. */
 do i=1 to last while (count<dim(hist)-1);
 /* Read in SAS data set again. Rename the variables to new names so
 they can be compared with the variable names coming in with the
 first SET statement. The POINT= option allows you to access each
 observation by observation number.*/
 set TEST(rename=(child=child1 parent=parent1)) nobs=last point=i;
 /* As you step through each observation, compare the value of PARENT to
 the value of CHILD1 (which is the new name given to the CHILD variable
 when data set is brought in second time). */
 if parent=child1 then do;
 count+1;
 /* populate array with value of CHILD1 */
 hist(count)=child1;
 child=child1;
 parent=parent1;
 i=1;
 end;
 end;
 /* increment COUNT */
 count+1;
 hist(count)=parent;
 run;
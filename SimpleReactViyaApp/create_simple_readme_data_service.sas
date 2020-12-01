%let appLoc=/Public/app/readme;  /* Metadata or Viya Folder per SASjs config */
filename mc url "https://raw.githubusercontent.com/sasjs/core/main/all.sas";
%inc mc; /* compile macros (can also be downloaded & compiled seperately) */
filename ft15f001 temp;
parmcards4;
  %webout(FETCH) /* receive all data as SAS datasets */
  proc sql;
  create table areas as select make,mean(invoice) as avprice
    from sashelp.cars
    where type in (select type from work.fromjs)
    group by 1;
  %webout(OPEN)
  %webout(OBJ,areas)
  %webout(CLOSE)
;;;;
%mp_createwebservice(path=&appLoc/common,name=getdata)
/* Test connexion hadoop */

cas mysess01;


/* Test creation de table CAS à partir d une requete en passthrough */

proc cas;
 fedSql.execDirect query='                                  
  select pos from connection to TDcaslib                      
  ( select unique Pos from employees )';
quit;





cas mysess01 terminate;

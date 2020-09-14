/*************************************************************************************************************/
/* Score production data with SAS Viya datalab generated model through selfgenereted SAS9 Script (SAS9.4M5+) */
/*************************************************************************************************************/

/****************************************************************************/
/* Prepare SAS9 script for scoring baed on model published by SAS Viya datalab */

proc astore;
	describe 
	store="C:\Users\frasep\Documents\My SAS\10 - Clients\Dossiers 2018\BNPP BDDF\Etude ASTORE\store" /* Atore physical file location */
	epcode="C:\Users\frasep\Documents\My SAS\10 - Clients\Dossiers 2018\BNPP BDDF\Etude ASTORE\scoring.sas";  /* location of generated scoring script based on the given astore metadata */
run;

/****************************************************************************/
/* Score the production data with the script generated in the previous step */

proc astore;
score 
store="C:\Users\frasep\Documents\My SAS\10 - Clients\Dossiers 2018\BNPP BDDF\Etude ASTORE\store"  /*là où est le fichier store que je t’ai envoyé*/
epcode="C:\Users\frasep\Documents\My SAS\10 - Clients\Dossiers 2018\BNPP BDDF\Etude ASTORE\try.sas"  /* là où est le code DS2*/
data=work.churn2   /* La table à scorer */
out=work.trytry;   /* La table des predictions produites */
run;
quit;


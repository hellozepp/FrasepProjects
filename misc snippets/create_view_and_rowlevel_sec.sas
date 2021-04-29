cas mysess001;
* Set OPTIONS;
options sessopts=(caslib="casuser" timeout=1800 locale="en_US" metrics="true");
* Leading scenario;


proc casutil;
	droptable casdata="churn_fr_star" incaslib="mydata" quiet;
quit;

caslib _ALL_ assign;


proc cas;

	table.view / promote=true caslib='mydata' name='churn_fr_star' 
		tables={
			{caslib='mydata',name='churn_fr', as='fait'}, 
				{
					keys={'fait_id = client_id'}, 
					caslib='mydata', 
					name='CHURN_DONNEES_CLIENT_BRUTES_FR', 
					varlist={'ADRESSE','CODEPOSTAL','CSP','DATE_NAISSANCE','ID_CLIENT','NB_CONTRATS','NOM','PRENOM','TELEPHONE','VILLE'},
					as='client' 
					 }
};

quit;

/* Add row level security */

proc cas;
accessControl.updSomeAcsTable /
   acs={
      {caslib="mydata",
       table="churn_fr_star",
       identity="viyademo02",
       identityType="User",
       permType="Grant",
       permission="Select",
       filter="client_ville='CHAMPAGNOLE'"},
      {caslib="mydata",
       table="churn_fr_star",
       identity="viyademo02",
       identityType="User",
       permType="Grant",
       permission="ReadInfo"}};
quit;

cas mysess001 terminate;



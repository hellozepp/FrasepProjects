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

/* List table effective access controls */
/* https://go.documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/caspg/p1v6omrbqeadyyn1otd0ibug53u9.htm */

/* Clean and add row level security rule */

proc cas;
	accessControl.assumeRole / adminRole="superuser";
	accessControl.remAllAcsData /  caslib="mydata"  table="churn_fr_star";

	accessControl.updSomeAcsTable /
	   acs={
	      {
			caslib="mydata",
	        table="churn_fr_star",
	        identity="viyademo02",
	        identityType="User",
	        permType="Grant",
	        permission="Select",
	        filter="client_ville='CHAMPAGNOLE'"},
	      {
			caslib="mydata",
	        table="churn_fr_star",
	        identity="viyademo02",
	        identityType="User",
	        permType="Grant",
	        permission="ReadInfo"}
	};
quit;

/* Display effective rules */
proc cas;
	accessControl.whatIsEffective /  objectSelector={objType="table",caslib="mydata",table="churn_fr_star"};
quit;

cas mysess001 terminate;

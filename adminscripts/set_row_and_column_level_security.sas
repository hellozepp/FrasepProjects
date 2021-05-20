cas sessiomgmt001;

proc cas;
    session sessiomgmt001;
    accessControl.assumeRole / adminRole="superuser";

	/* Remove all access control on a table  */
	accessControl.remAllAcsData / caslib="AzureDL", table="megacorp5_4m.orc";

	accessControl.whatIsEffective / objectSelector={objType="table",caslib="AzureDL",table="megacorp5_4m.orc"};

	/* Define rowlevel filters  */
	accessControl.updSomeAcsTable /
	   acs={
	      {caslib="AzureDL",
	       table="megacorp5_4m.orc",
	       identity="sales",
	       identityType="Group",
	       permType="Grant",
	       permission="Select",
	       filter="FacilityRegion ='South'"}};

	accessControl.whatIsEffective / objectSelector={objType="table",caslib="AzureDL",table="megacorp5_4m.orc"};

	/* Define column level security. Best practice to position it on source file/table. */
	/* example : give Revenue column access only for sales group */
	
	accessControl.updSomeAcsColumn /
	   acs={
	     {caslib="AzureDL",table="megacorp5_4m.orc",column="Revenue",identity="*",identityType="Group",permType="Deny",permission="ReadInfo"},
	     {caslib="AzureDL",table="megacorp5_4m.orc",column="Revenue",identity="*",identityType="Group",permType="Deny",permission="Select"},
	     {caslib="AzureDL",table="megacorp5_4m.orc",column="Revenue",identity="sales",identityType="Group",permType="Grant", permission="ReadInfo"},
	     {caslib="AzureDL",table="megacorp5_4m.orc",column="Revenue",identity="sales",identityType="Group",permType="Grant",permission="Select"}
	    };

	accessControl.whatIsEffective / objectSelector={objType="table",caslib="AzureDL",table="megacorp5_4m.orc"};

quit;


cas sessiomgmt001 terminate;

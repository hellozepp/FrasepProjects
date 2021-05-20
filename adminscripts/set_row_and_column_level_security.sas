cas sessiomgmt001;

/*
Content of result table meaning :
0       Unknown
1       Not Authorized (explicit)
2       Not Authorized (inherited)
3       Authorized (explicit)
4       Authorized with Filter (explicit)
5       Authorized (inherited)
6       Authorized with Filter (inherited)
*/

proc cas;
    session sessiomgmt001;
    accessControl.assumeRole / adminRole="superuser";

        /* Remove all access control on a table  */
        accessControl.remAllAcsData / caslib="mydata", table="megacorp5_4m.sashdat";

        accessControl.whatIsEffective / objectSelector={objType="table",caslib="mydata",table="megacorp5_4m.sashdat"};

        /* Define rowlevel filters  */
        accessControl.updSomeAcsTable /
           acs={
              {caslib="mydata",
               table="megacorp5_4m.sashdat",
               identity="sales",
               identityType="Group",
               permType="Grant",
               permission="Select",
               filter="FacilityRegion ='South'"}};

        accessControl.whatIsEffective / objectSelector={objType="table",caslib="mydata",table="megacorp5_4m.sashdat"};

        /* Define column level security. Best practice to position it on source file/table. */
        /* example : give Revenue column access only for sales group */

        accessControl.updSomeAcsColumn / acs={
                {caslib="mydata",table="megacorp5_4m.sashdat",column="Revenue",identity="*",identityType="Group",permType="Deny",permission="ReadInfo"},
                {caslib="mydata",table="megacorp5_4m.sashdat",column="Revenue",identity="*",identityType="Group",permType="Deny",permission="Select"},
                {caslib="mydata",table="megacorp5_4m.sashdat",column="Revenue",identity="sales",identityType="Group",permType="Grant", permission="ReadInfo"},
                {caslib="mydata",table="megacorp5_4m.sashdat",column="Revenue",identity="sales",identityType="Group",permType="Grant",permission="Select"}
         };

        /* Check effective access control on the specific column */
        accessControl.whatIsEffective / objectSelector={objType="column",caslib="mydata",table="megacorp5_4m.sashdat",column="Revenue"} returnEffectiveDetails=true;


quit;


cas sessiomgmt001 terminate;
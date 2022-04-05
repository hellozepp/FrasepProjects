## Implement policies

Ensure resource managament is properly enables

Implement default policy with implement_policies.sh script on Viya service node and obtain the following output :

The requested resource management policy for the CAS server was created successfully.
{
    "attributes": {
        "cpu": "55",
        "globalCasuser": "10000000000",
        "globalCasuserHdfs": "30000000000",
        "sessionTables": "5000000000"
    },
    "name": "cas-shared-default-priority-1",
    "type": "priorityLevels"
}


Create corresponding custom group cas-shared-default-priority-1 in EV and add members (not SAS Administrators)

## Test case 1 : session limits


## Test case 2 : global casuser (global cas table promoted in personal caslib "casuser")


## Test case 3 : 
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

Don't forget to restart the cas-controller service to take into account the new policies with a command below (executed on the cas controller node) :!
sudo systemctl stop sas-viya-cascontroller-default
sudo systemctl start sas-viya-cascontroller-default

Create corresponding custom group cas-shared-default-priority-1 in EV and add members (not SAS Administrators)

## Test case 1 : session limits


## Test case 2 : global casuser (global cas table promoted in personal caslib "casuser")


## Test case 3 : 
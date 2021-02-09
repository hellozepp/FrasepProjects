---
category: updateChecker
tocprty: 1
---

# Update Checker Cron Job

The Update Checker cron job builds a report comparing the currently
deployed release with available releases in the upstream repository.
The report is written to the stdout of the launched job pod and
indicates when new content related to the deployment is available.

For information about using the Update Checker, see [View Reports of Updates and Patches](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=k8sag&docsetTarget=p1it185kd37v25n1aoybu799tpk4.htm).

**Note:** Ensure that the version indicated by the version selector for the
document matches the version of your SAS Viya software.

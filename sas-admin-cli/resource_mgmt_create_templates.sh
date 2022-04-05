#!/bin/sh
clidir=/opt/sas/viya/home/bin
$clidir/sas-admin profile set-endpoint "https://frasepviya35vm1.cloud.com"
$clidir/sas-admin profile toggle-color off
$clidir/sas-admin profile set-output fulljson
$clidir/sas-admin auth login --user viyademo01 --password demopw
$clidir/sas-admin cas generate-cas-samples --output-location ~/rsc_mgmt_samples/
mkdir -p ~/rsc_mgmt_frasep
cp -R ~/rsc_mgmt_samples/* ~/rsc_mgmt_frasep
cd ~/rsc_mgmt_frasep
cp -R ./policies-examples/ ./policies-frasep
cd policies-frasep

/opt/sas/viya/home/bin/sas-admin cas servers policies define priority-levels --server cas-shared-default --priority 1 --cpu 55 --global-casuser 10000000000 --global-casuser-hdfs 30000000000 --session-tables 5000000000

#cp cas-shared-default-priority-2.json cas-shared-default-priority-1.json
#/opt/sas/viya/home/bin/sas-admin cas servers policies define priority-levels --server cas-shared-default --priority 1 --source-file cas-shared-default-priority-1.json
#/opt/sas/viya/home/bin/sas-admin cas servers policies define priority-levels --server cas-shared-default --priority 2 --source-file cas-shared-default-priority-2.json
#/opt/sas/viya/home/bin/sas-admin cas servers policies define global-caslibs --server cas-shared-default --source-file cas-shared-default-globalCaslibs.json
#/opt/sas/viya/home/bin/sas-admin cas servers policies define priority-assignments --server cas-shared-default --source-file cas-shared-default-priorityAssignments.json
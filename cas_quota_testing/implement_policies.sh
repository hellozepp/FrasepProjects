#!/bin/sh
source /opt/sas/viya/config/consul.conf
clidir=/opt/sas/viya/home/bin
$clidir/sas-admin profile set-endpoint "https://frasepviya35vm1.cloud.com"
$clidir/sas-admin profile toggle-color off
$clidir/sas-admin profile set-output fulljson
$clidir/sas-admin auth login --user viyademo01 --password demopw

/opt/sas/viya/home/bin/sas-admin cas servers policies define priority-levels --server cas-shared-default --priority 1 --cpu 55 --global-casuser 10000000000 --global-casuser-hdfs 30000000000 --session-tables 5000000000

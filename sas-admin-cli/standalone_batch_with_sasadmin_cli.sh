#!/bin/sh

clidir=/opt/sas/viya/home/bin

$clidir/sas-admin profile set-endpoint "https://host.example.com"
$clidir/sas-admin profile toggle-color off
$clidir/sas-admin profile set-output fulljson

$clidir/sas-admin auth login --user userID --password password


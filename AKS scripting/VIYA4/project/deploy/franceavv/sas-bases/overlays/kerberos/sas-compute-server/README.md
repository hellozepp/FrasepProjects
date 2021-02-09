# Configuring Compute Server Kerberos support for SAS Viya 4

This README describes the steps necessary to configure your SAS Viya 4 deployment SAS Compute Server for
using Kerberos.

## Prerequisites

Read and follow the instructions in ```$deploy/sas-bases/examples/kerberos/sas-servers/README.md```.  These steps only need to be performed once as they apply to all SAS Servers.

## Installation

1. Make the following changes to the base kustomization.yaml file in the ```$deploy``` directory.
    * If TLS enabled: Add sas-bases/overlays/kerberos/sas-compute-server/compute-server-kerberos-tls.yaml to the transformers block.
    * If TLS not enabled: Add sas-bases/overlays/kerberos/sas-compute-server/compute-server-kerberos-no-tls.yaml to the transformers block.
1. Check ```$deploy/sas-bases/overlays/kerberos``` for additional SAS Servers and follow instructions in the respective ```README.md``` files.

1. Once all SAS Servers are configured in the base kustomization.yaml, use the deployment commands described in [SAS Viya Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm) to apply the new settings.
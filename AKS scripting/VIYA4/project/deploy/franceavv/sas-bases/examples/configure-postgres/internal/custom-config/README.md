---
category: dataServer
tocprty: 8
---

# Configuration Settings for PostgreSQL Database Cluster

## Overview

This readme describes the configuration settings available for deploying a
PostgreSQL Database Cluster with defaults provided by SAS. Currently, the
TLS/SSL database parameters values are replaced with tokenized placeholders
that you must replace with proper values. These settings are applicable only 
if you are using an internal version of PostgreSQL.

## Installation

**Note:** These instructions only apply to the internal instance of
PostgreSQL server. If you are using an external instance of PostgreSQL, do
not perform any of these steps.

1. Copy the
   `sas-bases/examples/configure-postgres/internal/custom-config/postgres-custom-config.yaml`
   file to the site-config directory.

2. In the copied file, the variables that should be replaced are in this format:
   {{ VARIABLE-NAME }}. When replacing the variable, be sure to remove the brackets
   and spaces.

3. After replacing the variables, check the bootstrap/dcs/postgresql/parameters
   and bootstrap/postgresql/pg_hba sections in the yaml file to ensure that
   the tokens have been replaced with proper values.

4. After you have edited the file, add a reference to it in the generators
   block of the base kustomization.yaml file. Add the generators block if it does
   not already exist. Here is an example that assumes the file was copied to
   `$deploy/site-config/postgres/postgres-custom-config.yaml`:

   ```
   ...
   generators:
   - site-config/postgres/postgres-custom-config.yaml
   ...
   ```

5. These steps are for the initial deployment of SAS Viya. If you are modifying
   after the software has been deployed, additional steps are required so that
   any changes made to the PostgreSQL cluster configuration can take effect. See
   [SAS Infrastructure Data Server](http://documentation.sas.com/?cdcId=sasadmincdc&cdcVersion=default&docsetId=calsrvinf&docsetTarget=n00000sasinfrdatasrv000admin.htm&locale=en) in _SAS Viya Administration_ for those additional steps.

## Examples

The example file includes content for configuring the following settings.

* Specify the hba configuration as `hostssl` if TLS/SSL is enabled or as
  `host` if TLS/SSL is disabled.
* Specify whether the password uses md5 or scram-sha-256 encryption.
* If TLS/SSL is enabled, in order to lock down the Postgres cluster to allow
  SSL connections only, ensure all the HBA values are set to `hostssl`.

## Additional Resources

For more information about using the example file, see the
[SAS Viya Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

For more information about pgo.yaml configuration, go
[here](https://access.crunchydata.com/documentation/postgres-operator/4.5.0/configuration/pgo-yaml-configuration/).

For more information about postgresql.conf, go
[here](https://www.postgresql.org/docs/12/config-setting.html).

For more information about pg_hba.conf configuration, go
[here](https://www.postgresql.org/docs/12/auth-pg-hba-conf.html).
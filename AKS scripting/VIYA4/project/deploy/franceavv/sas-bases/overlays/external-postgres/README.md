---
category: dataServer
tocprty: 3
---

# Configure an External PostgreSQL Instance for SAS Viya

## Overview

By default, SAS Viya will not add a PostgreSQL instance to the Kubernetes
deployment. SAS Viya includes two options for your PostgreSQL server: an
internal instance provided by SAS or an external PostgreSQL that you want SAS
to use. 

This readme describes the files used to customize your SAS Viya deployment to
use an external PostgreSQL instance. Using these files means that you do not
wish to use the PostgreSQL server provided by SAS. Instead, you will create
your own and have SAS make use of it. 

**Note:** If you want to use an internal instance of PostgreSQL, you should
refer to the readme file located at
`$deploy/sas-bases/overlays/internal-postgres/README.md`.

The SAS Viya deployment performs the following tasks to configure your external 
database for use:

* Registers the connection information so services can find it.
* If not already provided, attempts to create a database that is owned by the
  SAS user using the name provided by the sas-postgres-config configMap.

**Note:** If you want to limit the SAS Database Role to only one database on
your server, create the database and role prior to deployment and ensure both
have the desired permissions. If you don't provide a database, SAS attempts
to create one using the name in the sas-postgres-config configMap. For this,
the SAS role must have CREATEDB permissions, otherwise you'll get an error.

## Prerequisites

Before beginning the SAS Viya deployment, your PostgreSQL server(s) should be
set up and running.

Your external PostgreSQL server(s) must support max connections and max prepared
transactions of at least 1024.

When the server is set up, you should record the following
information for later steps.

* Database Role/Password: The account to be used by the services to create
  databases (if applicable), schemas, and tables and to perform database
  transactions.
* Database name: The database SAS services will use. By default, SAS expects
  'SharedServices'.
* Server Host: The fully qualified domain name (FQDN) of the host of the
  cluster entry point of your PostgreSQL server.
* Server Port: The port for the cluster entry point process for your PostgreSQL 
  server. Typically PostgreSQL or PGPool port (if used).

## Instructions

This section describes how to modify the base kustomization.yaml file 
(`$deploy/kustomization.yaml`) to use an external PostgreSQL instance. To see an 
example of a completed base kustomization.yaml 
file for an external PostgreSQL instance, see
`$deploy/sas-bases/examples/configure-postgres/external-kustomization.yaml`.

### Create secretGenerator and configMapGenerator

To populate the SAS deployment with the information that you gathered in the
"Prerequisites" section, you must add some generators to the base
kustomization.yaml file.

In the base kustomization.yaml file (`$deploy/kustomization.yaml`), add a
secretGenerator and a configMapGenerator, both of which are described below.
In the generators, you will see tags that look like `{{ VARIABLE-NAME }}`.
Replace these tags with the appropriate values gathered in the "Prerequisites"
section.

The mapping of tags to values is as follows:

* Database Role Username: `{{ EXTERNAL-ADMIN-USERNAME }}`
* Database Role Password: `{{ EXTERNAL-ADMIN-PASSWORD }}`
* Server Host: `{{ EXTERNAL-HOST }}`
* Server Port: `{{ EXTERNAL-PORT }}`

Add the following secretGenerator to the base kustomization.yaml file:

```yaml
secretGenerator:
- name: postgres-sas-user  # THIS IS FOR INTERNAL USE ONLY - DO NOT EDIT
  literals:
  - username={{ EXTERNAL-ADMIN-USERNAME }}
  - password={{ EXTERNAL-ADMIN-PASSWORD }}
```

Then add the following configMapGenerator:

```yaml
configMapGenerator:
- name: sas-postgres-config  # THIS IS FOR INTERNAL USE ONLY - DO NOT EDIT
  behavior: merge
  literals:
  - DATABASE_HOST={{ EXTERNAL-HOST }}
  - DATABASE_PORT={{ EXTERNAL-PORT }}
  - DATABASE_SSL_ENABLED="true"
  - DATABASE_NAME=SharedServices
  - EXTERNAL_DATABASE="true"  # THIS IS FOR INTERNAL USE ONLY - DO NOT EDIT
  - SAS_DATABASE_DATABASESERVERNAME="postgres"
```

For example, a kustomization.yaml which has been properly edited with your
external database info generators might look like this:

```yaml
secretGenerator:
- name: postgres-sas-user  # THIS IS FOR INTERNAL USE ONLY - DO NOT EDIT
  literals:
  - username=dbmsowner
  - password=password

configMapGenerator:
- name: sas-postgres-config  # THIS IS FOR INTERNAL USE ONLY - DO NOT EDIT
  behavior: merge
  literals:
  - DATABASE_HOST=myProvider.myPostgreSQLHost
  - DATABASE_PORT=5432
  - DATABASE_SSL_ENABLED="true"
  - DATABASE_NAME=SharedServices
  - EXTERNAL_DATABASE="true"  # THIS IS FOR INTERNAL USE ONLY - DO NOT EDIT
  - SAS_DATABASE_DATABASESERVERNAME="postgres"
```

### Configure Transformers

Kustomize needs to know where to look for the external PostgreSQL transformer.
Add the following content to the transformers block of the base
kustomization.yaml file:

```yaml
transformers:
- sas-bases/overlays/external-postgres/external-postgres-transformer.yaml
```

### Multiple External PostgreSQL

You can provide multiple external PostgreSQL servers to SAS. The additional
servers will only be used by SAS if your deployment supports the use of more
than one.

You will need to decide a service name for each server (for example
'foopostgres') and create a secret with the database role/password and a
configMap with the connection information. The secret name must follow the
convention `{{ SERVICE_NAME }}-sas-user`. The configMap must follow the
convention `sas-{{ SERVICE_NAME }}-config`. For example: `foopostgres-sas-user`
and `sas-foopostgres-config`.

You must have at least one PostgreSQL server to serve as the "default"
PostgreSQL. This default service must be named 'postgres'. Therefore,
the `postgres-sas-user` secret and `sas-postgres-config` configMap must be
definied at a minimium.

Lastly, each additional PostgreSQL provided beyond the default 'postgres'
service must be added to the DATASERVER_LIST variable as a space-seperated
list in the `sas-postgres-config` ConfigMap.

To see an example of a completed base kustomization.yaml file for multiple
external PostgreSQL instances, see
`$deploy/sas-bases/examples/configure-postgres/multiple-external-kustomization.yaml` 

## Build

After you revise the base kustomization.yaml file, continue your SAS Viya
deployment as documented in
[SAS Viya Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm&locale=en).

## Additional Resources

For more information about the difference between the internal and external
instances of PostgreSQL, see
[SAS Infrastructure Data Server Requirements](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=itopssr&docsetTarget=n1rbbuql9epqa0n1pg3bvfx3dmvc.htm).

## Changelog

### 2020.0.3

****************************************************************************

                           Deprecation Statement

****************************************************************************

Effective in 2020.0.3 the following changes go into effect:

* *postgres-config* ConfigMap name changed to *sas-postgres-config*.

* *sas-postgres-config* modifies an existing ConfigMap. You must add the line
  `behavior: merge` to *sas-postgres-config* configMapGenerator in the base
  *kustomization.yaml* file.

* The configMapGenerator for *sas-shared-config* in the base
  *kustomization.yaml* file is no longer required and should be removed.

* In the *sas-postgres-config* ConfigMap, must modify the base
  *kustomization.yaml* to include `SAS_DATABASE_DATABASESERVERNAME="postgres"`.

Support has been added for these changes in the 2020.0.2 cadence.  Please make
the edits to your base kustomization.yml file prior to taking the 2020.0.3 or
later cadence.  Failure to do so may result in unintended results in your
environment up to and including that it may no longer work.

****************************************************************************

                        End of Deprecation Statement

****************************************************************************
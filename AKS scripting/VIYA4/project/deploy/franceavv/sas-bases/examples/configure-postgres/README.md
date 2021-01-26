---
category: dataServer
tocprty: 1
---

# Configure PostgreSQL

## Overview

By default, SAS Viya will not add a PostgreSQL instance to the Kubernetes
deployment. This is because SAS Viya provides two options for your
PostgreSQL server: an internal instance provided by SAS or an external
PostgreSQL that you would like SAS to utilize. So, before deploying you 
must select which of these options you would like to use for your
SAS Viya deployment.

## Internal PostgreSQL

If you want for SAS to create a PostgreSQL instance for you,
apply the `interal-postgres` overlays. To do so, refer to the
`$deploy/sas-bases/overlays/internal-postgres/README.md` file for the 
actions you need to take.

## External PostgreSQL

If you want SAS to use an external PostgreSQL provided and managed
by you, apply the `external-postgres` overlay. To do so, refer to the
`$deploy/sas-bases/overlays/external-postgres/README.md` file for the actions 
you need to take.
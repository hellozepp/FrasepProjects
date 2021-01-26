---
category: cas
tocprty: priority 12
---

# Auto Resources for CAS Server for SAS Viya

## Overview

This directory contains files to Kustomize your SAS Viya deployment to enable automatic resource 
limit allocation.

## Instructions

### Edit the kustomization.yaml File

In order to add this CAS server to your deployment, perform both of the following steps.

First, add a reference to the `auto-resources` overlay to the resources block of the base 
kustomization.yaml file (`$deploy/kustomization.yaml`).  This enables the ClusterRole and ClusterRoleBinding for the sas-cas-operator Service Account.

```yaml
resources:
...
- sas-bases/overlays/cas-server/auto-resources
```

Next, add the transformer to remove any hardcoded resource requests for cpu and memory from your CAS deployment. This allows the resources to be auto-calculated.

```yaml
transformers:
...
- sas-bases/overlays/cas-server/auto-resources/remove-resources.yaml
```

## Build

After you configure Kustomize, continue your SAS Viya deployment as documented.

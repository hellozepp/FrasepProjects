---
category: SAS Event Stream Processing
tocprty: 4
---

# Configuring a PersistentVolumeClaim for SAS Viya and SAS Event Stream Manager

## Overview

To configure SAS Event Stream Manager to apply a PersistentVolumeClaim (PVC) 
when deploying an ESP project in conjunction with the ESP operator, 
an environment variable must be set with the name of the PVC. The PVC is 
created by SAS Event Stream Processing Studio.

The transformer adds the following environment variable:

SAS_ESP_COMMON_KUBERNETES_DEFAULTS_PERSISTENTVOLUMECLAIM

The environment variable has the following value:

sas-event-stream-processing-studio-app

## Prerequisites

You must create the sas-event-stream-processing-studio-app PVC by applying 
the configuration that can be found in the following location:

$deploy/sas-bases/examples/sas-event-stream-processing-studio-app/pvc

## Installation

In the base kustomization.yaml file in the $deploy directory, add 
sas-bases/overlays/sas-event-stream-manager-app/pvc/pvc-transformer.yaml to the 
transformers block. The reference should look like this:

```
...
transformers:
...
- sas-bases/overlays/sas-event-stream-manager-app/pvc/pvc-transformer.yaml
...
```

After the base kustomization.yaml file is modified, deploy the software using 
the commands described in [SAS Viya Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).
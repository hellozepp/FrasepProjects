---
category: SAS Event Stream Processing
tocprty: 5
---

# Configuring an Analytic Store for SAS Viya and SAS Event Stream Processing Studio

## Overview

To configure SAS Event Stream Processing Studio to use analytic store (ASTORE) 
files inside the container, a volume mount with a PersistentVolumeClaim (PVC) 
of sas-microanalytic-score-astores is required in the deployment.

The PVC is created by the SAS Micro Analytic Service Analytic Store 
Configuration for the sas-microanalytic-score service and is mounted to the 
/models/astores/viya directory.

## Prerequisites

You must apply the configuration to create the SAS Micro Analytic Service 
Analytic Store PVC to be used as the SAS Micro Analytic Service ASTORE file 
repository.

## Installation

In the base kustomization.yaml file in the $deploy directory, add 
sas-bases/overlays/sas-event-stream-processing-studio-app/astores/astores-transformer.yaml 
to the transformers block. The reference should look like this:

```
...
transformers:
...
- sas-bases/overlays/sas-event-stream-processing-studio-app/astores/astores-transformer.yaml
...
```

After the base kustomization.yaml file is modified, deploy the software using 
the commands described in [SAS Viya Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).
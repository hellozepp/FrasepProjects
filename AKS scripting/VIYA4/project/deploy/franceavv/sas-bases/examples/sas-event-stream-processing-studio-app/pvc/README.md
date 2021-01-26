---
category: SAS Event Stream Processing
tocprty: 3
---

# Configuring a PersistentVolumeClaim for SAS Viya and SAS Event Stream Processing Studio

## Overview

To configure SAS Event Stream Processing Studio to apply a PersistentVolumeClaim (PVC) 
when deploying ESP projects with the ESP operator, two modifications are made. A new 
PVC is created and an environment variable is set with the name of that PVC.

The PVC is named sas-event-stream-processing-studio-app. The transformer adds the following environment variable:

SAS_ESP_COMMON_KUBERNETES_DEFAULTS_PERSISTENTVOLUMECLAIM

After the PVC and the environment variable are configured, new containers that are created when a project is deployed mount the /mnt/data directory.

## Prerequisites

* The storage must support ReadWriteMany access.
* Determine the STORAGE-CAPACITY required for input and output streaming data files, 
analytical models, and any other external files required by SAS Event Stream Processing.
* Make a note of the STORAGE-CLASS-NAME from the provider.

# Installation

1. Copy the files in `$deploy/sas-bases/examples/sas-event-stream-processing-studio-app/pvc` directory to the `$deploy/site-config/sas-event-stream-processing-studio-app/pvc` directory. Create the destination directory if it does not exist.

2. The resources.yaml file in the `$deploy/site-config/sas-event-stream-processing-studio-app/pvc` directory has the parameters of the storage required in the PeristentVolumeClaim.
   * Replace {{ STORAGE-CAPACITY }} with the amount of storage required.
   * Replace {{ STORAGE-CLASS-NAME }} with the appropriate storage class from the cloud provider that supports the ReadWriteMany access mode.

3. Make the following changes to the base kustomization.yaml file in the $deploy directory.
   * Add site-config/sas-event-stream-processing-studio-app/pvc/resources.yaml to the resources block.
   * Add sas-bases/overlays/sas-event-stream-processing-studio-app/pvc/pvc-transformer.yaml to the transformers block.
   The references should look like this:

   ```
   ...
   resources:
   ...
   - site-config/sas-event-stream-processing-studio-app/pvc/resources.yaml
   ...
   transformers:
   ...
   - sas-bases/overlays/sas-event-stream-processing-studio-app/pvc/pvc-transformer.yaml
   ...
   ```

After the base kustomization.yaml file is modified, deploy the software using 
the commands described in [SAS Viya Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).
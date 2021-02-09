---
category: SAS Visual Text Analytics
tocprty: 1
---

# Configure the Sentiment Scoring API for SAS Visual Text Analytics

## Overview

This directory contains files to customize your SAS Viya deployment to enable the sentiment scoring service API. You should include this service if you previously used the public sentiment scoring API for any custom sentiment modeling. This service is no longer used by SAS Visual Text Analytics and is completely optional.

## Installation

### Edit the kustomization.yaml File

In order to add this service to your deployment, add a reference to the `sas-text-sentiment` overlay
to the resources block of the base kustomization.yaml file (`$deploy/kustomization.yaml`).

```yaml
resources:
...
- sas-bases/overlays/sas-text-sentiment
```


### Build
After you configure Kustomize, continue your SAS Viya deployment as documented in the [SAS Viya Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).
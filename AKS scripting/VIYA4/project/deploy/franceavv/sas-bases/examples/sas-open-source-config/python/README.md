---
category: openSourceConfiguration
tocprty: 1
---

# Configure Python for SAS Viya

## Overview

SAS Viya can use a customer-prepared environment consisting of a Python installation and any required packages stored on a Kubernetes Persistent Volume. 
This README describes how to make that volume available to your deployment.

## Prerequisites

SAS Viya provides YAML files that the Kustomize tool uses to configure Python. Before you use those files, you must perform the following tasks:

1. Make note of the attributes for the volume where Python and the associated packages are to be deployed. For example, note the server and directory for NFS. 
   For more information about various types of persistent volumes in Kubernetes, see [Additional Resources](#additional-resources).
  
2. Install Python and any necessary packages on the volume.

3. In addition to the volume attributes, you must have the following information:

   * {{ PYTHON-EXECUTABLE }} - the name of the Python executable file (for example, python or python3.8)
   * {{ PYTHON-EXE-DIR }} - the directory (relative to the mount) containing the executable (for example, /bin)
   * {{ SAS-EXTLANG-SETTINGS-XML-FILE }} - configuration file for enabling Python and R integration in CAS. This is only required if you are using Python with CMP or the EXTLANG package.
   * {{ SAS-EXT-LLP-PYTHON-PATH }} - list of directories to look for when searching for run-time shared libraries (similar to LD_LIBRARY_PATH)

## Installation

1. Copy the files in the `$deploy/sas-bases/examples/sas-open-source-config/python` directory to the `$deploy/site-config/sas-open-source-config/python` directory. 
   Create the destination directory, if it does not already exist.

   **Note:** If the destination directory already exists, [verify that the overlay](#verify-overlay-for-python-volume) has been applied.
   If the output contains the `/python` mount directory path, you do not need to take any further actions, unless you want to change the overlay parameters to use a different Python environment.

2. The kustomization.yaml file defines all the necessary environment variables. Replace all tags, such as {{ PYTHON-EXE-DIR }}, with the values that you gathered in the [Prerequisites](#prerequisites) step. 
   Then, set the following parameters, according to the SAS products you will be using:

   * MAS_PYPATH and MAS_M2PATH are used by SAS Micro Analytic Service.
   * DM_PYPATH is used by the Open Source Code node in SAS Visual Data Mining and Machine Learning. You can add DM_PYPATH2, DM_PYPATH3, DM_PYPATH4 and DM_PYPATH5 if you need to specify multiple Python environments. 
     The Open Source Code node allows you to choose which of these five environment variables to use during execution.
   * SAS_EXTLANG_SETTINGS is used by applications that run Python and R code on Cloud Analytic Services (CAS). This includes PROC FCMP and the Time Series External Languages (EXTLANG) package. 
     SAS_EXTLANG_SETTINGS should only be set in one example file; for example, if you set it in the Python example, you should not set it the R example.
     SAS_EXTLANG_SETTINGS should point to an XML file that is readable by all users. The path can be in the same volume that contains the R environment or in any other volume that is accessible to CAS. 
     Refer to the documentation for the Time Series External Languages (EXTLANG) package for details on the expected XML schema.
   * SAS_EXT_LLP_PYTHON is used when the base distribution or packages for open-source software require additional run-time libraries that are not part of the shipped container image.

   **Note:** Any environment variables that you define in this example will be set on all pods, although they might not have an effect. 
   For example, setting MAS_PYPATH will not affect the Python executable used by the EXTLANG package. That executable is set in the SAS_EXTLANG_SETTINGS file. 
   However, if you define $MAS_PYPATH you can then use it in the SAS_EXTLANG_SETTINGS file. For example,

   ```<LANGUAGE name="PYTHON3" interpreter="$MAS_PYPATH"></LANGUAGE>```

3. Attach storage to your SAS Viya deployment. The python-transformer.yaml file uses PatchTransformers in Kustomize to attach the volume containing your Python installation to SAS Viya.
   Replace {{ VOLUME-ATTRIBUTES }} with the appropriate volume specification.
   
   For example, when using an NFS mount, the {{ VOLUME-ATTRIBUTES }} tag should be replaced with `nfs: {path: /vol/python, server: myserver.sas.com}` 
   where `myserver.sas.com` is the NFS server and `/vol/python` is the NFS path you recorded in the Prerequisites step.

   The relevant code excerpt from python-transformer.yaml file before the change:

   ```yaml
   patch: |-
    # Add Python Volume
     - op: add
       path: /spec/template/spec/volumes/-
       value: { name: python-volume, {{ VOLUME-ATTRIBUTES }} }
   ```

   The relevant code excerpt from python-transformer.yaml file after the change:

   ```yaml
   patch: |-
   # Add Python Volume
     - op: add
       path: /spec/template/spec/volumes/-
       value: { name: python-volume, nfs: {path: /vol/python, server: myserver.sas.com} }
   ```

4. Make the following changes to the base kustomization.yaml file in the $deploy directory.

   * Add site-config/sas-open-source-config/python to the resources block.
   * Add site-config/sas-open-source-config/python/python-transformer.yaml to the transformers block.

   Here is an example:

   ```yaml
   resources:
   - site-config/sas-open-source-config/python

   transformers:
   - site-config/sas-open-source-config/python/python-transformer.yaml
   ```

5. Complete the deployment steps to apply the new settings. See [Deploy the Software](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm) in _SAS Viya: Deployment Guide_.

    **Note:** This overlay can be applied during the initial deployment of SAS Viya or after the deployment of SAS Viya.
    
    * If you are applying the overlay during the initial deployment of SAS Viya, complete all the tasks in the README files that you want to use, then run `kustomize build` to create and apply the manifests.
    * If the overlay is applied after the initial deployment of SAS Viya, run `kustomize build` to create and apply the manifests.

## Verify Overlay for Python Volume

1. Run the following command to verify whether the overlay has been applied:

   ```sh
   kubectl describe pod  <sas-microanalyticscore-pod-name> -n <name-of-namespace>
   ```

2. Verify that the output contains the following mount directory paths:

   ```yaml
   Mounts:
     /python (r)
   ```

## Additional Resources

* [SAS Viya Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm)
* [Persistent Volumes in Kubernetes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
* [Volume Types in Kubernetes](https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes)
* [External Languages Access Control Configuration](http://documentation.sas.com/?cdcId=pgmsascdc&cdcVersion=default&docsetId=castsp&docsetTarget=castsp_extlang_sect002.htm) in _SAS Viya Programming Documentation_
* [Configuring SAS Micro Analytic Service to Use a Python Distribution](http://documentation.sas.com/?cdcId=mascdc&cdcVersion=default&docsetId=masag&docsetTarget=n149q46z3dnttzn1v4tt2adb1ebc.htm) in _SAS Micro Analytic Service: Programming and Administration Guide_
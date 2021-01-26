---
category: security
tocprty: 8
---

# Configuring Single Sign-On for Automatic Redirects

This README describes the steps to configure your SAS Viya deployment to automatically
redirect sign-ins to an external identity provider you have already configured for single sign-on.

## Prerequisites

You must configure SAS Viya for single sign-on with an external SAML or OIDC provider using the
steps described in the SAS Viya Administration guide. Make sure you have tested single sign-on
before proceeding with this installation.

**Note:** If you use the default transformer provided in this example, you cannot sign in as sasboot unless you manually go to `/SASLogon/login`.

## Installation

1. Copy the files in the `$deploy/sas-bases/examples/sas-logon-app` directory to the `$deploy/site-config/sas-logon-app` directory. Create the target directory, if it does not already exist.

2. Modify the snippet in `$deploy/site-config/sas-logon-app/login-hint-transformer.yaml`.

   * For example, you can replace example.com with an email address domain matching one configured for the external identity provider.
   * Add any additional clauses to the NGINX snippet configuration as desired. For example you can preclude the login_hint parameter from certain requests.
   * Only one server-snippet is allowed per host. Make sure this transformer includes any existing server-snippet. You can view the existing server-snippet using the following command:

   ```
   kubectl get ingress -o yaml sas-logon-app | grep nginx.ingress.kubernetes.io/server-snippet
   ```

3. Add site-config/sas-logon-app/login-hint-transformer.yaml to the transformers block of the base kustomization.yaml file in the $deploy directory.

4. Use the deployment commands described in [SAS Viya Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm) to apply the new settings.
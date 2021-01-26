---
category: security
tocprty: 10
---

# Configuring Ingress for Cross-Site Cookies

## Overview

When you configure SAS Viya to enable cross-site cookies via the `sas.commons.web.security.cookies.sameSite` configuration property, you must also update the Ingress configuration so that cookies managed by the Ingress controller have the same settings. Ingress annotations for same-site cookie settings are applied by adding the transformer overlay to your kustomization.yaml.

## Installation

Add the Ingress cookie same-site transformer overlay to the transformers block of the base kustomization.yaml in the $deploy directory.

```yaml
transformers:
...
- sas-bases/overlays/network/ingress/security/transformers/sas-ingress-cookie-samesite-transformer.yaml
```

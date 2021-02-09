---
category: kubernetesTools
tocprty: 4
---

# Lifecycle Operation: Deploy

## Overview

The `deploy` lifecycle operation runs the recommended sequence of
`kubectl apply` commands necessary to deploy the software.

For general lifecycle operation execution details, please
see the README file at `$deploy/sas-bases/examples/kubernetes-tools/README.md` (for Markdown)
or `$deploy/sas-bases/docs/using_kubernetes_tools_from_the_sas-orchestration_image.htm` (for HTML).

## Example

The following example assumes:

* A site.yaml exists in /deploy
* A kubeconfig file exists in /home/user/kubernetes
* The orchestration image has been pulled and has the local tag 'sas-orch'
* Downloaded deployment assets exist in /deploy/sas-bases

```
docker run --rm \
  -v /deploy:/deploy \
  -v /home/user/kubernetes:/kubernetes \
  -e "KUBECONFIG=/kubernetes/config" \
  sas-orch \
  lifecycle run \
    --operation deploy \
    --deployment-dir /deploy/sas-bases \
    -- \
    --manifest /deploy/site.yaml \
    --namespace default
```

**Note:** To see the commands that would be executed from the operation without
making any changes to the cluster, add `-e "DISABLE_APPLY=true"` to the container.

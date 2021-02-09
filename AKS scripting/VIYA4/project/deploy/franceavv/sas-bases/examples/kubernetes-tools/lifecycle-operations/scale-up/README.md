---
category: kubernetesTools
tocprty: 4
---

# Lifecycle Operation: Scale-up

## Overview

The `scale-up` lifecycle operation runs the recommended sequence of `kubectl
apply` commands necessary to restore the software to a running state after a
previous `scale-to-zero` lifecycle operation.

For general lifecycle operation execution details, please see the README file at
`$deploy/sas-bases/examples/kubernetes-tools/README.md` (for Markdown) or
`$deploy/sas-bases/docs/using_kubernetes_tools_from_the_sas-orchestration_image.htm`
(for HTML).

## Example

### Local Execution
The `scale-up` operation can be run locally (outside the cluster) using the
following command. The command looks up the definition of the `scale-up`
operation in the namespace specified in the first `--namespace` argument and
then performs the operation on the namespace specified in the second
`--namespace` argument. The following example assumes:

* A kubeconfig file exists in `/home/user/kubernetes`
* The orchestration image has been pulled and has the local tag `sas-orch`
* The software to be scaled has been deployed into the namespace `default`

Here is the command:

```
docker run --rm \
  -v /home/user/kubernetes:/kubernetes \
  -e "KUBECONFIG=/kubernetes/config" \
  sas-orch \
  lifecycle run \
    --operation scale-up \
    --namespace default \
    -- \
    --namespace default
```

**Note:** To see the commands that would be executed from the operation without
making any changes to the cluster, add `-e "DISABLE_APPLY=true"` to the container.

### Remote Execution
The `scale-up` operation can be run remotely (inside the cluster) using the
following script. The script looks up the appropriate image and imagePullSecret
and then creates the Kubernetes resources necessary to run the `scale-up`
operation as described in the `Local Execution` example above using a Kubernetes
`Job` to provide the execution. The following example assumes:

* The software to be scaled has been deployed into the namespace `default`
* These kubernetes resources are to be deployed into the same namespace as the
  software to be scaled

Here is the script:

```bash
#!/bin/bash

namespace=default
image=$(kubectl -n ${namespace}  get configmap --selector "orchestration.sas.com/lifecycle=image" -o jsonpath="{.items[0].data.image}" 2> /dev/null )
secretName=$(kubectl -n ${namespace} get secrets | awk '/sas-image-pull-secrets/ {print $1}')

kubectl -n ${namespace} apply -f - <<EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sas-lifecycle
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: sas-lifecycle
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  verbs:
  - get
- apiGroups:
  - ""
  - apps
  - batch
  - crunchydata.com
  - viya.sas.com
  resources:
  - casdeployments
  - configmaps
  - cronjobs
  - daemonsets
  - deployments
  - deployments/scale
  - pgclusters
  - pods
  - statefulsets
  - statefulsets/scale
  verbs:
  - get
  - list
  - patch
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sas-lifecycle
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: sas-lifecycle
subjects:
  - kind: ServiceAccount
    name: sas-lifecycle
---
apiVersion: batch/v1
kind: Job
metadata:
  name: scale-up-$(date +%s)
spec:
  template:
    spec:
      serviceAccountName: sas-lifecycle
      imagePullSecrets:
      - name: ${secretName}
      containers:
      - env:
        - name: DISABLE_APPLY
          value: "false"
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        name: scale-up
        image: ${image}
        command:
        - orchestration
        - lifecycle
        - run
        - --operation
        - scale-up
        - --namespace
        - \$(NAMESPACE)
        - --
        - --namespace
        - \$(NAMESPACE)
      restartPolicy: Never
  backoffLimit: 0
EOF
```

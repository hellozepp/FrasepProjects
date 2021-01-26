---
category: dataServer
tocprty: 32
---

# Granting Security Context Constraints on an OpenShift Cluster

The `/$deploy/sas-bases/examples/crunchydata/openshift` directory contains a file to 
grant Security Context Constraints for fsgroup 26 on an OpenShift cluster. A
Kubernetes cluster administrator should add these Security Context Constraints 
to their OpenShift cluster prior to deploying SAS Viya 4. Use one of the 
following commands:

```yaml
kubectl apply -f pgo-scc.yaml
```

or

```yaml
oc create -f pgo-scc.yaml
```
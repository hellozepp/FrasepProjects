---
category: kubernetesTools
tocprty: 1
---

# Using Kubernetes Tools from the sas-orchestration Image

## Overview

The sas-orchestration image includes several tools that help
deploy and manage the software. It includes a `lifecycle` command
that can run various lifecycle operations as well as the recommended
versions of both `kustomize` and `kubectl`. These latter tools may
be used with docker's `--entrypoint` option.

Note: The examples use Docker, but other container engines can be used that adhere to the OCI runtime specification.

Note: All examples below are auto-generated based on your order.

## Prerequisites

To run the sas-orchestration image, Docker must be installed.

Log in to the `cr.sas.com` Docker Registry, and retrieve the `sas-orchestration` image:

```
cat sas-bases/examples/kubernetes-tools/password.txt | docker login cr.sas.com --username '09V53F' --password-stdin
docker pull cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration:1.26.0-20201214.1607963475562
```

After pulling the sas-orchestration image, there is no need to stay logged in to the Docker Registry. To log out:

```
docker logout cr.sas.com
```


Replace 'cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration:1.26.0-20201214.1607963475562' with a local tag for ease of use in the examples that will follow:

```
docker tag cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration:1.26.0-20201214.1607963475562 sas-orch
```

## Examples

### lifecycle

The `lifecycle` command executes deployment-wide operations over the assets deployed from an order.
See the README file at `$deploy/sas-bases/examples/kubernetes-tools/README.md` (for Markdown)
or `$deploy/sas-bases/docs/using_kubernetes_tools_from_the_sas-orchestration_image.htm` (for HTML) for
lifecycle operation documentation.

Docker uses the following options:

* `-v` to mount the directories
* `-w` to define the working directory
* `-e` to define the needed environment variables

#### lifecycle list

The `list` sub-command displays the available operations of a deployment

##### `lifecycle list` example

```
docker run --rm \
  -v /deploy:/deploy \
  -w /deploy \
  sas-orch \
  lifecycle list --namespace a_namespace
```

#### lifecycle run

The `run` sub-command runs a given operation.
Arguments before `--` indicate the operation to run and how lifecycle should locate the operation's
definition. Arguments after `--` apply to the operation itself, and may vary between operations.

##### `lifecycle run` example

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

As indicated in the example, the `run` sub-command needs an operation (`--operation`) and the location of your assets (--deployment-dir).
The `deploy` lifecycle operation needs a manifest (`--manifest`) and the Kubernetes namespace to deploy
into, (`--namespace`). To connect and deploy into the Kubernetes cluster, the KUBECONFIG environment variable
is set on the container; (`-e`).

### kustomize

Use the `-v` option to mount the $deploy directory into the container,
with `-v <directory name>:/deploy`, and use `-w` to set the mounted /deploy
as the working directory. The following example assumes the $deploy
directory, with a kustomization.yaml and supporting files, is at /deploy.
Note that the `kustomize` call here is a simple example. Refer to the
deployment documentation for full usage details.

```
docker run --rm \
  -v /deploy:/deploy \
  -w /deploy \
  --entrypoint kustomize \
  sas-orch \
  build . > site.yaml
```

### kubectl

The following example assumes a site.yaml exists in /deploy,
and a kubeconfig file exists in /home/user/kubernetes. Use `-v`
to mount the directories, and `-w` to use /deploy as the working
directory. Note that the `kubectl` call here is a simple example.
Refer to the deployment documentation for full usage details.

```
docker run --rm \
  -v /deploy:/deploy \
  -v /home/user/kubernetes:/kubernetes \
  -w /deploy \
  --entrypoint kubectl \
  sas-orch \
  --kubeconfig=/kubernetes/kubeconfig apply -f site.yaml
```

## Additional Resources

* https://docs.docker.com/get-docker/
* https://kustomize.io/
* https://kubectl.docs.kubernetes.io/
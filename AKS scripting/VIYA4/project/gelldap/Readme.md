![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# GELLDAP documentation

## Disclaimer

```bash
####################################################################
#### DISCLAIMER                                                 ####
####################################################################
#### These files are provided as-is, without                    ####
#### warranty of any kind, either express or implied,           ####
#### including, but not limited to, the implied warranties      ####
#### of merchantability, fitness for a particular purpose, or   ####
#### non-infringement.                                          ####
#### SAS Institute shall not be liable whatsoever for any       ####
#### damages arising out of the use of this documentation and   ####
#### code, including any direct, indirect, or consequential     ####
#### damages. SAS Institute reserves the right to alter or      ####
#### abandon use of this documentation and code at any time.    ####
#### In addition, SAS Institute will provide no support for the ####
#### materials contained herein.                                ####
####################################################################
```

* [Disclaimer](#disclaimer)
* [GELLDAP Introduction](#gelldap-introduction)
* [GELMAIL Introduction](#gelmail-introduction)
* [Description](#description)
* [Requirements](#requirements)
  * [Kustomize](#kustomize)
  * [cert-manager](#cert-manager)
* [Assumptions](#assumptions)
* [Obtaining the GELLDAP Project](#obtaining-the-gelldap-project)
* [**NO** TLS](#no-tls)
  * [Creating a testing namespace](#creating-a-testing-namespace)
  * [Deploy GELLDAP **without** TLS](#deploy-gelldap-without-tls)
* [**YES** TLS](#yes-tls)
  * [Creating a testing namespace for TLS](#creating-a-testing-namespace-for-tls)
  * [Generating certificates](#generating-certificates)
  * [Deploy GELLDAP **with** TLS](#deploy-gelldap-with-tls)
* [Validate GELLDAP](#validate-gelldap)
* [LDAP details](#ldap-details)
  * [Host/port (no_TLS)](#hostport-no_tls)
  * [Host/port (yes_TLS)](#hostport-yes_tls)
  * [Users, Groups, Passwords](#users-groups-passwords)
  * [Accessing the LDAP (with Apache Directory Studio)](#accessing-the-ldap-with-apache-directory-studio)

## GELLDAP Introduction

GELLDAP is a standalone OpenLDAP server, running inside a Kubernetes Pod, with a set of pre-loaded users and groups. It is the LDAP server used in many of the GEL workshops and environments.  You have the choice to run with either secured LDAP (with startTLS or LDAPS) or unsecured LDAP.

## GELMAIL Introduction

GELMAIL is bundled with GELLDAP. For more information on it, read the specific [Readme](bases/gelmail/Readme.md).

## Description

The **GELLDAP** project  is made up of:

* a set of Kubernetes manifest files that describes
  * an OpenLDAP server in a pod, pre-loaded with a  set of known users and groups
  * a MailHog Server in a pod, ready to receive e-mails
* a matching sitedefault.yaml file
* a matching sssd.conf file, defined as a K8S configmap

When used together, these files allow you to quickly setup a simple OpenLDAP server, in the same namespace as Viya, and get Viya connected to it, with minimal efforts.

## Requirements

### Kustomize

In order to assemble the template files into a meaningful set of manifest files, you will have to use Kustomize.

### cert-manager

For a **secured** OpenLDAP, you require cert-manager, which will be used to generate and sign the TLS server certificate used by **GELLDAP**.  The instructions below will setup the required Certificate Authority and issuer.  You are responsible for ensuring the TLS server certificate used by **GELLDAP** is correctly trusted by your SAS Viya environments.

## Assumptions

* We will assume that you will want to deploy the **GELLDAP** in a namespace called "gelldap".
* This is true for testing.
* However, GELLDAP will work best if you place it in the same namespace as Viya itself, so once you get the hang of it:
  * delete the gelldap namespace
  * follow these instructions again and update the namespace

## Obtaining the GELLDAP Project

1. Clone the project into your home directory:

    ```bash
    cd ~
    git clone https://gelgitlab.race.sas.com/GEL/utilities/gelldap.git
    cd ~/gelldap/
    git fetch --all ; git reset --hard origin/master

    ```

## **NO** TLS

If you are not interested in securing the connection to LDAP with TLS, this is the option for you.

### Creating a testing namespace

So we will store this namespace value in a variable. (Update as needed)

```bash
NS=gelldap
echo "chosen namespace is: ${NS}"
```

Creating the namespace (if it does not already exist) can be done as follows:

```bash
if kubectl get ns | grep -q "${NS}"
then
    echo "Namespace ${NS} already exists"
else
    echo "Creating Namespace ${NS}"
    kubectl create ns ${NS}
fi

```

### Deploy GELLDAP **without** TLS

1. Navigate to the `GELLDAP` folder:

    ```bash
    cd ~/gelldap/
    ```

1. If you want to see of preview of the generated manifest, execute:

    ```bash

    kustomize build ./no_TLS/
    ```

1. If you are ready to deploy GELLDAP, execute:

    ```bash
    kustomize build ./no_TLS/ | kubectl -n ${NS} apply -f -
    ```

## **YES** TLS

### Creating a testing namespace for TLS

So we will store this namespace value in a variable. (Update as needed)

```bash
NS=gelldaps
echo "chosen namespace is: ${NS}"
```

Creating the namespace (if it does not already exist) can be done as follows:

```bash
if kubectl get ns | grep -q "${NS}"
then
    echo "Namespace ${NS} already exists"
else
    echo "Creating Namespace ${NS}"
    kubectl create ns ${NS}
fi

```

### Generating certificates

1. Use OpenSSL to create a Certificate Authority private key and public certificate

    ```bash
    cd ~/gelldap/
    openssl genrsa -aes256 -passout pass:lnxsas -out ~/gelldap/cluster_ca_key.pem 2048
    openssl req -new -x509 -sha256 -days 3650 -extensions v3_ca -subj "/C=US/ST=North Carolina/L=Cary/O=SAS/OU=GEL/CN=GEL Viya 2020 Root CA/emailAddress=noreply@none.sas.com" -key ~/gelldap/cluster_ca_key.pem -out ~/gelldap/cluster_ca_cert.pem -passin pass:lnxsas
    openssl rsa -in cluster_ca_key.pem -out cluster_ca_clear_key.pem -passin pass:lnxsas
    ```

1. Create the YAML file to define your cred-manager CA and issuer

    ```bash
    export BASE64_CERT=`cat ~/gelldap/cluster_ca_cert.pem|base64|tr -d '\n'`
    export BASE64_KEY=`cat ~/gelldap/cluster_ca_clear_key.pem|base64|tr -d '\n'`

    tee > ~/gelldap/yes_TLS/cert-manager-ca.yml  <<-EOF
    apiVersion: v1
    kind: Secret
    metadata:
      name: sas-viya-ca-certificate-secret
    data:
      tls.crt: $BASE64_CERT
      tls.key: $BASE64_KEY
    ---
    apiVersion: cert-manager.io/v1alpha2
    kind: Issuer
    metadata:
      name: sas-viya-issuer
    spec:
      ca:
        secretName: sas-viya-ca-certificate-secret
    EOF
    ```

1. Apply the cred-manager-ca.yml file to create the K8S objects

    ```bash
    kubectl -n ${NS} apply -f ~/gelldap/yes_TLS/cert-manager-ca.yml
    ```

1. Confirm the output looks like:

    ```bash
    kubectl -n ${NS} get issuers sas-viya-issuer -o wide
    ```

    should return:

    ```log
    NAME              READY   STATUS                AGE
    sas-viya-issuer   True    Signing CA verified   112m
    ```

### Deploy GELLDAP **with** TLS

1. Navigate to the `GELLDAP` folder:

    ```bash
    cd ~/gelldap/
    ```

1. If you want to see of preview of the generated manifest, execute:

    ```bash

    kustomize build ./yes_TLS/
    ```

1. If you are ready to deploy GELLDAP, execute:

    ```bash
    kustomize build ./yes_TLS/ | kubectl -n ${NS} apply -f -
    ```

## Validate GELLDAP

Regardless of which method you followed, validate that things work:

1. Confirm that the output looks like:

    ```bash
    kubectl -n ${NS} get pods,cm,svc,deployments -l app.kubernetes.io/part-of=gelldap
    ```

    should return:

    ```log
    NAME                                 READY   STATUS    RESTARTS   AGE
    pod/gelldap-server-c4d6f7cf6-ts9lp   1/1     Running   0          15m

    NAME                                 DATA   AGE
    configmap/gelldap-bootstrap-users    1      15m
    configmap/gelldap-memberof-overlay   1      15m

    NAME                      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)             AGE
    service/gelldap-service   ClusterIP   10.43.211.23   <none>        389/TCP,636/TCP     15m
    service/gelmail-service   ClusterIP   10.43.220.53   <none>        1025/TCP,8025/TCP   15m

    NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/gelldap-server   1/1     1            1           15m
    ```

1. Confirm that the kubernetes service is listening on port 389 (both with and without TLS):

    ```bash
    # first, get the service IP:
    kubectl -n ${NS} get svc -l app.kubernetes.io/part-of=gelldap,app=gelldap-service -o=custom-columns='IP:spec.clusterIP' --no-headers
    # store it in a variable:
    IP_GELLDAP=$(kubectl -n ${NS} get svc -l app.kubernetes.io/part-of=gelldap,app=gelldap-service -o=custom-columns='IP:spec.clusterIP' --no-headers)
    # now curl it:
    curl -v ${IP_GELLDAP}:389
    ```

    You should see:

    ```log
    * About to connect() to 10.43.103.202 port 389 (#0)
    *   Trying 10.43.103.202...
    * Connected to 10.43.103.202 (10.43.103.202) port 389 (#0)
    > GET / HTTP/1.1
    > User-Agent: curl/7.29.0
    > Host: 10.43.103.202:389
    > Accept: */*
    >
    * Empty reply from server
    * Connection #0 to host 10.43.103.202 left intact
    curl: (52) Empty reply from server
    ```

1. Confirm that the kubernetes service is listening on port 636 (only if TLS):

    The same can be done with port 636:

    ```bash
    curl -v ${IP_GELLDAP}:636
    ```

    You should see:

    ```log
    * About to connect() to 10.43.233.144 port 636 (#0)
    *   Trying 10.43.233.144...
    * Connected to 10.43.233.144 (10.43.233.144) port 636 (#0)
    > GET / HTTP/1.1
    > User-Agent: curl/7.29.0
    > Host: 10.43.233.144:636
    > Accept: */*
    >
    * Empty reply from server
    * Connection #0 to host 10.43.233.144 left intact
    curl: (52) Empty reply from server
    ```

## LDAP details

### Host/port (no_TLS)

From any Viya pod, you should be able to reach the LDAP server in the same namespace:

* Host: `gelldap-service`
* Port: `389`
* User: `cn=admin,dc=gelldap,dc=com`
* Password: `lnxsas`

### Host/port (yes_TLS)

From any Viya pod, you should be able to reach the LDAP server in the same namespace using startTLS:

* Host: `gelldap-service`
* Port: `389`
* User: `cn=admin,dc=gelldap,dc=com`
* Password: `lnxsas`

From any Viya pod, you should be able to reach the LDAP server using LDAPS:

* Host: `gelldap-service`
* Port: `636`
* User: `cn=admin,dc=gelldap,dc=com`
* Password: `lnxsas`

### Users, Groups, Passwords

This section will link to the LDAP user/group structure [documentation](bases/gelldap/Users_and_groups.md).

### Accessing the LDAP (with Apache Directory Studio)

To start a port forward on port 1389 in order to reach the ldap service (listening on port 389), you can execute the following command.

```sh
kubectl --namespace ${NS} port-forward --address 0.0.0.0  svc/gelldap-service 1389:389
```

Then you can point your LDAP client to the machine on which `kubectl` is running.

To authenticate, you can use:

* host: `<hostname of kubectl command with port-forward>`
* user: `cn=admin,dc=gelldap,dc=com`
* pass: `lnxsas`

<!--
Cheatcode howto

```sh
cd ~
git clone https://gelgitlab.race.sas.com/GEL/utilities/gelldap.git
cd ~/gelldap/
git fetch --all ; git reset --hard origin/master
git fetch --all ; git reset --hard origin/split_up

# gen cheatcode
curl https://gelgitlab.race.sas.com/GEL/utilities/raceutils/-/raw/master/cheatcodes/create.cheatcodes.sh | bash -s .
# run it
bash -x /home/cloud-user/gelldap/Readme.sh
```
-->

---
category: SAS/ACCESS
tocprty: 1
---

# Configuring SAS/ACCESS and Data Connectors for SAS Viya 4

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  * [Attach Storage to SAS Viya](#attach-storage-to-sas-viya)
  * [Set Environment Variables](#set-environment-variables)
  * [Restart CAS Server](#restart-cas-server)
- [Database-Specific Configuration](#database-specific-configuration)
  * [Configuration for ODBC-based Connectors](#configuration-for-odbc-based-connectors)
  * [SAS/ACCESS Interface to Amazon Redshift](#sas-access-interface-to-amazon-redshift)
  * [SAS/ACCESS Interface to DB2](#sas-access-interface-to-db2)
  * [SAS/ACCESS Interface to Google BigQuery](#sas-access-interface-to-google-bigquery)
  * [SAS/ACCESS Interface to Greenplum](#sas-access-interface-to-greenplum)
    + [Bulk-Loading](#bulk-loading)
  * [SAS/ACCESS Interface to Hadoop](#sas-access-interface-to-hadoop)
  * [SAS/ACCESS Interface to Impala](#sas-access-interface-to-impala)
    + [Bulk-Loading](#bulk-loading-1)
  * [SAS/ACCESS Interface to JDBC](#sas-access-interface-to-jdbc)
  * [SAS/ACCESS Interface to MongoDB](#sas-access-interface-to-mongodb)
  * [SAS/ACCESS Interface to Microsoft SQL Server](#sas-access-interface-to-microsoft-sql-server)
    + [Connecting to Microsoft Azure SQL Database or Microsoft Azure Synapse](#connecting-to-microsoft-azure-sql-database-or-microsoft-azure-synapse)
    + [Bulk-Loading](#bulk-loading-2)
  * [SAS/ACCESS Interface to MySQL](#sas-access-interface-to-mysql)
  * [SAS/ACCESS Interface to Netezza](#sas-access-interface-to-netezza)
  * [SAS/ACCESS Interface to ODBC](#sas-access-interface-to-odbc)
  * [SAS/ACCESS Interface to Oracle](#sas-access-interface-to-oracle)
  * [SAS/ACCESS Interface to the PI System](#sas-access-interface-to-the-pi-system)
    + [SSL Certificate](#ssl-certificate)  
  * [SAS/ACCESS Interface to PostgreSQL](#sas-access-interface-to-postgresql)
  * [SAS/ACCESS Interface to R/3](#sas-access-interface-to-r-3)
  * [SAS/ACCESS Interface to Salesforce](#sas-access-interface-to-salesforce)
  * [SAS/ACCESS Interface to SAP ASE](#sas-access-interface-to-sap-ase)
    + [Installing SAP ASE Procedures](#installing-sap-ase-procedures)
  * [SAS/ACCESS Interface to SAP HANA](#sas-access-interface-to-sap-hana)
  * [SAS/ACCESS Interface to Snowflake](#sas-access-interface-to-snowflake)
  * [SAS/ACCESS Interface to Spark](#sas-access-interface-to-spark)
  * [SAS/ACCESS Interface to Teradata](#sas-access-interface-to-teradata)
  * [SAS/ACCESS Interface to Yellowbrick](#sas-access-interface-to-yellowbrick)
  * [SAS/ACCESS Interface to Vertica](#sas-access-interface-to-vertica)
- [Enabling Data Connector Ports](#enabling-data-connector-ports)
- [Enabling SAS Embedded Process Continuous Session (EPCS) Ports](#enabling-sas-embedded-process-continuous-session--epcs--ports)
- [Additional Resources](#additional-resources)

## Overview
This directory contains files to customize your SAS Viya 4 deployment for SAS/ACCESS 
and Data Connectors. Some SAS/ACCESS products require third-party libraries and 
configurations. This README describes the steps necessary to make these files 
available to your SAS Viya deployment. It also describes how to set required 
environment variables to point to these files. 

**Note:** If you re-configure SAS/ACCESS products after the initial deployment, you must restart the CAS server.

## Prerequisites
Before you start the deployment, collect the third-party libraries and 
configuration files that are required for your data sources. Examples of 
these requirements include the following:

* Third-party drivers
* ODBC drivers
* JDBC drivers
* Hadoop configuration files

When you have collected these files, place them on storage that is accessible to 
your Kubernetes deployment. This storage could be a mount or a storage device 
with a PersistentVolume (PV) configured.

SAS recommends organizing your software in a consistent manner on your mount 
storage device. The following is an example directory structure:
    

```text
          access-clients
          ├── hadoop
          │   ├── jars
          │   ├── config
          ├── odbc
          │   ├── sql7.0.1
          │   ├── gplm7.1.6
          │   ├── dd7.1.6
          ├── oracle
          ├── postgres
          └── teradata
```

Note the details of your specific storage solution, as well 
as the paths to the configuration files within it. You will need this information
before you start the deployment.

You should also create a subdirectory within `$deploy/site-config` to store your ACCESS configurations. In this documentation, we will refer to a user-created subdirectory called 
`$deploy/site-config/data-access`. For more information, refer to the ["Directory Structure" section of the "Pre-installation
Tasks" Deployment Guide](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=v_002&docsetId=dplyml0phy0dkr&docsetTarget=p1goxvcgpb7jxhn1n85ki73mdxc8.htm&locale=en).
    
## Installation

### Attach Storage to SAS Viya 
Use Kustomize PatchTransformers to attach the storage with your configuration files to SAS Viya. Within the `$deploy/sas-bases/examples/data-access` directory, there are three example files to help you with this process: `data-mounts-cas.sample.yaml`, `data-mounts-deployment.sample.yaml`, and `data-mounts-job.sample.yaml`.

Copy these three files into your `$deploy/site-config/data-access` directory, removing ".sample" from the file names and making changes to each file according to your storage choice. The information should be largely duplicated across the three files, but notice that the path reference in each file is different, as well as the Kubernetes resource type that it targets.
    
When you have created your PatchTransformers, add them to the transformers block 
in the base `kustomization.yaml` file located in your `$deploy` directory.
    
```yaml 
transformers:
...
- site-config/data-access/data-mounts-cas.yaml
- site-config/data-access/data-mounts-deployment.yaml
- site-config/data-access/data-mounts-job.yaml
```

### Set Environment Variables
Copy `$deploy/sas-bases/examples/data-access/sas-access.properties` into your `$deploy/site-config/data-access` directory. Edit the values in the $(VARIABLE) format as they pertain to your data source configuration, un-commenting them as needed. These paths refer to the volumeMount location of the storage you attached within the containers.
    
As an example, to configure an ODBC connection, the lines within sas-access.properties look like this:
    
```bash
# ODBCHOME=$(ODBCHOME)
# ODBCINI=$(ODBCINI)
# ODBCINST=$(ODBCINST)
```

They should be un-commented and edited to include values like this, where /access-clients is the volumeMount location defined in [Attach Storage to SAS Viya](#attach-storage-to-sas-viya):
    
```bash
ODBCHOME=/access-clients/odbc
ODBCINI=/access-clients/odbc/odbc.ini
ODBCINST=/access-clients/odbc/odbcinst.ini
```

Edit the base kustomization.yaml file in the `$deploy` directory to add the following content to the configMapGenerator block, replacing $(PROPERTIES_FILE) with the relative path to your new file within the $deploy/site-config directory. 

```yaml 
configMapGenerator:
...
- name: sas-access-config
  behavior: merge
  envs:
  - $(PROPERTIES_FILE)
```

For example,

```yaml 
configMapGenerator:
...
- name: sas-access-config
  behavior: merge
  envs:
  - site-config/data-access/sas-access.properties
``` 

Also add the following reference to the transformers block of the base kustomization.yaml file.
This path references a SAS file that you do not need to edit, and it will apply the environment
variables in `sas-access.properties` to the appropriate parts of your SAS Viya deployment.

```yaml
transformers:
- sas-bases/overlays/data-access/data-env.yaml
```

### Restart CAS Server
After the initial deployment of SAS Viya, if you make changes to your SAS/ACCESS configuration, you should restart the CAS server. This will refresh the CAS environment and enable any changes that you've made. 

IMPORTANT: Performing this task will cause the termination of all active connections and sessions and the loss of any in-memory data.

Set your KUBECONFIG and run the following command:

```bash
kubectl -n name-of-namespace delete pods -l app.kubernetes.io/managed-by=sas-cas-operator
```


You can now proceed with your deployment as described in [SAS Viya Deployment Guide](http://documentation.sas.com/?softwareId=mysas&softwareVersion=prod&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm). 

## Database-Specific Configuration

### Configuration for ODBC-based Connectors
Configuring ODBC connectivity to your database for SAS Viya requires some or all of the following environment variables to be set. Configure these variables using the `sas-access.properties` file within your `$site-config` directory.

```bash
ODBCINI=$(PATH_TO_ODBCINI)
ODBCINST=$(PATH_TO_ODBCINST)
THIRD_PARTY_LIB=$(ODBC_DRIVER_LIB)
THIRD_PARTY_BIN=$(ODBC_DRIVER_BIN)
```

The THIRD_PARTY_LIB variable is a colon-separated set of directories where your third-party ODBC libraries are located. You must add the location of the ODBC shared libraries to this path so that drivers can be loaded dynamically at run time. This variable will be appended to the LD_LIBRARY_PATH as part of your install. If you need to set binaries on the PATH, you can also use a colon-separated set of bin directories using THIRD_PARTY_BIN.

It is possible to invoke multiple ODBC-based SAS/ACCESS products in the same SAS session. However, you must first define the driver names in a single odbcinst.ini configuration file. Also, if you decide to use DSNs in your SAS/ACCESS connections, the data sources must be defined in a single odbc.ini configuration file. You cannot pass a delimited string of files for the ODBCINST or ODBCINI environment variables. The requirement to use a single initialization file extends to any situation in which you are running multiple ODBC-based SAS/ACCESS products. Always set the  ODBCINI and ODBCINST to the full paths to the respective files, including the filenames.

```bash
ODBCINI=$(ODBCINI)
ODBCINST=$(ODBCINST)
```

The `$deploy/sas-bases/examples/data-access` directory has the odbcinst.ini and odbc.ini files included in your install. SAS recommends using these files to add additional ODBC drivers or set a DSN to ensure that you have the correct configuration for the included ODBC-based SAS/ACCESS products. It is also best to copy odbcinst.sample.ini or odbc.sample.ini  from the examples directory to a location on your PersistentVolume.

### SAS/ACCESS Interface to Amazon Redshift
SAS/ACCESS Interface to Amazon Redshift uses an ODBC client (from Progress DataDirect), which is included in your install. By default, the Amazon Redshift connector is set up for non-encrypted DSN-less connections. To reference a DSN, follow the [ODBC configuration](#configuration-for-odbc-based-connectors) steps to associate your odbc.ini file with your instance.

### SAS/ACCESS Interface to Google BigQuery
There are no additional configuration steps required.

### SAS/ACCESS Interface to Greenplum
SAS/ACCESS Interface to Greenplum uses an ODBC client (SAS/ACCESS to Greenplum from Progress DataDirect), which is included in your install. By default, the Greenplum connector is set up for non-encrypted DSN-less connections. To reference a DSN, follow the [ODBC configuration](#configuration-for-odbc-based-connectors) steps above to associate your odbc.ini file with your instance.

#### Bulk-Loading
SAS/ACCESS Interface to Greenplum can use the Greenplum Client Loader Interface for loading large volumes of data. To perform bulk loading, the Greenplum Client Loader Package must be accessible from a PersistentVolume. 

SAS recommends using the Greenplum Database parallel file distribution program (gpfdist) for bulk loading. The gpfdist binary and the temporary location gpfdist uses to write data files must be accessible from your Viya cluster and a secondary machine. You will need to launch the gpfdist server binary on the secondary machine to serve requests from SAS:

```bash
./gpfdist -d $(GPLOAD_HOME) -p 8081 -l $(GPLOAD_HOME)/gpfdist.log &
```

Within your sas-access.properties file, set the following environment variables. The $(GPLOAD_HOME) environment variable points to the directory where the external tables you want to load will reside. Note that this location must be mounted and accessible to your Viya cluster as a PersistentVolume, as well as the secondary machine running gpfdist.

```bash
GPHOME_LOADERS=$(PATH_TO_GPFDIST_UTILITY)
GPLOAD_HOST=$(HOST_RUNNING_GPFDIST)
GPLOAD_HOME=$(PATH_TO_EXTERNAL_TABLES_DIR)
GPLOAD_PORT=$(GPFDIST_LISTENING_PORT)
GPLOAD_LIBS=$(GPHOME_LOADERS)/lib
```

### SAS/ACCESS Interface to Hadoop
You must make your Hadoop JARs and configuration file available to SAS/ACCESS Interface to Hadoop on a PersistentVolume or mounted storage. After your SAS Viya software is deployed, set the options SAS_HADOOP_JAR_PATH and SAS_HADOOP_CONFIG_PATH within your SAS program to point to this location. SAS does not recommend setting these as environment variables within your sas-access.properties file, as they would then be used for any connections from your Viya cluster. Instead, within your SAS program, use:

```sas
options set=SAS_HADOOP_JAR_PATH=$(PATH_TO_HADOOP_JARs);
options set=SAS_HADOOP_CONFIG_PATH=$(PATH_TO_HADOOP_CONFIG);
```

### SAS/ACCESS Interface to Impala
SAS/ACCESS Interface to Impala requires the ODBC driver for Impala. The Impala ODBC driver is an API-compliant shared library, that must be accessible from a PersistentVolume. You must include the full path to the shared library by setting the IMPALA attribute so that the Impala driver can be loaded dynamically at run time.

```bash
IMPALA=$(PATH_TO_IMPALA_LIBS)
CLOUDERAIMPALAINI=$(PATH_TO_CLOUDERA_IMPALA_INI)
```

To reference a DSN in your connection and to configure the required third-party ODBC Driver Manager, follow the instructions in [ODBC configuration](#configuration-for-odbc-based-connectors).

#### Bulk-Loading
Bulk loading with Impala is accomplished in two ways:

1. Use the WebHDFS interface to Hadoop to push data to HDFS. The SAS environment variable SAS_HADOOP_RESTFUL must be specified and set to the value of 1. The properties for the WebHDFS location is included in the Hadoop hdfs-site.xml file. In this case, the hdfs-site.xml file must be accessible from a PersistentVolume.  Alternatively, you can specify the WebHDFS hostname or the server's IP address where the external file is stored using the BL_HOST= and BL_PORT= options. 
2. Configure a required set of Hadoop JAR files. JAR files must be in a single location accessible from a PersistentVolume. The SAS environment variable SAS_HADOOP_JAR_PATH and SAS_HADOOP_CONFIG_PATH must be specified and set to the location of the Hadoop JAR and configuration files. For a caslib connection, the data source options HADOOPJARPATH= and HADOOPCONFIGDIR= should be used.

### SAS/ACCESS Interface to JDBC
You must make your JDBC client and configuration file(s) available to SAS/ACCESS Interface to JDBC on a PersistentVolume or mounted storage.

### SAS/ACCESS Interface to MongoDB
The SAS/ACCESS Interface to MongoDB requires the MongoDB C API client library ([libmongoc](http://mongoc.org/)). The MongoDB C shared library must be accessible from a PersistentVolume, and the full path to the library must be set using the MONGODB variable.

```bash
MONGODB=$(PATH_TO_MONGODB_LIBS)
```

### SAS/ACCESS Interface to Microsoft SQL Server
SAS/ACCESS Interface to Microsoft SQL Server uses an ODBC client (from Progress DataDirect), which is included in your install. By default, the SQL Server connector is set up for non-encrypted DSN-less connections. To reference a DSN, follow the [ODBC configuration](#configuration-for-odbc-based-connectors) steps to associate your odbc.ini file with your instance.

#### Connecting to Microsoft Azure SQL Database or Microsoft Azure Synapse
When connecting to Microsoft Azure SQL Database or Microsoft Azure Synapse, add the option 

```bash
EnableScrollableCursors=4
```

to your DSN configuration in the odbc.ini file, or include it in the CONNECT_STRING libname option or the CONOPTS caslib option. 

#### Bulk-Loading
Bulk-loading is initiated by setting the connection option EnableBulkLoad to one.

```bash
EnableBulkLoad=4
```

This option can be set in your DSN (odbc.ini file) or with the CONNECT_STRING libname option for DSN-less connections. When connecting via a caslib, use the CONOPTS option for DSN-less connection. 

### SAS/ACCESS Interface to MySQL
The SAS/ACCESS Interface to MySQL requires the MySQL C API client ([libmysqlclient](https://dev.mysql.com/downloads/c-api/)). The MySQL C API client must be accessible from a PersistentVolume, and the full path to the library must be set using the MYSQL variable.

```bash
MYSQL=$(PATH_TO_MYSQL_LIBS)
```

### SAS/ACCESS Interface to Netezza
SAS/ACCESS Interface to Netezza requires the ODBC driver for Netezza. The IBM Netezza ODBC driver is an API-compliant shared library, that must be accessible from a PersistentVolume. The NETEZZA variable must be set to the full path of the shared library so that the Netezza driver can be loaded dynamically at run time.  IBM's Netezza client package may contain a "linux-64.tar.gz" archive which contains older files that can cause a conflict with other SAS/ACCESS products. SAS recommends that the following files and symbolic links not be included in the Netezza library path:

* libk5crypto.so.* 
* libkrb5.so.*
* libkrb5support.so.*

The libcom_err.so.* files/links must be included. 

```bash
NETEZZA=$(PATH_TO_NETEZZA_LIBS)
```

To reference a DSN in your connection and to configure the required third-party ODBC Driver Manager, follow the instructions in [ODBC configuration](#configuration-for-odbc-based-connectors).

### SAS/ACCESS Interface to ODBC
To configure your ODBC driver to work with SAS/ACCESS Interface to ODBC, follow the instructions in [ODBC configuration](#configuration-for-odbc-based-connectors).

### SAS/ACCESS Interface to Oracle
The SAS/ACCESS Interface to Oracle requires the Oracle shared libraries. The Oracle shared libraries must be accessible from a PersistentVolume, and the full path to the libraries must be set using the ORACLE variable. Set up the ORACLE_HOME environment variable to point to the directory where the Oracle client is installed. This variable is only required if you are using a full client install; it is not necessary if using the Oracle instant client. Also, set up the ORACLE_BIN environment variable to point to the bin directory within the Oracle client install.

```bash
ORACLE=$(PATH_TO_ORACLE_LIBS)
ORACLE_BIN=$(PATH_TO_ORACLE_BIN)
ORACLE_HOME=$(PATH_TO_ORACLE_HOME)
```

If connecting with a tnsnames configuration file, set the TNS_ADMIN environment variable to the location of our tnsnames.ora file. This step is not required if your tnsnames.ora file is located in its default location, ORACLE_HOME.

```bash
TNS_ADMIN=$(PATH_TO_TNS_ADMIN)
```
### SAS/ACCESS Interface to the PI System
The SAS/ACCESS Interface to the PI System uses the PI System Web API.  No PI System client software is required to be installed. However, the PI System Web API (PI Web API 2015-R2 or later) must be installed and activated on the host machine where the user connects.  

#### SSL Certificate
HTTPS requires an SSL (Secure Sockets Layer) certificate to authenticate with the host.  You can set the location to the certificate file in a SAS session using the "option set" command.  The syntax is as follows:

```sas
options set=SSLCALISTLOC "/usr/mydir/root.pem";
```

### SAS/ACCESS Interface to PostgreSQL
SAS/ACCESS Interface to PostgreSQL uses an ODBC client, which is included in your install. By default, the PostgreSQL connector is set up for DSN-less connections. To reference a DSN, follow the [ODBC configuration](#configuration-for-odbc-based-connectors) steps to associate your odbc.ini file with your instance.

### SAS/ACCESS Interface to R/3
The SAS/ACCESS Interface to R/3 requires the SAP NetWeaver RFC Library. The SAP NetWeaver RFC Library must be accessible from a PersistentVolume, and the full path to the library must be set using the R3 variable.

```bash
R3=$(PATH_TO_R3_LIBS)
```

Additional required post-installation tasks are described in [Post-Installation Instructions for SAS/ACCESS 9.4 Interface to R/3](https://support.sas.com/documentation/installcenter/en/ikr3cg/66652/PDF/default/config.pdf).

### SAS/ACCESS Interface to Salesforce
There are no configuration steps required. SAS/ACCESS Interface to Salesforce connects to Salesforce using version 46.0 of its SOAP API.

### SAS/ACCESS Interface to SAP ASE
The SAS/ACCESS Interface to SAP ASE requires the SAP ASE shared libraries. The SAP ASE shared libraries must be accessible from a PersistentVolume, and the full path to the libraries must be set using the SYBASELIBS variable. The SYBASE variable must also be set to the full path of the SAP ASE (Sybase) installation directory, and the SYBASE_BIN variable must be set to the SAP ASE installation bin directory. 

```bash
SYBASE=$(PATH_TO_SAPASE_INSTALLATION_DIR)
SYBASELIBS=$(PATH_TO_SAPASE_LIBS)
SYBASE_BIN=$(PATH_TO_SAPASE_BIN_DIRECTORY)
```

Here are optional SAP ASE (Sybase) environment variables that you may want to consider setting:

```bash
SYBASE_OCS=$(SAPASE_HOME_DIRECTORY_NAME)
DSQUERY=$(NAME_OF_TARGET_SERVER)
```

#### Installing SAP ASE Procedures
The SAP ASE  administrator or user must install two SAP ASE (Sybase) stored procedures on the target SAP server. These files are available in a compressed TGZ archive for download from the SAS Support site at https://support.sas.com/downloads/package.htm?pid=2458.

### SAS/ACCESS Interface to SAP HANA
SAS/ACCESS Interface to SAP HANA requires the ODBC driver for SAP HANA. The SAP HANA ODBC driver is an API-compliant shared library, that must be accessible from a PersistentVolume. The HANA variable must be set to the full path of the shared library so that the SAP HANA driver can be loaded dynamically at run time. 

```bash
HANA=$(PATH_TO_HANA_LIBS)
```

To reference a DSN in your connection and to configure the required third-party ODBC Driver Manager, follow the instructions in [ODBC configuration](#configuration-for-odbc-based-connectors).

### SAS/ACCESS Interface to Snowflake
SAS/ACCESS Interface to Snowflake requires the ODBC driver for Snowflake. The Snowflake driver is an API-compliant shared library, that must be accessible from a PersistentVolume. The SNOWFLAKE variable must be set to the full path of the shared library so that the Snowflake driver can be loaded dynamically at run time. 

```bash
SNOWFLAKE=$(PATH_TO_SNOWFLAKE_LIBS)
```

To reference a DSN in your connection and to configure the required third-party ODBC Driver Manager, follow the instructions in [ODBC configuration](#configuration-for-odbc-based-connectors).

### SAS/ACCESS Interface to Spark
You must make your Hadoop JARs and configuration file available to SAS/ACCESS Interface to Spark on a PersistentVolume or mounted storage. After your SAS Viya software is deployed, set the options SAS_HADOOP_JAR_PATH and SAS_HADOOP_CONFIG_PATH within your SAS program to point to this location. SAS does not recommend setting these as environment variables within your sas-access.properties file, as they would then be used for any connections from your Viya cluster. Instead, within your SAS program, use:

```sas
options set=SAS_HADOOP_JAR_PATH=$(PATH_TO_HADOOP_JARs);
options set=SAS_HADOOP_CONFIG_PATH=$(PATH_TO_HADOOP_CONFIG);
```

### SAS/ACCESS Interface to Teradata
SAS/ACCESS Interface to Teradata requires the Teradata Tools and Utilities (TTU) shared libraries. The TTU libraries must be accessible from a PersistentVolume, and the TERADATA variable must be set to the full path of the TTU libraries.

```bash
TERADATA=$(PATH_TO_TERADATA_LIBS)
```

Ensure that the Teradata client encoding is set to UTF-8 in the clispd.dat file. The two lines in the clispd.dat file that need to be set are:

```properties
charset_type=N
charset_id=UTF8
```

Set the COPLIB environment variable to the location of the updated clispd.dat file.

```bash
COPLIB=$(TERADATA_COPLIB)
```

### SAS/ACCESS Interface to Yellowbrick
SAS/ACCESS Interface to Yellowbrick uses an ODBC client, which is included in your install. By default, the Yellowbrick connector is set up for DSN-less connections. To reference a DSN, follow the [ODBC configuration](#configuration-for-odbc-based-connectors) steps to associate your odbc.ini file with your instance.  To use the bulkload/bulkunload feature, configure the path to the ybload/ybunload files in the Yellowbrick libname statement using the following options: BULKLOAD=YES BL_YB_PATH='path-to-ybload/ybunload'.

### SAS/ACCESS Interface to Vertica
SAS/ACCESS Interface to Vertica requires the ODBC driver for Vertica. The Vertica ODBC driver is an API-compliant shared library, that must be accessible from a PersistentVolume. The VERTICA variable must be set to the full path of the shared library so that the Vertica driver can be loaded dynamically at run time. Also, the VERTICAINI attribute must be set to point to vertica.ini file on your PersistentVolume. 

```bash
VERTICA=$(PATH_TO_VERTICAL_LIBS)
VERTICAINI=$(PATH_TO_VERTICA_ODBCINI)
```

Also, the driver manager encoding defined in the vertica.ini file should be set to UTF-8.

```properties
DriverManagerEncoding=UTF-8
```

To reference a DSN in your connection and to configure the required third-party ODBC Driver Manager, follow the instructions in [ODBC configuration](#configuration-for-odbc-based-connectors).

## Enabling Data Connector Ports
The publishDCNodePortServices key enables network connections between CAS and supported databases, such as Teradata and Hadoop, to transfer data in parallel between the database nodes and CAS nodes. Parallel data transfer is a functionality provided by the SAS Data Connector Accelerator for Hadoop or Teradata products.

Edit the base `kustomization.yaml` file in your `$deploy` directory to add the following lines.

```yaml 
transformers:
...
- sas-bases/overlays/data-config/enable-dc-ports.yaml
```

## Enabling SAS Embedded Process Continuous Session Ports
The publishEPCSNodePortService key enables the execution of the SAS Embedded Process for Spark Continuous Session (EPCS) in the Kubernetes cluster. The SAS Embedded Process for Spark continuous session (EPCS) is an instantiation of a long-lived SAS Embedded Process session on a cluster that can serve one CAS session. EPCS provides a tight integration between CAS and Spark by processing multiple execution requests without having to start and stop the SAS Embedded Process for Spark every time an execution request is made. 

Users can improve system performance by using the EPCS and the SAS Data Connector to Hadoop to perform multiple actions within the same CAS session. Users can also use the EPCS to run models in Spark.

Edit the base `kustomization.yaml` file in your `$deploy/site-config` directory to add the following lines.

```yaml 
transformers:
...
- sas-bases/overlays/data-config/enable-epcs-port.yaml
```

## Additional Resources
For information about PersistentVolumes, see [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).
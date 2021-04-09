library(swat)
library(ggplot2)
library(reshape2)
library(dplyr)

#Sys.setenv(CAS_CLIENT_SSL_CA_LIST = "C://Users/frasep/OneDrive - SAS/Mes Documents/Dossiers/Demoing/My_Local_Environments/frasepviya35smp/frasepviya35smp.cloud.com/cacerts/trustedcerts.pem")

Sys.setenv(CAS_CLIENT_SSL_CA_LIST = "C://Users/frasep/OneDrive - SAS/Mes Documents/Dossiers/Demoing/My_Azure_Environments/frasepviya35smp/cacerts/trustedcerts.pem")
conn <- CAS('frasepviya35smp.cloud.com', 5570,"viyademo01","demopw")

# Activate metric tracing and other session parameters
cas.sessionProp.setSessOpt(conn, metrics=TRUE, timeout=1800, caslib='casuser')

cas.session.listSessions(conn)

Sys.time()
tbl <- defCasTable(conn, tablename="sample_350columns", caslib = "PUBLIC")
tblR <- to.casDataFrame(tbl)
Sys.time()


Sys.time()
tblR <- cas.table.fetch(conn,to=10000,table=list(name="sample_350columns",caslib = "PUBLIC", singlepass="true"));
Sys.time()


install.packages("https://github.com/sassoftware/R-swat/releases/download/v1.6.1-snapshot/R-swat-1.6.0.9000+vb20060-win-64.tar.gz", repos=NULL, type='file')

cas.session.endSession(conn)

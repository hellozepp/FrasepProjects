library(swat)
library(ggplot2)
library(reshape2)
library(dplyr)

Rprof()

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
# 23 min 


cas.session.endSession(conn)

library(swat)

Sys.setenv(CAS_CLIENT_SSL_CA_LIST = "/opt/sas/viya/config/etc/SASSecurityCertificateFramework/cacerts/trustedcerts.pem")
conn <- CAS('frasepviya35smp.cloud.com', 5570)
# Activate metric tracing and other session parameters
cas.sessionProp.setSessOpt(conn, metrics=TRUE, timeout=1800, caslib='casuser')

cas.session.listSessions(conn)

# Read in the hmeq CSV to an in-memory data table and create a CAS table object reference
castbl <- cas.read.csv(conn, 'http://support.sas.com/documentation/onlinedoc/viya/exampledatasets/hmeq.csv')

# Create variable for the in-memory data set name
indata = 'hmeq'

cas.table.tableDetails(conn,
    level="node",
    caslib="casuser",
    name=indata
)

cas.table.tableInfo(conn)

dim(castbl)
names(castbl)

colMeans(castbl)
mean(castbl$BAD)

summary(castbl)

loadActionSet(conn, 'simple')

cas.simple.correlation(conn,
    table = indata,
    inputs = c("LOAN","VALUE","MORTDUE")
)
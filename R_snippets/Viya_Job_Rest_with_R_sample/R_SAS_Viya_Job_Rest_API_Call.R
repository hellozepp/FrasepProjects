# *******************************************************
# *******************************************************
library(httr)
library(jsonlite)

# *******************************************************
# Get oauth token for SAS Viya REST API calls
# *******************************************************
get_viya_oauth_token <- function(viyaBaseUri, authUri, clientid, clientsecret) {
  fullUri <- paste(viyaBaseUri,authUri,sep="")
  rJson <- POST(
              fullUri,
              accept("application/json"),
              content_type("application/x-www-form-urlencoded"),
              body=list(grant_type="password", username=clientid, password=clientsecret),
              encode="form",
              authenticate("frasepapp", "frasepsecret")
           )
  return(content(rJson)$id_token)
}

# ********************************************************
# Execute a SAS Viya job
# ********************************************************
execute_viya_job <- function(viyaBaseUri, fulljobname, parameterstr, access_token) {
  jobcalluri <- URLencode(paste(viyaBaseUri,"/SASJobExecution?_program=",fulljobname,parameterstr,sep=""))
  print("Generated URL :")
  print(jobcalluri)
  
  rJson <- GET(url = jobcalluri, add_headers("Authorization"=paste("Bearer", access_token)), verbose())
  
  return(fromJSON(content(rJson,as="text")))
}

# ******************************************************************************
# Example of freqTab proc wrapper function (calling viya job with json output)
# ******************************************************************************

compute_correlations_with_cas <- function(in_castablename, in_caslibname, freqtab_table_clause) {
  r <- execute_viya_job(
    viyaBaseUri='https://frasepviya35smp.cloud.com',
    fulljobname='/Public/Job definition/Job_correlation',
    parameterstr=paste('&castabname=',in_castablename,'&caslibname=',in_caslibname,'&tablesclause=',freqtab_table_clause,sep=""),
    access_token=viya_access_token
  )
  return(r)
}

# ********************************************************
# Test program
# ********************************************************

# Get Oauth token to access Viya REST API
client_id <- rstudioapi::askForPassword()
client_secret <- rstudioapi::askForPassword()
viya_access_token <- get_viya_oauth_token('https://frasepviya35smp.cloud.com', '/SASLogon/oauth/token', client_id, client_secret)

# Compute correlation with CAS
r <- compute_correlations_with_cas('HMEQ_TRAIN', 'AZUREDL', 'clage * debtinc)')

r[r['Statistic'] == 'Spearman Correlation']
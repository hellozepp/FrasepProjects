# *******************************************************
# *******************************************************

library(httr)

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
  jobcalluri <- paste(viyaBaseUri,"/SASJobExecution?_program=",fulljobname,parameterstr,sep="")
  
  rJson <- GET(url = jobcalluri, add_headers(.headers = c('Authorization : Bearer' = access_token)), verbose())
  return(rJson)
}

# Test program

client_id <- rstudioapi::askForPassword()
client_secret <- rstudioapi::askForPassword()

viya_access_token <- get_viya_oauth_token('https://frasepviya35smp.cloud.com', '/SASLogon/oauth/token', client_id, client_secret)

execute_viya_job('https://frasepviya35smp.cloud.com','%2FPublic%2FJob%20definition%2FJob_correlation','&castabname=churn&caslibname=PUBLIC&tablesclause=clage*job',viya_access_token)


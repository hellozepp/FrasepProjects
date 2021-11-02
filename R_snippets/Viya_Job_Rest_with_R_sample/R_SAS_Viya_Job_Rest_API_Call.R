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

compute_freqtab <- function(in_castablename, in_caslibname, freqtab_table_clause, freqtab_table_options, freqtab_output_clause) {
  r <- execute_viya_job(
    viyaBaseUri='https://frasepviya35smp.cloud.com',
    fulljobname='/Public/Job definition/Job_proc_freqtab',
    parameterstr=paste('&castabname=',in_castablename,'&caslibname=',in_caslibname,'&tablesclause=',freqtab_table_clause,'&table_options=',freqtab_table_options,'&output_options=',freqtab_output_clause,sep=""),
    access_token=viya_access_token
  )
  return(r)
}

# ********************************************************
# Test program
# ********************************************************

# Get Oauth token to access Viya REST API
client_id <- rstudioapi::showPrompt('User name', 'Enter your user name', default = NULL)
client_secret <- rstudioapi::askForPassword()
viya_access_token <- get_viya_oauth_token('https://frasepviya35smp.cloud.com', '/SASLogon/oauth/token', client_id, client_secret)

# Compute spearman correlation on Viya
starttime <- Sys.time()
r <- compute_freqtab('MEGACORP5_4m', 'AZUREDL', 'unitreliability * facilityage','measures','scorr')
endtime <- Sys.time()
difftime(endtime, starttime, unit = "secs")
r

# MEGACORP5_4m (4,5 million rows)
# r <- compute_freqtab('MEGACORP5_4m', 'AZUREDL', 'unitreliability * facilityage','measures','scorr')
# 10 seconds, output : ASE of Spearman Correlation Spearman Correlation
# r['Spearman Correlation'] to get it

# T thcurnow calculation : to be defined with simple formula based on freqtab outputs
# MEGACORP5_4m (4,5 million rows)  : Expenses (66399) * facilityage(32), chisq, chisq , 10 seconds
# N _PCHI_ DF_PCHI P_PCHI  _LRCHI_ DF_LRCHI P_LRCHI  _MHCHI_ DF_MHCHI P_MHCHI  _PHI_  _CONTGY_  _CRAMV_

# Compute Jeffreys confidence liimits on Viya
# Jeffreys : https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/casstat/casstat_freqtab_details35.htm?homeOnFail=
starttime <- Sys.time()
r <- compute_freqtab('MEGACORP5_4m', 'AZUREDL', 'unitreliability','binomial(cl=jeffreys)','binomial')
endtime <- Sys.time()
difftime(endtime, starttime, unit = "secs")
names(r)
# outputs :  [1] "H0 ASE of Binomial Proportion"    "ASE of Binomial Proportion"       "Lower CL (Jeffreys), Binomial Pr" "Number of Subjects"              
# [5] "P-value, Binomial P (Two-sided)"  "P-value, Binomial P (Left-sided)" "P-value, Binomial P (Right-sided" "Upper CL (Jeffreys), Binomial Pr"
# [9] "Standardized (Z) Binomial Propor" "Binomial Proportion P" 



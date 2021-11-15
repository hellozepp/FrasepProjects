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
  
  rJson <- GET(url = jobcalluri, add_headers("Authorization"=paste("Bearer", access_token)), verbose(), timeout(1800))
  
  return(fromJSON(content(rJson,as="text")))
}

# ******************************************************************************
# Example of freqTab proc wrapper function (calling viya job with json output)
# ******************************************************************************

compute_freqtab <- function(in_castablename, in_caslibname, freqtab_table_clause, freqtab_table_options, freqtab_output_clause) {
  r <- execute_viya_job(
    viyaBaseUri='https://frasepviya35smp.cloud.com',
    fulljobname='/Production/Job_definition/Job_proc_freqtab',
    parameterstr=paste('&castabname=',in_castablename,'&caslibname=',in_caslibname,'&tablesclause=',freqtab_table_clause,'&table_options=',freqtab_table_options,'&output_options=',freqtab_output_clause,sep=""),
    access_token=viya_access_token
  )
  return(r)
}

# ******************************************************************************
# Example of freqTab proc wrapper function (calling viya job with json output)
# ******************************************************************************

compute_corr <- function(in_castablename, in_caslibname, corrclause, varclause, withclause) {
  r <- execute_viya_job(
    viyaBaseUri='https://frasepviya35smp.cloud.com',
    fulljobname='/Production/Job_definition/Job_proc_corr',
    parameterstr=paste('&castabname=',in_castablename,'&caslibname=',in_caslibname,'&corrclause=',corrclause,'&varclause=',varclause,'&withclause=',withclause,'&_timeout=3600',sep=""),
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

# MEGACORP5_4m (4,5 million rows)

# Compute spearman correlation on Viya with proc corr (2 continous variables of 91000000 distinct values : 208 secondes)
starttime <- Sys.time()
r <- compute_corr(in_castablename='test_corr', in_caslibname='public', corrclause='spearman', varclause='nums1', withclause='nums2')
endtime <- Sys.time()
difftime(endtime, starttime, unit = "secs")
r

# Compute spearman correlation on Viya
starttime <- Sys.time()
r <- compute_freqtab('MEGACORP5_4m', 'AZUREDL', 'unitreliability * facilityage','measures','scorr')
endtime <- Sys.time()
difftime(endtime, starttime, unit = "secs")
r
# r['Spearman Correlation'] to get it

# T Tschuprow calculation : to be defined with simple formula based on freqtab outputs of pearson Chi square computed by freqtab
starttime <- Sys.time()
r <- compute_freqtab('MEGACORP5_4m', 'AZUREDL', 'unitreliability * facilityage','chisq','chisq')
endtime <- Sys.time()
difftime(endtime, starttime, unit = "secs")
names(r)
# outputs :
#  [1] "DF for Likelihood Ratio Chi-Squa" "DF for Mantel-Haenszel Chi-Squar" "DF for Chi-Square"                "Number of Subjects in the Stratu"
# [5] "P-value for Likelihood Ratio Chi" "P-value for Mantel-Haenszel Chi-" "P-value for Chi-Square"           "Contingency Coefficient"         
# [9] "Cramer's V"                       "Likelihood Ratio Chi-Square"      "Mantel-Haenszel Chi-Square"       "Chi-Square"                      
# [13] "Phi Coefficient" 
T_Tschuprow <- (sqrt((r["Chi-Square"]/r["Number of Subjects in the Stratu"])/sqrt(r["DF for Chi-Square"])))


# Compute Jeffreys confidence limits on Viya
# Jeffreys : https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/casstat/casstat_freqtab_details35.htm?homeOnFail=
starttime <- Sys.time()
r <- compute_freqtab('MEGACORP5_4m', 'AZUREDL', 'unitreliability','binomial(cl=jeffreys)','binomial')
endtime <- Sys.time()
difftime(endtime, starttime, unit = "secs")
names(r)
# outputs :  [1] "H0 ASE of Binomial Proportion"    "ASE of Binomial Proportion"       "Lower CL (Jeffreys), Binomial Pr" "Number of Subjects"              
# [5] "P-value, Binomial P (Two-sided)"  "P-value, Binomial P (Left-sided)" "P-value, Binomial P (Right-sided" "Upper CL (Jeffreys), Binomial Pr"
# [9] "Standardized (Z) Binomial Propor" "Binomial Proportion P"


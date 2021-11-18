# *******************************************************
# *******************************************************
library(httr)
library(jsonlite)

# **************************************************************************
# Function
# Name        : get_viya_oauth_token
# Description : Get oauth token for SAS Viya REST API calls
# Parameters  : viyaBaseUri, authUri, clientid, clientsecret
# ***************************************************************************
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

# **************************************************************************
# Function
# Name        : get_viya_job_definition_id_from_path
# Description : Get job id definitions from complete content path of job (including job name)
# Parameters  : viya_base_uri, fulljobname, access_token,job_args_list
# ***************************************************************************
get_viya_job_definition_id_from_path <- function(viyaBaseUri, access_token,maxnbjob=10000, fullPathLabel) {
  jobcalluri <- URLencode(paste(viyaBaseUri,"/jobDefinitions/definitions?limit=",maxnbjob,sep=""))
  job_id <- "noid"
  rJson <- GET(url = jobcalluri,add_headers("Authorization"=paste("Bearer", access_token)))
  
  df <- fromJSON(content(rJson,as="text"))

  for (row in 1:length(df$items$properties)) {
    cur_job_properties <- df$items$properties[[row]]
    cur_job_type <- df$items$type[[row]]
    if (cur_job_type == "Compute" && nrow(cur_job_properties)==4) {
        cur_pathlabel <- cur_job_properties[cur_job_properties$name == "pathLabel",]$value
        if (identical(cur_pathlabel,fullPathLabel)) {
          job_id <- df$items$id[[row]]
          break
        }
      }
  }
  return(job_id)
}

# **************************************************************************
# Function
# Name        : execute_job_async
# Description : Execute job in async mode
# Parameters  : viya_base_uri, fulljobname, access_token,job_args_list
# Output      : dataframe containing all job characteristics of the job started
# Example     : job_result <- execute_job_async(
#                   viya_base_uri = viya_base_uri, 
#                   fulljobname='/Production/job_definition/Job_proc_corr', 
#                   access_token=viya_access_token,
#                   job_args_list = list(castabname="test_corr",caslibname="public", corrclause="spearman", varclause="nums1", withclause="nums2", "_contextName"="SAS Job Execution compute context"))
# ***************************************************************************
execute_job_async <- function(viya_base_uri, fulljobname, access_token,job_args_list) {
  
  jobdefid <- get_viya_job_definition_id_from_path(viyaBaseUri = viya_base_uri, access_token=access_token,fullPathLabel=fulljobname)
  jobcalluri <- URLencode(paste(viya_base_uri,"/jobExecution/jobs",sep=""))
  
  body <- list(jobDefinitionUri=paste("/jobDefinitions/definitions/",jobdefid,sep=""),
               arguments = job_args_list)
  
  rJson <- POST(
    url = jobcalluri,
    verbose(),
    add_headers(
      "Authorization"=paste("Bearer", access_token),
      "Content-Type"="application/vnd.sas.job.execution.job.request+json",
      "Accept"="application/vnd.sas.job.execution.job+json"),
    body = toJSON(body, auto_unbox=TRUE)
  )
  
  return(fromJSON(content(rJson,as="text")))
}

# **************************************************************************
# Function
# Name        : execute_job_sync
# Description : Execute job in sync mode and return webout results (json expected)
# Parameters  : viya_base_uri, fulljobname, access_token,job_args_list
# Output      : dataframe containing the job _webout.json result after completed execution
# Example     : job_result <- execute_job_sync(
#                   viya_base_uri = viya_base_uri, 
#                   fulljobname='/Production/job_definition/Job_proc_corr', 
#                   access_token=viya_access_token,
#                   job_args_list = list(castabname="test_corr",caslibname="public", corrclause="spearman", varclause="nums1", withclause="nums2", "_contextName"="SAS Job Execution compute context"))
# ***************************************************************************
execute_job_sync <- function(viya_base_uri, fulljobname, access_token,job_args_list) {
  starttime <- Sys.time()
  job_json <- execute_job_async(viya_base_uri, fulljobname, access_token,job_args_list)
  flag_job_completed <- 0
  print(paste("Job id :",job_json$id,"Job status :",job_json$state),sep="")
  while (flag_job_completed==0) {
    Sys.sleep(0.5)
    # Get job state
    jobcalluri <- URLencode(paste(viya_base_uri,"/jobExecution/jobs/",job_json$id,sep=""))
    job_info_json <- GET(url = jobcalluri,add_headers("Authorization"=paste("Bearer", access_token)))
    job_info_df <- fromJSON(content(job_info_json,as="text"))
    if (job_info_df$state == "completed") { flag_job_completed <- 1 }
  }
  endtime <- Sys.time()
  print(paste(
    "Job Start time :",starttime,
    " Job End Time : ",endtime,
    " Job duration (in s) : ",difftime(endtime, starttime, unit = "secs"),
    sep=""))
  
  # Once the job is finished, retrieve the json output (_webout.json entry)
  jobcalluri <- URLencode(paste(viya_base_uri,job_info_df$results$'_webout.json','/content',sep=""))
  rJson <- GET(url = jobcalluri,add_headers("Authorization"=paste("Bearer", access_token)),verbose())
  return(fromJSON(content(rJson,as="text")))
}

# **************************************************************************
# Function
# Name        : get_viya_job_attributes
# Description : get all current value of job attributes including state, results, etc...
# Parameters  : viyaBaseUri, access_token, jobid
# Output      : dataframe containing all the job attributes
# Example     : 
# ***************************************************************************
get_viya_job_attributes <- function(viyaBaseUri, access_token, jobid) {
    jobcalluri <- URLencode(paste(viyaBaseUri,"/jobExecution/jobs/",jobid,sep=""))
    job_info_json <- GET(url = jobcalluri,add_headers("Authorization"=paste("Bearer", access_token)))
    return(fromJSON(content(job_info_json,as="text")))
}

# **************************************************************************
# Test for sync job execution
# **************************************************************************

# Define global variables
viya_base_uri<-'https://frasepviya35smp.cloud.com'
client_id <- rstudioapi::showPrompt('User name', 'Enter your user name', default = NULL)
client_secret <- rstudioapi::askForPassword()

# *******************************************************
# Get Oauth token to access Viya REST API defne
viya_access_token <- get_viya_oauth_token(viya_base_uri, '/SASLogon/oauth/token', client_id, client_secret)

# Execute de viya job /Production/job_definition/Job_proc_corr in synchronous mode
job_result <- execute_job_sync(
  viya_base_uri = viya_base_uri, 
  fulljobname='/Production/job_definition/Job_proc_corr', 
  access_token=viya_access_token,
  job_args_list = list(castabname="test_corr",caslibname="public", corrclause="spearman", varclause="nums1", withclause="nums2", "_contextName"="SAS Job Execution compute context"))

# Display the correlation
job_result[job_result$'_TYPE_' == "CORR",]$nums1

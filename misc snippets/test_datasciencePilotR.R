library(dplyr)
library(swat)
library(ggplot2)
library(reshape2)
library(shiny)
library(plotly)
options(cas.print.messages = TRUE)
options(shiny.maxRequestSize=30*1024^2)

conn <- CAS('frasepviya35smp', 5570)
# Activate metric tracing and other session parameters
cas.sessionProp.setSessOpt(conn, metrics=TRUE, timeout=1800, caslib='casuser')

castbl <- cas.read.csv(conn, 'http://support.sas.com/documentation/onlinedoc/viya/exampledatasets/hmeq.csv')

cas.table.columnInfo(conn, table = "HMEQ")$ColumnInfo$Column

cas.table.tableInfo(conn, caslib="CASUSER")$TableInfo$Name

# List tables from a specific CASLIB
list_tables <- function(lib) {
  tbls <- cas.table.tableInfo(conn, caslib=lib)
  names <- tbls$TableInfo[1:3]
  return(names)
}

list_tables("casuser")$Name


# use of SAS Viya native automML action (see help : https://documentation.sas.com/?docsetId=casactml&docsetTarget=cas-datasciencepilot-dsautoml.htm&docsetVersion=8.5&locale=en)

auto_ml_v2 <- function(trainingTable, targetVariable, dt,rf,gb,nn) {
  
  loadActionSet(conn,"dataSciencePilot")
  
  # tbl_name : table d entrainement
  
  colinfo <- head(cas.table.columnInfo(conn, table = model_tbl)$ColumnInfo, -1)
  target <<- targetVariable
  inputs <<- colinfo$Column[colinfo$Column != target]
  
  SelectedmodelTypes <- list()
  if (dt) SelectedmodelTypes <- list("decisionTree")
  if (rf) SelectedmodelTypes <- c(SelectedmodelTypes,"FOREST")
  if (gb) SelectedmodelTypes <- c(SelectedmodelTypes,"GRADBOOST")
  if (nn) SelectedmodelTypes <- c(SelectedmodelTypes,"NEURALNET")
  
  cas.dataSciencePilot.dsAutoMl(
    conn,
    table                 = list(name =trainingTable),
    target                = target,
    transformationPolicy  = list(missing = TRUE, cardinality = TRUE,
                                 entropy = TRUE, iqv = TRUE,
                                 skewness = TRUE, Outlier = TRUE),
    modelTypes            = SelectedmodelTypes,
    hyperParameterOptimizer = "MODELCOMPOSER",
    objective             = "AUC",
    sampleSize            = 10,
    topKPipelines         = 2,
    kFolds                = 5,
    transformationOut     = list(name= "TRANSFORMATION_OUT", replace = TRUE),
    featureOut            = list(name= "FEATURE_OUT", replace = TRUE),
    pipelineOut           = list(name= "PIPELINE_OUT", replace = TRUE),
    saveState             = list(name= "ASTORE_OUT", replace = TRUE)      
  )
  
  print(cas.table.fetch(conn,table = list(name = "PIPELINE_OUT")))
  print(cas.table.fetch(conn,table = list(name = "FEATURE_OUT")))
  print(cas.table.fetch(conn,table = list(name = "TRANSFORMATION_OUT")))
}

auto_ml_v2("HMEQ", "BAD", dt=TRUE,rf=TRUE,gb=TRUE,nn=TRUE)



conn.close()
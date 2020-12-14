# Copyright © 2020, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

setwd("C://my_local_data/github/FrasepProjects/viya_shiny_app/viya_shiny_app")
#setwd("/home/viyademo01/github/FrasepProjects/viya_shiny_app/viya_shiny_app")

#setwd("H://github/FrasepProjects/FrasepProjects/viya_shiny_app/viya_shiny_app")
library(dplyr)
library(swat)
library(ggplot2)
library(reshape2)
library(shiny)
library(plotly)
options(cas.print.messages = TRUE)
options(shiny.maxRequestSize=30*1024^2)


Sys.setenv(CAS_CLIENT_SSL_CA_LIST = "C://Users/frasep/OneDrive - SAS/Mes Documents/Dossiers/Demoing/My_Local_Environments/frasepviya35smp/frasepviya35smp.cloud.com/cacerts/trustedcerts.pem")
globalhostname <- "frasepviya35smp.cloud.com"


#####################################
# R code for data manipulation,
# model training and visualization
#####################################

conn <- 0
lst_caslibs <- list()

# List available caslibs
list_caslib <- function() {
    libs <- cas.table.caslibInfo(conn)
    lst_names <- libs$CASLibInfo[,"Name"]
    return(lst_names)
}

# Open connection to CAS and import main functions
connect <- function(username, password, lib) {
    conn <<- CAS(globalhostname, port=5570, caslib = 'casuser',   username = username,   password = password)
    lst_caslibs <<- list_caslib()
    return(cas.builtins.serverStatus(conn))
}

# List tables from a specific CASLIB
list_tables <- function(lib) {
    tbls <- cas.table.tableInfo(conn, caslib=lib)
    names <- tbls$TableInfo[1:3]
    return(names)
}


# Generate summary statistics for a specific CAS Table
explore_tbl <- function(tbl) {
    cols <- c("Column", "Min", "Max", "N", "NMiss", "Mean",	"Sum")
    summary_tbl <- data.frame(cas.simple.summary(conn, table={name=tbl}))[1:7]
    colnames(summary_tbl) <- cols
    return(summary_tbl)
}

# Get table from CAS to R dataframe
get_table <- function(tbl) {
    tbl <- defCasTable(conn, tbl)
    tbl <- to.casDataFrame(tbl)
    return(tbl)
}

# Upload SAS dataset to CAS
upload_tbl <- function(tbl_path) {
    str1 <- gsub("\\","/", tbl_path["datapath"], fixed=TRUE)
    
    name = unlist(strsplit(as.character(tbl_path["name"]), split='.', fixed=TRUE))[1]
    
    cas.table.dropTable(conn, caslib="casuser", name=name, quiet=TRUE)
    
    tbl <- cas.read.sas7bdat(conn, str1, casOut=list(name=name, caslib="casuser", replace = TRUE))
    tbl <- defCasTable(conn, table=name)
    tbl_sum <- explore_tbl(name)
    return(tbl_sum)
}

# Generate Missing analysis 
# and create GGPlot containing values
analyze_miss <- function(tbl_name){
    castbl <- defCasTable(conn, table=tbl_name)
    
    tbl <- cas.simple.distinct(castbl)$Distinct[,c('Column', 'NMiss')]
    
    tbl$PctMiss <- tbl$NMiss/nrow(castbl)
    
    plot <- ggplot(tbl, aes(Column, PctMiss)) +
        geom_col(fill = 'blue') +
        ggtitle('Pct Missing Values') +
        theme(plot.title = element_text(hjust = 0.5))
    
    return(plot)
}

# Analyze carninality on a CAS table
# this will generate cardinality for each variable
# and return a plot containing the information
analyze_cardinality <- function(tbl_name) {
    loadActionSet(conn, "cardinality")
    cas.cardinality.summarize(conn, table={name=tbl_name}, cardinality=list(caslib="casuser", name="cardinality", replace = TRUE))
    tbl <- get_table("cardinality")
    
    plot <- ggplot(tbl, aes(`_VARNAME_`, `_CARDINALITY_`)) +
        geom_col(fill = 'blue') +
        ggtitle('Cardinality') +
        theme(plot.title = element_text(hjust = 0.5))
    
    return(plot)
}

# Generate features
# uses featureMachine cas action
# it will analyze:
#     MISSING
#     ENTROPY
#     HIGH-CARDINALITY
#     SKEWNESS
#     CURTOSIS
#     OUTLIER
# and will apply transformations accordingly

feature_engineering <- function(tbl_name, target, a, b, c, d, e, f, g) {
    loadActionSet(conn, "dataSciencePilot")
    target <<- target
    tbl_name <<- tbl_name

    features <- cas.dataSciencePilot.featureMachine(
        conn,
        table                 = list(name =tbl_name),
        target                = target,
        copyVars              = list(target),
        transformationPolicy  = list(missing = a, cardinality = b, entropy = c, iqv = d, skewness = e, kurtosis = f, Outlier = g),
        transformationOut     = list(name= "TRANSFORMATION_OUT", replace = TRUE),
        featureOut            = list(name= "FEATURE_OUT", replace = TRUE),
        casout                = list(name= paste(tbl_name,"_TRANSFORMED",sep=""), replace = TRUE),
        saveState             = list(name= "ASTORE_OUT", replace = TRUE)
    )
    
    return(get_table("FEATURE_OUT"))
}


# Partition the dataset into 
#   70% training
#   30% test  
partition <- function(tbl) {
    loadActionSet(conn, "sampling")
    cas.sampling.srs(conn,
                     table = list(name=tbl, caslib="casuser"),
                     samppct = 30,
                     partind = TRUE,
                     output = list(casOut = list(name = paste(tbl,'_part', sep=""), replace = T, caslib="casuser"), copyVars = 'ALL')
    )
}

# Runs autoML
# It trains multiple ML models:
#   * Decision Tree
#   * Random Forest
#   * Gradient Boosting
#   * Neural Networks
# Then, scores on the 30% dataset
# and runs assessment

auto_ml <- function(dt, rf, gb, nn) {
    loadActionSet(conn, "decisionTree")
    loadActionSet(conn, "neuralNet")
    
    partition(paste(tbl_name, "_TRANSFORMED", sep =""))
    
    model_tbl <<- paste(tbl_name, "_TRANSFORMED_part", sep ="")
    
    colinfo <- head(cas.table.columnInfo(conn, table = model_tbl)$ColumnInfo, -1)

    print(cas.table.columnInfo(conn, table = model_tbl)$ColumnInfo)
    
    target <<- colinfo$Column[1]
    inputs <<- colinfo$Column[-1]
    nominals <<- c(target, subset(colinfo, Type == 'varchar')$Column)
    #nominals <<- subset(colinfo, Type == 'varchar')$Column
    
    models <- vector()
    scores <- vector()
    model_names <- vector()
    

    print("automl 1")

    print("target:")
    print(target)
    print("inputs:")
    print(inputs)
        
    if(dt) {
        print("Executing decisiton tree...")
        
        cas.decisionTree.dtreeTrain(conn,
                                    table = list(name = model_tbl, caslib = "casuser", where = "_PartInd_ = 0"),
                                    target = target,
                                    inputs = inputs,
                                    nominals = nominals,
                                    casOut = list(name = "dt_model", caslib="casuser", replace = TRUE))
        models <- c(models, 'dt')
        scores <- c(scores, cas.decisionTree.dtreeScore)
        model_names <- c(model_names, 'Decision Tree')
    }

    print("automl 2")
    
    if(rf) {
        print("Executing random forest ...")
        cas.decisionTree.forestTrain(conn,
                                     table = list(name = model_tbl, caslib = "casuser", where = '_PartInd_ = 0'),
                                     target = target,
                                     inputs = inputs,
                                     nominals = nominals,
                                     casOut = list(name = 'rf_model', caslib="casuser", replace = TRUE)
        )
        models <- c(models, 'rf')
        scores <- c(scores, cas.decisionTree.forestScore)
        model_names <- c(model_names, 'Random Forest')
    }
    if(gb) {
        print("Executing gb tree...")
        cas.decisionTree.gbtreeTrain(conn,
                                     table = list(name = model_tbl, caslib = "casuser", where = '_PartInd_ = 0'),
                                     target = target,
                                     inputs = inputs,
                                     nominals = nominals,
                                     casOut = list(name = 'gbt_model', caslib="casuser", replace = TRUE)
        )
        models <- c(models, 'gbt')
        scores <- c(scores, cas.decisionTree.gbtreeScore)
        model_names <- c(model_names, 'Gradient Boosting')
    }
    if(nn) {
        print("Executing neural network...")
        cas.neuralNet.annTrain(conn,
                               table = list(name = model_tbl, caslib = "casuser", where = '_PartInd_ = 0'),
                               target = target,
                               inputs = inputs,
                               nominals = nominals,
                               casOut = list(name = 'nn_model', caslib="casuser", replace = TRUE)
        )
        models <- c(models, 'nn')
        scores <- c(scores, cas.neuralNet.annScore)
        model_names <- c(model_names, 'Neural Network')
    }
    
    print("models:")
    print(models)

    print("model_names")
    print(model_names)
    
    return(measure_models(models, scores, model_names))
    
}

miss <- 0

# Submethod that calculates
# ROC curve on all models selected
# above

measure_models <- function(models, scores, model_names) {
    loadActionSet(conn, "percentile")
    
    names(scores) <- models

    print("OK1")
    
    score.params <- function(model){return(list(
        object       = defCasTable(conn, model_tbl),
        modelTable   = list(name = paste0(model, '_model')),
        copyVars     = list(target, '_PartInd_'),
        assessonerow = TRUE,
        casOut       = list(name = paste0(model, '_scored'), replace = T)
    ))}
    
    print("OK2")
    lapply(models, function(x) {do.call(scores[[x]], score.params(x))})
    
    print("OK3")
    assess.model <- function(model){
        cas.percentile.assess(conn,
                              table    = list(name = paste(model,'_scored', sep=""), 
                                              where = '_PartInd_ = 1', caslib="casuser"),
                              inputs   = paste0('_', model, '_P_1'),
                              response = target,
                              event    = '1')
    }
    
    print("OK4")
    roc.df <- data.frame()
    for (i in 1:length(models)){
        tmp <- (assess.model(models[i]))$ROCInfo
        tmp$Model <- model_names[i] 
        roc.df <- rbind(roc.df, tmp)
    }
    print("OK5")
    compare <- subset(roc.df, round(as.numeric(roc.df$CutOff), 2) == 0.5)
    str(roc.df)
    print(compare)
    rownames(compare) <- NULL
    print("OK6")
    compare[,c('Model','TP','FP','FN','TN')]
    print("OK64")
    compare$Misclassification <- 1 - compare$ACC
    print("OK65")
    miss <<- compare[order(compare$Misclassification), c('Model','Misclassification')]
    rownames(miss) <- NULL
    print("OK7")
    roc.df$Models <- paste(roc.df$Model, round(roc.df$C, 3), sep = ' - ')
    plot <- ggplot(data = roc.df[c('FPR', 'Sensitivity', 'Models')],
                   aes(x = as.numeric(FPR), y = as.numeric(Sensitivity), colour = Models)) +
        geom_line() + scale_y_continuous( limits = c(0,1), expand = c(0,0) ) +
        labs(x = 'False Positive Rate', y = 'True Positive Rate')
    return(plot)
}

get_miss <- function(){
    return(miss)
}


########################################
#             Defining the UI 
#    Creating the panels and tabs 
########################################

if (interactive()) {
    ui <- fluidPage(
        titlePanel("Viya App"),
        tabsetPanel(     
            tabPanel(title = "Login",
                     sidebarLayout(
                         sidebarPanel(
                             tags$head(tags$style(type="text/css", "
                       #loadmessage {
                         position: fixed;
                          top: 50%;
                          left: 50%;
                          transform: translate(-50%, -50%);
                          width: 100%;
                          padding: 5px 0px 5px 0px;
                          text-align: center;
                          font-weight: bold;
                          font-size: 100%;
                          color: #000000;
                          background-color: rgba(0,255,0,0.5);
                       }")
                             ),
                             textInput(label = "What is your username?", inputId = "username"),
                             passwordInput(label= "What is your password?", inputId = "pwd"),
                             submitButton("Login", icon("sign-in-alt")),
                             conditionalPanel(condition="$('html').hasClass('shiny-busy')",
                                              tags$div("Loading...",id="loadmessage"))
                         ),
                         mainPanel(
                             tableOutput("connection"),
                         )
                     )
            ),
            tabPanel(title = "Import Data",
                     sidebarLayout(
                         sidebarPanel(
                             fileInput(inputId = "csv_file", label="File", multiple = FALSE, accept = NULL, width = NULL)
                         ),
                         mainPanel(
                             tableOutput("tbl_import"),
                         )
                     )
            ),
            tabPanel(title = "Verify Data",
                     sidebarLayout(
                         sidebarPanel(
                             selectInput(inputId = "library_to_explore",label = "Library Name", lst_caslibs),
                             submitButton("List Tables", icon("wpexplorer"))
                         ),
                         mainPanel(
                             tableOutput("tbl_list"),
                         )
                     ),
                     sidebarLayout(
                         sidebarPanel(
                             selectInput(inputId = "tbl_to_profile",label = "Table Name", list()),
                             #textInput(label = "Table Name", inputId = "tbl_to_profile"),
                             submitButton("Profile Data", icon("wpexplorer"))
                         ),
                         mainPanel(
                             tableOutput("tbl_profile"),
                         )
                     )
            ),
            tabPanel(title = "Explore Data",
                     sidebarLayout(
                         sidebarPanel(
                             tags$head(tags$style(type="text/css", "
                       #loading {
                         position: fixed;
                        top: 50%;
                        left: 50%;
                        transform: translate(-50%, -50%);
                        width: 100%;
                        padding: 5px 0px 5px 0px;
                        text-align: center;
                        font-weight: bold;
                        font-size: 100%;
                        color: #000000;
                        background-color: rgba(0,255,0,0.5);
                       }")
                             ),
                             selectInput(inputId = "tbl_to_explore",label = "Table Name", list()),
                             #textInput(label = "Table Name", inputId = "tbl_to_explore"),
                             submitButton("Explore Data", icon("wpexplorer")),
                             conditionalPanel(condition="$('html').hasClass('shiny-busy')",
                                              tags$div("Loading...",id="loadmessage"))
                         ),
                         mainPanel(
                             plotlyOutput("tbl_explore"),
                             plotlyOutput("tbl_cardinality")
                         )
                     )
            ),
            tabPanel(title = "Feature Enginering",
                     sidebarLayout(
                         sidebarPanel(
                             tags$head(tags$style(type="text/css", "
                       #loading {
                         position: fixed;
                          top: 50%;
                          left: 50%;
                          transform: translate(-50%, -50%);
                          width: 100%;
                          padding: 5px 0px 5px 0px;
                          text-align: center;
                          font-weight: bold;
                          font-size: 100%;
                          color: #000000;
                          background-color: rgba(0,255,0,0.5);
                       }")
                             ),
       
                             selectInput(inputId = "tbl_to_model",label = "Table Name", list()),
                             #actionButton(inputId = "Refresh_col", label = "Refresh colum"),
                             #textInput(label = "Table Name", inputId = "tbl_to_model"),
                             textInput(label = "Target Variable", inputId = "target_var"),
                             #selectInput(inputId = "target_var",label = "Target Variable", list()),
                             checkboxInput(inputId="a", label="Analyze Missing", value = FALSE, width = NULL),
                             checkboxInput(inputId="b", label="Analyze Cardinality", value = FALSE, width = NULL),
                             checkboxInput(inputId="c", label="Analyze Entropy", value = FALSE, width = NULL),
                             checkboxInput(inputId="d", label="Analyze IQV", value = FALSE, width = NULL),
                             checkboxInput(inputId="e", label="Analyze Skewness", value = FALSE, width = NULL),
                             checkboxInput(inputId="f", label="Analyze Kurtosis", value = FALSE, width = NULL),
                             checkboxInput(inputId="g", label="Analyze Outlier", value = FALSE, width = NULL),
                             
                             conditionalPanel(condition="$('html').hasClass('shiny-busy')",
                                              tags$div("Loading...",id="loading")),
                             submitButton("Generate Features", icon("wpexplorer"))
                         ),
                         mainPanel(
                             tableOutput("transformed")
                         )
                     )
            ),
            tabPanel(title = "Auto ML",
                     sidebarLayout(
                         sidebarPanel(
                             tags$head(tags$style(type="text/css", "
                       #loading {
                         position: fixed;
                        top: 50%;
                        left: 50%;
                        transform: translate(-50%, -50%);
                        width: 100%;
                        padding: 5px 0px 5px 0px;
                        text-align: center;
                        font-weight: bold;
                        font-size: 100%;
                        color: #000000;
                        background-color: rgba(0,255,0,0.5);
                       }")
                             ),
                             checkboxInput(inputId="dt", label="Decision Tree", value = FALSE, width = NULL),
                             checkboxInput(inputId="rf", label="Random Forest", value = FALSE, width = NULL),
                             checkboxInput(inputId="gb", label="Gradient Boosting", value = FALSE, width = NULL),
                             checkboxInput(inputId="nn", label="Neural Network", value = FALSE, width = NULL),
                             
                             conditionalPanel(condition="$('html').hasClass('shiny-busy')",
                                              tags$div("Loading...",id="loading")),
                             submitButton("Train Models", icon("wpexplorer"))
                         ),
                         mainPanel(
                             plotlyOutput("model_perf"),
                             tableOutput("missclass")
                         )
                     )
            )

        )
    )
    
 
    ########################################
    #         Defining R Shiny Server
    #    Creating calls to R code and 
    #    rendering it on the panels
    #    defined above on the UI
    ########################################
    
    
    server <- function(input, output, session) {
        
        output$connection <- renderTable ({
            validate(need(input$username, ''))
            validate(need(input$pwd, ''))
            c_out <- connect(input$username, input$pwd, 'CASUSER')
            updateSelectInput(session, inputId = "library_to_explore",label = "Library Name",choices = lst_caslibs)
            c_out
        })
        
        output$tbl_import <- renderTable({
            validate(need(input$csv_file, ''))
            upload_tbl(input$csv_file)
        })
        
        output$tbl_profile <- renderTable({
            validate(need(input$tbl_to_profile, ''))
            explore_tbl(input$tbl_to_profile)
        })
        

        output$tbl_list <- renderTable({
            validate(need(input$library_to_explore, ''))
            lst_tab <<- list_tables(input$library_to_explore)
            updateSelectInput(session, inputId = "tbl_to_profile",label = "Table Name",choices = lst_tab$Name)
            updateSelectInput(session, inputId = "tbl_to_explore",label = "Table Name",choices = lst_tab$Name)
            updateSelectInput(session, inputId = "tbl_to_model",label = "Table Name",choices = lst_tab$Name)
            lst_tab
        })

        
        output$tbl_explore <- renderPlotly({
            validate(need(input$tbl_to_explore, ''))
            analyze_miss(input$tbl_to_explore)
        })
        
        output$tbl_cardinality <- renderPlotly({
            validate(need(input$tbl_to_explore, ''))
            analyze_cardinality(input$tbl_to_explore)})

        
        output$transformed <- renderTable({
            validate(need(input$tbl_to_model, ''))
            validate(need(input$target_var, ''))
            feature_engineering(input$tbl_to_model,input$target_var, input$a, input$b, input$c, input$d, input$e, input$f, input$g)})
        
        output$model_perf <- renderPlotly({
            validate(need(input$dt, ''))
            auto_ml(input$dt,input$rf,input$gb,input$nn)
        })
        
        output$missclass <- renderTable({
            validate(need(input$gb, ''))
            get_miss()
        })
    }
}

shinyApp(ui, server)

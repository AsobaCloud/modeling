#!/usr/bin/Rscript

### Task to load environment for house price modeling

#Install and load easypackages for package management
install.packages("devtools")
install.packages("easypackages")
library(easypackages)
library(devtools)


#install CRAN packages
lib<-c("devtools","magrittr","caret","gbm","glmnet","randomForest","kernlab","doParallel","tidyverse","knitr","asobalife/lookr","lockedata/starters","snowflakedb/dplyr-snowflakedb","zeallot","glue","httr","jsonlite","bigrquery","dplyr")
packages(lib, prompt = FALSE)
libraries(lib)


#initialize sdk's
#source(file="/R/initializeLooker.R")
#source(file="/R/initializeSnowflake.R")
#source(file="/R/initializeBigQuery.R")

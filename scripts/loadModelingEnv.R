#!/usr/bin/Rscript

### Task to load environment for house price modeling

#Install and load easypackages for package management
install.packages("devtools")
install.packages("easypackages")
library(easypackages)
library(devtools)


#install CRAN packages
lib<-c("devtools","SDMtune","INWT/INWTUtils","Quandl","magrittr","caret","gbm","glmnet","randomForest","kernlab","doParallel","tidyverse","knitr","asobalife/lookr","rJava","dplyr","snowflakedb/dplyr-snowflakedb","zeallot","glue","httr","jsonlite","bigrquery","rich1000/lookr")
packages(lib, prompt = FALSE)
libraries(lib)


#initialize sdk's
#source(file="/R/initializeLooker.R")
#source(file="/R/initializeSnowflake.R")
#source(file="/R/initializeBigQuery.R")

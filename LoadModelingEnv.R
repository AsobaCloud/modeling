#!/usr/bin/Rscript

### Task to load environment for Ona (asobahousing) package

#Install and load easypackages for package management
install.packages("devtools")
install.packages("easypackages")
library(easypackages)
library(devtools)


#install CRAN packages
lib<-c("devtools","magrittr","caret","gbm","glmnet","randomForest","kernlab","doParallel","asobalife/lookr")
packages(lib, prompt = FALSE)
libraries(lib)

#install asobahousing package
install_github("asobalife/ona")

#initialize sdk's
source(file="~/ona_environment/sdk/Looker/initializeLooker.R")
source(file="~/ona_environment/sdk/Snowflake/initializeSnowflake.R")


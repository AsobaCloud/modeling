## R interface to BigQuery

#install.packages("bigrquery")
library(bigrquery)



# Provide authentication
bq_auth(use_oob = TRUE)

#define connection parameters
projectid <- "24440683188"
datasetid <- "house_price_model"
bq_conn <-  dbConnect(bigquery(),
                      project = projectid,
                      dataset = datasetid,
                      use_legacy_sql = FALSE
)

# list available tables
#bigrquery::dbListTables(bq_conn)

# example save a dataframe to a new table created on the fly
#renter_costs_CA <- bq_table(projectid,datasetid,table="renter_costs_CA")
#bq_table_upload(renter_costs_CA,rents,quiet=FALSE,fields=as_bq_fields(rents))

#Script to combine multi-year Census Datasets
install.packages("janitor")
library(dplyr)
library(readr)
library(janitor)

### Create dataframe with all of the CSV's
### note, each CSV must have the same header values

df <- list.files(path="/Users/shingisamudzi/Downloads/Median Income CA/med", full.names = TRUE) %>% 
      lapply(read_csv) %>% 
      bind_rows

df <- make_clean_names(df)



# clean up the column names to make them BigQuery compliant

names(df) = make_clean_names(df)

names(df) <- gsub(x = names(df), pattern = "\\;\\.\\-\\", replacement = "_") 

# make names lowercase


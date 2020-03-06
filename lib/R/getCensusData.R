
### Pull all years of a specific statistic from the US Census data

#' `getCensusDataAllYears` function calls on `censusapi::listCensusApis` to identify the years the data is available for a target statistic and loops through each year by calling `censusapi::getCensus`.
#' Error handling, messaging prompts, and timing have been added.
#' Refer for more details here https://cran.r-project.org/web/packages/censusapi/vignettes/getting-started.html
#' 
#' @param censusStats (character) this will be passed on to the `name` parameter when calling `censusapi::getCensus` function
#' @param vars (character) this will be passed on to the `vars` parameter when calling `censusapi::getCensus` function
#' @param region (character) this will be passed on to the `region` parameter when calling `censusapi::getCensus` function
#' @param regionin (character) this will be passed on to the `regionin` parameter when calling `censusapi::getCensus` function
#' @param ST (character) this will be passed on to the `ST` parameter when calling `censusapi::getCensus` function
#' @param apiKey (character) this will be passed on to the `key` parameter when calling `censusapi::getCensus` function
#' @return (data frame) a data.frame containing all years of available data for the target statitics
#' @export


#Load relevant libraries

library(dplyr)
library(tictoc)
library(censusapi)

# Add key to .Renviron
Sys.setenv(CENSUS_KEY="5f7e600cffb6db8ddc21129cda45a74ce7447bcc")

getCensusDataAllYears <- function(censusStats,vars,region,regionin = NULL,ST = NULL,apiKey = Sys.getenv("CENSUS_KEY")){
  cat(paste("\nPulling data for",censusStats,"statistics...\n"))
  tictoc::tic(paste(censusStats,"statistics for all avaiable years have been completed."))
  years <- censusapi::listCensusApis() %>% 
    dplyr::filter(name == censusStats) %>% 
    dplyr::pull(vintage) %>% 
    sort()
  yearMin <- min(years)
  yearMax <- max(years)
  yearLength <- length(years)
  cat(paste(censusStats,"statistics has",yearLength,"years of Census data from",yearMin,"to",yearMax,"available to be accessed...\n"))
  censusData <- years %>% 
    purrr::map_dfr(
      function(year){
        cat(paste("\nPulling data for",year,censusStats,"statistics...\n"))
        tictoc::tic(paste("Data pull for",year,censusStats,"statistics completed..."))
        getCensusError <- FALSE
        data <- tryCatch(
          censusapi::getCensus(
            name = censusStats
            ,vars = vars
            ,region = region
            ,vintage = year
            ,key = apiKey
            ,regionin = regionin
            ,ST = ST) %>% 
            dplyr::mutate(YEAR = year),
          error = function(cond){
            message(paste("ERROR ENCOUNTERED:\n",cond))
            return(NULL)
          }
        )
        if(is.null(data)){
          tictoc::toc(quiet = T)
          cat(paste("\nEncountered errors when pulling data for",year,censusStats,"statistics...\n"))
        } else {
          tictoc::toc()
          cat("Total records:",nrow(data),"\n")
        }
        return(data)
      }
    ) %>% 
    dplyr::select(c(vars,"YEAR"))
  cat("\n")
  tictoc::toc()
  return(censusData)
}


# EXAMPLE USE: Getting ZBP census data
get_zbp_census <- function(censusStats="zbp"
                           ,vars = c("EMP","ESTAB","PAYANN","ZIPCODE")
                           ,region = "zipcode"
                           ,apiKey = "5f7e600cffb6db8ddc21129cda45a74ce7447bcc"
                           ,ST = "06"){
  data <- getCensusDataAllYears(
    censusStats = censusStats
    ,vars = vars
    ,region = region
    ,apiKey = apiKey
    ,ST = ST)
  return(data)
}

# EXAMPLE USE: Getting NONEMP census data
get_nonemp_census <- function(censusStats="nonemp"
                              ,vars =  c("COUNTY","NESTAB","NRCPTOT","ST")
                              ,region = "county"
                              ,regionin = "state:06"
                              ,apiKey = "5f7e600cffb6db8ddc21129cda45a74ce7447bcc"){
  data <- getCensusDataAllYears(
    censusStats = censusStats
    ,vars = vars
    ,region = region
    ,regionin = regionin
    ,apiKey = apiKey)
  return(data)
}

# EXECUTE
# zbp_data <- get_zbp_census()
# nonemp_data <- get_nonemp_census()

## Schooldigger API

library(httr)
library(jsonlite)
library(tidyverse)


######################################################################
# create function for saving state-specific school scores for a given year
# x is the year (ie from 2004 to 2019), y is the state (use "CA"), p is the page number
getSchoolScores <- function(x, y, p){
      ddata <<- data.frame()
      url <-paste0("https://api.schooldigger.com/v1.2/rankings/schools/", y, "?year=", x, "&page=", p, "&perPage=50&appID=14ea1018&appKey=ffd7197ea67cbc356aaa663385321128")
      json_data  <- fromJSON(url)
      ddata <<- json_data$schoolList
      return(ddata)
}

###########################################################
# functiont that gets the first row of rankHistory
get_first_row = function(each){
   return(each[1, ])
}

###########################################################
# function that gets a dataframe from school list of a year.
get_one = function(schoolList){
   address = schoolList$address
   latLong = address$latLong
   address$latLong = NULL

   district = schoolList$district
   colnames(district)[3] = "url_district"  #changing the column name
   county = schoolList$county

   details = schoolList$schoolYearlyDetails
   details = map_df(details, data.frame)

   rank_history = schoolList$rankHistory
   rank_history = map_df(rank_history, get_first_row)
   rank_history$year = NULL

   schoolList$address = NULL
   schoolList$rankHistory = NULL
   schoolList$district = NULL
   schoolList$county = NULL
   schoolList$schoolYearlyDetails = NULL

   final = cbind(schoolList, address, latLong, district, county, details, rank_history)

   return(final)
}

# function that gets data for all pages in a single year.
get_all_page_single_year = function(x, y = "CA", number_of_pages){
   all_pages = data.frame()
   for(i in 1:number_of_pages){
      print(glue::glue("page {i}"))
      schoolList = getSchoolScores(x, y, i)
      single_page = get_one(schoolList)
      all_pages = rbind(all_pages, single_page)
   }
   return(all_pages)
}



####################################################
# get the number of pages, total number of obs for each year. it is saved in a data frame in an RDS file named pages.
# no need to run the loop

# x = 2017
# y = "CA"
# p = 1
# pages = numeric()
# total = numeric()
# for(i in seq_along(years)){
#    x = years[i]
#    url <-paste0("https://api.schooldigger.com/v1.2/rankings/schools/",y,"?year=",x,"&page=",p,"&perPage=50&appID=14ea1018&appKey=ffd7197ea67cbc356aaa663385321128")
#    json_data  <- fromJSON(url)
#    print(years[i])
#    pages = c(pages, json_data[[5]])
#    total = c(total, json_data[[4]])
# }
#
# ypt_data = data.frame(years, pages, total)
# saveRDS(ypt_data, "ypt_data.RDS")


##############################################################
# getting it all together.


ypt_data = readRDS("./ypt_data.RDS")


#q = 7:10
#yp = ypt_data[q, ]

# getting all the data
final = data.frame()
for(i in seq_along(ypt_data$years)){
   print(glue::glue("year {yp$years[i]}"))
   single_year = get_all_page_single_year(x = ypt_data$years[i], y = "CA", ypt_data$pages[i])
   final = rbind(final, single_year)
}



write_csv(final, "./schoolList_all_years.csv")

#f1 = readRDS("./upto_2007.RDS")

#saveRDS(f1, "upto_2007.RDS")
#saveRDS(f2, "from_2008_to_2015.RDS")

#saveRDS(final, "from_2016_to_last.RDS")





##############################################################








# looping years and add all to a single dataframe


# json <- do.call(rbind.data.frame,
#              lapply(years$years,
#                     function (i){
#                         json  <- fromJSON(paste0('https://api.schooldigger.com/v1.2/rankings/schools/CA?year=',i,'&level=High&appID=14ea1018&appKey=ffd7197ea67cbc356aaa663385321128'))
#                         print(json)
#                         Sys.sleep(30)
#                       }
#
#
#              ))

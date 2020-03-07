
library(httr)
library(tidyverse)
library(glue)
library(zeallot)

#######################################################################
### function that creates the url according to stock and endpoint required
get_url <- function(stock, endpoint = c("income", "balance_sheet", "cash_flow")) {
    endpoint = match.arg(endpoint)
    url = case_when(
        endpoint == "income" ~ 'https://financialmodelingprep.com/api/v3/financials/income-statement',
        endpoint == "balance_sheet" ~ 'https://financialmodelingprep.com/api/v3/financials/balance-sheet-statement',
        endpoint == "cash_flow" ~ 'https://financialmodelingprep.com/api/v3/financials/cash-flow-statement'
    )
    url = glue("{url}/{stock}")
    return(url)
}

### function to get single data
get_single_data <- function(url) {

    headers = c(`Upgrade-Insecure-Requests` = '1')
    params = list(`datatype` = 'json')

    res = httr::GET(url = url, httr::add_headers(.headers=headers), query = params)
    content = content(res)
    financials = content$financials
    data = map_df(financials, data.frame)
    return(data)
}

### function that gets the 3 data frames in a list
get_all_data <- function(stock) {

    endpoints = c("income", "balance_sheet", "cash_flow")
    urls = map(endpoints, get_url, stock = stock)
    data = map(urls, get_single_data)
    names(data) = endpoints
    return(data)
}


###############################################
### Example

# aapl = get_all_data("AAPL")
# aapl$income
# aapl$balance_sheet
# apl$cash_flow

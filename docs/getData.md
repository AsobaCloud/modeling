#Accessing Preprocessed Datasets

A quick way to get data out of Ona’s Looker instance into R
Returns a data frame (well actually it's a tibble) with all data from specified Look.
##set up
You will first need to create a file ~/.Renviron with the following variables:
LOOKER_API_PATH = 'https://data.asoba.co:19999/api/3.1'
LOOKER_CLIENT_ID = 'v53XyrTCYKrqxkRDwt4y'
LOOKER_CLIENT_SECRET = 'J949yjq7hP5x8ggkSQWmW2Xx'
##installation
    install.packages('devtools')
    library('devtools')
    install_github('rich1000/lookr')
##usage
    library(lookr)
    
    df = get_look(look_id = 123)  # default row limit of 500
    
    df = get_look(look_id = 123, limit = 10000)  # custom row limit
    
    df = get_look(look_id = 123, limit = -1)  # without row limit

And that's it, there are no other functions!
##looks
- Look 97 - Home Sales Fact Table
- Look 100 - Household Size by Tenure
- Look 95 - Households with Investment Income
- Look 102 - Housing Costs
- Look 93 - Housing Vacancy
- Look 92 - Labor Participation
- Look 94 - Median Age
- Look 101 - Median Income by Age
- Look 103 - Payroll and Local Employment
- Look 91 - Quarterly HPI by ZipCode
- Look 98 - Resident Ownership Status
- Look 96 - School Rankings



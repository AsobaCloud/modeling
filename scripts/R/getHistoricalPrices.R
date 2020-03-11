

## function to get the Open/Close prices for selected time frame
## inputs: stock, stock code
## time: time frame, accepted values {“5y”(default), “2y”, “1y”, “ytd”, “6m”, “3m”, “1m”, “1d”}
## sk: secret key.
## path: the path to save the data. Defaults to current working directory.
get_open_close_data = function(stock, time = "5y", sk = "sk_1bef956c797b4d08945e0240b5bfaadd", path = "./") {
    data = iex.chart(stock, time, sk)
    data1 = data.frame(Date = index(data), coredata(data))
    readr::write_csv(data1, glue::glue("{path}{stock}_{time}_data.csv"))
    return(data1)
}

## Example
GM = get_open_close_data(stock = "GM")

############################################################################

## function to get pE ratio
## inputs: stock & sk
get_pe_ratio = function(stock, sk = "sk_1bef956c797b4d08945e0240b5bfaadd") {
    book = iex.book(stock, sk)
    return(book[book$Field == "peRatio", ])
}

## Example
GM_pe = get_pe_ratio(stock = "GM")


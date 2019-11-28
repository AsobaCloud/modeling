# Connect with Snowflake datawarehouse

library("dplyr")
library(dplyr.snowflakedb)

#Setting environment variables
options(dplyr.jdbc.classpath = "~/ona_environment/lib/snowflake-jdbc-3.9.2.jar") 

connect_var <- src_snowflakedb(user="shingilooker", 
                              password="EBuUCdFzLpa5FPX", 
                              account="qj88169", 
                              host="https://qj88169.snowflakecomputing.com", 
                              opts=list(db="US_CENSUS", 
                                        warehouse="COMPUTE_WH", 
                                        schema="PUBLIC"))
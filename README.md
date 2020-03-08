# Readme

## purpose

This is a containerized environment for the basic ingest, preprocessing, and storage of datasets used
for economic and complexity modeling purposes.  The family of functions and packages within this environment support projects focused on modeling macroeconomic trends as well as agent-based modeling/microeconomic simulations

## Contents

There are several folders with home-cooked and modified scripts for data cleansing related tasks using Python, Shell, R and SQL scripts.  Modeling cookbooks, guides, and ABMs build for Netlogo are also provided in the docs folder.

## transformation and storage

Data here will be generally be stored in BigQuery, Snowflake, or other SQL-based database/MPPdb.  Additional transformations may be made "in-database" via ETL, or using data modeling tools such as Looker or Meltano.

## languages

Core technologies in use are R, Python, SQL, and Shell scripts

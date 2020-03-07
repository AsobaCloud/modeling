#Find in the 2016 business patterns by zip code table all of the zip codes (with county #name and state) where there is no single dominant industry

DROP TABLE IF EXISTS bp_2016_diverse;

CREATE TABLE  bp_2016_diverse AS
(SELECT bp_2016.zip, COUNTYNAME, STATE FROM bp_2016
JOIN zip2all
ON bp_2016.zip = zip2all.ZIP
WHERE `11`/`0` and `21`/`0` and `22`/`0` and `23`/`0` and `42`/`0` and `51`/`0` and `52`/`0` and `53`/`0` and `54`/`0` and `55`/`0` and `56`/`0` and `61`/`0` and `62`/`0` and `71`/`0` and `72`/`0` and `81`/`0` and `99`/`0` and `31-33`/`0` and `44-45`/`0` and `48-49`/`0` < 0.4);


#Determine the percentage of current population that are 'immigrants' (not born in state)
DROP TABLE IF EXISTS imm_stats_2017;

CREATE TABLE imm_stats_2017 AS
(SELECT d.zip as ZCTA, d.COUNTYNAME as County, (1-(f.HD01_VD13/f.HD01_VD01))*100 as Perc_Immigrant_TotalPop, (1-(f.HD01_VD23/f.HD01_VD12))*100 as Perc_Immigrant_HIPop, f.`GEO.id2` as Census_Tract
FROM bp_2016_diverse d
JOIN tract2zip ON d.zip = tract2zip.zip
JOIN fileB06010 f ON f.`GEO.id2` = tract2zip.tract
WHERE f.HD01_VD12 != 0);


#Find the % of population under 18
DROP TABLE IF EXISTS imm_age_stats_2017;

CREATE TABLE imm_age_stats_2017 AS
(SELECT County, ZCTA, ROUND(Perc_Immigrant_TotalPop,0) as `%_Immigrant`, ROUND(Perc_Immigrant_HIPop,0) as `HI_%_Immigrant`, Census_Tract, ROUND(100-HC01_EST_VC28,0) as `%_Under18`
FROM imm_stats_2017
JOIN fileS0101 ON fileS0101.`GEO.id2` =imm_stats_2017.Census_Tract
ORDER BY County);

#Find the % of total occupied units that are renter-occupied
DROP TABLE IF EXISTS imm_age_housing_stats_2017;

CREATE TABLE imm_age_housing_stats_2017 AS
(SELECT County, ZCTA, `%_Immigrant`, `HI_%_Immigrant`, Census_Tract, `%_Under18`, ROUND(((f.HC03_EST_VC01/f.HC01_EST_VC01)*100),0) as `%_Units_Rented`,ROUND(f.HC01_EST_VC12,0) as `%_Units_NewlyBuilt`
FROM imm_age_stats_2017
JOIN fileS2504 f ON f.`GEO.id2` =imm_age_stats_2017.Census_Tract
WHERE f.HC01_EST_VC01 != 0
ORDER BY County);

#Add HPI information

DROP TABLE IF EXISTS imm_age_housing_stats;

CREATE TABLE imm_age_housing_stats AS
(SELECT i.*, h.`2014`, h.`2015`, h.`2016`, h.`2017` FROM us_census.imm_age_housing_stats_2017 i
JOIN (SELECT * FROM us_census.HPIstats
WHERE `2014` !=0 AND `2015` !=0 AND `2016` !=0 AND `2017` !=0) h
ON i.Census_Tract = h.tractid); 

#Focus specifically on the census tracts that are in opportunity zones
DROP TABLE IF EXISTS tract_analysis;

CREATE TABLE tract_analysis AS
(SELECT i.*, o.LIC_Qual, o.Poverty_Rate, o.MedInc_Bench FROM
us_census.imm_age_housing_stats i
LEFT JOIN opportunity_zone o
ON i.Census_Tract = o.tract);

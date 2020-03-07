#!/bin/sh

MYSQL_ARGS="--defaults-file=/etc/mysql/debian.cnf"
DB="us_census"
DELIM=","

CSV="$1"
TABLE="$2"

[ "$CSV" = "" -o "$TABLE" = "" ] && echo "Syntax: $0 csvfile tablename" && exit 1

FIELDS=$(head -1 "$CSV" | sed -e 's/'$DELIM'/` varchar(255),\n`/g' -e 's/\r//g')
FIELDS='`'"$FIELDS"'` varchar(255)'

#echo "$FIELDS" && exit

mysql $MYSQL_ARGS $DB -e "
DROP TABLE IF EXISTS $TABLE;
CREATE TABLE $TABLE ($FIELDS);

LOAD DATA INFILE '$(pwd)/$CSV' INTO TABLE $TABLE
FIELDS TERMINATED BY '$DELIM'
IGNORE 1 LINES
;
"

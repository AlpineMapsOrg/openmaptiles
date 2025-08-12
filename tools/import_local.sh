#!/bin/bash

# this script imports the full.sql to your local postgres repo
# ideally this should also work for any server

# set current working directory to root of openmaptiles repo
cd "$(dirname "$0")"

# start local postgres
sudo service postgresql start

# 
psql -U postgres postgres < import_local.sql

# country grid sql contains some meta data not available in the full.sql export (e.g. administration boundaries), but full.sql depends on it
wget https://www.nominatim.org/data/country_grid.sql.gz
gzip -d "country_grid.sql.gz"
psql -U openmaptiles openmaptiles < country_grid.sql

# import the full.sql
psql -U openmaptiles openmaptiles < full.sql 
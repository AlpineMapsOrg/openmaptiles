#!/bin/bash

# 
psql -U postgres postgres < import.sql

# country grid sql contains some meta data not available in the full.sql export (e.g. administration boundaries), but full.sql depends on it
wget https://www.nominatim.org/data/country_grid.sql.gz
gzip -d "country_grid.sql.gz"
psql -U martin openmaptiles < country_grid.sql

# import the full.sql
psql -U martin openmaptiles < full.sql 
#!/bin/bash

# set current working directory to root of openmaptiles repo
cd "$(dirname "$0")"
cd ../

# stop local postgres
# if you do not have this service just comment it out -> this just makes sure that start-db comment does not conflict
sudo service postgresql stop

# start postgres docker
make start-db



docker exec -it openmaptiles-postgres-1 pg_dump -U openmaptiles -d openmaptiles > tools/full.sql

# remove disabling of search path -> by doing this we can find country_grid.sql public schemas
sed -i "s/SELECT pg_catalog.set_config('search_path', '', false);/-- SELECT pg_catalog.set_config('search_path', '', false);/" tools/full.sql 


# stop postgres docker again
make stop-db
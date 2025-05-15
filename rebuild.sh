#!/bin/bash

# stop postgresql if it is running
sudo service postgresql stop


## deep clean all -> by destroying all containers we force all data to be redone
make destroy-db
make stop-db
make clean-unnecessary-docker
make remove-docker-images
make refresh-docker-images


mkdir -p log

# clear build/ directory
echo "clean"
make clean |& tee log/1-clean.txt
echo "make"
make |& tee log/2-make.txt

echo "start-db"
# if we changed a mapping.yaml this is necessary
make start-db |& tee log/3-db.txt

echo "import-data"
# if we changed a mapping.yaml this is necessary
make import-data |& tee log/4-data.txt


# if we changed a mapping.yaml this is necessary
echo "import-osm"
make import-osm |& tee log/5-osm.txt

echo "import-wikidata"
make import-wikidata |& tee log/6-wikidata.txt

echo "import-sql"
# if we changed a .sql file this is necessary
make import-sql |& tee log/7-sql.txt

echo "combining logs"
# combine logs
cat log/1-clean.txt log/2-make.txt log/3-db.txt log/4-data.txt log/5-osm.txt log/6-wikidata.txt log/7-sql.txt > log/all.txt
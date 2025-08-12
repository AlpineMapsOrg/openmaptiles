DROP DATABASE IF EXISTS openmaptiles;
CREATE DATABASE openmaptiles;
CREATE USER openmaptiles PASSWORD 'openmaptiles';
GRANT ALL PRIVILEGES ON DATABASE openmaptiles TO openmaptiles;
\c openmaptiles
GRANT CREATE,USAGE ON SCHEMA public TO openmaptiles;
CREATE EXTENSION postgis;
CREATE EXTENSION hstore;
CREATE EXTENSION gzip;
\q
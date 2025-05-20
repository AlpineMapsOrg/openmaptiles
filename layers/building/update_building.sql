DROP TRIGGER IF EXISTS trigger_refresh ON buildings.updates;
DROP TRIGGER IF EXISTS trigger_flag ON osm_building_polygon;

-- Creating aggregated building blocks with removed small polygons and small
-- holes. Aggregated polygons are simplified by Visvalingam-Whyatt algorithm.
-- Aggregating is made block by block using country_osm_grid polygon table.

-- Function returning recordset for matview.
-- Returning recordset of buildings aggregates by zres 14, with removed small
-- holes and with removed small buildings/blocks.

CREATE OR REPLACE FUNCTION osm_building_block_gen(zoom int)
    RETURNS table
            (
                osm_id   bigint,
                geometry geometry
            )
AS
$$
DECLARE
    zres_big float := Zres(zoom+1);
    zres_small float := Zres(zoom-1);
    zres_big_vw float := Zres(zoom+1) * Zres(zoom+1);
    polyg_world record;

BEGIN
    FOR polyg_world IN 
        SELECT ST_Transform(country.geometry, 3857) AS geometry 
        FROM country_osm_grid country
        
        LOOP
            FOR osm_id, geometry IN
                WITH dta AS ( -- CTE is used because of optimization
                    SELECT o.osm_id,
                            o.geometry,
                            ST_ClusterDBSCAN(o.geometry, eps := zres_big, minpoints := 1) OVER () cid
                    FROM osm_building_polygon o
                    WHERE ST_Intersects(o.geometry, polyg_world.geometry)
                )
                SELECT (array_agg(dta.osm_id))[1] AS osm_id,
                    ST_Buffer(
                        ST_Union(
                            ST_Buffer(
                                ST_SnapToGrid(dta.geometry, 0.000001)
                                , zres_big, 'join=mitre')
                            )
                        , -zres_big, 'join=mitre') AS geometry
                FROM dta
                GROUP BY cid

                LOOP
                    -- removing holes smaller than
                    IF ST_NumInteriorRings(geometry) > 0 THEN -- only from geometries wih holes
                        geometry := (
                            -- there are some multi-geometries in this layer
                            SELECT ST_Collect(gn)
                            FROM (
                                    -- in some cases are "holes" NULL, because all holes are smaller than
                                    SELECT COALESCE(
                                                -- exterior ring
                                                    ST_MakePolygon(ST_ExteriorRing(dmp.geom), holes),
                                                    ST_MakePolygon(ST_ExteriorRing(dmp.geom))
                                                ) gn

                                    FROM ST_Dump(geometry) dmp, -- 1 dump polygons
                                        LATERAL (
                                            SELECT array_agg(ST_Boundary(rg.geom)) holes -- 2 create array
                                            FROM ST_DumpRings(dmp.geom) rg -- 3 from rings
                                            WHERE rg.path[1] > 0 -- 5 except inner ring
                                                AND ST_Area(rg.geom) >= power(zres_small, 2) -- 4 bigger than
                                            ) holes
                                ) new_geom
                        );
                    END IF;

                    IF ST_Area(geometry) < power(zres_small, 2) THEN
                        CONTINUE;
                    END IF;

                    -- simplify
                    geometry := ST_SimplifyVW(geometry, zres_big_vw);

                    RETURN NEXT;
                END LOOP;
        END LOOP;
END;
$$ LANGUAGE plpgsql STABLE
                    STRICT
                    PARALLEL SAFE;



DROP MATERIALIZED VIEW IF EXISTS osm_building_block_gen16 CASCADE;

CREATE MATERIALIZED VIEW osm_building_block_gen16 AS
SELECT *
FROM osm_building_block_gen(16);

CREATE INDEX ON osm_building_block_gen16 USING gist (geometry);



DROP MATERIALIZED VIEW IF EXISTS osm_building_block_gen15 CASCADE;

CREATE MATERIALIZED VIEW osm_building_block_gen15 AS
SELECT *
FROM osm_building_block_gen(15);

CREATE INDEX ON osm_building_block_gen15 USING gist (geometry);



DROP MATERIALIZED VIEW IF EXISTS osm_building_block_gen14 CASCADE;

CREATE MATERIALIZED VIEW osm_building_block_gen14 AS
SELECT *
FROM osm_building_block_gen(14);

CREATE INDEX ON osm_building_block_gen14 USING gist (geometry);




DROP MATERIALIZED VIEW IF EXISTS osm_building_block_gen13 CASCADE;

CREATE MATERIALIZED VIEW osm_building_block_gen13 AS
SELECT *
FROM osm_building_block_gen(13);

CREATE INDEX ON osm_building_block_gen13 USING gist (geometry);




DROP MATERIALIZED VIEW IF EXISTS osm_building_block_gen_z16;
CREATE MATERIALIZED VIEW osm_building_block_gen_z16 AS
(
WITH 
    counts AS (
        SELECT count(osm_id) AS counts,
                osm_id
        FROM osm_building_block_gen16
    GROUP BY osm_id
    ),

    duplicates AS (
        SELECT counts.osm_id
        FROM counts
        WHERE counts.counts > 1
    )

SELECT osm.osm_id,
        ST_Union(
            ST_MakeValid(osm.geometry)) AS geometry
    FROM osm_building_block_gen16 osm,
            duplicates
    WHERE osm.osm_id = duplicates.osm_id
    GROUP BY osm.osm_id
    
    UNION ALL

    SELECT osm.osm_id, 
            osm.geometry 
    FROM osm_building_block_gen16 osm, 
            counts 
    WHERE counts.counts = 1 
        AND osm.osm_id = counts.osm_id
);

CREATE INDEX ON osm_building_block_gen_z16 USING gist (geometry);
CREATE UNIQUE INDEX ON osm_building_block_gen_z16 USING btree (osm_id);




DROP MATERIALIZED VIEW IF EXISTS osm_building_block_gen_z15;
CREATE MATERIALIZED VIEW osm_building_block_gen_z15 AS
(
WITH 
    counts AS (
        SELECT count(osm_id) AS counts,
                osm_id
        FROM osm_building_block_gen15
    GROUP BY osm_id
    ),

    duplicates AS (
        SELECT counts.osm_id
        FROM counts
        WHERE counts.counts > 1
    )

SELECT osm.osm_id,
        ST_Union(
            ST_MakeValid(osm.geometry)) AS geometry
    FROM osm_building_block_gen15 osm,
            duplicates
    WHERE osm.osm_id = duplicates.osm_id
    GROUP BY osm.osm_id
    
    UNION ALL

    SELECT osm.osm_id, 
            osm.geometry 
    FROM osm_building_block_gen15 osm, 
            counts 
    WHERE counts.counts = 1 
        AND osm.osm_id = counts.osm_id
);

CREATE INDEX ON osm_building_block_gen_z15 USING gist (geometry);
CREATE UNIQUE INDEX ON osm_building_block_gen_z15 USING btree (osm_id);




DROP MATERIALIZED VIEW IF EXISTS osm_building_block_gen_z14;
CREATE MATERIALIZED VIEW osm_building_block_gen_z14 AS
(
WITH 
    counts AS (
        SELECT count(osm_id) AS counts,
                osm_id
        FROM osm_building_block_gen14
    GROUP BY osm_id
    ),

    duplicates AS (
        SELECT counts.osm_id
        FROM counts
        WHERE counts.counts > 1
    )

SELECT osm.osm_id,
        ST_Union(
            ST_MakeValid(osm.geometry)) AS geometry
    FROM osm_building_block_gen14 osm,
            duplicates
    WHERE osm.osm_id = duplicates.osm_id
    GROUP BY osm.osm_id
    
    UNION ALL

    SELECT osm.osm_id, 
            osm.geometry 
    FROM osm_building_block_gen14 osm, 
            counts 
    WHERE counts.counts = 1 
        AND osm.osm_id = counts.osm_id
);

CREATE INDEX ON osm_building_block_gen_z14 USING gist (geometry);
CREATE UNIQUE INDEX ON osm_building_block_gen_z14 USING btree (osm_id);





-- etldoc: osm_building_polygon -> osm_building_block_gen_z13
DROP MATERIALIZED VIEW IF EXISTS osm_building_block_gen_z13;
CREATE MATERIALIZED VIEW osm_building_block_gen_z13 AS
(
WITH 
    counts AS (
        SELECT count(osm_id) AS counts,
		        osm_id
	    FROM osm_building_block_gen13
	GROUP BY osm_id
    ),

    duplicates AS (
        SELECT counts.osm_id
	    FROM counts
	    WHERE counts.counts > 1
    )

SELECT osm.osm_id,
		ST_Union(
            ST_MakeValid(osm.geometry)) AS geometry
	FROM osm_building_block_gen13 osm,
			duplicates
	WHERE osm.osm_id = duplicates.osm_id
	GROUP BY osm.osm_id
	
	UNION ALL

	SELECT osm.osm_id, 
			osm.geometry 
	FROM osm_building_block_gen13 osm, 
            counts 
	WHERE counts.counts = 1 
		AND osm.osm_id = counts.osm_id
);

CREATE INDEX ON osm_building_block_gen_z13 USING gist (geometry);
CREATE UNIQUE INDEX ON osm_building_block_gen_z13 USING btree (osm_id);



-- Handle updates

CREATE SCHEMA IF NOT EXISTS buildings;

CREATE TABLE IF NOT EXISTS buildings.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);

CREATE OR REPLACE FUNCTION buildings.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO buildings.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION buildings.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh buildings block';
    REFRESH MATERIALIZED VIEW osm_building_block_gen16;
    REFRESH MATERIALIZED VIEW osm_building_block_gen_z16;
    REFRESH MATERIALIZED VIEW osm_building_block_gen15;
    REFRESH MATERIALIZED VIEW osm_building_block_gen_z15;
    REFRESH MATERIALIZED VIEW osm_building_block_gen14;
    REFRESH MATERIALIZED VIEW osm_building_block_gen_z14;
    REFRESH MATERIALIZED VIEW osm_building_block_gen13;
    REFRESH MATERIALIZED VIEW osm_building_block_gen_z13;
    -- noinspection SqlWithoutWhere
    DELETE FROM buildings.updates;

    RAISE LOG 'Update buildings block done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_building_polygon
    FOR EACH STATEMENT
EXECUTE PROCEDURE buildings.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON buildings.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE buildings.refresh();
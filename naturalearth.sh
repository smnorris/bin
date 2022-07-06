#!/bin/bash
set -euxo pipefail

# load select natural earth data to postgis

CULTURAL="ne_10m_admin_0_countries \
    ne_10m_admin_1_states_provinces"

psql $DATABASE_URL -c "create schema if not exists natural_earth"

for LYR in $CULTURAL ; do
    ogr2ogr \
        -f PostgreSQL \
        PG:$DATABASE_URL \
        /vsicurl/https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/10m_cultural/$LYR.shp \
        -nln natural_earth.$LYR \
        -lco OVERWRITE=YES \
        -lco GEOMETRY_NAME=geom \
        -nlt PROMOTE_TO_MULTI

done

PHYSICAL="ne_10m_coastline \
    ne_10m_lakes \
    ne_10m_lakes_north_america \
    ne_10m_land \
    ne_10m_minor_islands \
    ne_10m_ocean \
    ne_10m_rivers_lake_centerlines \
    ne_10m_rivers_north_america"

for LYR in $PHYSICAL ; do
    ogr2ogr \
        -f PostgreSQL \
        PG:$DATABASE_URL \
        /vsicurl/https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/10m_physical/$LYR.shp \
        -nln natural_earth.$LYR \
        -lco OVERWRITE=YES \
        -lco GEOMETRY_NAME=geom \
        -nlt PROMOTE_TO_MULTI
done
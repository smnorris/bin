#!/bin/bash
set -euxo pipefail

# load parcel fabric to postgis

TMP=~/tmp

wget --trust-server-names -qNP "$TMP" https://pub.data.gov.bc.ca/datasets/4cf233c2-f020-4f7a-9b87-1923252fbc24/pmbc_parcel_fabric_poly_svw.zip

unzip $TMP/pmbc_parcel_fabric_poly_svw.zip -d $TMP

psql -c "CREATE SCHEMA IF NOT EXISTS whse_cadastre"

# load to pg
ogr2ogr \
   -progress \
   --config PG_USE_COPY YES \
   -t_srs EPSG:3005 \
   -dim XY \
   -f PostgreSQL \
   PG:"$PGOGR" \
   -overwrite \
   -lco GEOMETRY_NAME=geom \
   -lco FID=PARCEL_FABRIC_POLY_ID \
   -nln whse_cadastre.pmbc_parcel_fabric_poly_svw \
   $TMP/pmbc_parcel_fabric_poly_svw.gdb \
   pmbc_parcel_fabric_poly_svw

# cleanup
rm $TMP/pmbc_parcel_fabric_poly_svw.zip
rm -r $TMP/pmbc_parcel_fabric_poly_svw.gdb
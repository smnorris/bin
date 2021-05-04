#!/bin/bash
set -euxo pipefail

# load BC forest cover to postgis

TMP=~/Downloads

psql -c "CREATE SCHEMA IF NOT EXISTS whse_forest_vegetation"

wget --trust-server-names -qNP "$TMP" https://pub.data.gov.bc.ca/datasets/02dba161-fdb7-48ae-a4bb-bd6ef017c36d/current/VEG_COMP_LYR_R1_POLY_2020.gdb.zip
wget --trust-server-names -qNP "$TMP" https://pub.data.gov.bc.ca/datasets/02dba161-fdb7-48ae-a4bb-bd6ef017c36d/2019/VEG_COMP_LYR_R1_POLY_2019.gdb.zip
wget --trust-server-names -qNP "$TMP" https://pub.data.gov.bc.ca/datasets/02dba161-fdb7-48ae-a4bb-bd6ef017c36d/2018/VEG_COMP_LYR_R1_POLY_2018.gdb.zip


# just unzipping the files is problematic, zip doesn't like the large archives.
# This temp file workaround does the job:
# https://stackoverflow.com/questions/31481701/how-to-extract-files-from-a-large-30gb-zip-file-on-linux-server

# extract and load to pg
echo "Loading 2020 VEG_COMP_LYR_R1_POLY"
zip -FF $TMP/VEG_COMP_LYR_R1_POLY_2020.gdb.zip --out tmp.zip -fz
unzip tmp.zip
ogr2ogr \
   -progress \
   --config PG_USE_COPY YES \
   -t_srs EPSG:3005 \
   -dim XY \
   -f PostgreSQL \
   PG:"$PGOGR" \
   -overwrite \
   -lco GEOMETRY_NAME=geom \
   -lco SPATIAL_INDEX=NONE \
   -lco FID=FEATURE_ID \
   -lco FID64=TRUE \
   -nln whse_forest_vegetation.veg_comp_lyr_r1_poly \
   VEG_COMP_LYR_R1_POLY_2020.gdb \
   VEG_COMP_LYR_R1_POLY
rm tmp.zip
rm -r VEG_COMP_LYR_R1_POLY_2020.gdb

echo "Loading 2019 VEG_COMP_LYR_R1_POLY"
zip -FF $TMP/VEG_COMP_LYR_R1_POLY_2019.gdb.zip --out tmp.zip -fz
unzip tmp.zip
ogr2ogr \
   -progress \
   --config PG_USE_COPY YES \
   -t_srs EPSG:3005 \
   -dim XY \
   -f PostgreSQL \
   PG:"$PGOGR" \
   -overwrite \
   -lco GEOMETRY_NAME=geom \
   -lco SPATIAL_INDEX=NONE \
   -lco FID=FEATURE_ID \
   -lco FID64=TRUE \
   -nln whse_forest_vegetation.veg_comp_lyr_r1_poly_2019 \
   VEG_COMP_LYR_R1_POLY.gdb \
   VEG_COMP_LYR_R1_POLY
rm tmp.zip
rm -r VEG_COMP_LYR_R1_POLY.gdb

echo "Loading 2018 VEG_COMP_LYR_R1_POLY"
zip -FF $TMP/VEG_COMP_LYR_R1_POLY_2018.gdb.zip --out tmp.zip -fz
unzip tmp.zip
ogr2ogr \
   -progress \
   --config PG_USE_COPY YES \
   -t_srs EPSG:3005 \
   -dim XY \
   -f PostgreSQL \
   PG:"$PGOGR" \
   -overwrite \
   -lco GEOMETRY_NAME=geom \
   -lco SPATIAL_INDEX=NONE \
   -lco FID=FEATURE_ID \
   -lco FID64=TRUE \
   -nln whse_forest_vegetation.veg_comp_lyr_r1_poly_2018 \
   VEG_COMP_LYR_R1_POLY.gdb \
   VEG_COMP_LYR_R1_POLY
rm tmp.zip
rm -r VEG_COMP_LYR_R1_POLY.gdb

# with data load completed, create indexes
# echo "Indexing"
for TABLE in veg_comp_lyr_r1_poly veg_comp_lyr_r1_poly_2019 veg_comp_lyr_r1_poly_2018
do
   psql --single-transaction --dbname=$PGDATABASE --quiet --command="
   CREATE INDEX ON whse_forest_vegetation.$TABLE (for_mgmt_land_base_ind);
   CREATE INDEX ON whse_forest_vegetation.$TABLE (inventory_standard_cd);
   CREATE INDEX ON whse_forest_vegetation.$TABLE (non_productive_descriptor_cd);
   CREATE INDEX ON whse_forest_vegetation.$TABLE (species_pct_1);
   CREATE INDEX ON whse_forest_vegetation.$TABLE (species_cd_1);
   CREATE INDEX ON whse_forest_vegetation.$TABLE (site_index);
   CREATE INDEX ON whse_forest_vegetation.$TABLE (bclcs_level_1);
   CREATE INDEX ON whse_forest_vegetation.$TABLE (bclcs_level_2);
   CREATE INDEX ON whse_forest_vegetation.$TABLE (bclcs_level_3);
   CREATE INDEX ON whse_forest_vegetation.$TABLE (bclcs_level_4);
   CREATE INDEX ON whse_forest_vegetation.$TABLE (bclcs_level_5);
   CREATE INDEX ON whse_forest_vegetation.$TABLE (map_id);
   CREATE INDEX ON whse_forest_vegetation.$TABLE USING GIST (geom);"
done

# don't bother clustering, likely not worth it unless doing lots of work with this data
# Cluster records on disk based on index
# http://postgis.net/docs/performance_tips.html#database_clustering
#psql --single-transaction --dbname=$PGDATABASE --quiet --command="
#CLUSTER whse_forest_vegetation.veg_comp_lyr_r1_poly USING veg_comp_lyr_r1_poly_geom_idx;"


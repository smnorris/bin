#!/bin/bash
set -euxo pipefail

# ** note the file name changes yearly **
year=$(date +'%Y')

# download file
wget --trust-server-names -qNP /tmp \
  https://pub.data.gov.bc.ca/datasets/02dba161-fdb7-48ae-a4bb-bd6ef017c36d/current/VEG_COMP_LYR_R1_POLY_$year.gdb.zip

# load to postgres
psql -v ON_ERROR_STOP=1 $DATABASE_URL -c "CREATE SCHEMA IF NOT EXISTS whse_forest_vegetation"
ogr2ogr \
   -progress \
   --config PG_USE_COPY YES \
   -t_srs EPSG:3005 \
   -dim XY \
   -f PostgreSQL \
   PG:$DATABASE_URL \
   -overwrite \
   -lco GEOMETRY_NAME=geom \
   -lco SPATIAL_INDEX=NONE \
   -lco FID=FEATURE_ID \
   -lco FID64=TRUE \
   -nln whse_forest_vegetation.veg_comp_lyr_r1_poly \
   /tmp/VEG_COMP_LYR_R1_POLY_$year.gdb.zip \
   VEG_COMP_LYR_R1_POLY

# index columns of interest
psql -v ON_ERROR_STOP=1 $DATABASE_URL -c "CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (for_mgmt_land_base_ind); \
   CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (inventory_standard_cd); \
   CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (non_productive_descriptor_cd); \
   CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (species_pct_1); \
   CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (species_cd_1); \
   CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (site_index); \
   CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (bclcs_level_1); \
   CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (bclcs_level_2); \
   CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (bclcs_level_3); \
   CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (bclcs_level_4); \
   CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (bclcs_level_5); \
   CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (map_id); \
   CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly USING GIST (geom);"

# cleanup
rm /tmp/VEG_COMP_LYR_R1_POLY_$year.gdb.zip
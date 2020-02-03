# forest cover

tmp=~/Downloads

wget --trust-server-names -qNP "$tmp" https://pub.data.gov.bc.ca/datasets/2ebb35d8-c82f-4a17-9c96-612ac3532d55/VEG_COMP_LYR_R1_POLY.gdb.zip

# mac unzip can't handle really big files
# use 7zip instead http://mylescarrick.com/post/3195382919/unzipping-massive-files-on-osx
# install 7zip with this:   > brew install p7zip
7z x $tmp/VEG_COMP_LYR_R1_POLY.gdb.zip

psql -c "CREATE SCHEMA IF NOT EXISTS whse_forest_vegetation"

# load to pg
# This doesn't take very long, it isn't worth loading in parallel to temp
# tiled tables
echo "Loading VEG_COMP_LYR_R1_POLY"
ogr2ogr \
   -progress \
   --config PG_USE_COPY YES \
   -t_srs EPSG:3005 \
   -dim XY \
   -f PostgreSQL \
   PG:"$PGOGR" \
   -lco OVERWRITE=YES \
   -lco SCHEMA=whse_forest_vegetation \
   -lco GEOMETRY_NAME=geom \
   -lco SPATIAL_INDEX=NONE \
   -lco FID=FEATURE_ID \
   -lco FID64=TRUE \
   -nln veg_comp_lyr_r1_poly \
   VEG_COMP_LYR_R1_POLY.gdb \
   WHSE_FOREST_VEGETATION_2018_VEG_COMP_LYR_R1_POLY

# with data loaded, create indexes
echo "Creating veg attribute indexes"
psql --single-transaction --dbname=$PGDATABASE --quiet --command="
CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (for_mgmt_land_base_ind);
CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (inventory_standard_cd);
CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (non_productive_descriptor_cd);
CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (species_pct_1);
CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (species_cd_1);
CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (site_index);
CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (bclcs_level_1);
CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (bclcs_level_2);
CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (bclcs_level_3);
CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (bclcs_level_4);
CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (bclcs_level_5);
CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly (map_id);"

echo "Creating veg geometry index"
psql --dbname=$PGDATABASE --quiet --command="CREATE INDEX ON whse_forest_vegetation.veg_comp_lyr_r1_poly USING GIST (geom);"

# Cluster records on disk based on index
# http://postgis.net/docs/performance_tips.html#database_clustering
psql --single-transaction --dbname=$PGDATABASE --quiet --command="
CLUSTER whse_forest_vegetation.veg_comp_lyr_r1_poly USING veg_comp_lyr_r1_poly_geom_idx;"

# cleanup
rm "$tmp/veg_comp_lyr_r1_poly.gdb.zip"
rm -r VEG_COMP_LYR_R1_POLY.gdb


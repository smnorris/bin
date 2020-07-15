# forest cover

tmp=~/Downloads

wget --trust-server-names -qNP "$tmp" https://pub.data.gov.bc.ca/datasets/02dba161-fdb7-48ae-a4bb-bd6ef017c36d/current/VEG_COMP_LYR_R1_POLY_2019.gdb.zip

# mac unzip can't handle really big files
# use 7zip instead http://mylescarrick.com/post/3195382919/unzipping-massive-files-on-osx
# install 7zip with this:   > brew install p7zip
# (or consider ditto - https://superuser.com/questions/114011/extract-large-zip-file-50-gb-on-mac-os-x)
7z x $tmp/VEG_COMP_LYR_R1_POLY_2019.gdb.zip -o $tmp

# on linux, 7zip still seems to have issues.
# this seems to work:
# https://stackoverflow.com/questions/31481701/how-to-extract-files-from-a-large-30gb-zip-file-on-linux-server
#zip -FF VEG_COMP_LYR_R1_POLY_2019.gdb.zip --out tmp.zip -fz
#unzip tmp.zip

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
   -overwrite \
   -lco GEOMETRY_NAME=geom \
   -lco SPATIAL_INDEX=NONE \
   -lco FID=FEATURE_ID \
   -lco FID64=TRUE \
   -nln whse_forest_vegetation.veg_comp_lyr_r1_poly \
   VEG_COMP_LYR_R1_POLY.gdb \
   VEG_COMP_LYR_R1_POLY

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
rm "$tmp/veg_comp_lyr_r1_poly_2019.gdb.zip"
rm -r VEG_COMP_LYR_R1_POLY.gdb
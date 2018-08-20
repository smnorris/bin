
# forest cover

tmp=~/Downloads

wget --trust-server-names -qNP "$tmp" https://pub.data.gov.bc.ca/datasets/2ebb35d8-c82f-4a17-9c96-612ac3532d55/VEG_COMP_LYR_R1_POLY.gdb.zip

# mac unzip can't handle really big files
# use 7zip instead http://mylescarrick.com/post/3195382919/unzipping-massive-files-on-osx
# install 7zip with this:   > brew install p7zip
7z x $tmp/VEG_COMP_LYR_R1_POLY.gdb.zip

psql -c "CREATE SCHEMA IF NOT EXISTS whse_forest"

# load to pg
echo "Loading VEG_COMP_LYR_R1_POLY"
ogr2ogr \
   -progress \
   --config PG_USE_COPY YES \
   -t_srs EPSG:3005 \
   -dim 2 \
   -f PostgreSQL \
   PG:$PGOGR \
   -lco OVERWRITE=YES \
   -lco GEOMETRY_NAME=geom \
   -nln veg_comp_lyr_r1_poly \
   $tmp/VEG_COMP_LYR_R1_POLY.gdb \
   VEG_COMP_LYR_R1_POLY

# with data loaded, create indexes
echo "Creating veg indexes"
psql --single-transaction --dbname=$PGDATABASE --quiet --command="
CREATE INDEX fmlb_idx ON whse_forest.veg_comp_lyr_r1_poly (FOR_MGMT_LAND_BASE_IND);
CREATE INDEX inv_std_cd_idx ON whse_forest.veg_comp_lyr_r1_poly (INVENTORY_STANDARD_CD);
CREATE INDEX npd_idx ON whse_forest.veg_comp_lyr_r1_poly (NON_PRODUCTIVE_DESCRIPTOR_CD);
CREATE INDEX sppct1_idx ON whse_forest.veg_comp_lyr_r1_poly (SPECIES_PCT_1);
CREATE INDEX spcd1_idx ON whse_forest.veg_comp_lyr_r1_poly (SPECIES_CD_1);
CREATE INDEX siteidx_idx ON whse_forest.veg_comp_lyr_r1_poly (SITE_INDEX);
CREATE INDEX bclcs1_idx ON whse_forest.veg_comp_lyr_r1_poly (BCLCS_LEVEL_1);
CREATE INDEX bclcs2_idx ON whse_forest.veg_comp_lyr_r1_poly (BCLCS_LEVEL_2);
CREATE INDEX bclcs3_idx ON whse_forest.veg_comp_lyr_r1_poly (BCLCS_LEVEL_3);
CREATE INDEX bclcs4_idx ON whse_forest.veg_comp_lyr_r1_poly (BCLCS_LEVEL_4);
CREATE INDEX bclcs5_idx ON whse_forest.veg_comp_lyr_r1_poly (BCLCS_LEVEL_5);
CREATE INDEX mapid_idx ON whse_forest.veg_comp_lyr_r1_poly (MAP_ID);"

# try this spatial index performance enhancement
# http://postgis.net/docs/performance_tips.html#database_clustering
psql --single-transaction --dbname=$PGDATABASE --quiet --command="
ALTER TABLE whse_forest.veg_comp_lyr_r1_poly ALTER COLUMN geom SET not null;
CLUSTER veg_comp_lyr_r1_poly_geom_geom_idx ON veg_comp_lyr_r1_poly;"

# cleanup
rm "$tmp/veg_comp_lyr_r1_poly.gdb.zip"
rm -r "$tmp/VEG_COMP_LYR_R1_POLY.gdb"


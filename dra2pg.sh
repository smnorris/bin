#!/bin/bash
set -euxo pipefail

# load DRA to postgis

TMP=~/tmp

wget --trust-server-names -qNP "$TMP" ftp://ftp.geobc.gov.bc.ca/sections/outgoing/bmgs/DRA_Public/dgtl_road_atlas.gdb.zip

# mac unzip can't handle really big files
# use 7zip instead http://mylescarrick.com/post/3195382919/unzipping-massive-files-on-osx
# install 7zip with this:   > brew install p7zip
# (or consider ditto - https://superuser.com/questions/114011/extract-large-zip-file-50-gb-on-mac-os-x)
unzip $TMP/dgtl_road_atlas.gdb.zip -d $TMP

psql -c "CREATE SCHEMA IF NOT EXISTS whse_basemapping"

# load to pg
echo "Loading DRA"
ogr2ogr \
   -progress \
   --config PG_USE_COPY YES \
   -t_srs EPSG:3005 \
   -dim XY \
   -f PostgreSQL \
   PG:"$PGOGR" \
   -lco OVERWRITE=YES \
   -lco SCHEMA=whse_basemapping \
   -lco GEOMETRY_NAME=geom \
   -lco FID=TRANSPORT_LINE_ID \
   -nln transport_line \
   tmp/dgtl_road_atlas.gdb \
   TRANSPORT_LINE

# probably want to index the names for full text search...

# cleanup
rm "$TMP/dgtl_road_atlas.gdb.zip"
rm -r $TMP/dgtl_road_atlas.gdb
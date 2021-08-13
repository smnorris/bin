#!/bin/bash
set -euxo pipefail

# Use ghostscript to reduce pdf file sizes (output from QGIS)

# create target folder
mkdir -p shrunk

# find all pdfs in current directory, write new file to shrunk folder
for i in $( ls *.pdf ); do
    gs \
      -sDEVICE=pdfwrite \
      -dPDFSETTINGS=/ebook \
      -dCompatibilityLevel=1.4 \
      -dNOPAUSE \
      -dQUIET \
      -dBATCH \
      -dCompressFonts=true \
      -sOutputFile=shrunk/$i \
      $i
  done
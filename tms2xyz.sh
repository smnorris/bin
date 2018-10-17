#!/bin/bash
# https://gist.github.com/tmcw/4954720
# https://gist.github.com/kannes/ebfe021458f96e4f30b5

# rename TMS tiles to the XYZ schema
# no quoting, since all files have simple numeric names
# do not run this anywhere else than INSIDE your tiles directory

# run it like this: find . -name "*.png" -exec ./tms2xyz.sh {} \;

filename=$1

tmp=${filename#*/}     # remove to first /
z=${tmp%%/*}           # remove from first /

tmp=${filename%/*}     # remove from last /
x=${tmp##*/}           # remove to last /

tmp=${filename##*/}    # remove to last /
y=${tmp%.*}            # remove from first .

extension=${filename##*.}

let newy="2**$z-$y-1"  # calculate the xyz tile
#echo $z $x $y $newy $extension

# remove the echo if you are sure you want to do this
mv ${filename} ./$z/$x/$newy.$extension
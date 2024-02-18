#!/bin/bash

#fw=mouSTer.adf
fw=$2
echo "creating $2"

XDFOPTS=-f

xdftool $XDFOPTS "$fw" create + format 'mouSTer' 

#+  write mouSTer.driver

#Create dir structure, only one level deep allowed
while IFS= read -rd '' dir; do
   adfdir=$(realpath --relative-to $1 $dir)
   xdftool $XDFOPTS "$fw" makedir $adfdir 
done < <(find $1 -mindepth 1 -type d -print0)

#Copy files
while IFS= read -rd '' file; do
   adffile=$(realpath --relative-to $1 $file)
   adfpath=$(dirname $adffile)"/"
   #strip leadint dot in root
   adfpath=${adfpath#.}
   xdftool $XDFOPTS "$fw" write $file $adfpath 
done < <(find $1 -mindepth 1 -type f -print0)



exit 0






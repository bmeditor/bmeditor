#!/bin/bash
if [ $# -ne 3 ]; then
echo -e "Usage: $0 in.pdf out.pdf bookmarks-file"
exit 1
fi
tmpfile=/tmp/insert-$RANDOM-$RANDOM
# remove existing bookmarks:
pdftk $1 cat output $tmpfile 
gs -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=$2 $tmpfile $3
rm $tmpfile
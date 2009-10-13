#!/bin/bash
# call with rotate90 [-m] file url
# lossless jpeg rotation maintaines exif headers

angle=90
if [ "$1" = "-m" ]
then 
	shift
	angle=270
fi

file="$1"
url="$2"

#echo ""
#echo "got file: $file"
#echo "got url: $url"

jhead -ft -cmd "jpegtran -progressive -rotate $angle -outfile &o &i" "$file"

# now delete kde thumbnails
url=$(/home/rich/bin/urlencode.pl "$file")
url="file://${url//\%2F//}"
md=$(echo -n "$url" | md5sum | cut -f1 -d" ")
#echo "looking for '$md' from $url in " ~/.thumbnails/
#echo "find results----------------------"
#find ~/.thumbnails/ -name "$md.png" 
#echo "----------------------------------"
find ~/.thumbnails/ -name "$md.png" -print0 | xargs -0 rm -f

#find mtime of file
#mt=$(stat -c "%Y" "$file" )
#find thumbnails with same time.
#ls ~/.thumbnails/ | xargs stat -c "%Y %n" | grep ^$mt | cut -f2 -d" "


#!/bin/bash
# mass ogg to mp3 converter
if [ $# -lt 1 ]
then echo ""
	echo "Usage: $0 filenames.ogg"
	echo "       call from within a directory containing the oggs to process"
	exit
fi

mp3dir=$(pwd)
mp3dir="${mp3dir##*/}_mp3"

[ -e "$mp3dir" ] && [ ! -d "$mp3dir" ] && echo "$mp3dir must be a directory, but it is a file." && exit 1

[ -e "$mp3dir" ] || mkdir "$mp3dir"


while [ -n "$1" ]
do
	echo "Firing up process for $1"
	( nice -n19 ogg2mp3 "$1" >/dev/null ; mv "${1%.ogg}.mp3" "$mp3dir/." >/dev/null 2>&1 ; echo "Finished $1" ; )  &
	shift
done
echo "Waiting..."
wait

#!/bin/bash
h=$(pwd)
while [ -n "$1" ]
do 	d="$1"
	echo "doing $d" 
	cd "$d"
	wma2wav *m4a *wma >/dev/null 2>&1 
	oggenc *wav >/dev/null 2>&1
	rm *wav -f 2>/dev/null
	echo "done $d"
	cd "$h"
	shift;
done

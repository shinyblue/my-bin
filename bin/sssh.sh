#!/bin/bash

if [ $# -le 0 ]; then
	echo "Usage: $0 option"
	echo "	option		Meaning"
	echo "	intranet	set up portfwd from local 22220 to maui:80"
	echo "	caimap		set up portfwd from local 22221 to fozzy:imap"
	exit 0;
fi

if [ "_$1" = "_intranet" ]
then
	ssh -L 22220:127.0.0.1:80 rich@maui.work -p22622 -N &
	sleep 5
	echo "Link set up, use http://intranet:22220/ "
	echo "use kill $! to kill."
elif [ "_$1" = "_caimap" ]
then
	ssh -L 22221:127.0.0.1:143 root@ca -p22922 -N &
	sleep 5
	echo "Link set up, use imap://localhost:22221 to access. "
	echo "use kill $! to kill."
fi


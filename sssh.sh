#!/bin/bash

# commands
# list
# start
# stop


if [ $# -le 0 ]; then
	echo "Usage: $0 option"
	echo "	option		Meaning"
	echo "	intranet	set up portfwd from local 22220 to maui:80"
	echo "	caimap		set up portfwd from local 22221 to fozzy:imap"
	echo "	one			set up portfwd from local 22222 to maui:3306"
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
elif [ "_$1" = "_one" ]
then
	ssh -L 22222:localhost:3306 rich@maui.work -p22622 -N &
	sleep 5
	echo "Link set up, use mysql -P22222 to access. "
	echo "use kill $! to kill."
else
	echo "Must give one of: intranet, caimap, one. " >&2
fi


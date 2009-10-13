#!/bin/bash
SND_TRY="/usr/share/sounds/KDE_Beep_Connect.ogg"
SND_SUCCESS="/usr/share/sounds/KDE_TypeWriter_Bell.ogg"
SND_FAIL="/usr/share/sounds/KDE_Error_3.ogg"
SND_PLAY="play -v 0.3 "
MAX_TRIES=10
NONE_VALUE=eth0-none

cat >/tmp/guessnetcall
logger -s "$0[$$]: started"

if ifplugstatus eth0 | fgrep unplugged >/dev/null 2>&1
then
	logger -s "$0[$$]: unplugged, exiting without bringing it up."
	exit
fi


logger -s "$0[$$]: doing first call for interface $1..." 

tries=1
output=$NONE_VALUE

$SND_PLAY "$SND_TRY" >/dev/null 2>&1
while [ "x$output" = "x$NONE_VALUE" -a $tries -lt $MAX_TRIES ]
do 	output=$(/usr/sbin/guessnet-ifupdown $1 </tmp/guessnetcall)
	logger -s "$0[$$]: Try $tries got $output" 
	tries=$(( $tries + 1 ))
	if [ "x$output" = "x$NONE_VALUE" ] 
	then
		$SND_PLAY "$SND_TRY" >/dev/null 2>&1
		sleep 2
	fi
done
if [ "x$output" = "x$NONE_VALUE" ] 
then
	$SND_PLAY "$SND_FAIL" >/dev/null 2>&1
else
	$SND_PLAY "$SND_SUCCESS" >/dev/null 2>&1
fi

logger -s "$0[$$]: exiting, returning: $output" 
rm -f /tmp/guessnetcall >/dev/null 2>&1
echo $output;

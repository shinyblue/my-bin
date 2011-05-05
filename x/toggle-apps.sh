#!/bin/bash

function usage
{
	[ -n "$*" ] && echo "ERROR: $*" >&2
	echo "Usage: toggle-apps [--class classname] launch_cmd"
	echo "Options"
	echo "--class classname"
    echo "          For some apps you might need to specify the class name"
	echo "          Generally though the launch command will do."
	exit 1
}


LAUNCH_CMD=("$@")
[ "${#LAUNCH_CMD[@]}" -lt 1 ] && usage "No launch command provided"

CMD_NAME="${LAUNCH_CMD[0]}"
WINDOW_CLASS="$CMD_NAME"

## Set the appropriate window ID.
function setwid 
{
	CACHE="/tmp/toggle-apps-$WINDOW_CLASS"
	WID=

	# load previous terminal window id, if file exists
	#[ -e "$CACHE" ] && PREV=$(<"$CACHE")

	# if we have previous one, see if it's still available
#	[ -n "$PREV" ] && WID=`xdotool search --class "$WINDOW_CLASS" | fgrep "$PREV"`

	# if we don't have an id yet, try taking the first available one
	[ -z "$WID" ] && WID=`xdotool search --class "$WINDOW_CLASS" | head -1`

	# store this for next time
	echo $WID>"$CACHE"
	echo "WID $WID"
}

echo "Looking for $CMD_NAME is process table"
pgrep -u "$USER" "$CMD_NAME" | grep -qv "$$"

## If there's already a $WINDOW_CLASS running -- signified by
## the exit status ($$) of the above pgrep -- do this:
if [ "$?" == "0" ]
then
    echo "Found a $WINDOW_CLASS" >&2
    setwid
    if [[ `xdotool getactivewindow` == $WID ]]
	then
		echo "window is active" >&2
#### If the window is active, shade it and send it to the back of the stack.
		# wmctrl -i -r $WID -b toggle,shaded
		# sleep 0.5s
		# wmctrl -i -r $WID -b remove,above
		# wmctrl -i -r $WID -b add,hidden
		wmctrl -i -r $WID -a
		sleep 0.1
		xdotool key alt+F9
    else 

		echo "window $WID is not active" >&2
#### If the window is NOT active, activate it and bring it to the top.
		#wmctrl -i -r $WID -b remove,hidden
		# wmctrl -i -r $WID -b add,above
		xdotool windowactivate $WID
    fi
else
## If the pgrep returns a "1" (which is false, 0 is true, bash is backwards)
## then start up a new terminal, make it on top and sticky, and go to town.
	echo "Trying to launch with ""${LAUNCH_CMD[@]}"
    "${LAUNCH_CMD[@]}" &
	NEW_PID=$!

	sleep 0.3
	WID=
	while [ -z "$WID" ]
   	do
		echo -n "Not running yet..."
		sleep 0.5
		setwid
	done
	echo "running"
    xdotool windowfocus $WID
    #wmctrl -i -r $WID -b add,above
    #wmctrl -i -r $WID -b add,sticky

## ctrl+alt+h is bound in Compiz to maximize horizontally.
    #xdotool key "ctrl+alt+h"
    xdotool key alt+F10
fi

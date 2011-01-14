#!/bin/bash
## Uncomment set -x to debug.
#set -x
## Path: /usr/local/bin/gnome-terminal

## Set the appropriate window ID.
function setwid 
{
	CACHE=/tmp/current_terminal

	# load previous terminal window id, if file exists
	[ -e $CACHE ] && PREV=$(<$CACHE)

	# if we have previous one, see if it's still available
	[ ! -z "$PREV" ] && WID=`xdotool search --class "gnome-terminal" | fgrep "$PREV"`

	# if we don't have an id yet, try taking the first available one
	[ -z "$WID" ] && WID=`xdotool search --class "gnome-terminal" | head -1`

	# store this for next time
	echo $WID>/tmp/current_terminal
}

## Check if there are arguments, and if so, run the standard
## gnome-terminal app with those args.
if [ "x$*" != "x" ]; then
  /usr/bin/gnome-terminal "$@"
else
  pgrep -u "$USER" gnome-terminal | grep -qv "$$"

## If there's already a gnome-terminal running -- signified by
## the exit status ($$) of the above pgrep -- do this:
  if [ "$?" == "0" ]; then
    setwid
    if [[ `xdotool getactivewindow` == $WID ]]; then

#### If the window is active, shade it and send it to the back of the stack.
#	wmctrl -i -r $WID -b toggle,shaded
#	sleep 0.5s
#	wmctrl -i -r $WID -b remove,above
#	wmctrl -i -r $WID -b add,hidden
	xdotool key alt+F9
    else 

#### If the window is NOT active, activate it and bring it to the top.
	#wmctrl -i -r $WID -b remove,hidden
	# wmctrl -i -r $WID -b add,above
	xdotool windowactivate $WID
    fi
  else

## If the pgrep returns a "1" (which is false, 0 is true, bash is backwards)
## then start up a new terminal, make it on top and sticky, and go to town.
    /usr/bin/gnome-terminal --geometry=150x35+0+0 &
    sleep 1
    setwid
    xdotool windowfocus $WID
    #wmctrl -i -r $WID -b add,above
    #wmctrl -i -r $WID -b add,sticky

## ctrl+alt+h is bound in Compiz to maximize horizontally.
    #xdotool key "ctrl+alt+h"
    xdotool key alt+F10
  fi
fi
#EOF

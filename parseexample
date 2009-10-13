#!/bin/bash
#example parsing of command lines

# {{{ start of parse
args=''

opt1=''
opt2=''

while [ "$#" -gt 0 ]
do
	dontcollect=''
	case "$1" in

	# Adapt for yes/no options:
	"--opt1" | "-o")
		opt1='yes'
		;;
	
	# --opt=value style
	"--opt2="* )
		opt2="${1#--opt2=}"
		;;
		
	# -Ovalue style
	"-O"* )
		opt2="${1#-O}"
		echo "here";
		;;
	
	# --opt value style
	"--opt2" | "-O" )
		shift
		opt2="$1"
		dontcollect='true'
		;;
	
	# collect other args
	*)
		[ -z "$dontcollect" ] && [ "${#args}" -eq 0 ] && args=( "$1" ) || args=( "${args[@]}" "$1" )
		;;
	esac
	shift
done

# }}} end of parsing

# output {{{
echo "opt1: $opt1"
echo "opt2: $opt2"
echo "args: ${#args} no0 ${args[0]} no0 default to rrrr: ${args[0]:-rrrr}"

i=1
for arg in "${args[@]}"
do echo "arg $i : $arg "
	i=$(( $i + 1 ))
done
# }}}

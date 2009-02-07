#!/bin/sh
###########################################################################HP##
##
# FILE: 	runVimTests.sh
# PRODUCT:	VIM tools
# AUTHOR: 	/^--
# DATE CREATED:	02-Feb-2009
#
###############################################################################
# CONTENTS: 
#   This script implements a small unit testing framework for VIM. 
#   
# REMARKS: 
#   
# FILE_SCCS = "@(#)runVimTests.sh	001	(02-Feb-2009)	VIM Tools";
#
# REVISION	DATE		REMARKS 
#	001	02-Feb-2009	file creation
###############################################################################

printUsage()
{
    # This is the short help when launched with no or incorrect arguments. 
    # It is printed to stderr to avoid accidental processing. 
    cat >&2 <<SHORTHELPTEXT
Usage: "$(basename "$1")" [--pure|--reallypure] [--source filespec [--source filespec [...]]] [--runtime plugin/file.vim [--runtime autoload/file.vim [...]]] [--summaryonly] [--debug] [--help] test001.vim|testsuite.txt|path/to/testdir/ [...]
Try "$(basename "$1")" --help for more information.
SHORTHELPTEXT
}
printLongUsage()
{
    # This is the long "man page" when launched with the help argument. 
    # It is printed to stdout to allow paging with 'more'. 
    cat <<HELPTEXT
A small unit testing framework for VIM. 

Usage: "$(basename "$1")" [--pure|--reallypure] [--source filespec [--source filespec [...]]] [--runtime plugin/file.vim [--runtime autoload/file.vim [...]]] [--summaryonly] [--debug] [--help] test001.vim|testsuite.txt|path/to/testdir/ [...]
   --pure		Start VIM without loading .vimrc and plugins, but in
			nocompatible mode and with some essential test support
			scripts sourced. 
   --reallypure		Start VIM without loading .vimrc and plugins, but in
			nocompatible mode. Some essential scripts may be missing
			and must be sourced manually.
   --source filespec	Source filespec before test execution.
   --runtime filespec	Source filespec relative to ~/.vim. Important to load
			the script-under-test when using --pure.
   --summaryonly	Do not show detailed transcript and differences, during
			test run, only summary. 
   --debug		Test debugging mode: Sets g:debug = 1 inside VIM
HELPTEXT
}

executionOutput()
{
    [ "$isExecutionOutput" ] && echo "$@"
}

determineEssentialVimScripts()
{
}

determineEssentialVimScripts

vimArguments=""
isExecutionOutput='true'

if [ $# -eq 0 ]; then
    printUsage "$0"
    exit 1
fi
while [ $# -ne 0 ]
do
    case "$1" in
	--help|-h|-\?)	shift; printLongUsage "$0"; exit 1;;
	--pure)		shift; vimArguments="-N -u NONE $essentialVimScripts $vimArguments";;
	--reallypure)	shift; vimArguments="-N -u NONE $vimArguments";;
	--runtime)	shift; vimArguments="$vimArguments -S '$HOME/.vim/$1'";;
	--source)	shift; vimArguments="$vimArguments -S '$1'";;
	--summaryonly)	shift; isExecutionOutput='true';;
	--debug)	shift; vimArguments="$vimArguments --cmd 'let g:debug=1'";;
	--)		shift; break;;
	*)		break;;
    esac
done
[ $# -eq 0 ] && { printLongUsage "$0"; exit 1; }

cntTests=0
cntRun=0
cntOk=0
cntFail=0
cntError=0
listFailed=""
listError=""

for arg
do
    if [ -d "$arg" ]; then
	runDir "$arg"
    elif [ "${arg#/}" = ".vim" ]; then
	runTest "$arg"
    elif [ -r "$arg" ]; then
	runSuite "$arg"
    else
	cntError+=1
	echo "ERROR: Suite file \"${arg}\" doesn't exist. "
    fi
done


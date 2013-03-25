#!/bin/bash
##########################################################################/^--#
##
# FILE: 	compareLog.sh
# PRODUCT:	runVimTests
# AUTHOR: 	Ingo Karkat <ingo@karkat.de>
# DATE CREATED:	11-Feb-2009
#
###############################################################################
# CONTENTS:
#  Runs a runVimTests self-test and compares the test output with previously
#  captured nominal output.
#  The command-line arguments to runVimTests and the test file are embedded in
#  the captured output filename and are extracted automatically:
#  testrun.suite-1-v.log ->
#	$ runVimTests -1 -v testrun.suite > /tmp/testrun.suite-1-v.log 2>&1
#  The special name "testdir" represents all tests in the directory (i.e. '.'):
#  testdir-1-v.log ->
#	$ runVimTests -1 -v . > /tmp/testdir-1-v.log 2>&1
#
# REMARKS:
#
# REVISION	DATE		REMARKS
#	006	25-Mar-2013	Prepend the repository's bin directory to PATH
#				to prefer the current script from the repository.
#	005	28-May-2009	Pin down locale to get reproducible sorting order.
#	004	12-Mar-2009	Also capturing stderr output, e.g. for "test not
#				found" errors.
#				BF: Didn't handle captured output filename
#				without any -options.
#	003	07-Mar-2009	The test file (suite) is now also embedded in
#				the captured output name so that multiple test
#				files and suites can be captured.
#				Added command-line option --onlyresults for
#				compareAllLogs.sh.
#	002	25-Feb-2009	Command-line arguments are now embedded in the
#				captured output filename and extracted
#				automatically.
#	001	11-Feb-2009	file creation
###############################################################################

readonly scriptDir=$([ "${BASH_SOURCE[0]}" ] && dirname -- "${BASH_SOURCE[0]}" || exit 2)
[ -d "$scriptDir" ] || { echo >&2 "ERROR: Cannot determine script directory!"; exit 2; }

# Prefer the current script from the repository.
PATH="${scriptDir}/../../bin:$PATH"

# Pin down locale to get reproducible sorting order.
export LC_ALL=C

isTrackProgress='true'
if [ "$1" == "--onlyresults" ]; then
    shift
    isTrackProgress=
fi

old=${1:-testdir.log}
log=/tmp/$(basename -- "${1:-testdir.log}")
[ -f "$log" ] && { rm "$log" || exit 1; }

[ -f "$old" ] || { echo >&2 "ERROR: Old log \"${old}\" does not exist!"; exit 1; }

options=
tests='testdir'
if [ $# -gt 0 ]; then
    argname=$(basename -- "$1")
    argname=${argname%.log}

    tests=${argname%%-*}
    if [[ "$argname" == *-* ]]; then
	options=-${argname#*-}
	options=${options//--/ !!}
	options=${options//-/ !}
	options=${options//!/-}
    fi
fi

if [ "$tests" == "testdir" ]; then
    tests='.'
fi
if [ "$isTrackProgress" ]; then
    runVimTests.sh $options "$tests" 2>&1 | tee "$log"
else
    runVimTests.sh $options "$tests" > "$log" 2>&1
fi

echo
echo "DIFFERENCES:"
diff -u "$old" "$log"


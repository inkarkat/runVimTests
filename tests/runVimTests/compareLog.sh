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
#  Runs the runVimTests self-test suite and compares the test output with
#  previously captured nominal output. 
#  The command-line arguments to runVimTests are embedded in the captured
#  output filename and are extracted automatically: 
#  testrun-1-v.log -> $ runVimTests -1 -v . > /tmp/testrun-1-v.log
#   
# REMARKS: 
#   
# REVISION	DATE		REMARKS 
#	002	25-Feb-2009	Command-line arguments are now embedded in the
#				captured output filename and extracted
#				automatically. 
#	001	11-Feb-2009	file creation
###############################################################################

old=${1:-testrun.log}
log=/tmp/$(basename -- "${1:-testrun.log}")
[ -f "$log" ] && { rm "$log" || exit 1; }

[ -f "$old" ] || { echo >&2 "ERROR: Old log \"${old}\" does not exist!"; exit 1; }

options=
if [ $# -gt 0 ]; then
    options=$(basename -- "$1")
    options=${options%.log}
    options=${options#testrun}
    options=${options//--/ !!}
    options=${options//-/ !}
    options=${options//!/-}
fi

runVimTests.sh $options . | tee "$log"

echo
echo "DIFFERENCES:"
diff -u "$old" "$log"


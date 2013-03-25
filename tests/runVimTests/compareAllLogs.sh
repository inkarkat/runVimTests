#!/bin/bash
##########################################################################/^--#
##
# FILE: 	compareAllLogs.sh
# PRODUCT:	runVimTests
# AUTHOR: 	Ingo Karkat <ingo@karkat.de>
# DATE CREATED:	07-Mar-2009
#
###############################################################################
# CONTENTS: 
#  Runs all existing runVimTests self-test suites. 
#   
# REMARKS: 
#   
# REVISION	DATE		REMARKS 
#	001	07-Mar-2009	file creation
###############################################################################

readonly scriptDir=$(readonly scriptFile="$(type -P -- "$0")" && dirname -- "$scriptFile" || exit 1)
[ -d "$scriptDir" ] || { echo >&2 "ERROR: cannot determine script directory!"; exit 1; } 

pushd "$scriptDir" >/dev/null

IFS=$'\n'
for file in *.log
do
    echo
    echo $file
    ./compareLog.sh --onlyresults "$file"
done

popd >/dev/null


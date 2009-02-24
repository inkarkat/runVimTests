#!/bin/sh

log=/tmp/testrun.log
old=testrun.log

[ -f "$old" ] || { echo >&2 "ERROR: Old log \"${old}\" does not exist!"; exit 1; }

runVimTests.sh --default . | tee "$log"

echo
echo "DIFFERENCES:"
diff -u "$old" "$log"


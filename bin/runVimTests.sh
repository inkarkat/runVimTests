#!/bin/bash
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
Usage: "$(basename "$1")" [--pure|--default] [--source filespec [--source filespec [...]]] [--runtime plugin/file.vim [--runtime autoload/file.vim [...]]] [--vimexecutable path/to/vim] [-g|--graphical] [--summaryonly] [--debug] [--help] test001.vim|testsuite.txt|path/to/testdir/ [...]
Try "$(basename "$1")" --help for more information.
SHORTHELPTEXT
}
printLongUsage()
{
    # This is the long "man page" when launched with the help argument. 
    # It is printed to stdout to allow paging with 'more'. 
    cat <<HELPTEXT
A small unit testing framework for VIM. 

Usage: "$(basename "$1")" [--pure|--default] [--source filespec [--source filespec [...]]] [--runtime plugin/file.vim [--runtime autoload/file.vim [...]]] [--vimexecutable path/to/vim] [-g|--graphical] [--summaryonly] [--debug] [--help] test001.vim|testsuite.txt|path/to/testdir/ [...]
    --pure		Start VIM without loading .vimrc and plugins, but in
			nocompatible mode. Adds 'pure' to ${vimVariableOptionsName}.
    --default		Start VIM only with default settings and plugins,
			without loading user .vimrc and plugins.
			Adds 'default' to ${vimVariableOptionsName}.
    --source filespec	Source filespec before test execution.
    --runtime filespec	Source filespec relative to ~/.vim. Can be used to
			load the script-under-test when using --pure.
    --vimexecutable path/to/vim   Use passed VIM executable instead of the one
			found in \$PATH.
    -g^|--graphical	Use GUI version of VIM.
    --summaryonly	Do not show detailed transcript and differences, during
			test run, only summary. 
    --debug		Test debugging mode: Adds 'debug' to ${vimVariableOptionsName}
			variable inside VIM (so that tests do not exit or can
			produce additional debug info).
HELPTEXT
}

executionOutput()
{
    [ "$isExecutionOutput" ] && echo "$@"
}
makePlural()
{
    if [ $1 -eq 1 ]; then
	echo "$2"
    else
	echo "$2s"
    fi
}

processTestEntry()
{
    if [ -d "$1" ]; then
	runDir "$1"
    elif [ "${1##*.}" = "vim" ]; then
	runTest "$1"
    elif [ -r "$1" ]; then
	runSuite "$1"
    else
	let cntError+=1
	echo >&2 "ERROR: Suite file \"${1}\" doesn't exist. "
    fi
}

runSuite()
{
    readonly suiteDir=$(dirname -- "$1")

    # Change to suite directory so that relative paths and filenames are
    # resolved correctly. 
    pushd "$suiteDir"

    local testEntry
    while read testEntry
    do
	case "$testEntry" in
	    \#*|"") continue ;;
	esac
	processTestEntry "$testEntry"
    done < "$1"

    popd
}
runDir()
{
    local testFile
    for testFile in *.vim
    do
	runTest "$testFile"
    done
}

addToListFailed()
{
    echo "$listFailed" | grep "$1" >/dev/null || listFailed="${listFailed}${1}, "
}
addToListError()
{
    echo "$listError" | grep "$1" >/dev/null || listError="${listError}${1}, "
}
printTestHeader()
{
    [ ! "$isExecutionOutput" ] && return
    # If the first line of the test script starts with '" Test', include this as
    # the test's synopsis in the test header. Otherwise, just print the test
    # name. Limit the test header to one unwrapped output line, i.e. truncate to
    # 80 characters. 
    sed -n -e "1s/^\\d034 \\(Test.*\\)$/Running ${2}: \\1/p" -e 'tx' -e "1cRunning ${2}:" -e ':x' "$1" | sed '/^.\{80,\}/s/\(^.\{,76\}\).*$/\1.../'
}

compareOutput()
{
    diff -q "$1" "$2" >/dev/null
    if [ $? -eq 0 ]; then
	let thisOk+=1
	executionOutput "OK (out)"
    elif [ $? -eq 1 ]; then
	let thisFail+=1
	if [ "$isExecutionOutput" ]; then
	    echo "FAIL (out): expected output                                                                                 |   actual output" | sed 's/\(^.\{'$((${COLUMNS:-80}/2-2))'\}\) *\(|.*$\)/\1\2/'
	    diff --side-by-side --width ${COLUMNS:-80} "$1" "$2"
	fi
    else
	let thisError+=1
	executionOutput "ERROR (out): diff operation failed."
    fi
}

runTest()
{
    if [ ! -f "$1" ]; then
	let cntError+=1
	echo >&2 "ERROR: Test file \"$1\" doesn't exist."
	return
    fi

    readonly testDirspec=$(dirname -- "$1")
    readonly testFile=$(basename -- "$1")
    readonly testFilespec=$(cd "$testDirspec" && echo "${PWD}/${testFile}") || { echo >&2 "ERROR: Cannot determine absolute filespec!"; exit 1; }
    readonly testName=${testFile%.*}

    # The setup script is not a test, silently skip it. 
    [ "$testFile" == "$vimLocalSetupScript" ] && return

    readonly testOk=${testName}.ok
    readonly testOut=${testName}.out
    readonly testMsgok=${testName}.msgok
    readonly testMsgout=${testName}.msgout
    readonly testTap=${testName}.tap

    pushd "$testDirspec"

    # Remove old output files from the previous test run. 
    local file
    for file in "$testOut" "$testMsgout" "$testTap"
    do
	[ -f "$file" ] && rm "$file"
    done

    # Source local setup script before the testfile. 
    local vimLocalSetup
    [ -f "$vimLocalSetupScript" ] && vimLocalSetup=" -S \"${vimLocalSetupScript}\""

    printTestHeader "$testFile" "$testName"

    # Default VIM arguments and options:
    # -n		No swapfile. 
    # :set nomore	Suppress the more-prompt when the screen is filled with messages
    #			or output to avoid blocking. 
    # :set verbosefile	Capture all messages in a file. 
    # :let $vimVariableTestName = Absolute test filespec. 
    # :let $vimVariableOptionsName = Options for this test run, concatenated with ','. 
    $vimExecutable -n -c "let ${vimVariableTestName}='${testFilespec//'/''}'|set nomore verbosefile=${testMsgout// /\\ }" ${vimArguments}${vimLocalSetup} -S "${testFile}"
    # "}'"

    let thisTests=0
    let thisRun=0
    let thisOk=0
    let thisFail=0
    let thisError=0

    # Method output. 
    if [ -r "$testOk" ]; then
	let thisTests+=1
	if [ -r "$testOut" ]; then
	    let thisRun+=1
	    compareOutput "$testOk" "$testOut" "$testName"
	else
	    let thisError+=1
	    executionOutput "ERROR (out): No test output."
	fi
    fi

    # Method message output. 
    if [ -r "$testMsgok" ]; then
	let thisTest+=1
	if [ -r "$testMsgout" ]; then
	    let thisRun+=1
	    compareMessages "$testMsgok" "$testMsgout" "$testName"
	else
	    let thisError+=1
	    executionOutput "ERROR (msgout): No test messages."
	fi
    fi

    # Method TAP. 
    let tapTestCnt=0
    if [ -r "$testTap" ]; then
	parseTapOutput "$testTap" "$testName"
    fi

    # Results evaluation. 
    if [ $thisTests -eq 0 ]; then
	let thisError+=1
	executionOutput "ERROR: No test results at all."
    else
	let cntTests+=thisTests
    fi
    if [ $thisRun -ge 1 ]; then
	let cntRun+=thisRun
    fi
    if [ $thisOk -ge 1 ]; then
	let cntOk+=thisOk
    fi
    if [ $thisFail -ge 1 ]; then
	let cntFail+=thisFail
	addToListFailed "$testName%"
    fi
    if [ $thisError -ge 1 ]; then
	let cntError+=thisError
	addToListError "$testName%"
    fi

    popd
}

readonly scriptDir=$(readonly scriptFile="$(type -P -- "$0")" && dirname -- "$scriptFile" || exit 1)
[ -d "$scriptDir" ] || { echo >&2 "ERROR: cannot determine script directory!"; exit 1; } 

vimExecutable=''
vimArguments=''
vimLocalSetupScript=_setup.vim
vimGlobalSetupScript=${scriptDir}/$(basename "$0")Setup.vim
[ -r "$vimGlobalSetupScript" ] && vimArguments="$vimArguments -S '${vimGlobalSetupScript}'"
vimVariableOptionsName=g:runVimTests
vimVariableOptionsValue=''
vimVariableTestName=g:runVimTest

isExecutionOutput='true'

if [ $# -eq 0 ]; then
    printUsage "$0"
    exit 1
fi
while [ $# -ne 0 ]
do
    case "$1" in
	--help|-h|-\?)	    shift; printLongUsage "$0"; exit 1;;
	--pure)		    shift
			    vimArguments="-N -u NONE $vimArguments"
			    vimVariableOptionsValue="${vimVariableOptionsValue}pure,"
			    ;;
	--default)	    shift
			    vimArguments="--cmd 'set rtp=$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after' -N -u NORC -c 'set rtp&' $vimArguments"
			    vimVariableOptionsValue="${vimVariableOptionsValue}default,"
			    ;;
	--runtime)	    shift; vimArguments="$vimArguments -S '$HOME/.vim/$1'"; shift;;
	--source)	    shift; vimArguments="$vimArguments -S '$1'"; shift;;
	--vimexecutable)    shift; vimExecutable=$1; shift;;
	--graphical|-g)	    shift; vimArguments="-g $vimArguments";;
	--summaryonly)	    shift; isExecutionOutput='true';;
	--debug)	    shift; vimVariableOptionsValue="${vimVariableOptionsValue}debug,";;
	--)		    shift; break;;
	*)		    break;;
    esac
done
[ $# -eq 0 ] && { printLongUsage "$0"; exit 1; }
vimVariableOptionsValue=${vimVariableOptionsName%,}
vimArguments="$vimArguments --cmd \"let ${vimVariableOptionsName}='${vimVariableOptionsValue}'\""

let cntTests=0
let cntRun=0
let cntOk=0
let cntFail=0
let cntError=0
listFailed=""
listError=""

executionOutput
if [ "$vimArguments" ]; then
    executionOutput "Starting test run with these VIM options:"
    executionOutput "$vimExecutable $vimArguments"
elif
    executionOutput "Starting test run."
fi
executionOutput

for arg
do
    processTestEntry "$arg"
done

echo "$cntTests $(makePlural $cntTests 'test'), $cntRun run: $cndOk OK, $cntFail $(makePlural $cntFail 'failure'), $cntError $(makePlural $cntError 'error')."
[ "$listFailed" ] && echo "Failed tests: $listFailed"
[ "$listError" ] && echo "Tests with errors: $listError"

let cntAllProblems=cntError+cntFail
if [ $cntAllProblems -ne 0 ]; then
    exit 1
fi


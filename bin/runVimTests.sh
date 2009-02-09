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

# Enable extended file pattern matching operators from ksh
# (?(pattern-list), !(pattern-list), ...) in bash. 
shopt -qs extglob

initialize()
{
    readonly scriptDir=$(readonly scriptFile="$(type -P -- "$0")" && dirname -- "$scriptFile" || exit 1)
    [ -d "$scriptDir" ] || { echo >&2 "ERROR: cannot determine script directory!"; exit 1; } 

    # Prerequisite VIM script to match the message assumptions against the actual
    # message output. 
    readonly runVimMsgFilterScript=${scriptDir}/runVimMsgFilter.vim
    if [ ! -r "$runVimMsgFilterScript" ]; then
	echo >&2 "ERROR: Script prerequisite \"${runVimMsgFilterScript}\" does not exist!"
	exit 1
    fi

    # VIM variables set by the test framework. 
    readonly vimVariableOptionsName=g:runVimTests
    vimVariableOptionsValue=
    readonly vimVariableTestName=g:runVimTest
}

printUsage()
{
    # This is the short help when launched with no or incorrect arguments. 
    # It is printed to stderr to avoid accidental processing. 
    cat >&2 <<SHORTHELPTEXT
Usage: "$(basename "$0")" [--pure|--default] [--source filespec [--source filespec [...]]] [--runtime plugin/file.vim [--runtime autoload/file.vim [...]]] [--vimexecutable path/to/vim] [-g|--graphical] [--summaryonly] [--debug] [--help] test001.vim|testsuite.txt|path/to/testdir/ [...]
Try "$(basename "$0")" --help for more information.
SHORTHELPTEXT
}
printLongUsage()
{
    # This is the long "man page" when launched with the help argument. 
    # It is printed to stdout to allow paging with 'more'. 
    cat <<HELPTEXT
A small unit testing framework for VIM. 

Usage: "$(basename "$0")" [--pure|--default] [--source filespec [--source filespec [...]]] [--runtime plugin/file.vim [--runtime autoload/file.vim [...]]] [--vimexecutable path/to/vim] [-g|--graphical] [--summaryonly] [--debug] [--help] test001.vim|testsuite.txt|path/to/testdir/ [...]
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
parseCommandLineArguments()
{
    # VIM executable and command-line arguments. 
    vimExecutable='vim'
    vimArguments=

    # Use silent-batch mode (-e -s) when the test log is not printed to stdout (but
    # redirected into a file or pipe). This avoids that the output is littered with
    # escape sequences and suppresses the VIM warning: "Vim: Warning: Output is not
    # to a terminal". (Just passing '-T dumb' is not enough.)
    [ -t 1 ] || vimArguments="$vimArguments -e -s"

    # Optional user-provided setup scripts. 
    readonly vimLocalSetupScript=_setup.vim
    readonly vimGlobalSetupScript=${scriptDir}/$(basename -- "$0")Setup.vim
    [ -r "$vimGlobalSetupScript" ] && vimArguments="$vimArguments -S '${vimGlobalSetupScript}'"

    isExecutionOutput='true'

    if [ $# -eq 0 ]; then
	printUsage
	exit 1
    fi
    while [ $# -ne 0 ]
    do
	case "$1" in
	    --help|-h|-\?)	    shift; printLongUsage; exit 1;;
	    --pure)		    shift
				    vimArguments="-N -u NONE $vimArguments"
				    vimVariableOptionsValue="${vimVariableOptionsValue}pure,"
				    ;;
	    --default)		    shift
				    vimArguments="--cmd 'set rtp=\$VIM/vimfiles,\$VIMRUNTIME,\$VIM/vimfiles/after' -N -u NORC -c 'set rtp&' $vimArguments"
				    vimVariableOptionsValue="${vimVariableOptionsValue}default,"
				    ;;
	    --runtime)		    shift; vimArguments="$vimArguments -S '$HOME/.vim/$1'"; shift;;
	    --source)		    shift; vimArguments="$vimArguments -S '$1'"; shift;;
	    --vimexecutable)	    shift
				    vimExecutable=$1
				    shift
				    if ! type -P -- "$vimExecutable" >/dev/null; then
					echo >&2 "ERROR: \"${vimExecutable}\" is not a VIM executable!"
					exit 1
				    fi
				    ;;
	    --graphical|-g)	    shift
				    gvimExecutable=$(echo "$vimExecutable" | sed -e 's+^vim$+gvim+' -e 's+/vim$+/gvim+')
				    if [ "$gvimExecutable" != "$vimExecutable" ] && type -- -P "$gvimExecutable" >/dev/null; then
					vimExecutable=$gvimExecutable
				    else
					vimArguments="-g $vimArguments"
				    fi
				    ;;
	    --summaryonly)	    shift; isExecutionOutput='true';;
	    --debug)		    shift; vimVariableOptionsValue="${vimVariableOptionsValue}debug,";;
	    --)			    shift; break;;
	    *)			    break;;
	esac
    done
    [ $# -eq 0 ] && { printUsage; exit 1; }
    vimVariableOptionsValue=${vimVariableOptionsValue%,}
    vimArguments="$vimArguments --cmd \"let ${vimVariableOptionsName}='${vimVariableOptionsValue}'\""

    readonly tests="$@"
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
    typeset -r suiteDir=$(dirname -- "$1")
    typeset -r suiteFilename=$(basename -- "$1")

    # Change to suite directory so that relative paths and filenames are
    # resolved correctly. 
    pushd "$suiteDir" >/dev/null

    local testEntry
    local IFS=$'\n'
    for testEntry in $(cat -- "$suiteFilename")
    do
	case "$testEntry" in
	    \#*|'') continue;;
	esac
	processTestEntry "$testEntry"
    done

    popd >/dev/null
}
runDir()
{
    local testFilename
    for testFilename in "${1}/"*.vim
    do
	runTest "$testFilename"
    done
}

addToListFailed()
{
    echo "$listFailed" | grep -- "$1" >/dev/null || listFailed="${listFailed}${1}, "
}
addToListError()
{
    echo "$listError" | grep -- "$1" >/dev/null || listError="${listError}${1}, "
}
printTestHeader()
{
    [ ! "$isExecutionOutput" ] && return
    # If the first line of the test script starts with '" Test', include this as
    # the test's synopsis in the test header. Otherwise, just print the test
    # name. Limit the test header to one unwrapped output line, i.e. truncate to
    # 80 characters. 
    sed -n -e "1s/^\\d034 \\(Test.*\\)$/Running ${2}: \\1/p" -e 'tx' -e "1cRunning ${2}:" -e ':x' -- "$1" | sed '/^.\{80,\}/s/\(^.\{,76\}\).*$/\1.../'
}

compareOutput()
{
    diff -q -- "$1" "$2" >/dev/null
    if [ $? -eq 0 ]; then
	let thisOk+=1
	executionOutput "OK (out)"
    elif [ $? -eq 1 ]; then
	let thisFail+=1
	if [ "$isExecutionOutput" ]; then
	    printf "%-$((${COLUMNS:-80}/2-2))s| %s\n" "FAIL (out): expected output" "actual output"
	    diff --side-by-side --width ${COLUMNS:-80} -- "$1" "$2"
	fi
    else
	let thisError+=1
	executionOutput "ERROR (out): diff operation failed."
    fi
}
compareMessages()
{
    typeset -r testMsgresult="${3}.msgresult"
    [ -f "$testMsgresult" ] && rm "$testMsgresult"

    # Use silent-batch mode (-e -s) to match the message assumptions against the
    # actual message output. 
    vim -N -u NONE -e -s -c 'set nomore' -S "$runVimMsgFilterScript" -c 'RunVimMsgFilter' -c 'quitall!' -- "$testMsgok"

    if [ ! -r "$testMsgresult" ]; then
	let thisError+=1
	executionOutput "ERROR (msgout): Evaluation of test messages failed."
	return
    fi
    typeset -r evaluationResult=$(sed -n '1s/^\([A-Z][A-Z]*\).*/\1/p' -- "$testMsgresult")
    case "$evaluationResult" in
	OK)	let thisOk+=1;;
	FAIL)	let thisFail+=1;;
	ERROR)	let thisError+=1;;
	*)	echo >&2 "ASSERT: Received unknown result \"${evaluationResult}\" from RunVimMsgFilter."; exit 1;;
    esac
    if [ "$isExecutionOutput" ]; then
	cat -- "$testMsgresult"
    fi
}
parseTapOutput()
{
    local tapTestNum=
    local tapTestCnt=0

    local tapLine
    local IFS=$'\n'
    while read tapLine
    do
	case "$tapLine" in
	    \#*|'')		continue;;
	    ok*)		let thisOk+=1   thisRun+=1 tapTestCnt+=1;;
	    not\ ok*)		let thisFail+=1 thisRun+=1 tapTestCnt+=1;;
	    +([0-9])..+([0-9]))	local startNum=${tapLine%%.*}
				local endNum=${tapLine##*.}
				let tapTestNum=endNum-startNum+1
				;;
	esac
    done < "$1"

    if [ "$isExecutionOutput" ]; then
	cat -- "$1"
    fi

    if [ ! "$tapTestNum" ]; then
	let thisTests+=tapTestCnt
	return
    fi

    local tapTestDifference
    let tapTestDifference=tapTestNum-tapTestCnt
    [ $tapTestDifference -lt 0 ] && let tapTestDifference*=-1
    if [ $tapTestCnt -lt $tapTestNum ]; then
	let thisTests+=tapTestNum
	executionOutput "ERROR (tap): Not all $tapTestNum planned tests have been executed, $tapTestDifference $(makePlural $tapTestDifference 'test') missed."
	let thisError+=1
    elif [ $tapTestCnt -gt $tapTestNum ]; then
	let thisTests+=tapTestCnt
	executionOutput "ERROR (tap): $tapTestDifference more test $(makePlural $tapTestDifference 'execution') than planned."
	let thisError+=1
    else
	let thisTests+=tapTestNum
    fi
}

runTest()
{
    if [ ! -f "$1" ]; then
	let cntError+=1
	echo >&2 "ERROR: Test file \"$1\" doesn't exist."
	return
    fi

    typeset -r testDirspec=$(dirname -- "$1")
    typeset -r testFile=$(basename -- "$1")
    typeset -r testFilespec=$(cd "$testDirspec" && echo "${PWD}/${testFile}") || { echo >&2 "ERROR: Cannot determine absolute filespec!"; exit 1; }
    typeset -r testName=${testFile%.*}

    # The setup script is not a test, silently skip it. 
    [ "$testFile" == "$vimLocalSetupScript" ] && return

    typeset -r testOk=${testName}.ok
    typeset -r testOut=${testName}.out
    typeset -r testMsgok=${testName}.msgok
    typeset -r testMsgout=${testName}.msgout
    typeset -r testTap=${testName}.tap

    pushd "$testDirspec" >/dev/null

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
    eval "$vimExecutable -n -c \"let ${vimVariableTestName}='${testFilespec//\'/\'\'}'|set nomore verbosefile=${testMsgout// /\\ }\" ${vimArguments}${vimLocalSetup} -S \"${testFile}\""
    # "}'"

    local thisTests=0
    local thisRun=0
    local thisOk=0
    local thisFail=0
    local thisError=0

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
	let thisTests+=1
	if [ -r "$testMsgout" ]; then
	    let thisRun+=1
	    compareMessages "$testMsgok" "$testMsgout" "$testName"
	else
	    let thisError+=1
	    executionOutput "ERROR (msgout): No test messages."
	fi
    fi

    # Method TAP. 
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
	addToListFailed "$testName"
    fi
    if [ $thisError -ge 1 ]; then
	let cntError+=thisError
	addToListError "$testName"
    fi

    popd >/dev/null
}

execute()
{
    cntTests=0
    cntRun=0
    cntOk=0
    cntFail=0
    cntError=0
    listFailed=
    listError=

    executionOutput
    if [ "$vimArguments" ]; then
	executionOutput "Starting test run with these VIM options:"
	executionOutput "$vimExecutable $vimArguments"
    else
	executionOutput "Starting test run."
    fi
    executionOutput

    echo "$tests"
    exit
    for arg in "$tests"
    do
	processTestEntry "$arg"
    done

    echo
    echo "$cntTests $(makePlural $cntTests 'test'), $cntRun run: $cntOk OK, $cntFail $(makePlural $cntFail 'failure'), $cntError $(makePlural $cntError 'error')."
    [ "$listFailed" ] && echo "Failed tests: ${listFailed%, }"
    [ "$listError" ] && echo "Tests with errors: ${listError%, }"

    let cntAllProblems=cntError+cntFail
    if [ $cntAllProblems -ne 0 ]; then
	exit 1
    fi
}

initialize
parseCommandLineArguments "$@"
execute


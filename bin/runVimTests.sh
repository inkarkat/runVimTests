#!/bin/bash
##########################################################################/^--#
##
# FILE: 	runVimTests.sh
# PRODUCT:	runVimTests
# AUTHOR: 	Ingo Karkat <ingo@karkat.de>
# DATE CREATED:	02-Feb-2009
#
###############################################################################
# CONTENTS:
#   This script implements a testing framework for Vim.
#
# REMARKS:
#
# DEPENDENCIES:
#   - Requires Bash 3.0 or higher.
#   - GNU diff, grep, readlink, sed, sort, tr, uniq.
#   - runVimMsgFilter.vim, located in this script's directory.
#
# Copyright: (C) 2009-2013 Ingo Karkat
#   The VIM LICENSE applies to this script; see 'vim -c ":help copyright"'.
#
# FILE_SCCS = "@(#)runVimTests.sh	1.23.016	(25-Mar-2013)	runVimTests";
#
# REVISION	DATE		REMARKS
#  1.23.016	25-Mar-2013	Add support for Mac OS X; thanks to Israel
#				Chauca Fuentes for sending a pull request.
#				Add support for BSD.
#  1.21.015	06-Mar-2013	CHG: Drop comma in the lists of failed / skipped
#				/ errored test and add .vim extension, so that
#				the file list can be copy-and-pasted to another
#				runVimTests invocation or :argedit'ed in Vim.
#				CHG: Change default mode from "user" to
#				"default"; this is what I use all the time,
#				anyway, as the "user" mode is too susceptible to
#				incompatible customizations.
#   1.18.014	19-Oct-2011	BUG: When everything is skipped and no TAP tests
#				have been run, this would be reported as a "No
#				test results at all" error.
#				CHG: Bail out only aborts from the current
#				recursion level, i.e. it skips further tests in
#				the same directory, suite, or passed arguments,
#				but not testing entirely. Otherwise, a
#				super-suite that includes individual suites
#				would be aborted by a single bail out.
#   1.17.013	04-Sep-2011	BUG: When runVimTests.sh is invoked via a
#				relative filespec, $scriptDir is relative and
#				this makes the message output comparison
#				(but not the prerequisite check) fail with
#				"ERROR (msgout): Evaluation of test messages
#				failed." when CWD has changed into $testDirspec.
#				Thanks to Javier Rojas for sending a patch.
#				Use "readlink -f" to resolve symlinks and into
#				absolute dirspec. This also handles the case
#				when runVimTests.sh, but not runVimMsgFilter.vim
#				is symlinked into another bin directory.
#   1.14.012	02-Jun-2010	Now also handling *.suite files with Windows
#				(CR-LF) line endings.
#   1.13.011	28-May-2009	ENH: Now including SKIP reasons in the summary
#				(identical reasons are condensed and counted)
#				when not running with verbose output. I always
#				wanted to know why certain tests were skipped.
#   1.12.010	14-Mar-2009	Added quoting of regexp in addToList(), which is
#				needed in Bash 3.0 and 3.1.
#				Now checking Bash version.
#				Only exiting with exit code 1 in case of test
#				failures; using code 2 for invocation errors
#				(i.e. wrong command-line arguments) or
#				missing prerequisites and code 3 for internal
#				errors.
#   1.11.009	12-Mar-2009	ENH: TODO tests are reported in test summary.
#				ENH: TAP output is also parsed for bail out
#				message.
#			    	ENH: TAP output is now parsed for # SKIP and #
#				TODO directives. The entire TAP test is skipped
#				if a 1..0 plan is announced. Non-verbose TAP
#				output now also includes succeeding TODO tests
#				and any details in the lines following it.
#				Factored out addToList(), which now only matches
#				exact test names, not partial overlaps.
#   1.10.008	06-Mar-2009	ENH: Also counting test files.
#				ENH: Message output is now parsed for signals to
#				this test driver. Implemented signals: BAILOUT!,
#				ERROR, SKIP, SKIP(out), SKIP(msgout), SKIP(tap).
#				Summary reports skipped tests and tests with
#				skips.
#				Changed API for echoStatus.
#   1.00.007	02-Mar-2009	Reviewed for publication.
#	006	28-Feb-2009	BF: FAIL (msgout) and FAIL (tap) didn't print
#				test header in non-verbose mode.
#				Refactored :printTestHeader so that it does the
#				check for already printed header itself.
#	005	25-Feb-2009	Now only printing failed tests and errors, and
#				only explicitly mentioning the test if it wasn't
#				successful. This greatly reduces the visual
#				output the user has to scan.
#				Added --verbose option to also print successful
#				tests, the previous default behavior.
#				Added empty line between individual tests.
#	004	24-Feb-2009	Added short options -0/1/2 for the plugin load
#				level.
#	003	19-Feb-2009	Added explicit option '--user' for the default
#				Vim mode, and adding 'user' to
#				%vimVariableOptionsValue% (so that tests can
#				easily check for that mode). Command-line
#				argument parsing now ensures that only one mode
#				is specified.
#	002	11-Feb-2009	Completed porting of Windows shell script.
#	001	02-Feb-2009	file creation
###############################################################################

# Enable extended file pattern matching operators from ksh
# (?(pattern-list), !(pattern-list), ...) in Bash.
shopt -qs extglob

# https://github.com/dominictarr/JSON.sh/pull/2#issuecomment-2526006
readlinkEmulation()
{
    cd "$(dirname $1)"
    local filename=$(basename $1)
    if [ -h "$filename" ]; then
	readlinkEmulation "$(readlink $filename)"
    else
	printf %s "$(pwd -P)/${filename}"
    fi
}
readlinkWrapper()
{
    readlink -nf "$@" 2>/dev/null || readlinkEmulation "$@"
}
initialize()
{
    [ ${BASH_VERSINFO[0]} -ge 3 ] || { echo >&2 "ERROR: This script requires Bash 3.0 or higher!"; exit 2; }

    readonly scriptDir=$([ "${BASH_SOURCE[0]}" ] && absoluteScriptFile="$(readlinkWrapper "${BASH_SOURCE[0]}")" && dirname -- "$absoluteScriptFile" || exit 3)
    [ -d "$scriptDir" ] || { echo >&2 "ERROR: Cannot determine script directory!"; exit 3; }

    skipsRecord=${TEMP:-/tmp}/skipsRecord.txt.$$
    [ -f "$skipsRecord" ] && { rm -- "$skipsRecord" || skipsRecord=; }

    # Prerequisite Vim script to match the message assumptions against the actual
    # message output.
    readonly runVimMsgFilterScript=${scriptDir}/runVimMsgFilter.vim
    if [ ! -r "$runVimMsgFilterScript" ]; then
	echo >&2 "ERROR: Script prerequisite \"${runVimMsgFilterScript}\" does not exist!"
	exit 2
    fi

    # Vim variables set by the test framework.
    readonly vimVariableOptionsName=g:runVimTests
    vimVariableOptionsValue=
    readonly vimVariableTestName=g:runVimTest

    # Vim mode of sourcing scripts.
    vimMode=

    # Default Vim executable.
    vimExecutable='vim'

    # Default Vim command-line arguments.
    #
    # Always wait for the edit session to finish (only applies to the GUI
    # version, is ignored for the terminal version), so that this script can
    # process the files generated by the test run.
    vimArguments=-f

    # Use silent-batch mode (-es) when the test log is not printed to stdout (but
    # redirected into a file or pipe). This avoids that the output is littered with
    # escape sequences and suppresses the Vim warning and a small delay:
    # "Vim: Warning: Output is not to a terminal".
    # (Just passing '-T dumb' is not enough.)
    [ -t 1 ] || vimArguments="$vimArguments -es"

    # Optional user-provided setup scripts.
    readonly vimLocalSetupScript=_setup.vim
    readonly vimGlobalSetupScript=${scriptDir}/$(basename -- "$0")Setup.vim
    [ -r "$vimGlobalSetupScript" ] && vimArguments="$vimArguments $(vimSourceCommand "$vimGlobalSetupScript")"

    verboseLevel=0
    isExecutionOutput='true'
    isBailOut=
}
verifyVimModeSetOnlyOnce()
{
    if [ "$vimMode" ]; then
	{ echo "ERROR: \"${1}\": Mode already set!"; echo; printShortUsage; } >&2; exit 2
    fi
}

printShortUsage()
{
    cat <<SHORTHELPTEXT
Usage: "$(basename "$0")" [-0|--pure|-1|--default|-2|--user] [--source filespec [--source filespec [...]]] [--runtime plugin/file.vim [--runtime autoload/file.vim [...]]] [--vimexecutable path/to/vim] [-g|--graphical] [--summaryonly|-v|--verbose] [-d|--debug] [-?|-h|--help] test001.vim|testsuite.txt|path/to/testdir/ [...]
SHORTHELPTEXT
}
printUsage()
{
    # This is the short help when launched with no or incorrect arguments.
    # It is printed to stderr to avoid accidental processing.
    printShortUsage >&2
    cat >&2 <<MOREHELP
Try "$(basename "$0")" --help for more information.
MOREHELP
}
printLongUsage()
{
    # This is the long "man page" when launched with the help argument.
    # It is printed to stdout to allow paging with 'more'.
    cat <<HELPDESCRIPTION
A testing framework for Vim.
HELPDESCRIPTION
    echo
    printShortUsage
    cat <<HELPTEXT
    -0|--pure		Start Vim without loading .vimrc and plugins, but in
			nocompatible mode. Adds 'pure' to ${vimVariableOptionsName}.
    -1|--default	Start Vim only with default settings and plugins,
			without loading user .vimrc and plugins.
			Adds 'default' to ${vimVariableOptionsName}.
    -2|--user		Start Vim with user .vimrc and plugins.
			Adds 'user' to ${vimVariableOptionsName}.
    --source filespec	Source filespec before test execution.
    --runtime filespec	Source filespec relative to ~/.vim. Can be used to
			load the script-under-test when using --pure.
    --vimexecutable	Use passed Vim executable instead of the one
	path/to/vim	found in \$PATH.
    -g|--graphical	Use GUI version of Vim.
    --summaryonly	Do not show detailed transcript and differences, during
			test run, only summary.
    -v^|--verbose	Show passed tests and more details during test
			execution.
    -d|--debug		Test debugging mode: Adds 'debug' to ${vimVariableOptionsName}
			variable inside Vim (so that tests do not exit or can
			produce additional debug info).
HELPTEXT
}

executionOutput()
{
    [ "$isExecutionOutput" ] && echo "$@"
}
echoOk()
{
    [ "$isExecutionOutput" -a $verboseLevel -gt 0 ] && echo "OK ($1)"
}
echoStatusForced()
{
    local -r status="${1}${2:+ (}${2}${2:+)}"
    echo "${status}${3:+: }$3"
}
echoStatus()
# $1 status
# $2 method (or empty)
# $3 explanation (or empty)
{
    printTestHeader "$testFile" "$testName"
    if [ "$isExecutionOutput" ]; then
	echoStatusForced "$@"
    fi
}
echoSkip()
{
    local -r skipMethod=${1:5:${#1}-6}
    [ "$skipsRecord" ] && echoStatusForced "SKIP" "$skipMethod" "$2" >> "$skipsRecord"
    [ "$isExecutionOutput" -a $verboseLevel -gt 0 ] && echoStatus "SKIP" "$skipMethod" "$2"
}
echoError()
{
    echoStatus 'ERROR' "$@"
}
echoFail()
{
    echoStatus 'FAIL' "$@"
}
listSkipReasons()
{
    [ ! "$skipsRecord" -o $cntSkip -eq 0 -o ! -f "$skipsRecord" ] && return
    sort --ignore-case -- "$skipsRecord" | uniq -i -c | sed 's/^ \{4\}/ /'
    case "$DEBUG" in *skipsRecord*) ;; *) rm -- "$skipsRecord";; esac
}

makePlural()
{
    if [ $1 -eq 1 ]; then
	echo "$2"
    else
	echo "${2}s"
    fi
}
vimSourceCommand()
{
    # Note: With -S {file}, Vim wants {file} escaped for Ex commands. (It should
    # really escape {file} itself, as it does for normal {file} arguments.)
    # As we don't know the Vim version, we cannot work around this via
    #	-c "execute 'source' fnameescape('${testfile}')"
    # Thus, we just escape spaces and hope that no other special string (like %,
    # # or <cword>) is part of a test filename.
    echo "-S '${1// /\\ }'"
}

processTestEntry()
{
    if [ -d "$1" ]; then
	runDir "$1"
	isBailOut=
    elif [ "${1##*.}" = "vim" ]; then
	runTest "$1"
    elif [ -r "$1" ]; then
	runSuite "$1"
	isBailOut=
    else
	let cntError+=1
	echo >&2 "ERROR: Suite file \"${1}\" doesn't exist."
    fi
}

runSuite()
{
    local -r suiteDir=$(dirname -- "$1")
    local -r suiteFilename=$(basename -- "$1")

    # Change to suite directory so that relative paths and filenames are
    # resolved correctly.
    pushd "$suiteDir" >/dev/null

    local testEntry
    local IFS=$'\n'
    for testEntry in $(cat -- "$suiteFilename" | tr -d '\015')
    do
	case "$testEntry" in
	    \#*|'') continue;;
	esac
	[ "$isBailOut" ] && break
	processTestEntry "$testEntry"
    done

    popd >/dev/null
}
runDir()
{
    local testFilename
    for testFilename in "${1}/"*.vim
    do
	[ "$isBailOut" ] && break
	runTest "$testFilename"
    done
}

addToList()
{
    eval local listName=\$list$1
    if [[ ! "$listName" =~ "(^|\ )${2}\.vim(\ |$)" ]]; then
	eval list${1}=\"${listName}${2}.vim \"
    fi
}
addToListSkipped()
{
    addToList 'Skipped' "$1"
}
addToListSkips()
{
    addToList 'Skips' "$1"
}
addToListFailed()
{
    addToList 'Failed' "$1"
}
addToListError()
{
    addToList 'Error' "$1"
}
addToListTodo()
{
    addToList 'Todo' "$1"
}
printTestHeader()
{
    [ "$isPrintedHeader" ] && return
    isPrintedHeader='true'
    [ ! "$isExecutionOutput" ] && return

    local -r headerMessage="${2}:"
    echo
    # If the first line of the test script starts with '" Test', include this as
    # the test's synopsis in the test header. Otherwise, just print the test
    # name. Limit the test header to one unwrapped output line, i.e. truncate to
    # 80 characters.
    sed -n "
	1s/^\" \\(Test.*\\)$/${headerMessage} \\1/p
	t
	1c\\
${headerMessage}" "$1" | sed '/^.\{80\}/s/\(^.\{1,76\}\).*$/\1.../'
}

parseSignal()
{
    [ "$isBailOut" ] && return
    case "$1" in
	BAILOUT!)	isBailOut='true'
			let thisError+=1
			echoStatus 'BAIL OUT' '' "$2"
			;;
	ERROR)	    	let thisError+=1
			echoError '' "$2"
			;;
	SKIP)		isSkipOut='true'
			isSkipMsgout='true'
			isSkipTap='true'
			;;
	SKIP\(out\))	isSkipOut='true';;
	SKIP\(msgout\))	isSkipMsgout='true';;
	SKIP\(tap\))	isSkipTap='true';;
	*)		echo >&2 "ASSERT: Received unknown signal \"${1}\" in message output."; exit 3;;
    esac
    case "$1" in
	SKIP*)		echoSkip "$1" "$2"
    esac
}
parseMessageOutputForSignals()
{
    if [ ! -r "$testMsgout" ]; then
	let thisError+=1
	echoError '' "Could not capture message output."
	return
    fi

    # Vim doesn't put a final newline at the end of the last written message.
    # This incomplete last line is in turn not processed by 'read'. Fix this by
    # appending a final newline.
    echo >> "$testMsgout"

    local signalLine
    local IFS=' '
    while read marker signal description
    do
	if [ "$marker" = "runVimTests:" ]; then
	    parseSignal "$signal" "$description"
	fi
    done < "$testMsgout"
}

compareOutput()
{
    diff -q -- "$1" "$2" >/dev/null
    if [ $? -eq 0 ]; then
	let thisOk+=1
	echoOk 'out'
    elif [ $? -eq 1 ]; then
	let thisFail+=1
	if [ "$isExecutionOutput" ]; then
	    printTestHeader "$testFile" "$testName"
	    printf "%-$((${COLUMNS:-80}/2-2))s|   %s\n" "FAIL (out): expected output" "actual output"
	    diff --side-by-side --width ${COLUMNS:-80} -- "$1" "$2"
	fi
    else
	let thisError+=1
	echoError 'out' 'diff operation failed.'
    fi
}
compareMessages()
{
    local -r testMsgresult="${3}.msgresult"
    [ -f "$testMsgresult" ] && rm "$testMsgresult"

    # Use silent-batch mode (-es) to match the message assumptions against the
    # actual message output.
    eval "vim -N -u NONE -es -c 'set nomore' $(vimSourceCommand "$runVimMsgFilterScript") -c 'RunVimMsgFilter' -c 'quitall!' -- \"$testMsgok\""

    if [ ! -r "$testMsgresult" ]; then
	let thisError+=1
	echoError 'msgout' 'Evaluation of test messages failed.'
	return
    fi
    local -r evaluationResult=$(sed -n '1s/^\([A-Z][A-Z]*\).*/\1/p' "$testMsgresult")
    local isPrintEvaluation='true'
    case "$evaluationResult" in
	OK)	let thisOk+=1
		if [ $verboseLevel -eq 0 ]; then
		    isPrintEvaluation=
		fi
		;;
	FAIL)	let thisFail+=1;;
	ERROR)	let thisError+=1;;
	*)	echo >&2 "ASSERT: Received unknown result \"${evaluationResult}\" from RunVimMsgFilter."; exit 3;;
    esac
    if [ "$isExecutionOutput" -a "$isPrintEvaluation" ]; then
	printTestHeader "$testFile" "$testName"
	cat -- "$testMsgresult"
    fi
}
recordTapSkip()
{
    local -r skipReason=${1#*[sS][kK][iI][pP]}
    [ "$skipsRecord" ] && echo "SKIP (tap): ${skipReason##+( )}" >> "$skipsRecord"
}
parseTapOutput()
{
    local tapTestNum=
    local tapTestCnt=0
    local tapTestIsPrintTapOutput=

    local tapLine
    local IFS=$'\n'
    while read tapLine
    do
	case "$tapLine" in
	    \#*|'')
		continue
		;;
	    ok\ ?(+([0-9])\ )\#\ [sS][kK][iI][pP]*)
		let thisSkip+=1 	   tapTestCnt+=1
		recordTapSkip "$tapLine"
		;;
	    ok\ ?(+([0-9])\ )\#\ [tT][oO][dD][oO]*)
		let thisTodo+=1 thisRun+=1 tapTestCnt+=1; tapTestIsPrintTapOutput='true'
		;;
	    ok*)
		let thisOk+=1   thisRun+=1 tapTestCnt+=1
		;;
	    not\ ok\ ?(+([0-9])\ )\#\ [sS][kK][iI][pP]*)
		let thisSkip+=1 	   tapTestCnt+=1
		recordTapSkip "$tapLine"
		;;
	    not\ ok\ ?(+([0-9])\ )\#\ [tT][oO][dD][oO]*)
		let thisTodo+=1 thisRun+=1 tapTestCnt+=1; tapTestIsPrintTapOutput='true'
		;;
	    not\ ok*)
		let thisFail+=1 thisRun+=1 tapTestCnt+=1; tapTestIsPrintTapOutput='true'
		;;
	    Bail\ out!*)
		isBailOut='true'
		let thisError+=1
		# Ignore all further TAP output after a bail out.
		break
		;;
	    1..0)
		# No tests planned means the TAP test is skipped completely.
		let thisTests+=1
		let thisSkip+=1
		recordTapSkip "${tapLine#1..0}"
		;;
	    +([0-9])..+([0-9]))
		local startNum=${tapLine%%.*}
		local endNum=${tapLine##*.}
		let tapTestNum=endNum-startNum+1
		;;
	esac
    done < "$1"

    # Print the entire TAP output if in verbose mode, else only print
    # - failed tests
    # - successful TODO tests
    # - bail out message
    # plus any details in the lines following it.
    # (But truncate any additional TAP output after a bail out.)
    if [ "$isExecutionOutput" ]; then
	if [ $verboseLevel -gt 0 ]; then
	    # In verbose mode, the test header has already been printed.
	    cat -- "$1"
	else
	    [ "$tapTestIsPrintTapOutput" ] && printTestHeader "$testFile" "$testName"
	    local -r tapPrintTapOutputSedPattern='^not ok|^ok ([0-9]+ )?# [tT][oO][dD][oO]|^Bail out!'
	    sed -E -n "
		\${
		    /^#/H
		    x
		    /${tapPrintTapOutputSedPattern}/p
		}
		/${tapPrintTapOutputSedPattern}/{
		    x
		    /${tapPrintTapOutputSedPattern}/p
		    b
		}
		/^#/{
		    H
		    b
		}
		x
		/${tapPrintTapOutputSedPattern}/p
		/^Bail out!/q
		" "$1"
	fi
    fi

    # If this TAP test has bailed out, return the number of tests run so far,
    # but at least one (to avoid the "no test results" error).
    if [ "$isBailOut" ]; then
	if [ $tapTestCnt -eq 0 ]; then
	    let thisTests+=1
	else
	    let thisTests+=tapTestCnt
	fi
	return
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
	echoError 'tap' "Not all $tapTestNum planned tests have been executed, $tapTestDifference $(makePlural $tapTestDifference 'test') missed."
	let thisError+=1
    elif [ $tapTestCnt -gt $tapTestNum ]; then
	let thisTests+=tapTestCnt
	echoError 'tap' "$tapTestDifference more test $(makePlural $tapTestDifference 'execution') than planned."
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
    local -r testDirspec=$(dirname -- "$1")
    local -r testFile=$(basename -- "$1")
    local -r testFilespec=$(cd "$testDirspec" && echo "${PWD}/${testFile}") || { echo >&2 "ERROR: Cannot determine absolute filespec!"; exit 3; }
    local -r testName=${testFile%.*}

    # The setup script is not a test, silently skip it.
    [ "$testFile" = "$vimLocalSetupScript" ] && return

    local -r testOk=${testName}.ok
    local -r testOut=${testName}.out
    local -r testMsgok=${testName}.msgok
    local -r testMsgout=${testName}.msgout
    local -r testTap=${testName}.tap

    let cntTestFiles+=1
    pushd "$testDirspec" >/dev/null

    # Remove old output files from the previous test run.
    local file
    for file in "$testOut" "$testMsgout" "$testTap"
    do
	[ -f "$file" ] && rm "$file"
    done

    # Source local setup script before the testfile.
    local vimLocalSetup
    [ -f "$vimLocalSetupScript" ] && vimLocalSetup=" $(vimSourceCommand "${vimLocalSetupScript}")"

    local isPrintedHeader=
    [ $verboseLevel -gt 0 ] && printTestHeader "$testFile" "$testName"

    # Default Vim arguments and options:
    # -n		No swapfile.
    # :set nomore	Suppress the more-prompt when the screen is filled with messages
    #			or output to avoid blocking.
    # :set verbosefile	Capture all messages in a file.
    # :let $vimVariableTestName = Absolute test filespec.
    # :let $vimVariableOptionsName = Options for this test run, concatenated with ','.
    eval "$vimExecutable -n -c \"let ${vimVariableTestName}='${testFilespec//\'/\'\'}'|set nomore verbosefile=${testMsgout// /\\ }\" ${vimArguments}${vimLocalSetup} $(vimSourceCommand "$testFile")"

    local thisTests=0
    local thisRun=0
    local thisOk=0
    local thisSkip=0
    local thisFail=0
    local thisError=0
    local thisTodo=0

    local isSkipOut=
    local isSkipMsgout=
    local isSkipTap=
    parseMessageOutputForSignals
    if [ "$isBailOut" ]; then
	# In case of a bail out, do not run check the results of any method;
	# just say that a test has run and go straight to the results
	# evaluation.
	let thisTests=1
    else
	# Method output.
	if [ -r "$testOk" ]; then
	    let thisTests+=1
	    if [ "$isSkipOut" ]; then
		let thisSkip+=1
	    else
		if [ -r "$testOut" ]; then
		    let thisRun+=1
		    compareOutput "$testOk" "$testOut" "$testName"
		else
		    let thisError+=1
		    echoError 'out' 'No test output.'
		fi
	    fi
	fi

	# Method message output.
	if [ -r "$testMsgok" ]; then
	    let thisTests+=1
	    if [ "$isSkipMsgout" ]; then
		let thisSkip+=1
	    else
		if [ -r "$testMsgout" ]; then
		    let thisRun+=1
		    compareMessages "$testMsgok" "$testMsgout" "$testName"
		else
		    let thisError+=1
		    echoError 'msgout' 'No test messages.'
		fi
	    fi
	fi

	# Method TAP.
	if [ -r "$testTap" ]; then
	    if [ "$isSkipTap" ]; then
		let thisTests+=1	# Just assume there was only one TAP test.
		let thisSkip+=1
	    else
		parseTapOutput "$testTap" "$testName"
	    fi
	fi

	# When everything is skipped and no TAP tests have been run, this would
	# be reported as a "No test results at all" error.
	if [ $thisTests -eq 0 -a "$isSkipOut" -a "$isSkipMsgout" -a "$isSkipTap" ]; then
	    let thisTests=1
	    let thisSkip=1
	fi
    fi
    # Results evaluation.
    if [ $thisTests -eq 0 ]; then
	let thisError+=1
	echoError '' 'No test results at all.'
    else
	let cntTests+=thisTests
    fi
    if [ $thisRun -ge 1 ]; then
	let cntRun+=thisRun
    fi
    if [ $thisOk -ge 1 ]; then
	let cntOk+=thisOk
    fi
    if [ $thisSkip -ge 1 ]; then
	let cntSkip+=thisSkip
	if [ $thisSkip -eq $thisTests ]; then
	    addToListSkipped "$testName"
	else
	    addToListSkips "$testName"
	fi
    fi
    if [ $thisFail -ge 1 ]; then
	let cntFail+=thisFail
	addToListFailed "$testName"
    fi
    if [ $thisError -ge 1 ]; then
	let cntError+=thisError
	addToListError "$testName"
    fi
    if [ $thisTodo -ge 1 ]; then
	let cntTodo+=thisTodo
	addToListTodo "$testName"
    fi

    popd >/dev/null
}

execute()
{
    cntTestFiles=0
    cntTests=0
    cntRun=0
    cntOk=0
    cntSkip=0
    cntFail=0
    cntError=0
    cntTodo=0
    listSkipped=
    listSkips=
    listFailed=
    listError=
    listTodo=

    executionOutput
    if [ "$vimArguments" ]; then
	executionOutput 'Starting test run with these Vim options:'
	executionOutput "$vimExecutable $vimArguments"
    else
	executionOutput 'Starting test run.'
    fi

    for arg
    do
	[ "$isBailOut" ] && break
	processTestEntry "$arg"
    done
}
report()
{
    [ $cntTodo -ge 1 ] && local -r todoNotification=", $cntTodo TODO" || local -r todoNotification=
    [ "$isBailOut" ] && local -r bailOutNotification=' (aborted)' || local -r bailOutNotification=
    echo
    echo "$cntTestFiles $(makePlural $cntTestFiles 'file') with $cntTests $(makePlural $cntTests 'test')${bailOutNotification}; $cntSkip skipped, $cntRun run: $cntOk OK, $cntFail $(makePlural $cntFail 'failure'), $cntError $(makePlural $cntError 'error')${todoNotification}."
    [ "$listSkipped" ] && echo "Skipped tests: ${listSkipped% }"
    [ "$listSkips" ] && echo "Tests with skips: ${listSkips% }"
    listSkipReasons
    [ "$listFailed" ] && echo "Failed tests: ${listFailed% }"
    [ "$listError" ] && echo "Tests with errors: ${listError% }"
    [ "$listTodo" ] && echo "TODO tests: ${listTodo% }"

    let cntAllProblems=cntError+cntFail
    if [ $cntAllProblems -ne 0 ]; then
	exit 1
    else
	exit 0
    fi
}

#- main -----------------------------------------------------------------------

initialize

while [ $# -ne 0 ]
do
    case "$1" in
	--help|-h|-\?)	    shift; printLongUsage; exit 0;;
	--pure|-0)	    verifyVimModeSetOnlyOnce "$1"
			    shift
			    vimMode='pure'
			    ;;
	--default|-1)	    verifyVimModeSetOnlyOnce "$1"
			    shift
			    vimMode='default'
			    ;;
	--user|-2)	    verifyVimModeSetOnlyOnce "$1"
			    shift
			    vimMode='user'
			    ;;
	--runtime)	    shift; vimArguments="$vimArguments $(vimSourceCommand "$HOME/.vim/$1")"; shift;;
	--source)	    shift; vimArguments="$vimArguments $(vimSourceCommand "$1")"; shift;;
	--vimexecutable)    shift
			    vimExecutable=$1
			    shift
			    if ! type -P -- "$vimExecutable" >/dev/null; then
				echo >&2 "ERROR: \"${vimExecutable}\" is not a Vim executable!"
				exit 2
			    fi
			    ;;
	--graphical|-g)	    shift
			    gvimExecutable=$(echo "$vimExecutable" | sed -e 's+^vim$+gvim+' -e 's+/vim$+/gvim+')
			    if [ "$gvimExecutable" != "$vimExecutable" ] && type -P -- "$gvimExecutable" >/dev/null; then
				vimExecutable=$gvimExecutable
			    else
				vimArguments="-g $vimArguments"
			    fi
			    ;;
	--summaryonly)	    shift; isExecutionOutput='true';;
	--verbose|-v)	    shift; let verboseLevel+=1; skipsRecord=;;
	-d|--debug)	    shift; vimVariableOptionsValue="${vimVariableOptionsValue}debug,";;
	--)		    shift; break;;
	-*)		    { echo "ERROR: Unknown option \"${1}\"!"; echo; printShortUsage; } >&2; exit 2;;
	*)		    break;;
    esac
done
[ $# -eq 0 ] && { printUsage; exit 2; }
[ "$vimMode" ] || vimMode='default'
case $vimMode in
    pure)	vimArguments="-N -u NONE $vimArguments";;
    default)	vimArguments="--cmd 'set rtp=\$VIM/vimfiles,\$VIMRUNTIME,\$VIM/vimfiles/after' -N -u NORC -c 'set rtp&' $vimArguments";;
esac
vimVariableOptionsValue="${vimMode},${vimVariableOptionsValue}"
vimVariableOptionsValue="${vimVariableOptionsValue%,}"
vimArguments="$vimArguments --cmd \"let ${vimVariableOptionsName}='${vimVariableOptionsValue}'\""

execute "$@"
report


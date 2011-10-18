@echo off %debug%
::/*************************************************************************/^--*
::**
::* FILE: 	runVimTests.cmd
::* PRODUCT:	runVimTests
::* AUTHOR: 	Ingo Karkat <ingo@karkat.de>
::* DATE CREATED:   12-Jan-2009
::*
::*******************************************************************************
::* DESCRIPTION: 
::	This script implements a testing framework for Vim. 
::
::* REMARKS: 
::       	
::* DEPENDENCIES:
::  - GNU diff, grep, sed available through %PATH% or 'unix.cmd' script. 
::  - Optionally for SKIP summary: GNU sort, uniq available through %PATH% or
::    'unix.cmd' script. 
::  - runVimMsgFilter.vim, located in this script's directory. 
::
::* Copyright: (C) 2009-2011 Ingo Karkat
::   The VIM LICENSE applies to this script; see 'vim -c ":help copyright"'.  
::
::* REVISION	DATE		REMARKS 
::  1.16.025	28-Feb-2011	Minor: Need to un-double ^ character in
::				parseTapLineEnd; this failed the testdir-v.log
::				self-test. 
::				Align error handling of test dir without any
::				tests with runVimTests.sh: Print error message
::				instead of silently ignoring this. 
::  1.13.024	29-May-2009	BF: Also sourcing 'unix.cmd' if only optional
::				tools are not in %PATH%. 
::				BF: Now handling (most?) special characters
::				([<>|]) in SKIP reasons. 
::  1.13.023	28-May-2009	ENH: Now including SKIP reasons in the summary
::				(identical reasons are condensed and counted)
::				when not running with verbose output. I always
::				wanted to know why certain tests were skipped. 
::				Not removing temporary files if %debug%. 
::  1.12.022	14-Mar-2009	Only exiting with exit code 1 in case of test
::				failures; using code 2 for invocation errors
::				(i.e. wrong command-line arguments) and code 3
::				for internal errors. 
::  1.11.021	12-Mar-2009	ENH: TODO tests are reported in test summary. 
::				ENH: TAP output is also parsed for bail out
::				message. 
::  1.11.020	12-Mar-2009	ENH: TAP output is now parsed for # SKIP and #
::				TODO directives. The entire TAP test is skipped
::				if a 1..0 plan is announced. Non-verbose TAP
::				output now also includes succeeding TODO tests
::				and any details in the lines following it. 
::  1.10.019	06-Mar-2009	ENH: Also counting test files. 
::				ENH: Message output is now parsed for signals to
::				this test driver. Implemented signals: BAILOUT!,
::				ERROR, SKIP, SKIP(out), SKIP(msgout), SKIP(tap). 
::				Summary reports skipped tests and tests with
::				skips. 
::				Replaced duplicate processing in
::				:commandLineLoop with call to
::				:processSuiteEntry. 
::				Changed API for :echoStatus. 
::				BF: Also re-enable debugging after Vim
::				invocation in :compareMessages. 
::  1.00.018	02-Mar-2009	Reviewed for publication. 
::	017	28-Feb-2009	BF: FAIL (msgout) and FAIL (tap) didn't print
::				test header in non-verbose mode. 
::				Refactored :printTestHeader so that it does the
::				check for already printed header itself. 
::	016	24-Feb-2009	Added short options -0/1/2 for the plugin load
::				level and -d for --debug. 
::				Added check for Unix tools; Unix tools can be
::				winked in via 'unix' script. 
::				Now only printing failed tests and errors, and
::				only explicitly mentioning the test if it wasn't
::				successful. This greatly reduces the visual
::				output the user has to scan.
::				Added --verbose option to also print successful
::				tests, the previous default behavior. 
::				Added empty line between individual tests. 
::	015	19-Feb-2009	Added explicit option '--user' for the default
::				Vim mode, and adding 'user' to
::				%vimVariableOptionsValue% (so that tests can
::				easily check for that mode). Command-line
::				argument parsing now ensures that only one mode
::				is specified. 
::	014	12-Feb-2009	Shortened -e -s to -es. 
::	013	11-Feb-2009	Merged in changes resulting from the bash
::				implementation of this script: 
::				Variable renamings. 
::				Checking whether Vim executable exists and
::				whether output is to terminal. 
::	012	06-Feb-2009	Renamed g:debug to g:runVimTests; now, script
::				options 'debug' and 'pure' are appended to this
::				variable. This allows for greater flexibility
::				inside Vim and avoids that overly general
::				variable name. 
::				Added command-line options --vimexecutable,
::				--vimversion and --graphical. 
::				Added command-line option --default to launch
::				Vim without any user settings. 
::	011	05-Feb-2009	Replaced runVimTests.cfg with
::				runVimTestsSetup.vim, which is sourced on every
::				test run if it exists. I was mistaken in that
::				:runtime commands don't work in pure mode; that
::				was caused by my .vimrc not setting
::				'runtimepath' to ~/.vim! Thus, there's no need
::				for the "essential Vim scripts" and the
::				--reallypure option. 
::				Split off documentation into separate help file. 
::	010	04-Feb-2009	Suites can now also contain directories and
::				other suite files, not just tests. 
::	009	02-Feb-2009	Added --debug argument to :let g:debug = 1
::				inside Vim. 
::	008	29-Jan-2009	Added --runtime argument to simplify sourcing of
::				scripts below the user's ~/.vim directory. 
::				Essential vimscripts are now read from separate
::				runVimTests.cfg config file to remove hardcoding
::				inside this script. 
::				BF: Forgot -N -u NONE when invoking Vim for
::				runVimMsgFilter. 
::	007	28-Jan-2009	Changed counting of tests and algorithm to
::				determine whether any test results have been
::				supplied: Added counter for tests (vs. tests
::				run) and removed the special handling for the
::				TAP method. 
::				ENH: In case of a TAP test count mismatch, the
::				difference is included in the error message. 
::				ENH: All method-specific messages include the
::				method (out, msgout, tap) now. 
::				ENH: Use first comment line from test script as
::				test synopsis and include in test header. 
::	006	27-Jan-2009	ENH: Now supporting enhanced matching of
::				captured messages by filtering through custom
::				'runVimMsgFilter.vim' functionality instead of a
::				plain diff. The previous line-by-line comparison
::				was too limited and prompted test writers to
::				re-echo canonicalized messages or manipulate the
::				msgout themselves (e.g. to get rid of platform-
::				and system-specific strings like path separators
::				and dirspecs). 
::				BF: Still forgot to add to fail and error lists
::				when TAP test failed or errored. 
::				Added autoload/vimtest.vim and
::				plugin/SidTools.vim to essential Vim scripts
::				sourced with --pure (if they exist). 
::				Added --reallypure option. 
::	005	16-Jan-2009	BF: Added testname twice to fail and error lists
::				when both output and saved messages tests failed. 
::				Forgot to add when TAP test failed or errored. 
::				Moved adding to fail and error lists from the
::				individual test methods to :runTest. 
::				Now explicitly sourcing vimtap.vim in pure mode. 
::	004	15-Jan-2009	Added support for TAP unit tests. 
::	003	15-Jan-2009	Improved accuracy of :compareMessages algorithm. 
::	002	13-Jan-2009	Generalized and documented. 
::				Addded summary of failed / error test names and
::				optional suppression of test transcript. 
::	001	12-Jan-2009	file creation
::*******************************************************************************
setlocal enableextensions

set skipsRecord=%TEMP%\skipsRecord.txt
if exist "%skipsRecord%" del "%skipsRecord%"
if exist "%skipsRecord%" set skipsRecord=

call :checkUnixTools "all" || call unix --quiet || goto:prerequisiteError
call :checkUnixTools "mandatory" || goto:prerequisiteError

call :determineUserVimFilesDirspec

:: Prerequisite Vim script to match the message assumptions against the actual
:: message output. 
set runVimMsgFilterScript=%~dp0runVimMsgFilter.vim
if not exist "%runVimMsgFilterScript%" (
    echo.ERROR: Script prerequisite "%runVimMsgFilterScript%" does not exist!
    exit /B 2
)

:: Vim variables set by the test framework. 
set vimVariableOptionsName=g:runVimTests
set vimVariableOptionsValue=
set vimVariableTestName=g:runVimTest

:: Vim mode of sourcing scripts. 
set vimMode=

:: Default Vim executable. 
set vimExecutable=vim

:: Default Vim command-line arguments. 
::
:: Always wait for the edit session to finish (only applies to the GUI version,
:: is ignored for the terminal version), so that this script can process the
:: files generated by the test run. 
set vimArguments=-f

:: Optional user-provided setup scripts. 
set vimLocalSetupScript=_setup.vim
set vimGlobalSetupScript=%~dpn0Setup.vim
if exist "%vimGlobalSetupScript%" set vimArguments=%vimArguments% -S "%vimGlobalSetupScript%"

set verboseLevel=0
set isExecutionOutput=true
set EXECUTIONOUTPUT=
set isBailOut=

:: Constants
set PIPE=!PIPE!

:commandLineOptions
set arg=%~1

:: Allow short /o and -o option syntax. 
if /I "%arg:/=-%" == "-h" set arg=--help
if /I "%arg:/=-%" == "-g" set arg=--graphical
if /I "%arg:/=-%" == "-v" set arg=--verbose
if /I "%arg:/=-%" == "-0" set arg=--pure
if /I "%arg:/=-%" == "-1" set arg=--default
if /I "%arg:/=-%" == "-2" set arg=--user
if /I "%arg:/=-%" == "-d" set arg=--debug

:: Allow both /option and --option syntax. 
if not "%arg%" == "" set arg=%arg:/=--%

if not "%arg%" == "" (
    if /I "%arg%" == "--help" (
	(goto:printLongUsage)
    ) else if /I "%arg%" == "--?" (
	(goto:printLongUsage)
    ) else if /I "%arg%" == "--pure" (
	if defined vimMode (
	    (echo.ERROR: "%~1": Mode already set!)
	    (echo.)
	    (goto:printShortUsage)
	)
	set vimArguments=-N -u NONE %vimArguments%
	set vimMode=pure
	shift /1
    ) else if /I "%arg%" == "--default" (
	if defined vimMode (
	    (echo.ERROR: "%~1": Mode already set!)
	    (echo.)
	    (goto:printShortUsage)
	)
	set vimArguments=--cmd "set rtp=$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after" -N -u NORC -c "set rtp&" %vimArguments%
	set vimMode=default
	shift /1
    ) else if /I "%arg%" == "--user" (
	if defined vimMode (
	    (echo.ERROR: "%~1": Mode already set!)
	    (echo.)
	    (goto:printShortUsage)
	)
	set vimMode=user
	shift /1
    ) else if /I "%arg%" == "--runtime" (
	set vimArguments=%vimArguments% -S "%userVimFilesDirspec%%~2"
	shift /1
	shift /1
    ) else if /I "%arg%" == "--source" (
	set vimArguments=%vimArguments% -S %2
	shift /1
	shift /1
    ) else if /I "%arg%" == "--vimexecutable" (
	set vimExecutable=%2
	shift /1
	shift /1
    ) else if /I "%arg%" == "--vimversion" (
	set vimExecutable="%ProgramFiles%\vim\vim%~2\vim.exe"
	shift /1
	shift /1
    ) else if /I "%arg%" == "--graphical" (
	if %vimExecutable% == vim (
	    set vimExecutable=gvim
	) else (
	    set vimExecutable=%vimExecutable:vim.exe=gvim.exe%
	)
	shift /1
    ) else if /I "%arg%" == "--summaryonly" (
	set isExecutionOutput=
	set EXECUTIONOUTPUT=rem
	shift /1
    ) else if /I "%arg%" == "--verbose" (
	set /A verboseLevel+=1
	set skipsRecord=
	shift /1
    ) else if /I "%arg%" == "--debug" (
	set vimVariableOptionsValue=%vimVariableOptionsValue%debug,
	shift /1
    ) else if /I "%~1" == "--" (
	shift /1
	(goto:commandLineArguments)
    ) else if /I "%arg:~0,1%" == "-" (
	(echo.ERROR: Unknown option "%~1"!)
	(echo.)
	(goto:printShortUsage)
    ) else (
	(goto:commandLineArguments)
    )
    (goto:commandLineOptions)
)

:commandLineArguments
if "%~1" == "" (goto:printUsage)

call :determineTerminalAndValidVimExecutable
if not defined vimExecutable (exit /B 2)

if not defined vimMode (set vimMode=user)
set vimVariableOptionsValue=%vimMode%,%vimVariableOptionsValue%
set vimVariableOptionsValue=%vimVariableOptionsValue:~0,-1%
set vimArguments=%vimArguments% --cmd "let %vimVariableOptionsName%='%vimVariableOptionsValue%'"

set /A cntTestFiles=0
set /A cntTests=0
set /A cntRun=0
set /A cntOk=0
set /A cntSkip=0
set /A cntFail=0
set /A cntError=0
set /A cntTodo=0
set listSkipped=
set listSkips=
set listFailed=
set listError=
set listTodo=

%EXECUTIONOUTPUT% echo.
if defined vimArguments (
    %EXECUTIONOUTPUT% echo.Starting test run with these Vim options:
    %EXECUTIONOUTPUT% echo.%vimExecutable% %vimArguments%
) else (
    %EXECUTIONOUTPUT% echo.Starting test run.
)

:commandLineLoop
call :processSuiteEntry "%~1"
shift /1
if defined isBailOut (goto:commandLineLoopEnd)
if not "%~1" == "" (goto:commandLineLoop)

:commandLineLoopEnd
set pluralTestFiles=& if %cntTestFiles%	NEQ 1 set pluralTestFiles=s
set pluralTests=&     if %cntTests%	NEQ 1 set pluralTests=s
set pluralFail=&      if %cntFail%	NEQ 1 set pluralFail=s
set pluralError=&     if %cntError%	NEQ 1 set pluralError=s
set todoNotification=& if %cntTodo% GEQ 1 set todoNotification=, %cntTodo% TODO
set bailOutNotification=& if defined isBailOut set bailOutNotification= ^(aborted^)
echo.
echo.%cntTestFiles% file%pluralTestFiles% with %cntTests% test%pluralTests%%bailOutNotification%; %cntSkip% skipped, %cntRun% run: %cntOk% OK, %cntFail% failure%pluralFail%, %cntError% error%pluralError%%todoNotification%.
if defined listSkipped (echo.Skipped tests: %listSkipped:~0,-2%)
if defined listSkips (echo.Tests with skips: %listSkips:~0,-2%)
call :listSkipReasons
if defined listFailed (echo.Failed tests: %listFailed:~0,-2%)
if defined listError (echo.Tests with errors: %listError:~0,-2%)
if defined listTodo (echo.TODO tests: %listTodo:~0,-2%)

set /A cntAllProblems=%cntError% + %cntFail%
if %cntAllProblems% NEQ 0 (exit /B 1) else (exit /B 0)
(goto:EOF)

::------------------------------------------------------------------------------
:prerequisiteError
echo.ERROR: Script prerequisites aren't met!
exit /B 2
(goto:EOF)

:printShortUsage
echo.Usage: "%~nx0" [-0^|--pure^|-1^|--default^|-2^|--user] [--source filespec [--source filespec [...]]] [--runtime plugin/file.vim [--runtime autoload/file.vim [...]]] [--vimexecutable path\to\vim.exe^|--vimversion NN] [-g^|--graphical] [--summaryonly^|-v^|--verbose] [-d^|--debug] [-?^|-h^|--help] test001.vim^|testsuite.txt^|path\to\testdir\ [...]
exit /B 2
:printUsage
call :printShortUsage
echo.Try "%~nx0" --help for more information.
exit /B 2
:printLongUsage
echo.A testing framework for Vim.
echo.
call :printShortUsage
echo.    -0^|--pure		Start Vim without loading any .vimrc and plugins,
echo.    			but in nocompatible mode. Adds 'pure' to %vimVariableOptionsName%.
echo.    -1^|--default	Start Vim only with default settings and plugins,
echo.    			without loading user .vimrc and plugins.
echo.    			Adds 'default' to %vimVariableOptionsName%.
echo.    -2^|--user		^(Default:^) Start Vim with user .vimrc and plugins.
echo.    --source filespec	Source filespec before test execution.
echo.    --runtime filespec	Source filespec relative to ~/.vim. Can be used to
echo.    			load the script-under-test when using --pure.
echo.    --vimexecutable	Use passed Vim executable instead
echo.        path\to\vim.exe	of the one found in %%PATH%%.
echo.    --vimversion NN	Use Vim version N.N. ^(Must be in standard installation
echo.    			directory %ProgramFiles%\vim\vimNN\.^)
echo.    -g^|--graphical	Use GUI version of Vim.
echo.    --summaryonly	Do not show detailed transcript and differences,
echo.    			during test run, only summary.
echo.    -v^|--verbose	Show passed tests and more details during test
echo.    			execution.
echo.    -d^|--debug		Test debugging mode: Adds 'debug' to %vimVariableOptionsName%
echo.    			variable inside Vim ^(so that tests do not exit or can
echo.    			produce additional debug info^).
exit /B 0

:checkUnixTools
for %%F in (grep.exe sed.exe diff.exe) do if "%%~$PATH:F" == "" exit /B 2
for %%F in (sort.exe uniq.exe) do (
    if "%%~$PATH:F" == "" (
	if /I "%~1" == "all" (
	    exit /B 2
	) else (
	    set skipsRecord=
	)
    )
)
exit /B 0
(goto:EOF)

:determineUserVimFilesDirspec
:: Determine dirspec of user vimfiles for --runtime argument. 
set userVimFilesDirspec=%HOME%\vimfiles\
if not exist "%userVimFilesDirspec%" set userVimFilesDirspec=%HOME%\.vim\
if not exist "%userVimFilesDirspec%" set userVimFilesDirspec=%HOMEDRIVE%%HOMEPATH%\vimfiles\
if not exist "%userVimFilesDirspec%" set userVimFilesDirspec=%HOMEDRIVE%%HOMEPATH%\.vim\
if not exist "%userVimFilesDirspec%" set userVimFilesDirspec=$VIMRUNTIME/
(goto:EOF)
:determineTerminalAndValidVimExecutable
:: Use silent-batch mode (-es) when the test log is not printed to stdout (but
:: redirected into a file or pipe). This avoids that the output is littered with
:: escape sequences and suppresses the Vim warning and a small delay:
:: "Vim: Warning: Output is not to a terminal".
:: (Just passing '-T dumb' is not enough.)
::
:: Since the Windows shell cannot tell us whether the output is connected to a
:: terminal, we ask Vim instead by invoking it and checking stderr for the
:: warning message. This also allows us to check at the same time whether
:: %vimExecutable% is a valid executable. (Which would also be difficult
:: to do in the Windows shell, considering that the file extension may be
:: missing from the executable name, so a simple ~$PATH:I search wouldn't be
:: sufficient.) 
set capturedVimErrorOutput=%TEMP%\capturedVimErrorOutput
set vimTerminalArguments=
call %vimExecutable% -f -N -u NONE -c "quitall!" 2>"%capturedVimErrorOutput%"
if %ERRORLEVEL% NEQ 0 (
    (echo.ERROR: "%vimExecutable%" is not a Vim executable!)
    set vimExecutable=
) else (
    findstr /C:"Output is not to a terminal" "%capturedVimErrorOutput%" >NUL && set vimTerminalArguments= -es
)
set vimArguments=%vimArguments%%vimTerminalArguments%
if not defined debug del "%capturedVimErrorOutput%" >NUL 2>&1
(goto:EOF)

:printTestHeader
if defined isPrintedHeader (goto:EOF)
set isPrintedHeader=true
if not defined isExecutionOutput (goto:EOF)

set headerMessage=%~2:
echo.
:: If the first line of the test script starts with '" Test', include this as
:: the test's synopsis in the test header. Otherwise, just print the test name. 
:: Limit the test header to one unwrapped output line, i.e. truncate to 80
:: characters. 
sed -n -e "1s/^\d034 \(Test.*\)$/%headerMessage% \1/p" -e "tx" -e "1c%headerMessage%" -e ":x" -- %1 | sed "/^.\{80,\}/s/\(^.\{,76\}\).*$/\1.../"
(goto:EOF)

:addToListSkipped
echo.%listSkipped% | findstr /C:%1 >NUL || set listSkipped=%listSkipped%%~1, 
(goto:EOF)
:addToListSkips
echo.%listSkips% | findstr /C:%1 >NUL || set listSkips=%listSkips%%~1, 
(goto:EOF)
:addToListFailed
echo.%listFailed% | findstr /C:%1 >NUL || set listFailed=%listFailed%%~1, 
(goto:EOF)
:addToListError
echo.%listError% | findstr /C:%1 >NUL || set listError=%listError%%~1, 
(goto:EOF)
:addToListTodo
echo.%listTodo% | findstr /C:%1 >NUL || set listTodo=%listTodo%%~1, 
(goto:EOF)

:echoOk
if not defined isExecutionOutput (goto:EOF)
if %verboseLevel% GTR 0 (
    echo.OK ^(%~1^)
)
(goto:EOF)
:echoStatus
:: %1 status
:: %2 method (or empty)
:: %3 explanation (or empty)
if not defined isExecutionOutput (goto:EOF)
call :printTestHeader "%testFile%" "%testName%"
:echoStatusForced
set status=%~1
if not "%~2" == "" (
    set status=%status% ^(%~2^)
)
if "%~3" == "" (
    echo.%status%
) else (
    echo.%status%: %~3|sed "s/%PIPE%/|/g"
)
(goto:EOF)
:echoSkip
set skipMethod=%~1
set skipMethod=%skipMethod:~5,-1%
if defined skipsRecord (
    call :echoStatusForced "SKIP" "%skipMethod%" %2 >> "%skipsRecord%"
)
if not defined isExecutionOutput (goto:EOF)
if %verboseLevel% EQU 0 (goto:EOF)
call :echoStatus "SKIP" "%skipMethod%" %2
(goto:EOF)
:echoError
call :echoStatus "ERROR" %*
(goto:EOF)
:echoFail
call :echoStatus "FAIL" %*
(goto:EOF)

:listSkipReasons
if not defined skipsRecord (goto:EOF)
if %cntSkip% EQU 0 (goto:EOF)
if not exist "%skipsRecord%" (goto:EOF)
sort --ignore-case -- "%skipsRecord%" | uniq --ignore-case --count
if not defined debug del "%skipsRecord%"
(goto:EOF)

::------------------------------------------------------------------------------
:runDir
set isProcessedTestInDir=
for %%f in (%~1*.vim) do (
    set isProcessedTestInDir=true
    if not defined isBailOut call :runTest "%%f"
)
if not defined isProcessedTestInDir (
    set /A cntError+=1
    echo.ERROR: Test file "%~1*.vim" doesn't exist.
)
set isProcessedTestInDir=
(goto:EOF)

:processSuiteEntry
set arg=%~1
set argExt=%~x1
set argAsDirspec=%~1
if not "%argAsDirspec:~-1%" == "\" set argAsDirspec=%argAsDirspec%\
if exist "%argAsDirspec%" (
    call :runDir "%argAsDirspec%"
) else if "%argext%" == ".vim" (
    call :runTest "%arg%"
) else if exist "%arg%" (
    call :runSuite "%arg%"
) else (
    set /A cntError+=1
    (echo.ERROR: Suite file "%arg%" doesn't exist.)
)
(goto:EOF)
:runSuite
:: Change to suite directory so that relative paths and filenames are resolved
:: correctly. 
pushd "%~dp1"
for /F "eol=# delims=" %%f in (%~nx1) do (
    if not defined isBailOut call :processSuiteEntry "%%f"
)
popd
(goto:EOF)

:runTest
if not exist "%~1" (
    set /A cntError+=1
    (echo.ERROR: Test file "%~1" doesn't exist.)
    (goto:EOF)
)
set testFilespec=%~f1
set testDirspec=%~dp1
set testFile=%~nx1
set testName=%~n1

:: The setup script is not a test, silently skip it. 
if "%testFile%" == "%vimLocalSetupScript%" (goto:EOF)

set testOk=%testName%.ok
set testOut=%testName%.out
set testMsgok=%testName%.msgok
set testMsgout=%testName%.msgout
set testTap=%testName%.tap
:: Escape for Vim :set command. 
set testMsgoutForSet=%testMsgout:\=/%
set testMsgoutForSet=%testMsgout: =\ %

set /A cntTestFiles+=1
pushd "%testDirspec%"

:: Remove old output files from the previous testrun. 
if exist "%testOut%" del "%testOut%"
if exist "%testMsgout%" del "%testMsgout%"
if exist "%testTap%" del "%testTap%"

:: Source local setup script before the testfile. 
set vimLocalSetup=
if exist "%vimLocalSetupScript%" (
    set vimLocalSetup= -S "%vimLocalSetupScript%"
)

set isPrintedHeader=
if %verboseLevel% GTR 0 call :printTestHeader "%testFile%" "%testName%"

:: Default Vim arguments and options:
:: -n		No swapfile. 
:: :set nomore	Suppress the more-prompt when the screen is filled with messages
::		or output to avoid blocking. 
:: :set verbosefile Capture all messages in a file. 
:: :let %vimVariableTestName% = Absolute test filespec. 
:: :let %vimVariableOptionsName% = Options for this test run, concatenated with ','. 
::
:: Note: With -S {file}, Vim wants {file} escaped for Ex commands. (It should
:: really escape {file} itself, as it does for normal {file} arguments.)
:: As we don't know the Vim version, we cannot work around this via
::	-c "execute 'source' fnameescape('${testfile}')"
:: Thus, we just escape spaces and hope that no other special string (like %,
:: # or <cword>) is part of a test filename. (On Windows somehow spaces must not
:: necessarily be escaped?!)
call %vimExecutable% -n -c "let %vimVariableTestName%='%testFilespec:'=''%'|set nomore verbosefile=%testMsgoutForSet%" %vimArguments%%vimLocalSetup% -S "%testFile: =\ %"
:: vim.bat turns echo off. Redo here to allow debugging to continue. 
@echo on
@echo off %debug%

set /A thisTests=0
set /A thisRun=0
set /A thisOk=0
set /A thisSkip=0
set /A thisFail=0
set /A thisError=0
set /A thisTodo=0

set isSkipOut=
set isSkipMsgout=
set isSkipTap=
call :parseMessageOutputForSignals
:: In case of a bail out, do not run check the results of any method; just say
:: that a test has run and go straight to the results evaluation. 
if defined isBailOut (
    set /A thisTests=1
    (goto:resultsEvaluation)
)

:methodOutput
if exist "%testOk%" (
    set /A thisTests+=1
    if defined isSkipOut (
	set /A thisSkip+=1
    ) else (
	if exist "%testOut%" (
	    set /A thisRun+=1
	    call :compareOutput "%testOk%" "%testOut%" "%testName%"
	) else (
	    set /A thisError+=1
	    call :echoError "out" "No test output."
	)
    )
)

:methodMessageOutput
if exist "%testMsgok%" (
    set /A thisTests+=1
    if defined isSkipMsgout (
	set /A thisSkip+=1
    ) else (
	if exist "%testMsgout%" (
	    set /A thisRun+=1
	    call :compareMessages "%testMsgok%" "%testMsgout%" "%testName%"
	) else (
	    set /A thisError+=1
	    call :echoError "msgout" "No test messages."
	)
    )
)

:methodTap
if exist "%testTap%" (
    if defined isSkipTap (
	set /A thisTests+=1
	set /A thisSkip+=1
    ) else (
	call :parseTapOutput "%testTap%" "%testName%"
    )
)

:resultsEvaluation
if %thisTests% EQU 0 (
    set /A thisError+=1
    call :echoError "" "No test results at all."
) else (
    set /A cntTests+=%thisTests%
)
if %thisRun% GEQ 1 (
    set /A cntRun+=%thisRun%
)
if %thisOk% GEQ 1 (
    set /A cntOk+=%thisOk%
)
if %thisSkip% GEQ 1 (
    set /A cntSkip+=%thisSkip%
    if %thisSkip% EQU %thisTests% (
	call :addToListSkipped "%testName%"
    ) else (
	call :addToListSkips "%testName%"
    )
)
if %thisFail% GEQ 1 (
    set /A cntFail+=%thisFail%
    call :addToListFailed "%testName%"
)
if %thisError% GEQ 1 (
    set /A cntError+=%thisError%
    call :addToListError "%testName%"
)
if %thisTodo% GEQ 1 (
    set /A cntTodo+=%thisTodo%
    call :addToListTodo "%testName%"
)
popd
(goto:EOF)

:parseSignal
if defined isBailOut (goto:EOF)
if "%~1" == "BAILOUT!" (
    set isBailOut=true
    set /A thisError+=1
    call :echoStatus "BAIL OUT" "" %2
) else if "%~1" == "ERROR" (
    set /A thisError+=1
    call :echoError "" %2
) else if "%~1" == "SKIP" (
    set isSkipOut=true
    set isSkipMsgout=true
    set isSkipTap=true
    call :echoSkip %1 %2
) else if "%~1" == "SKIP(out)" (
    set isSkipOut=true
    call :echoSkip %1 %2
) else if "%~1" == "SKIP(msgout)" (
    call :echoSkip %1 %2
    set isSkipMsgout=true
) else if "%~1" == "SKIP(tap)" (
    set isSkipTap=true
    call :echoSkip %1 %2
) else (
    (echo.ASSERT: Received unknown signal "%~1" in message output.)
    exit 3
)
(goto:EOF)
:parseMessageOutputForSignals
if not exist "%testMsgout%" (
    set /A thisError+=1
    call :echoError "" "Couldn't capture message output."
    (goto:EOF)
)
for /F "tokens=2* delims= " %%s in ('grep -e "^runVimTests: " "%testMsgout%"') do call :parseSignal "%%~s" "%%~t"
(goto:EOF)

:compareOutput
diff -q -- %1 %2 >NUL
if %ERRORLEVEL% EQU 0 (
    set /A thisOk+=1
    call :echoOk "out"
) else if %ERRORLEVEL% EQU 1 (
    set /A thisFail+=1
    call :echoFail "out" "expected output           %PIPE%   actual output"
    %EXECUTIONOUTPUT% diff --side-by-side --width 80 -- %1 %2
) else (
    set /A thisError+=1
    call :echoError "out" "diff operation failed."
)
(goto:EOF)

:compareMessages
set testMsgresult=%~3.msgresult
if exist "%testMsgresult%" del "%testMsgresult%"
:: Note: Cannot use silent-batch mode (-es) here, because that one messes up
:: the console. (Except when the entire test log is not printed to stdout but
:: redirected.) 
call vim %vimTerminalArguments% -N -u NONE -n -c "set nomore" -S "%runVimMsgFilterScript%" -c "RunVimMsgFilter" -c "quitall!" -- "%testMsgok%"
:: vim.bat turns echo off. Redo here to allow debugging to continue. 
@echo on
@echo off %debug%

if not exist "%testMsgresult%" (
    set /A thisError+=1
    call :echoError "msgout" "Evaluation of test messages failed."
    (goto:EOF)
)
for /F "delims=" %%r in ('sed -n "1s/^\([A-Z][A-Z]*\).*/\1/p" -- "%testMsgresult%"') do set result=%%r
if "%result%" == "OK" (
    set /A thisOk+=1
) else if "%result%" == "FAIL" (
    set /A thisFail+=1
) else if "%result%" == "ERROR" (
    set /A thisError+=1
) else (
    (echo.ASSERT: Received unknown result "%result%" from RunVimMsgFilter.)
    exit 3
)
if "%result%" == "OK" (
    if %verboseLevel% EQU 0 (goto:EOF)
)
call :printTestHeader "%testFile%" "%testName%"
%EXECUTIONOUTPUT% type "%testMsgresult%"
(goto:EOF)

:parseTapLine
:: Ignore all further TAP output after a bail out. 
if defined isBailOut (goto:EOF)

set tapTestSkipReason=
if "%~1" == "ok" (
    if /I "%~2 %~3" == "# SKIP" (
	set /A thisSkip+=1
	set tapTestSkipReason="%~4 %~5 %~6"
    ) else if /I "%~3 %~4" == "# SKIP" (
	set /A thisSkip+=1
	set tapTestSkipReason="%~5 %~6"
    ) else if /I "%~2 %~3" == "# TODO" (
	set /A thisTodo+=1
	set /A thisRun+=1
	set tapTestIsPrintTapOutput=true
    ) else if /I "%~3 %~4" == "# TODO" (
	set /A thisTodo+=1
	set /A thisRun+=1
	set tapTestIsPrintTapOutput=true
    ) else (
	set /A thisOk+=1
	set /A thisRun+=1
    )
    set /A tapTestCnt+=1
    (goto:parseTapLineEnd)
)
if "%~1 %~2" == "not ok" (
    if /I "%~3 %~4" == "# SKIP" (
	set /A thisSkip+=1
	set tapTestSkipReason="%~5 %~6"
    ) else if /I "%~4 %~5" == "# SKIP" (
	set /A thisSkip+=1
	set tapTestSkipReason="%~6"
    ) else if /I "%~3 %~4" == "# TODO" (
	set /A thisTodo+=1
	set /A thisRun+=1
	set tapTestIsPrintTapOutput=true
    ) else if /I "%~4 %~5" == "# TODO" (
	set /A thisTodo+=1
	set /A thisRun+=1
	set tapTestIsPrintTapOutput=true
    ) else (
	set /A thisFail+=1
	set /A thisRun+=1
	set tapTestIsPrintTapOutput=true
    )
    set /A tapTestCnt+=1
    (goto:parseTapLineEnd)
)

:: Handle bail out. 
if "%~1 %~2" == "Bail out!" (
    set isBailOut=true
    set /A thisError+=1
    (goto:parseTapLineEnd)
)

:: Ignore all other TAP output unless it's a plan. 
echo.%~1|grep -q -e "^[0-9][0-9]*\.\.[0-9][0-9]*$" || (goto:parseTapLineEnd)
:: No tests planned means the TAP test is skipped completely. 
if "%~1" == "1..0" (
    set /A thisTests+=1
    set /A thisSkip+=1
    set tapTestSkipReason="%~4 %~5 %~6"
    (goto:parseTapLineEnd)
)
:: Extract the number of planned tests. 
for /F "tokens=1,2 delims=." %%a in ("%~1") do set /A tapTestNum=%%b - %%a + 1

:parseTapLineEnd
if defined skipsRecord (
    if defined tapTestSkipReason (
	echo."SKIP (tap): %tapTestSkipReason:~1,-1%"|sed -e "s/^\d034\(SKIP (tap): \) *\d034$/\1/" -e "s/^\d034\(SKIP (tap): .*[^ ]\) *\d034$/\1/" -e "s/\^\^/^/g" >> "%skipsRecord%"
	set tapTestSkipReason=
    )
)
(goto:EOF)

:parseTapOutput
set tapTestNum=
set /A tapTestCnt=0
set tapTestIsPrintTapOutput=
for /F "eol=# tokens=1-5* delims= " %%i in (%~1) do call :parseTapLine "%%i" "%%j" "%%k" "%%l" "%%m" "%%n"
:: Print the entire TAP output if in verbose mode, else only print 
:: - failed tests
:: - successful TODO tests
:: - bail out message
:: plus any details in the lines following it. 
:: (But truncate any additional TAP output after a bail out.)
set tapPrintTapOutputSedPattern=^^not ok\^|^^ok \([0-9]\+ \)\?# [tT][oO][dD][oO]\^|^^Bail out!
if %verboseLevel% GTR 0 (
    %EXECUTIONOUTPUT% type "%~1"
) else (
    if defined tapTestIsPrintTapOutput (
	call :printTestHeader "%testFile%" "%testName%"
    )
    %EXECUTIONOUTPUT% type "%~1" | sed -n -e "${/^#/H;x;/%tapPrintTapOutputSedPattern%/p}" -e "/%tapPrintTapOutputSedPattern%/{x;/%tapPrintTapOutputSedPattern%/p;b}" -e "/^#/{H;b}" -e "x;/%tapPrintTapOutputSedPattern%/p" -e "/^Bail out!/q"
)

:: If this TAP test has bailed out, return the number of tests run so far, but
:: at least one (to avoid the "no test results" error). 
if defined isBailOut (
    if %tapTestCnt% EQU 0 (
	set /A thisTests+=1
    ) else (
	set /A thisTests+=%tapTestCnt%
    )
    (goto:EOF)
)

if not defined tapTestNum (
    set /A thisTests+=%tapTestCnt%
    (goto:EOF)
)
set /A tapTestDifference=%tapTestNum%-%tapTestCnt%
if %tapTestDifference% LSS 0 set /A tapTestDifference*=-1
if %tapTestDifference% NEQ 1 (set tapTestDifferencePlural=s) else (set tapTestDifferencePlural=)

if %tapTestCnt% LSS %tapTestNum% (
    set /A thisTests+=%tapTestNum%
    call :echoError "tap" "Not all %tapTestNum% planned tests have been executed, %tapTestDifference% test%tapTestDifferencePlural% missed."
    set /A thisError+=1
) else if %tapTestCnt% GTR %tapTestNum% (
    set /A thisTests+=%tapTestCnt%
    call :echoError "tap" "%tapTestDifference% more test execution%tapTestDifferencePlural% than planned."
    set /A thisError+=1
) else (
    set /A thisTests+=%tapTestNum%
)
(goto:EOF)

endlocal

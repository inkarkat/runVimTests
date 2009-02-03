@echo off %debug%
::/**************************************************************************HP**
::**
::* FILE: 	runVimTests.cmd
::* PRODUCT:	VIM tools
::* AUTHOR: 	/^--
::* DATE CREATED:   12-Jan-2009
::*
::*******************************************************************************
::* DESCRIPTION: 
::	This script implements a small unit testing framework for VIM. 
::
::	Similar to the tests that are part of VIM's source distribution, each
::	test consists of a testXXX.vim file which is executed in a a separate
::	VIM instance. The outcome of a test can be determined by a combination
::	of the following methods:
::
::	Saved buffer output)
::	If a testXXX.ok file is provided, the testXXX.vim should save a
::	testXXX.out file at the end of its execution via: 
::	    execute 'saveas! ' . expand('<sfile>:p:r') . '.out'
::	The contents of the testXXX.out test file must be identical to the
::	provided testXXX.ok file for the test to succeed. 
::	The test can either generate the test output itself, or start by editing
::	a testXXX.in (or similar) file and doing modifications to it. 
::
::	Captured messages)
::	If a testXXX.msgok file is provided, the testXXX.vim file should
::	generate VIM messages (from built-in VIM commands, or via :echomsg),
::	which are captured during test execution in a testXXX.msgout file. 
::	The testXXX.msgok file contains multiple message assertions (separated
::	by empty lines), each of which is compiled into a VIM regexp and then
::	matched against the captured messages. Each assertion can match exactly
::	once, and all assertions must match in the same order in the captured
::	VIM messages. (But there can be additional VIM messages before, after
::	and in between matches, so that you can omit irrelevant or
::	platform-specific messages from the testXXX.msgok file.)
::	For details, cp. runVimMsgFilter.vim. 
::
::	TAP unit tests)
::	If a testXXX.tap file exists at the end of a test execution, it is
::	assumed to represent unit test output in the Test Anything Protocol [1],
::	which is then parsed and incorporated into the test run. This method
::	allows detailed verification also of internal functions; the entire
::	determination of the test result is done in VIM script. 
::	Each TAP unit test counts as one test, even though all those test
::	results are produced by a single testXXX.vim file. If a plan announced
::	more tests than what was found in the test output, the test is assumed
::	to be erroneous. 
::
::	[1]
::	web site: http://testanything.org,
::	original implementation: http://search.cpan.org/~petdance/TAP-1.00/TAP.pm,
::	TAP protocol for VIM: http://www.vim.org/scripts/script.php?script_id=2213
::
::
::	A test causes an error if none of these ok-files exist for a test, and
::	no testXXX.tap file was generated (so actually no verification is
::	possible), or if the test execution does not produce the corresponding
::	output files. 
::
::* USAGE: 
::	The tests are specified through these three methods, which can be
::	combined: 
::	- Directly specify the filespec of testXXX.vim test script file(s). 
::	- Specify a directory; all *.vim files inside this directory will be
::	  used as test scripts. 
::	- A test suite is a text file containing (relative or absolute)
::	  filespecs to test scripts, one filespec per line. (Commented lines
::	  start with #.) 
::
::	The script returns 0 if all tests were successful, 1 if any errors or
::	failures occurred. 
::
::	After test execution, a summary is printed like this:
::	    33 tests, 27 run: 16 OK, 11 failures, 6 errors.
::	    Failed tests: test002, test012, test014, test022, test032, test033
::	    Tests with errors: test003, test013, test023, test033
::	A test is counted as each existing *.[msg]ok file, or by an announcement
::	of the planned tests by a TAP test. Tests have "run" when corresponding
::	output has been produced. If it hasn't, that's an error, as well as when
::	there were neither *.[msg]ok files nor any TAP output, or if the test
::	result evaluation had a problem. The result of a correct test evaluation
::	is either OK or FAIL. 
::
::* CONFIGURATION:
::	System-specific, global unit test configuration is stored in
::	'runVimTests.cfg', residing in the same directory as this script. The
::	following items can be configured:
::
::	- essential vimscripts
::	  If you specify the --pure argument, no default plugins are sourced,
::	  and the :runtime command has no effect inside VIM. If you have some
::	  general helper scripts that (almost) all tests require (e.g. the
::	  vimtap utility functions for TAP testing), configure these scripts as
::	  essential, so that they'll be automatically included:
::	    essential = autoload/vimtap.vim
::	  Multiple essential scripts can be configured. The path is taked
::	  relative to the user's ~/.vim directory, as with the --runtime
::	  argument. 
::
::* TEST SCRIPTS:
::	Each test is implemented in a testXXX.vim file. Depending on which
::	method(s) shall be used for verification, the tests needs to do:
::
::	Saved buffer output)
::	Load a predefined test input (e.g. testXXX.in), or start from scratch in
::	the empty buffer, and make modifications to it. Finally, save the result
::	in testXXX.out. 
::
::	Captured messages)
::	Issue :echo or :echomsg, or execute commands that will cause messages.
::	The messages are automatically captured in testXXX.msgout. 
::
::	TAP unit tests)
::	Initialize the TAP testing framework with the output file name
::	testXXX.tap, submit a plan (i.e. how many tests you intend to run; this
::	is optional, but highly recommended), execute the test and verify the
::	outcomes with the TAP-provided functions. The TAP framework will
::	automatically save the TAP output. 
::
::	If the first line of the test contains a comment starting with:
::	'" Test', this is taken as the test synopsis and included in the test
::	header that is printed before each test is executed. Example: 
::	" Test mutation that adds lines after the current line. 
::
::* REMARKS: 
::       	
::* DEPENDENCIES:
::  - GNU grep, sed, diff, wc tools available through 'unix.cmd' script. 
::  - runVimMsgFilter.vim, located in this script's directory. 
::
::* REVISION	DATE		REMARKS 
::	009	02-Feb-2009	Added --debug argument to :let g:debug = 1
::				inside VIM. 
::	008	29-Jan-2009	Added --runtime argument to simplify sourcing of
::				scripts below the user's ~/.vim directory. 
::				Essential vimscripts are now read from separate
::				runVimTests.cfg config file to remove hardcoding
::				inside this script. 
::				BF: Forgot -N -u NONE when invoking VIM for
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
::				plugin/SidTools.vim to essential VIM scripts
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

call unix --quiet || goto:prerequisiteError

call :determineUserVimFilesDirspec
call :determineEssentialVimScripts

set vimArguments=
set isExecutionOutput=1
set EXECUTIONOUTPUT=
:commandLineOptions
set arg=%~1
:: Allow both /option and --option syntax. 
if not "%arg%" == "" set arg=%arg:/=--%
if not "%arg%" == "" (
    if /I "%arg%" == "--help" (
	(goto:printUsage)
    ) else if /I "%arg%" == "--?" (
	(goto:printUsage)
    ) else if /I "%arg%" == "--pure" (
	set vimArguments=-N -u NONE %essentialVimScripts% %vimArguments%
	shift /1
    ) else if /I "%arg%" == "--reallypure" (
	set vimArguments=-N -u NONE %vimArguments%
	shift /1
    ) else if /I "%arg%" == "--runtime" (
	set vimArguments=%vimArguments% -S "%userVimFilesDirspec%%~2"
	shift /1
	shift /1
    ) else if /I "%arg%" == "--source" (
	set vimArguments=%vimArguments% -S %2
	shift /1
	shift /1
    ) else if /I "%arg%" == "--summaryonly" (
	set isExecutionOutput=
	set EXECUTIONOUTPUT=rem
	shift /1
    ) else if /I "%arg%" == "--debug" (
	set vimArguments=%vimArguments% --cmd "let g:debug=1"
	shift /1
    ) else if /I "%~1" == "--" (
	shift /1
	(goto:commandLineArguments)
    ) else (
	(goto:commandLineArguments)
    )
    (goto:commandLineOptions)
)

:commandLineArguments
if "%~1" == "" (goto:printUsage)

set /A cntTests=0
set /A cntRun=0
set /A cntOk=0
set /A cntFail=0
set /A cntError=0
set listFailed=
set listError=

%EXECUTIONOUTPUT% echo.
if defined vimArguments (
    %EXECUTIONOUTPUT% echo.Starting test run with these VIM options: 
    %EXECUTIONOUTPUT% echo.%vimArguments%
) else (
    %EXECUTIONOUTPUT% echo.Starting test run. 
)
%EXECUTIONOUTPUT% echo.

:commandLineLoop
set arg=%~1
set argExt=%~x1
set argAsDirspec=%~1
if not "%argAsDirspec:~-1%" == "\" set argAsDirspec=%argAsDirspec%\
shift /1

if exist "%argAsDirspec%" (
    call :runDir "%argAsDirspec%"
) else if "%argext%" == ".vim" (
    call :runTest "%arg%"
) else if exist "%arg%" (
    call :runSuite "%arg%"
) else (
    set /A cntError+=1
    (echo.ERROR: Suite file "%arg%" doesn't exist. )
)
if not "%~1" == "" (goto:commandLineLoop)

if %cntTests% NEQ 1 set pluralTests=s
if %cntFail% NEQ 1 set pluralFail=s
if %cntError% NEQ 1 set pluralError=s
echo.
echo.%cntTests% test%pluralTests%, %cntRun% run: %cntOk% OK, %cntFail% failure%pluralFail%, %cntError% error%pluralError%. 
if defined listFailed (echo.Failed tests: %listFailed:~0,-2%)
if defined listError (echo.Tests with errors: %listError:~0,-2%)

set /A cntAllProblems=%cntError% + %cntFail%
if %cntAllProblems% NEQ 0 (exit /B 1)
(goto:EOF)

::------------------------------------------------------------------------------
:prerequisiteError
echo.ERROR: Script prerequisites aren't met!
exit /B 1
(goto:EOF)

:printUsage
(echo."%~nx0" [--pure^|--reallypure] [--source filespec [--source filespec [...]]] [--runtime plugin/file.vim [--runtime autoload/file.vim [...]]] [--summaryonly] [--debug] [--help] test001.vim^|testsuite.txt^|path\to\testdir\ [...])
(echo.    --pure		Start VIM without loading .vimrc and plugins,)
(echo.    			but in nocompatible mode and with some essential)
(echo.    			test support scripts sourced. )
(echo.    --reallypure	Start VIM without loading .vimrc and plugins,)
(echo.    			but in nocompatible mode. Some essential scripts may)
(echo.    			be missing and must be sourced manually.)
(echo.    --source filespec	Source filespec before test execution.)
(echo.    --runtime filespec	Source filespec relative to ~/.vim. Important to)
(echo.    			load the script-under-test when using --pure.)
(echo.    --summaryonly	Do not show detailed transcript and differences,)
(echo.    			during test run, only summary. )
(echo.    --debug		Test debugging mode: Sets g:debug = 1 inside VIM)
(echo.    			^(so that tests do not exit or print debug info^). )
(goto:EOF)

:determineUserVimFilesDirspec
:: Determine dirspec of user vimfiles for --runtime argument. 
set userVimFilesDirspec=%HOME%\vimfiles\
if not exist "%userVimFilesDirspec%" set userVimFilesDirspec=%HOME%\.vim\
if not exist "%userVimFilesDirspec%" set userVimFilesDirspec=%HOMEDRIVE%%HOMEPATH%\vimfiles\
if not exist "%userVimFilesDirspec%" set userVimFilesDirspec=%HOMEDRIVE%%HOMEPATH%\.vim\
if not exist "%userVimFilesDirspec%" set userVimFilesDirspec=$VIMRUNTIME/
(goto:EOF)

:addEssentialVimScripts
if not "%~1" == "essential" (goto:EOF)
if exist %2 (
    set essentialVimScripts=%essentialVimScripts% -S %2
) else (
    echo.Warning: Configured essential vimscript "%~2" does not exist.
)
(goto:EOF)
:determineEssentialVimScripts
:: Read configured vimscripts that are essential for test implementations and
:: must be sourced explicitly when argument --pure is given. 
set essentialVimScripts=

set configFilespec=%~dpn0.cfg
if not exist "%configFilespec%" (goto:EOF)

for /F "usebackq eol=# tokens=1,* delims== " %%a in ("%configFilespec%") do call :addEssentialVimScripts "%%~a" "%userVimFilesDirspec%%%~b"
(goto:EOF)

:printTestHeader
if not defined isExecutionOutput (goto:EOF)
:: If the first line of the test script starts with '" Test', include this as
:: the test's synopsis in the test header. Otherwise, just print the test name. 
:: Limit the test header to one unwrapped output line, i.e. truncate to 80
:: characters. 
sed -n -e "1s/^\d034 \(Test.*\)$/Running %~2: \1/p" -e "tx" -e "1cRunning %~2:" -e ":x" %1 | sed "/^.\{80,\}/s/\(^.\{,76\}\).*$/\1.../"
(goto:EOF)

:addToListError
echo.%listError% | findstr /C:%1 >NUL || set listError=%listError%%~1, 
(goto:EOF)
:addToListFailed
echo.%listFailed% | findstr /C:%1 >NUL || set listFailed=%listFailed%%~1, 
(goto:EOF)

::------------------------------------------------------------------------------
:runDir
for %%f in (%~1*.vim) do call :runTest "%%f"
(goto:EOF)

:runSuite
:: Change to suite directory so that relative paths and filenames are resolved
:: correctly. 
pushd "%~dp1"
for /F "eol=# delims=" %%f in (%~nx1) do call :runTest "%%f"
popd
(goto:EOF)

:runTest
if not exist "%~1" (
    set /A cntError+=1
    (echo.ERROR: Test file "%~1" doesn't exist. )
    (goto:EOF)
)
set testdirspec=%~dp1
set testfile=%~nx1
set testname=%~n1
set testok=%testname%.ok
set testout=%testname%.out
set testmsgok=%testname%.msgok
set testmsgout=%testname%.msgout
set testtap=%testname%.tap
:: Escape for VIM :set command. 
set testmsgoutForSet=%testmsgout:\=/%
set testmsgoutForSet=%testmsgout: =\ %

pushd "%testdirspec%"
if exist "%testout%" del "%testout%"
if exist "%testmsgout%" del "%testmsgout%"
if exist "%testtap%" del "%testtap%"

call :printTestHeader "%testfile%" "%testname%"

:: Default VIM arguments and options:
:: -n		No swapfile. 
:: :set nomore	Suppress the more-prompt when the screen is filled with messages
::		or output to avoid blocking. 
:: :set verbosefile Capture all messages in a file. 
call vim -n -c "set nomore verbosefile=%testmsgoutForSet%" %vimArguments% -S "%testfile%"

set /A thisTests=0
set /A thisRun=0
set /A thisOk=0
set /A thisFail=0
set /A thisError=0

:methodOutput
if exist "%testok%" (
    set /A thisTests+=1
    if exist "%testout%" (
	set /A thisRun+=1
	call :compareOutput "%testok%" "%testout%" "%testname%"
    ) else (
	set /A thisError+=1
	%EXECUTIONOUTPUT% echo.ERROR ^(out^): No test output. 
    )
)

:methodMessageOutput
if exist "%testmsgok%" (
    set /A thisTests+=1
    if exist "%testmsgout%" (
	set /A thisRun+=1
	call :compareMessages "%testmsgok%" "%testmsgout%" "%testname%"
    ) else (
	set /A thisError+=1
	%EXECUTIONOUTPUT% echo.ERROR ^(msgout^): No test messages. 
    )
)

:methodTap
set /A tapTestCnt=0
if exist "%testtap%" (
    call :parseTapOutput "%testtap%" "%testname%"
)

:resultsEvaluation
if %thisTests% EQU 0 (
    set /A thisError+=1
    %EXECUTIONOUTPUT% echo.ERROR: No test results at all. 
) else (
    set /A cntTests+=%thisTests%
)
if %thisRun% GEQ 1 (
    set /A cntRun+=%thisRun%
)
if %thisOk% GEQ 1 (
    set /A cntOk+=%thisOk%
)
if %thisFail% GEQ 1 (
    set /A cntFail+=%thisFail%
    call :addToListFailed "%testname%"
)
if %thisError% GEQ 1 (
    set /A cntError+=%thisError%
    call :addToListError "%testname%"
)
popd
(goto:EOF)

:compareOutput
diff -q %1 %2 >NUL
if %ERRORLEVEL% EQU 0 (
    set /A thisOk+=1
    %EXECUTIONOUTPUT% echo.OK ^(out^)
) else if %ERRORLEVEL% EQU 1 (
    set /A thisFail+=1
    %EXECUTIONOUTPUT% echo.FAIL ^(out^): expected output           ^|   actual output
    %EXECUTIONOUTPUT% diff --side-by-side --width 80 %1 %2
) else (
    set /A thisError+=1
    %EXECUTIONOUTPUT% echo.ERROR ^(out^): diff operation failed. 
)
(goto:EOF)

:compareMessages
set testmsgresult=%~3.msgresult
if exist "%testmsgresult%" del "%testmsgresult%"
:: Note: Cannot use silent-batch mode (-s -e) here, because that one messes up
:: the console. 
call vim -N -u NONE -n -c "set nomore" -S "%~dp0runVimMsgFilter.vim" -c "RunVimMsgFilter" -c "quitall!" "%testmsgok%"
if not exist "%testmsgresult%" (
    set /A thisError+=1
    %EXECUTIONOUTPUT% echo.ERROR ^(msgout^): Evaluation of test messages failed. 
    (goto:EOF)
)
for /F "delims=" %%r in ('sed -n "1s/^\([A-Z][A-Z]*\).*/\1/p" "%testmsgresult%"') do set result=%%r
if "%result%" == "OK" (
    set /A thisOk+=1
) else if "%result%" == "FAIL" (
    set /A thisFail+=1
) else if "%result%" == "ERROR" (
    set /A thisError+=1
) else (
    (echo.Assert: Received unknown result "%result%" from RunVimMsgFilter.)
    exit 1
)
%EXECUTIONOUTPUT% type "%testmsgresult%"
(goto:EOF)

:parseTapLine
if "%~1" == "ok" (
    set /A thisOk+=1
    set /A thisRun+=1
    set /A tapTestCnt+=1
    (goto:EOF)
)
if "%~1 %~2" == "not ok" (
    set /A thisFail+=1
    set /A thisRun+=1
    set /A tapTestCnt+=1
    (goto:EOF)
)
echo.%~1|grep -q -e "^[0-9][0-9]*\.\.[0-9][0-9]*$" || (goto:EOF)
for /F "tokens=1,2 delims=." %%a in ("%~1") do set /A tapTestNum=%%b - %%a + 1
(goto:EOF)

:parseTapOutput
set tapTestNum=
set /A tapTestCnt=0
for /F "eol=# tokens=1-3 delims= " %%i in (%~1) do call :parseTapLine "%%i" "%%j" "%%k" %2
%EXECUTIONOUTPUT% type "%~1"

if not defined tapTestNum (
    set /A thisTests+=%tapTestCnt%
    (goto:EOF)
)
set /A tapTestDifference=%tapTestNum%-%tapTestCnt%
if %tapTestDifference% LSS 0 set /A tapTestDifference*=-1
if %tapTestDifference% NEQ 1 (set tapTestDifferencePlural=s) else (set tapTestDifferencePlural=)

if %tapTestCnt% LSS %tapTestNum% (
    set /A thisTests+=%tapTestNum%
    %EXECUTIONOUTPUT% echo.ERROR ^(tap^): Not all %tapTestNum% planned tests have been executed, %tapTestDifference% test%tapTestDifferencePlural% missed. 
    set /A thisError+=1
) else if %tapTestCnt% GTR %tapTestNum% (
    set /A thisTests+=%tapTestCnt%
    %EXECUTIONOUTPUT% echo.ERROR ^(tap^): %tapTestDifference% more test execution%tapTestDifferencePlural% than planned. 
    set /A thisError+=1
) else (
    set /A thisTests+=%tapTestNum%
)
(goto:EOF)

endlocal

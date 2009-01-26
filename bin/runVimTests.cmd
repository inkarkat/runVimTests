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
::	A test causes an error if none of these ok-files exist for a test, or if
::	the test execution does not produce the corresponding output files. 
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
::* REMARKS: 
::       	
::* DEPENDENCIES:
::  - GNU grep, sed, diff, wc tools available through 'unix.cmd' script. 
::  - runVimMsgFilter.vim, located in this script's directory. 
::
::* REVISION	DATE		REMARKS 
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

set vimtapPlugin=$HOME/.vim/autoload/vimtap.vim

set vimArguments=
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
	set vimArguments=%vimArguments% -N -u NONE -S "%vimtapPlugin%"
	shift /1
    ) else if /I "%arg%" == "--source" (
	set vimArguments=%vimArguments% -S %2
	shift /1
	shift /1
    ) else if /I "%arg%" == "--summaryonly" (
	set EXECUTIONOUTPUT=rem
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

if %cntFail% NEQ 1 set pluralFail=s
if %cntError% NEQ 1 set pluralError=s
echo.
echo.%cntRun% run: %cntOk% OK, %cntFail% failure%pluralFail%, %cntError% error%pluralError%. 
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
(echo."%~nx0" [--pure] [--source filespec [--source filespec [...]]] [--summaryonly] [--help] test001.vim^|testsuite.txt^|path\to\testdir\ [...])
(echo.    --pure		Start VIM without loading .vimrc and plugins,)
(echo.    			but in nocompatible mode. )
(echo.    --source filespec	Source filespec before test execution. Important to)
(echo.    			load the script-under-test when using --pure.)
(echo.    --summaryonly	Do not show detailed transcript and differences,)
(echo.    			during test run, only summary. )
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

%EXECUTIONOUTPUT% echo.Running %testname%:

:: Default VIM arguments and options:
:: -n		No swapfile. 
:: :set nomore	Suppress the more-prompt when the screen is filled with messages
::		or output to avoid blocking. 
:: :set verbosefile Capture all messages in a file. 
call vim -n -c "set nomore verbosefile=%testmsgoutForSet%" %vimArguments% -S "%testfile%"

set /A thisOk=0
set /A thisError=0
set /A thisFail=0
if exist "%testok%" (
    if exist "%testout%" (
	call :compareOutput "%testok%" "%testout%" "%testname%"
    ) else (
	set /A thisError+=1
	%EXECUTIONOUTPUT% echo.ERROR: No test output. 
    )
)

if exist "%testmsgok%" (
    if exist "%testmsgout%" (
	call :compareMessages "%testmsgok%" "%testmsgout%" "%testname%"
    ) else (
	set /A thisError+=1
	%EXECUTIONOUTPUT% echo.ERROR: No test messages. 
    )
)

set /A tapTestCnt=0
if exist "%testtap%" (
    call :parseTapOutput "%testtap%" "%testname%"
)

set /A thisAll=%thisOk% + %thisError% + %thisFail% + %tapTestCnt%
if %thisAll% EQU 0 (
    set /A thisError+=1
    %EXECUTIONOUTPUT% echo.ERROR: No test results at all. 
)
if %thisError% GEQ 1 (
    set /A cntError+=1
    call :addToListError "%testname%"
) else if %thisFail% GEQ 1 (
    set /A cntFail+=1
    call :addToListFailed "%testname%"
) else if %thisOk% GEQ 1 (
    set /A cntOk+=1
)
:: The TAP unit tests increase the test count themselves. 
set /A thisNonTap=%thisOk% + %thisError% + %thisFail%
if %thisNonTap% GTR 0 (set /A cntRun+=1)
popd
(goto:EOF)

:compareOutput
diff -q %1 %2 >NUL
if %ERRORLEVEL% EQU 0 (
    set /A thisOk+=1
    %EXECUTIONOUTPUT% echo.OK ^(out^)
) else if %ERRORLEVEL% EQU 1 (
    set /A thisFail+=1
    %EXECUTIONOUTPUT% echo.FAIL: expected output                 ^|   actual output
    %EXECUTIONOUTPUT% diff --side-by-side --width 80 %1 %2
) else (
    set /A thisError+=1
    %EXECUTIONOUTPUT% echo.ERROR: diff operation failed. 
)
(goto:EOF)

:compareMessages
set testmsgresult=%~3.msgresult
if exist "%testmsgresult%" del "%testmsgresult%"
call vim -n -c "set nomore" -S "%~dp0runVimMsgFilter.vim" -c "RunVimMsgFilter" -c "quitall!" "%testmsgok%"
if not exist "%testmsgresult%" (
    set /A thisError+=1
    %EXECUTIONOUTPUT% echo.ERROR: Evaluation of test messages failed. 
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
    set /A cntOk+=1
    set /A cntRun+=1
    set /A tapTestCnt+=1
    (goto:EOF)
)
if "%~1 %~2" == "not ok" (
    set /A cntFail+=1
    set /A cntRun+=1
    set /A tapTestCnt+=1
    call :addToListFailed %4
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

if not defined tapTestNum (goto:EOF)
if %tapTestCnt% LSS %tapTestNum% (
    %EXECUTIONOUTPUT% echo.ERROR: Not all planned tests have been executed. 
    set /A cntError+=1
    call :addToListError %2
) else if %tapTestCnt% GTR %tapTestNum% (
    %EXECUTIONOUTPUT% echo.ERROR: More test executions than planned. 
    set /A cntError+=1
    call :addToListError %2
)
(goto:EOF)

endlocal

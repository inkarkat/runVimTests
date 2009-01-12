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
::	All lines of testXXX.msgok must appear identically and in the same order
::	in the captured VIM messages. (But there can be additional VIM messages
::	before, after and in between, so that you can omit irrelevant or
::	platform-specific messages from the testXXX.msgok file.)
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
::
::* REVISION	DATE		REMARKS 
::	002	13-Jan-2009	Generalized and documented. 
::				Addded summary of failed / error test names. 
::	001	12-Jan-2009	file creation
::*******************************************************************************
setlocal enableextensions

call unix --quiet || goto:prerequisiteError

set vimArguments=
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
	set vimArguments=%vimArguments% -N -u NONE
	shift /1
    ) else if /I "%arg%" == "--source" (
	set vimArguments=%vimArguments% -S %2
	shift /1
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

if defined vimArguments (
    echo.Starting test run with these VIM options: 
    echo.%vimArguments%
) else (
    echo.Starting test run. 
)
echo.

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
(echo."%~nx0" [--pure] [--source filespec [--source filespec [...]]] [--help] test001.vim^|testsuite.txt^|path\to\testdir\ [...])
(echo.    --pure		Start VIM without loading .vimrc and plugins,)
(echo.    			but in nocompatible mode. )
(echo.    --source filespec	Source filespec before test execution. Important to)
(echo.    			load the script-under-test when using --pure.)
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
:: Escape for VIM :set command. 
set testmsgoutForSet=%testmsgout:\=/%
set testmsgoutForSet=%testmsgout: =\ %

pushd "%testdirspec%"
if exist "%testout%" del "%testout%"
if exist "%testmsgout%" del "%testmsgout%"

echo.Running %testname%:

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
	echo.ERROR: No test output. 
    )
)

if exist "%testmsgok%" (
    if exist "%testmsgout%" (
	call :compareMessages "%testmsgok%" "%testmsgout%" "%testname%"
    ) else (
	set /A thisError+=1
	echo.ERROR: No test messages. 
    )
)

set /A thisAll=%thisOk% + %thisError% + %thisFail%
if %thisAll% EQU 0 (
    set /A thisError+=1
    echo.ERROR: No test results at all. 
)
if %thisError% GEQ 1 (
    set /A cntError+=1
) else if %thisFail% GEQ 1 (
    set /A cntFail+=1
) else if %thisOk% GEQ 1 (
    set /A cntOk+=1
)
set /A cntRun+=1
popd
(goto:EOF)

:compareOutput
diff -q %1 %2 >NUL
if %ERRORLEVEL% EQU 0 (
    set /A thisOk+=1
    echo.OK ^(out^)
) else if %ERRORLEVEL% EQU 1 (
    set /A thisFail+=1
    set listFailed=%listFailed%%~3^, 
    echo.FAIL: expected output                 ^|   actual output
    diff --side-by-side --width 80 %1 %2
) else (
    set /A thisError+=1
    set listError=%listError%%~3^, 
    echo.ERROR: diff operation failed. 
)
(goto:EOF)

:compareMessages
for /F "delims=" %%l in ('diff -U 1 %1 %2 ^| grep -e "^-[^-]" ^| wc -l') do set missingLines=%%l
if %missingLines% EQU 0 (
    set /A thisOk+=1
    echo.OK ^(msgout^)
) else (
    set /A thisFail+=1
    set listFailed=%listFailed%%~3^, 
    echo.FAIL: The following messages were missing in the output: 
    diff -U 1 %1 %2 | grep -e "^-[^-]" | sed "s/^-//"
)
(goto:EOF)

endlocal

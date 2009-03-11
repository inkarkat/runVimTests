@echo off %debug%
::/*************************************************************************/^--*
::**
::* FILE: 	compareLog.cmd
::* PRODUCT:	runVimTests
::* AUTHOR: 	Ingo Karkat <ingo@karkat.de>
::* DATE CREATED:   11-Feb-2009
::*
::*******************************************************************************
::* CONTENTS: 
::  Runs a runVimTests self-test and compares the test output with previously
::  captured nominal output. 
::  The command-line arguments to runVimTests and the test file are embedded in
::  the captured output filename and are extracted automatically: 
::  testrun.suite-1-v.log ->
::	$ runVimTests -1 -v testrun.suite > /tmp/testrun.suite-1-v.log 2>&1
::  The special name "testdir" represents all tests in the directory (i.e. '.'): 
::  testdir-1-v.log ->
::	$ runVimTests -1 -v . > /tmp/testdir-1-v.log 2>&1
::       	
::* REMARKS: 
::       	
::* DEPENDENCIES:
::  - GNU diff available through %PATH% or 'unix.cmd' script. 
::
::* REVISION	DATE		REMARKS 
::	004	12-Mar-2009	Also capturing stderr output, e.g. for "test not
::				found" errors. 
::	003	07-Mar-2009	The test file (suite) is now also embedded in
::				the captured output name so that multiple test
::				files and suites can be captured. 
::	002	25-Feb-2009	Command-line arguments are now embedded in the
::				captured output filename and extracted
::				automatically. 
::	001	11-Feb-2009	file creation
::*******************************************************************************
setlocal enableextensions

call unix --quiet >NUL 2>&1

if "%~1" == "" (set old=testdir.log) else (set old=%~1)
if "%~1" == "" (set log=%TEMP%\testdir.log) else (set log=%TEMP%\%~nx1)
if exist "%log%" del "%log%" || exit /B 1

if not exist "%old%" (
    echo.ERROR: Old log "%old%" does not exist!
    exit /B 1
)

set options=
set tests=testdir
if "%~1" == "" (goto:run)
set tests=
set options=%~n1

:cutOffTests
if "%options%" == "" (goto:run)
set tests=%tests%%options:~0,1%
set options=%options:~1%
if "%options%" == "" (goto:run)
if not "%options:~0,1%" == "-" (goto:cutOffTests)

set options=%options:--= !!%
set options=%options:-= !%
set options=%options:!=-%

:run
if "%tests%" == "testdir" set tests=.
call runVimTests.cmd%options% "%tests%" > "%log%" 2>&1

echo.
echo.DIFFERENCES:
diff -u "%old%" "%log%"


endlocal

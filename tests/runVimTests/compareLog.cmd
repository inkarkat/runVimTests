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
::  Runs the runVimTests self-test suite and compares the test output with
::  previously captured nominal output. 
::  The command-line arguments to runVimTests are embedded in the captured
::  output filename and are extracted automatically: 
::  testrun-1-v.log -> $ runVimTests -1 -v . > /tmp/testrun-1-v.log
::       	
::* REMARKS: 
::       	
::* REVISION	DATE		REMARKS 
::	002	25-Feb-2009	Command-line arguments are now embedded in the
::				captured output filename and extracted
::				automatically. 
::	001	11-Feb-2009	file creation
::*******************************************************************************

if "%~1" == "" (set old=testrun.log) else (set old=%~1)
if "%~1" == "" (set log=%TEMP%\testrun.log) else (set log=%TEMP%\%~nx1)
if exist "%log%" del "%log%" || exit /B 1

if not exist "%old%" (
    echo.ERROR: Old log "%old%" does not exist!
    exit /B 1
)

set options=
if "%~1" == "" (goto:run)
set options=%~n1
set options=%options:testrun=%
set options=%options:--= !!%
set options=%options:-= !%
set options=%options:!=-%

:run
call runVimTests.cmd%options% . > "%log%"

echo.
echo.DIFFERENCES:
diff -u "%old%" "%log%"


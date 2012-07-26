@echo off %debug%
::/*************************************************************************/^--*
::**
::* FILE: 	compareAllLogs.cmd
::* PRODUCT:	runVimTests
::* AUTHOR: 	Ingo Karkat <ingo@karkat.de>
::* DATE CREATED:   07-Mar-2009
::*
::*******************************************************************************
::* CONTENTS:
::  Runs all existing runVimTests self-test suites.
::
::* REMARKS:
::
::* REVISION	DATE		REMARKS
::	001	07-Mar-2009	file creation
::*******************************************************************************

for %%f in ("%~dp0*.log") do (
    (echo.)
    (echo.%%~nxf)
    call "%~dp0compareLog.cmd" "%%~f"
)


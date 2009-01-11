@echo off %debug%
::/**************************************************************************HP**
::**
::* FILE: 	
::* PRODUCT:	
::* AUTHOR: 	
::* DATE CREATED:	
::*
::*******************************************************************************
::* CONTENTS: 
::       	
::* REMARKS: 
::       	
::* REVISION	DATE		REMARKS 
::	001	12-Jan-2009	file creation
::*******************************************************************************
setlocal enableextensions

pushd "%~dp0"
set /A cntRun=0
set /A cntOk=0
set /A cntFail=0
set /A cntError=0

for %%f in (*.vim) do call :runTest "%%f"

echo.%cntRun% run: %cntOk% OK, %cntFail% failures, %cntError% errors. 

popd
(goto:EOF)

::------------------------------------------------------------------------------
:prerequisiteError
echo.ERROR: Script prerequisites aren't met!
exit /B 1
(goto:EOF)

:runTest
set testfile=%~1
set testname=%~n1
set testok=%testname%.ok
set testout=%testname%.out
set testmsgok=%testname%.msgok
set testmsgout=%testname%.msgout
:: Escape for VIM :set command. 
set testmsgoutForSet=%testmsgout:\=/%
set testmsgoutForSet=%testmsgout: =\ %

if exist "%testout%" del "%testout%"
if exist "%testmsgout%" del "%testmsgout%"

echo.Running %testname%:
call vim -n -c "set nomore verbosefile=%testmsgoutForSet%" -c "runtime incubator/CommandWithMutableRange.vim" -S "%testfile%"
set /A cntRun+=1
if exist "%testok%" (
    if exist "%testout%" (
	call :compareFiles "%testok%" "%testout%"
    ) else (
	set /A cntError+=1
	echo.ERROR: No test output. 
    )
) else (
    set /A cntError+=1
    echo.ERROR: No success criteria. 
)
(goto:EOF)

:compareFiles
diff -q %1 %2
if %ERRORLEVEL% EQU 0 (
    set /A cntOk+=1
    echo.OK
) else (
    set /A cntFail+=1
    echo.FAIL: 
    diff --side-by-side --width 80 %1 %2
)
(goto:EOF)

endlocal

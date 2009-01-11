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

set /A thisOk=0
set /A thisError=0
set /A thisFail=0
if exist "%testok%" (
    if exist "%testout%" (
	call :compareOutput "%testok%" "%testout%"
    ) else (
	set /A thisError+=1
	echo.ERROR: No test output. 
    )
)

if exist "%testmsgok%" (
    if exist "%testmsgout%" (
	call :compareMessages "%testmsgok%" "%testmsgout%"
    ) else (
	set /A thisError+=1
	echo.ERROR: No test messages. 
    )
)

set /A thisAll=%thisOk% + %thisError% + %thisFail%
if %thisAll% EQU 0 (
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
(goto:EOF)

:compareOutput
diff -q %1 %2 >NUL
if %ERRORLEVEL% EQU 0 (
    set /A thisOk+=1
    echo.OK
) else if %ERRORLEVEL% EQU 1 (
    set /A thisFail+=1
    echo.FAIL: expected output                   + actual output
    diff --side-by-side --width 80 %1 %2
) else (
    set /A thisError+=1
    echo.ERROR: diff operation failed. 
)
(goto:EOF)

:compareMessages
for /F "delims=" %%l in ('diff -U 1 %1 %2 ^| grep -e "^-[^-]" ^| wc -l') do set missingLines=%%l
if %missingLines% EQU 0 (
    set /A thisOk+=1
    echo.OK
) else (
    set /A thisFail+=1
    echo.FAIL: The following messages were missing in the output: 
    diff -U 1 %1 %2 | grep -e "^-[^-]" | sed "s/^-//"
)
(goto:EOF)

endlocal

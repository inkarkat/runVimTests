@echo off %debug%

set log=%TEMP%\testrun.log
set old=testrun.log

if not exist "%old%" (
    echo.ERROR: Old log "%old%" does not exist!
    exit /B 1
)

call runVimTests.cmd --default . > "%log%"

echo.
echo.DIFFERENCES:
diff -u "%old%" "%log%"


@echo off %debug%
::/*************************************************************************/^--*
::**
::* FILE: 	runVimTests.cmd
::* PRODUCT:	VIM tools
::* AUTHOR: 	/^--
::* DATE CREATED:   12-Jan-2009
::*
::*******************************************************************************
::* DESCRIPTION: 
::	This script implements a small testing framework for VIM. 
::
::* REMARKS: 
::       	
::* DEPENDENCIES:
::  - GNU grep, sed, diff available through 'unix.cmd' script. 
::  - runVimMsgFilter.vim, located in this script's directory. 
::
::* Copyright: (C) 2009 by Ingo Karkat
::   The VIM LICENSE applies to this script; see 'vim -c ":help copyright"'.  
::
::* REVISION	DATE		REMARKS 
::	016	24-Feb-2009	Added short options -0/1/2 for the plugin load
::				level. 
::				Added check for Unix tools; Unix tools can be
::				winked in via 'unix' script. 
::	015	19-Feb-2009	Added explicit option '--user' for the default
::				VIM mode, and adding 'user' to
::				%vimVariableOptionsValue% (so that tests can
::				easily check for that mode). Command-line
::				argument parsing now ensures that only one mode
::				is specified. 
::	014	12-Feb-2009	Shortened -e -s to -es. 
::	013	11-Feb-2009	Merged in changes resulting from the bash
::				implementation of this script: 
::				Variable renamings. 
::				Checking whether VIM executable exists and
::				whether output is to terminal. 
::	012	06-Feb-2009	Renamed g:debug to g:runVimTests; now, script
::				options 'debug' and 'pure' are appended to this
::				variable. This allows for greater flexibility
::				inside VIM and avoids that overly general
::				variable name. 
::				Added command-line options --vimexecutable,
::				--vimversion and --graphical. 
::				Added command-line option --default to launch
::				VIM without any user settings. 
::	011	05-Feb-2009	Replaced runVimTests.cfg with
::				runVimTestsSetup.vim, which is sourced on every
::				test run if it exists. I was mistaken in that
::				:runtime commands don't work in pure mode; that
::				was caused by my .vimrc not setting
::				'runtimepath' to ~/.vim! Thus, there's no need
::				for the "essential VIM scripts" and the
::				--reallypure option. 
::				Split off documentation into separate help file. 
::	010	04-Feb-2009	Suites can now also contain directories and
::				other suite files, not just tests. 
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

call :checkUnixTools || call unix --quiet || goto:prerequisiteError
call :checkUnixTools || goto:prerequisiteError

call :determineUserVimFilesDirspec

:: Prerequisite VIM script to match the message assumptions against the actual
:: message output. 
set runVimMsgFilterScript=%~dp0runVimMsgFilter.vim
if not exist "%runVimMsgFilterScript%" (
    echo.ERROR: Script prerequisite "%runVimMsgFilterScript%" does not exist!
    exit /B 1
)

:: VIM variables set by the test framework. 
set vimVariableOptionsName=g:runVimTests
set vimVariableOptionsValue=
set vimVariableTestName=g:runVimTest

:: VIM mode of sourcing scripts. 
set vimMode=

:: Default VIM executable. 
set vimExecutable=vim

:: Default VIM command-line arguments. 
::
:: Always wait for the edit session to finish (only applies to the GUI version,
:: is ignored for the terminal version), so that this script can process the
:: files generated by the test run. 
set vimArguments=-f

:: Optional user-provided setup scripts. 
set vimLocalSetupScript=_setup.vim
set vimGlobalSetupScript=%~dpn0Setup.vim
if exist "%vimGlobalSetupScript%" set vimArguments=%vimArguments% -S "%vimGlobalSetupScript%"

set isExecutionOutput=1
set EXECUTIONOUTPUT=

:commandLineOptions
set arg=%~1

:: Allow short /o and -o option syntax. 
if /I "%arg:/=-%" == "-h" set arg=--help
if /I "%arg:/=-%" == "-g" set arg=--graphical
if /I "%arg:/=-%" == "-0" set arg=--pure
if /I "%arg:/=-%" == "-1" set arg=--default
if /I "%arg:/=-%" == "-2" set arg=--user

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
if not defined vimExecutable (exit /B 1)

if not defined vimMode (set vimMode=user)
set vimVariableOptionsValue=%vimMode%,%vimVariableOptionsValue%
set vimVariableOptionsValue=%vimVariableOptionsValue:~0,-1%
set vimArguments=%vimArguments% --cmd "let %vimVariableOptionsName%='%vimVariableOptionsValue%'"

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
    %EXECUTIONOUTPUT% echo.%vimExecutable% %vimArguments%
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
    (echo.ERROR: Suite file "%arg%" doesn't exist.)
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

:printShortUsage
(echo.Usage: "%~nx0" [-0^|--pure^|-1^|--default^|-2^|--user] [--source filespec [--source filespec [...]]] [--runtime plugin/file.vim [--runtime autoload/file.vim [...]]] [--vimexecutable path\to\vim.exe^|--vimversion NN] [-g^|--graphical] [--summaryonly] [--debug] [-?^|-h^|--help] test001.vim^|testsuite.txt^|path\to\testdir\ [...])
(goto:EOF)
:printUsage
call :printShortUsage
(echo.Try "%~nx0" --help for more information.)
(goto:EOF)
:printLongUsage
(echo.A small testing framework for VIM.)
(echo.)
call :printShortUsage
(echo.    -0^|--pure		Start VIM without loading any .vimrc and plugins,)
(echo.    			but in nocompatible mode. Adds 'pure' to %vimVariableOptionsName%.)
(echo.    -1^|--default		Start VIM only with default settings and plugins,)
(echo.    			without loading user .vimrc and plugins.)
(echo.    			Adds 'default' to %vimVariableOptionsName%.)
(echo.    -2^|--user		^(Default:^) Start VIM with user .vimrc and plugins.)
(echo.    --source filespec	Source filespec before test execution.)
(echo.    --runtime filespec	Source filespec relative to ~/.vim. Can be used to)
(echo.    			load the script-under-test when using --pure.)
(echo.    --vimexecutable path\to\vim.exe   Use passed VIM executable instead)
(echo.    			of the one found in %%PATH%%.)
(echo.    --vimversion NN	Use VIM version N.N. ^(Must be in standard installation)
(echo.    			directory %ProgramFiles%\vim\vimNN\.^))
(echo.    -g^|--graphical	Use GVIM.)
(echo.    --summaryonly	Do not show detailed transcript and differences,)
(echo.    			during test run, only summary.)
(echo.    --debug		Test debugging mode: Adds 'debug' to %vimVariableOptionsName%)
(echo.    			variable inside VIM ^(so that tests do not exit or can)
(echo.    			produce additional debug info^).)
(goto:EOF)

:checkUnixTools
for %%F in (grep.exe sed.exe diff.exe) do if "%%~$PATH:F" == "" exit /B 1
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
:: escape sequences and suppresses the VIM warning and a small delay:
:: "Vim: Warning: Output is not to a terminal".
:: (Just passing '-T dumb' is not enough.)
::
:: Since the Windows shell cannot tell us whether the output is connected to a
:: terminal, we ask VIM instead by invoking it and checking stderr for the
:: warning message. This also allows us to check at the same time whether
:: %vimExecutable% is a valid executable. (Which would also be difficult
:: to do in the Windows shell, considering that the file extension may be
:: missing from the executable name, so a simple ~$PATH:I search wouldn't be
:: sufficient.) 
set capturedVimErrorOutput=%TEMP%\capturedVimErrorOutput
set vimTerminalArguments=
call %vimExecutable% -f -N -u NONE -c "quitall!" 2>"%capturedVimErrorOutput%"
if %ERRORLEVEL% NEQ 0 (
    (echo.ERROR: "%vimExecutable%" is not a VIM executable!)
    set vimExecutable=
) else (
    findstr /C:"Output is not to a terminal" "%capturedVimErrorOutput%" >NUL && set vimTerminalArguments= -es
)
set vimArguments=%vimArguments%%vimTerminalArguments%
del "%capturedVimErrorOutput%" >NUL 2>&1
(goto:EOF)

:printTestHeader
if not defined isExecutionOutput (goto:EOF)
:: If the first line of the test script starts with '" Test', include this as
:: the test's synopsis in the test header. Otherwise, just print the test name. 
:: Limit the test header to one unwrapped output line, i.e. truncate to 80
:: characters. 
sed -n -e "1s/^\d034 \(Test.*\)$/Running %~2: \1/p" -e "tx" -e "1cRunning %~2:" -e ":x" -- %1 | sed "/^.\{80,\}/s/\(^.\{,76\}\).*$/\1.../"
(goto:EOF)

:addToListFailed
echo.%listFailed% | findstr /C:%1 >NUL || set listFailed=%listFailed%%~1, 
(goto:EOF)
:addToListError
echo.%listError% | findstr /C:%1 >NUL || set listError=%listError%%~1, 
(goto:EOF)

::------------------------------------------------------------------------------
:runDir
for %%f in (%~1*.vim) do call :runTest "%%f"
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
for /F "eol=# delims=" %%f in (%~nx1) do call :processSuiteEntry "%%f"
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
:: Escape for VIM :set command. 
set testMsgoutForSet=%testMsgout:\=/%
set testMsgoutForSet=%testMsgout: =\ %

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

call :printTestHeader "%testFile%" "%testName%"

:: Default VIM arguments and options:
:: -n		No swapfile. 
:: :set nomore	Suppress the more-prompt when the screen is filled with messages
::		or output to avoid blocking. 
:: :set verbosefile Capture all messages in a file. 
:: :let %vimVariableTestName% = Absolute test filespec. 
:: :let %vimVariableOptionsName% = Options for this test run, concatenated with ','. 
::
:: Note: With -S {file}, VIM wants {file} escaped for Ex commands. (It should
:: really escape {file} itself, as it does for normal {file} arguments.)
:: As we don't know the VIM version, we cannot work around this via
::	-c "execute 'source' fnameescape('${testfile}')"
:: Thus, we just escape spaces and hope that no other special string (like %,
:: # or <cword>) is part of a test filename. (On Windows somehow spaces must not
:: necessarily be escaped?!)
call %vimExecutable% -n -c "let %vimVariableTestName%='%testFilespec:'=''%'|set nomore verbosefile=%testMsgoutForSet%" %vimArguments%%vimLocalSetup% -S "%testFile: =\ %"

set /A thisTests=0
set /A thisRun=0
set /A thisOk=0
set /A thisFail=0
set /A thisError=0

:methodOutput
if exist "%testOk%" (
    set /A thisTests+=1
    if exist "%testOut%" (
	set /A thisRun+=1
	call :compareOutput "%testOk%" "%testOut%" "%testName%"
    ) else (
	set /A thisError+=1
	%EXECUTIONOUTPUT% echo.ERROR ^(out^): No test output.
    )
)

:methodMessageOutput
if exist "%testMsgok%" (
    set /A thisTests+=1
    if exist "%testMsgout%" (
	set /A thisRun+=1
	call :compareMessages "%testMsgok%" "%testMsgout%" "%testName%"
    ) else (
	set /A thisError+=1
	%EXECUTIONOUTPUT% echo.ERROR ^(msgout^): No test messages.
    )
)

:methodTap
if exist "%testTap%" (
    call :parseTapOutput "%testTap%" "%testName%"
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
    call :addToListFailed "%testName%"
)
if %thisError% GEQ 1 (
    set /A cntError+=%thisError%
    call :addToListError "%testName%"
)
popd
(goto:EOF)

:compareOutput
diff -q -- %1 %2 >NUL
if %ERRORLEVEL% EQU 0 (
    set /A thisOk+=1
    %EXECUTIONOUTPUT% echo.OK ^(out^)
) else if %ERRORLEVEL% EQU 1 (
    set /A thisFail+=1
    %EXECUTIONOUTPUT% echo.FAIL ^(out^): expected output           ^|   actual output
    %EXECUTIONOUTPUT% diff --side-by-side --width 80 -- %1 %2
) else (
    set /A thisError+=1
    %EXECUTIONOUTPUT% echo.ERROR ^(out^): diff operation failed.
)
(goto:EOF)

:compareMessages
set testMsgresult=%~3.msgresult
if exist "%testMsgresult%" del "%testMsgresult%"
:: Note: Cannot use silent-batch mode (-es) here, because that one messes up
:: the console. (Except when the entire test log is not printed to stdout but
:: redirected.) 
call vim %vimTerminalArguments% -N -u NONE -n -c "set nomore" -S "%runVimMsgFilterScript%" -c "RunVimMsgFilter" -c "quitall!" -- "%testMsgok%"
if not exist "%testMsgresult%" (
    set /A thisError+=1
    %EXECUTIONOUTPUT% echo.ERROR ^(msgout^): Evaluation of test messages failed.
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
    exit 1
)
%EXECUTIONOUTPUT% type "%testMsgresult%"
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

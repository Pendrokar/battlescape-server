@echo off
setlocal EnableExtensions EnableDelayedExpansion

call "%~dp0ib_env.bat"
if errorlevel 1 exit /b 1

if /i "%~1"=="help" goto :usage
if /i "%~1"=="-h" goto :usage
if /i "%~1"=="/?" goto :usage
if /i "%~1"=="-help" goto :usage
if /i "%~1"=="--help" goto :usage

if not "%~2"=="" (
    echo ERROR: Incorrect command argument "%~2".
    echo Only an optional PID is accepted.
    goto :usage
)

set "TARGET="
set "SOURCE="

if not "%~1"=="" (
    echo %~1| findstr /r /c:"^[1-9][0-9]*$" >nul
    if errorlevel 1 (
        echo ERROR: Incorrect command argument "%~1".
        echo Expected a numeric PID.
        goto :usage
    )
    set "TARGET=%~1"
    set "SOURCE=argument"
) else if exist "%IB_SERVER_PID_FILE%" (
    set /p TARGET=<"%IB_SERVER_PID_FILE%"
    set "SOURCE=pid file"
)

if not defined TARGET goto :fallback
if "%TARGET%"=="" goto :fallback

call :kill_pid %TARGET%
if errorlevel 1 (
    if /i "%SOURCE%"=="argument" exit /b 1
    echo Saved server PID %TARGET% is not a running IB process. Searching by command line...
    goto :fallback
)

if exist "%IB_SERVER_PID_FILE%" (
    set /p FILEPID=<"%IB_SERVER_PID_FILE%"
    if "!FILEPID!"=="%TARGET%" del "%IB_SERVER_PID_FILE%" >nul 2>&1
)
exit /b 0

:fallback
set "IB_KILL_MARKER=%TEMP%\ib_kill_server_%RANDOM%.txt"
if exist "%IB_KILL_MARKER%" del "%IB_KILL_MARKER%" >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command "$n = 0; Get-CimInstance Win32_Process -Filter 'Name=''Infinity Battlescape.exe''' | Where-Object { $_.CommandLine -match '(^|\s)-server(\s|$)' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue; Write-Output $_.ProcessId; $n++ }; if ($n -eq 0) { exit 2 }" > "%IB_KILL_MARKER%"

if errorlevel 2 (
    if exist "%IB_KILL_MARKER%" del "%IB_KILL_MARKER%" >nul 2>&1
    if exist "%IB_SERVER_PID_FILE%" del "%IB_SERVER_PID_FILE%" >nul 2>&1
    echo No Infinity Battlescape server process is running.
    exit /b 0
)

echo Stopped IB server process^(es^):
type "%IB_KILL_MARKER%"
if exist "%IB_SERVER_PID_FILE%" del "%IB_SERVER_PID_FILE%" >nul 2>&1
if exist "%IB_KILL_MARKER%" del "%IB_KILL_MARKER%" >nul 2>&1
exit /b 0

:kill_pid
set "KPID=%~1"
tasklist /FI "PID eq %KPID%" /NH | findstr /i "%KPID%" >nul
if errorlevel 1 (
    echo Process %KPID% is not running.
    exit /b 1
)
tasklist /FI "PID eq %KPID%" /NH | findstr /i "Infinity" >nul
if errorlevel 1 (
    echo ERROR: PID %KPID% is not an Infinity Battlescape process. Refusing to kill it.
    exit /b 1
)
taskkill /PID %KPID% /F
if errorlevel 1 (
    echo Failed to terminate process %KPID%.
    exit /b 1
)
echo Process %KPID% terminated successfully.
exit /b 0

:usage
echo.
echo Usage: %~nx0 [PID]
echo.
echo Stop the local Infinity Battlescape server process.
echo.
echo   %~nx0          Kill the PID in server.pid, or any IB process launched with -server
echo   %~nx0 1234     Kill that PID if it is an Infinity Battlescape process
echo.
echo Incorrect arguments abort without killing a process.
exit /b 1

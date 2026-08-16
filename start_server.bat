@echo off
setlocal EnableExtensions EnableDelayedExpansion

call "%~dp0ib_env.bat"
if errorlevel 1 exit /b 1

set "USE_STEAM=0"
set "SERVER_MODE=private"
set "USE_REBOOT=1"
set "MISSION=%IB_MISSION_DEFAULT%"
set "SERVERCONFIG=%IB_SERVERCONFIG%"

:parse
if "%~1"=="" goto :parsed
if /i "%~1"=="help" goto :usage
if /i "%~1"=="-h" goto :usage
if /i "%~1"=="/?" goto :usage
if /i "%~1"=="-help" goto :usage
if /i "%~1"=="--help" goto :usage

if /i "%~1"=="steam" (
    set "USE_STEAM=1"
    shift
    goto :parse
)
if /i "%~1"=="nosteam" (
    set "USE_STEAM=0"
    shift
    goto :parse
)
if /i "%~1"=="public" (
    set "SERVER_MODE=public"
    shift
    goto :parse
)
if /i "%~1"=="private" (
    set "SERVER_MODE=private"
    shift
    goto :parse
)
if /i "%~1"=="db" (
    set "USE_REBOOT=0"
    shift
    goto :parse
)
if /i "%~1"=="reboot" (
    set "USE_REBOOT=1"
    shift
    goto :parse
)
if /i "%~1"=="mission" (
    if "%~2"=="" (
        echo ERROR: Incorrect command argument. "mission" requires a path.
        goto :usage
    )
    set "MISSION=%~2"
    shift
    shift
    goto :parse
)
if /i "%~1"=="config" (
    if "%~2"=="" (
        echo ERROR: Incorrect command argument. "config" requires a serverconfig name or path.
        goto :usage
    )
    set "SERVERCONFIG=%~2"
    shift
    shift
    goto :parse
)

echo ERROR: Incorrect command argument "%~1".
echo The server was not started.
goto :usage

:parsed
if not exist "%IB_EXE%" (
    echo ERROR: Game executable not found:
    echo   "%IB_EXE%"
    exit /b 1
)
if not exist "%IB_BIN%" (
    echo ERROR: IB Bin directory not found:
    echo   "%IB_BIN%"
    exit /b 1
)
if not exist "%MISSION%" (
    echo ERROR: Mission file not found:
    echo   "%MISSION%"
    echo The server was not started.
    exit /b 1
)

if exist "%IB_SERVER_PID_FILE%" (
    set /p OLDPID=<"%IB_SERVER_PID_FILE%"
    if defined OLDPID (
        tasklist /FI "PID eq !OLDPID!" /NH | findstr /i "!OLDPID!" >nul
        if not errorlevel 1 (
            echo ERROR: Server already running as PID !OLDPID!.
            echo Stop it first: kill_server.bat
            exit /b 1
        )
    )
    del "%IB_SERVER_PID_FILE%" >nul 2>&1
)

set "IB_USE_STEAM=%USE_STEAM%"
set "IB_SERVER_MODE=%SERVER_MODE%"
set "IB_REBOOT=%USE_REBOOT%"
set "IB_MISSION=%MISSION%"
set "IB_SERVERCONFIG=%SERVERCONFIG%"

echo Starting Infinity Battlescape server...
echo   Working dir : "%IB_BIN%"
echo   Mission     : "%MISSION%"
echo   Config      : "%SERVERCONFIG%"
if "%SERVER_MODE%"=="public" (
    echo   Mode        : dedicated public
) else (
    echo   Mode        : shared private
)
if "%USE_STEAM%"=="1" (echo   Steam       : yes) else (echo   Steam       : no)
if "%USE_REBOOT%"=="1" (echo   Reboot/no-DB: yes) else (echo   Reboot/no-DB: no)
if exist "%IB_DOCS_SERVER%\%SERVERCONFIG%" (
    echo   Documents   : "%IB_DOCS_SERVER%\%SERVERCONFIG%"
) else (
    echo   Documents   : "%SERVERCONFIG%" not found yet -- the game copies it from Dev\ on first run.
)

REM Launch outside the parent job so the server keeps running after this window closes.
set "IB_LAUNCH_EXTRA="
if "%USE_STEAM%"=="1" set "IB_LAUNCH_EXTRA=%IB_LAUNCH_EXTRA% -steam"
if "%SERVER_MODE%"=="public" (set "IB_LAUNCH_MODE=-dedicated -public") else (set "IB_LAUNCH_MODE=-shared -private")
set "IB_LAUNCH_REBOOT="
if "%USE_REBOOT%"=="1" set "IB_LAUNCH_REBOOT=-reboot"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ib_launch.ps1" -PidFile "%IB_SERVER_PID_FILE%" %IB_LAUNCH_EXTRA% -server %IB_LAUNCH_MODE% %IB_LAUNCH_REBOOT% -mission "%MISSION%" -serverconfig "%SERVERCONFIG%"

if not exist "%IB_SERVER_PID_FILE%" (
    echo ERROR: Failed to start the server process.
    exit /b 1
)

set /p NEWPID=<"%IB_SERVER_PID_FILE%"
if not defined NEWPID (
    echo ERROR: Server started but no PID was recorded.
    exit /b 1
)

ping 127.0.0.1 -n 3 >nul
tasklist /FI "PID eq %NEWPID%" /NH | findstr /i "%NEWPID%" >nul
if errorlevel 1 (
    echo ERROR: Server process %NEWPID% exited immediately. Check the game logs.
    del "%IB_SERVER_PID_FILE%" >nul 2>&1
    exit /b 1
)

echo Waiting for ServerStarted ^(client splash poll needs this signaled^)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ib_wait_event.ps1" -Name ServerStarted -TimeoutSec 30
if errorlevel 1 (
    echo WARNING: Server process is up but ServerStarted was not signaled.
    echo A -shared client will not LocalPlayer-join.
) else (
    echo ServerStarted is signaled. start_client.bat can join as LocalPlayer.
)

echo.
echo Server started as PID %NEWPID%
echo PID file: "%IB_SERVER_PID_FILE%"
echo Stop with: kill_server.bat
echo            kill_server.bat %NEWPID%
exit /b 0

:usage
echo.
echo Usage: %~nx0 [options]
echo.
echo Start a local Infinity Battlescape dedicated server as a separate process.
echo Commands are launched from the IB Bin directory.
echo Creates named events ServerStarted/ServerClosed so a -shared client
echo can LocalPlayer-join. Start the server before start_client.bat.
echo.
echo Options:
echo   steam              Add -steam
echo   nosteam            Do not add -steam ^(default^)
echo   private            -shared -private ^(default, matches notes^)
echo   public             -dedicated -public instead
echo   reboot             Do not load DB ^(default, -reboot^)
echo   db                 Load DB ^(omit -reboot^)
echo   mission ^<xml^>      Mission file ^(default: Documents Workshop\Empty.xml^)
echo   config ^<xml^>       -serverconfig name ^(default: LocalServerConfig.xml^)
echo   help               Show this help
echo.
echo Examples:
echo   %~nx0
echo   %~nx0 steam
echo   %~nx0 public
echo   %~nx0 mission "%IB_MISSION_DEFAULT%"
echo.
echo Incorrect arguments abort without starting a process.
echo Stop a running server with kill_server.bat
exit /b 1

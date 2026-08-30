@echo off
setlocal EnableExtensions EnableDelayedExpansion

call "%~dp0ib_env.bat"
if errorlevel 1 exit /b 1

set "USE_STEAM=1"
set "USE_JOIN=1"
set "USE_OFFLINE=1"
set "USE_AUTH=1"
set "USE_PASSWORD=0"
set "USE_SHARED=0"
set "USE_DIRECT=1"
set "USE_NOPRELOAD=1"
set "AUTH_TOKEN="
set "HOST=%IB_HOST%"
set "PORT=%IB_PORT%"
set "PORTRANGE=%IB_PORTRANGE%"
set "USERNAME=%IB_USERNAME%"
set "PASSWORD=%IB_PASSWORD%"

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
if /i "%~1"=="join" (
    set "USE_JOIN=1"
    shift
    goto :parse
)
if /i "%~1"=="offline" (
    set "USE_OFFLINE=1"
    shift
    goto :parse
)
if /i "%~1"=="nooffline" (
    set "USE_OFFLINE=0"
    shift
    goto :parse
)
if /i "%~1"=="shared" (
    set "USE_SHARED=1"
    shift
    goto :parse
)
if /i "%~1"=="noshared" (
    set "USE_SHARED=0"
    shift
    goto :parse
)
if /i "%~1"=="direct" (
    set "USE_DIRECT=1"
    shift
    goto :parse
)
if /i "%~1"=="nopreload(
    set "USE_NOPRELOAD=1"
    shift
    goto :parse
)
if /i "%~1"=="nodirect" (
    set "USE_DIRECT=0"
    shift
    goto :parse
)
if /i "%~1"=="noauth" (
    set "USE_AUTH=0"
    set "AUTH_TOKEN="
    shift
    goto :parse
)
if /i "%~1"=="auth" (
    set "USE_AUTH=1"
    if "%~2"=="" (
        shift
        goto :parse
    )
    if /i "%~2"=="steam" (shift & goto :parse)
    if /i "%~2"=="nosteam" (shift & goto :parse)
    if /i "%~2"=="join" (shift & goto :parse)
    if /i "%~2"=="offline" (shift & goto :parse)
    if /i "%~2"=="nooffline" (shift & goto :parse)
    if /i "%~2"=="shared" (shift & goto :parse)
    if /i "%~2"=="noshared" (shift & goto :parse)
    if /i "%~2"=="direct" (shift & goto :parse)
    if /i "%~2"=="nodirect" (shift & goto :parse)
    if /i "%~2"=="noauth" (shift & goto :parse)
    if /i "%~2"=="username" (shift & goto :parse)
    if /i "%~2"=="password" (shift & goto :parse)
    if /i "%~2"=="host" (shift & goto :parse)
    if /i "%~2"=="port" (shift & goto :parse)
    if /i "%~2"=="portrange" (shift & goto :parse)
    if /i "%~2"=="help" (shift & goto :parse)
    set "AUTH_TOKEN=%~2"
    shift
    shift
    goto :parse
)
if /i "%~1"=="username" (
    if "%~2"=="" (
        echo ERROR: Incorrect command argument. "username" requires a name.
        goto :usage
    )
    set "USERNAME=%~2"
    shift
    shift
    goto :parse
)
if /i "%~1"=="password" (
    if "%~2"=="" (
        echo ERROR: Incorrect command argument. "password" requires a value.
        goto :usage
    )
    set "PASSWORD=%~2"
    set "USE_PASSWORD=1"
    shift
    shift
    goto :parse
)
if /i "%~1"=="host" (
    if "%~2"=="" (
        echo ERROR: Incorrect command argument. "host" requires an IP or hostname.
        goto :usage
    )
    set "HOST=%~2"
    shift
    shift
    goto :parse
)
if /i "%~1"=="port" (
    if "%~2"=="" (
        echo ERROR: Incorrect command argument. "port" requires a number.
        goto :usage
    )
    echo %~2| findstr /r /c:"^[0-9][0-9]*$" >nul
    if errorlevel 1 (
        echo ERROR: Incorrect command argument for port: "%~2"
        echo Expected a positive integer.
        goto :usage
    )
    set "PORT=%~2"
    shift
    shift
    goto :parse
)
if /i "%~1"=="portrange" (
    if "%~2"=="" (
        echo ERROR: Incorrect command argument. "portrange" requires a number.
        goto :usage
    )
    echo %~2| findstr /r /c:"^[0-9][0-9]*$" >nul
    if errorlevel 1 (
        echo ERROR: Incorrect command argument for portrange: "%~2"
        echo Expected a positive integer.
        goto :usage
    )
    set "PORTRANGE=%~2"
    shift
    shift
    goto :parse
)

echo ERROR: Incorrect command argument "%~1".
echo The client was not started.
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
if not defined HOST (
    echo ERROR: Host is empty.
    echo The client was not started.
    exit /b 1
)
if not defined USERNAME (
    echo ERROR: Username is empty.
    echo The client was not started.
    exit /b 1
)

if exist "%IB_CLIENT_PID_FILE%" (
    set /p OLDPID=<"%IB_CLIENT_PID_FILE%"
    if defined OLDPID (
        tasklist /FI "PID eq !OLDPID!" /NH | findstr /i "!OLDPID!" >nul
        if not errorlevel 1 (
            echo ERROR: Client already running as PID !OLDPID!.
            echo Stop it first: kill_client.bat
            exit /b 1
        )
    )
    del "%IB_CLIENT_PID_FILE%" >nul 2>&1
)

set "IB_USE_STEAM=%USE_STEAM%"
set "IB_OFFLINE=%USE_OFFLINE%"
set "IB_USE_AUTH=%USE_AUTH%"
set "IB_AUTH_TOKEN=%AUTH_TOKEN%"
set "IB_HOST=%HOST%"
set "IB_PORT=%PORT%"
set "IB_PORTRANGE=%PORTRANGE%"
set "IB_USERNAME=%USERNAME%"
set "IB_PASSWORD=%PASSWORD%"

echo Starting Infinity Battlescape client...
echo   Working dir : "%IB_BIN%"
if "%USE_SHARED%"=="1" (echo   Shared      : yes ^(LocalPlayer after ServerStarted^)) else (echo   Shared      : no)
if "%USE_DIRECT%"=="1" (
    echo   Direct/host : %HOST%
    echo   Port        : %PORT%  ^(range %PORTRANGE%^)
) else (
    echo   Direct      : no
)
echo   Username    : %USERNAME%
if "%USE_STEAM%"=="1" (echo   Steam       : yes) else (echo   Steam       : no)
if "%USE_OFFLINE%"=="1" (echo   Offline     : yes ^(notes: may sit on the loading screen^)) else (echo   Offline     : no)
if "%USE_PASSWORD%"=="1" (echo   Server pwd  : set) else (echo   Server pwd  : omitted)
if "%USE_AUTH%"=="1" (
    if defined AUTH_TOKEN (echo   Auth        : token set) else (echo   Auth        : flag only, no token)
) else (
    echo   Auth        : omitted
)

if "%USE_SHARED%"=="1" (
    echo Waiting for local server event ServerStarted...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ib_wait_event.ps1" -Name ServerStarted -TimeoutSec 90
    if errorlevel 1 (
        echo WARNING: ServerStarted was not signaled.
        echo Start the dedicated server first with start_server.bat
        echo The client splash poll is 0 ms and will skip LocalPlayer join.
    ) else (
        echo ServerStarted is signaled. Launching client.
    )
)

REM Launch outside the parent job so the game keeps running after this window closes.
set "IB_LAUNCH_EXTRA="
if "%USE_STEAM%"=="1" set "IB_LAUNCH_EXTRA=%IB_LAUNCH_EXTRA% -steam"
if "%USE_JOIN%"=="1" set "IB_LAUNCH_EXTRA=%IB_LAUNCH_EXTRA% -join"
if "%USE_OFFLINE%"=="1" set "IB_LAUNCH_EXTRA=%IB_LAUNCH_EXTRA% -offline"
if "%USE_SHARED%"=="1" set "IB_LAUNCH_EXTRA=%IB_LAUNCH_EXTRA% -shared"
if "%USE_NOPRELOAD%"=="1" set "IB_LAUNCH_EXTRA=%IB_LAUNCH_EXTRA% -nopreload"
set "IB_LAUNCH_AUTH="
if "%USE_AUTH%"=="1" (
    if defined AUTH_TOKEN (set "IB_LAUNCH_AUTH=-auth %AUTH_TOKEN%") else (set "IB_LAUNCH_AUTH=-auth")
)
set "IB_LAUNCH_PASSWORD="
if "%USE_PASSWORD%"=="1" set "IB_LAUNCH_PASSWORD=-serverpassword %PASSWORD%"
set "IB_LAUNCH_DIRECT="
if "%USE_DIRECT%"=="1" (
    set "IB_LAUNCH_DIRECT=-direct %HOST% -host %HOST% %IB_LAUNCH_PASSWORD% -port %PORT% -portrange %PORTRANGE% -username %USERNAME%"
) else (
    set "IB_LAUNCH_DIRECT=-host %HOST% -port %PORT% -portrange %PORTRANGE% -username %USERNAME%"
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ib_launch.ps1" -PidFile "%IB_CLIENT_PID_FILE%" %IB_LAUNCH_EXTRA% %IB_LAUNCH_DIRECT% %IB_LAUNCH_AUTH%

if not exist "%IB_CLIENT_PID_FILE%" (
    echo ERROR: Failed to start the client process.
    exit /b 1
)

set /p NEWPID=<"%IB_CLIENT_PID_FILE%"
if not defined NEWPID (
    echo ERROR: Client started but no PID was recorded.
    exit /b 1
)

ping 127.0.0.1 -n 3 >nul
tasklist /FI "PID eq %NEWPID%" /NH | findstr /i "%NEWPID%" >nul
if errorlevel 1 (
    echo ERROR: Client process %NEWPID% exited immediately. Check the game logs.
    del "%IB_CLIENT_PID_FILE%" >nul 2>&1
    exit /b 1
)

echo.
echo Client started as PID %NEWPID%
echo PID file: "%IB_CLIENT_PID_FILE%"
echo Stop with: kill_client.bat
echo            kill_client.bat %NEWPID%
exit /b 0

:usage
echo.
echo Usage: %~nx0 [options]
echo.
echo Start an Infinity Battlescape client aimed at the local dedicated server.
echo This is a separate process from start_server.bat.
echo Default: -steam -shared. The client polls ServerStarted at splash and
echo joins as LocalPlayer if start_server.bat has already signaled it.
echo -direct only lists the server in the browser and is rejected locally
echo ^(Player 0 with an empty name^). -mission is a server-only flag.
echo.
echo Options:
echo   steam                 Add -steam ^(default; client launched as from the Steam environment^)
echo   nosteam               Omit -steam
echo   shared                Add -shared and wait for ServerStarted ^(default^)
echo   noshared              Omit -shared
echo   direct                Also add -direct/-host/-port ^(browser list; local reject^)
echo   nodirect              Omit -direct ^(default^)
echo   nopreload             Add -nopreload ^(default^)
echo   offline               Add -offline
echo   nooffline             Omit -offline ^(default^)
echo   auth [token]          Add -auth, optionally with a token
echo   noauth                Omit -auth ^(default; local servers do not use Steam tokens^)
echo   username ^<name^>       Default: Pendrokar
echo   password ^<password^>   Add -serverpassword. Default omitted; admin password is abcd1234
echo   host ^<ip^>             Default: 127.0.0.1
echo   port ^<n^>              Default: 7778
echo   portrange ^<n^>         Default: 1
echo   help                  Show this help
echo.
echo Examples:
echo   %~nx0
echo   %~nx0 offline
echo   %~nx0 direct
echo   %~nx0 username Pendrokar password abcd1234
echo   %~nx0 host 127.0.0.1 port 7778
echo.
echo Incorrect arguments abort without starting a process.
echo Stop a running client with kill_client.bat
exit /b 1

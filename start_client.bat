@echo off
setlocal EnableExtensions EnableDelayedExpansion

call "%~dp0ib_env.bat"
if errorlevel 1 exit /b 1

set "USE_STEAM=0"
set "USE_OFFLINE=0"
set "USE_AUTH=0"
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
    if /i "%~2"=="offline" (shift & goto :parse)
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
echo   Direct/host : %HOST%
echo   Port        : %PORT%  ^(range %PORTRANGE%^)
echo   Username    : %USERNAME%
if "%USE_STEAM%"=="1" (echo   Steam       : yes) else (echo   Steam       : no)
if "%USE_OFFLINE%"=="1" (echo   Offline     : yes ^(notes: may sit on the loading screen^)) else (echo   Offline     : no)
if "%USE_AUTH%"=="1" (
    if defined AUTH_TOKEN (echo   Auth        : token set) else (echo   Auth        : flag only, no token)
) else (
    echo   Auth        : omitted
)

REM Must stay outside parenthesized blocks: PowerShell uses ^( ^).
REM Quote args that contain spaces. Start-Process -ArgumentList does not.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$list = New-Object System.Collections.Generic.List[string]; if ($env:IB_USE_STEAM -eq '1') { $list.Add('-steam') }; if ($env:IB_OFFLINE -eq '1') { $list.Add('-offline') }; $list.Add('-direct'); $list.Add('-join'); $list.Add($env:IB_HOST); $list.Add('-host'); $list.Add($env:IB_HOST); $list.Add('-serverpassword'); $list.Add($env:IB_PASSWORD); $list.Add('-port'); $list.Add($env:IB_PORT); $list.Add('-portrange'); $list.Add($env:IB_PORTRANGE); $list.Add('-username'); $list.Add($env:IB_USERNAME); if ($env:IB_USE_AUTH -eq '1') { $list.Add('-auth'); if ($env:IB_AUTH_TOKEN) { $list.Add($env:IB_AUTH_TOKEN) } }; $parts = New-Object System.Collections.Generic.List[string]; foreach ($a in $list) { if ($a -match '\s') { $parts.Add(([string][char]34 + $a + [char]34)) } else { $parts.Add($a) } }; $psi = New-Object System.Diagnostics.ProcessStartInfo; $psi.FileName = $env:IB_EXE; $psi.WorkingDirectory = $env:IB_BIN; $psi.UseShellExecute = $true; $psi.Arguments = [string]::Join(' ', $parts.ToArray()); $p = [Diagnostics.Process]::Start($psi); Set-Content -Path $env:IB_CLIENT_PID_FILE -Value $p.Id -Encoding ascii"

if not exist "%IB_CLIENT_PID_FILE%" (
    echo ERROR: Failed to start the client process.
    exit /b 1
)

set /p NEWPID=<"%IB_CLIENT_PID_FILE%"
if not defined NEWPID (
    echo ERROR: Client started but no PID was recorded.
    exit /b 1
)

timeout /t 1 /nobreak >nul
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
echo -direct/-host/-port only list the server in the multiplayer browser.
echo The exe does not auto-join an already-running dedicated server from the CLI.
echo.
echo Options:
echo   steam                 Add -steam ^(marks a Steam-environment launch; not for local servers^)
echo   nosteam               Omit -steam ^(default; standalone / local dedicated server^)
echo   offline               Add -offline
echo   nooffline             Omit -offline ^(default^)
echo   auth [token]          Add -auth, optionally with a token
echo   noauth                Omit -auth ^(default; local servers do not use Steam tokens^)
echo   username ^<name^>       Default: Pendrokar
echo   password ^<password^>   Default: abcd1234 ^(Admin password in server config^)
echo   host ^<ip^>             Default: 127.0.0.1
echo   port ^<n^>              Default: 7778
echo   portrange ^<n^>         Default: 1
echo   help                  Show this help
echo.
echo Examples:
echo   %~nx0
echo   %~nx0 offline
echo   %~nx0 username Pendrokar password abcd1234
echo   %~nx0 host 127.0.0.1 port 7778
echo.
echo Incorrect arguments abort without starting a process.
echo Stop a running client with kill_client.bat
exit /b 1
